savedTextures = {}
loaded = {}
streaming = {}

local fileNames = {}
local errorLoading = false

-- store encrypted file names so they can be used in case of needing to clear cache
function encryptFileNameClient(url)
	local new = sha256(tostring(url))
	if new then addFilenameToList(new) end
	return new
end

function addFilenameToList(name)

	if errorLoading then return end
	fileNames[name] = true
end

addEventHandler( "onClientResourceStop", resourceRoot,
function ()
	-- Save the file names list to file
	local file
	if not fileExists(listFilePath) then
		file = xmlCreateFile(listFilePath, rootNodeName)
	else
		file = xmlLoadFile(listFilePath)
	end
	if not file then

		return print("Error(2) opening file: "..listFilePath)
	end

	local names = xmlNodeGetChildren(file)
	if not names then
		return print("Error(2) getting file names on parent: "..rootNodeName)
	end

	-- Don't add to the file those already there
	for i,n in pairs(names) do
		local nn = xmlNodeGetName(n)
    	if tostring(nn) == tostring(entryNodeName) then
    		local nv = tostring(xmlNodeGetValue(n))
    		if fileNames[nv] then
    			fileNames[nv] = nil
    		end
    	end
	end

	for fileName,_  in pairs(fileNames) do
		local newEntry = xmlCreateChild(file, entryNodeName)
	    if not newEntry then
	    	break
	    end
	    xmlNodeSetValue(newEntry, fileName)
    end

    xmlSaveFile(file)
    xmlUnloadFile(file)
end)


addEventHandler( "onClientResourceStart", resourceRoot,
function()
	-- Load saved file names into Lua table

	local file
	if not fileExists(listFilePath) then
		file = xmlCreateFile(listFilePath, rootNodeName)
	else
		file = xmlLoadFile(listFilePath)
	end
	if not file then

		errorLoading = true
		return print("Error(1) opening file: "..listFilePath)
	end

    local names = xmlNodeGetChildren(file)
    if not names then
    	errorLoading = true
    	xmlUnloadFile(file)
		return print("Error(1) getting file names on parent: "..rootNodeName)
    end

    local count = 0
    for k, n in pairs(names) do
    	local nn = xmlNodeGetName(n)
    	if tostring(nn) == tostring(entryNodeName) then
    		local nv = tostring(xmlNodeGetValue(n))
    		if nv then
    			local fn = string.format(cacheFileName, nv)
    			if not fileExists(fn) then
	    			xmlDestroyNode(n)
	    		else
	    			fileNames[nv] = true
	    			count = count +1
	    		end
    		else
	    		xmlDestroyNode(n)
	    	end
    	else
	    	xmlDestroyNode(n)
	    end
    end

    xmlSaveFile(file)
    xmlUnloadFile(file)

    -- print("[texture-system] Found "..count.." cached files.")
end)

function flushTextureSystemCache()

	-- Deletes all cached files
	local count = 0
	for fileName,_ in pairs(fileNames) do
		local fn = string.format(cacheFileName, fileName)
		if fileExists(fn) then
			fileDelete(fn)
			fileNames[fileName] = nil
			count = count + 1
		end
	end
	-- remove all current textures
	for k, v in pairs(loaded) do
		engineRemoveShaderFromWorldTexture(v.shader, v.texname)
		destroyElement(getElementData(v.texture, "window") or v.texture)
		destroyElement(v.shader)
	end
	loaded = {}
	streaming = {}
	savedTextures = {}

	outputChatBox("Flushed "..count.." loaded interior textures.", 0,255,0)

	triggerLatentServerEvent('frames:loadInteriorTextures', localPlayer, getElementDimension(localPlayer))
end
addEvent("texture-system:flush_client", true)
addEventHandler("texture-system:flush_client", root, flushTextureSystemCache)
addCommandHandler("flush", flushTextureSystemCache, false, false)


function getPath(url)
	return string.format(cacheFileName, encryptFileNameClient(url))
end

function addTexture(id)
	-- current dimension?
	local dimension = getElementDimension(localPlayer)
	local data = savedTextures[dimension] and savedTextures[dimension][id]
	if not data then return end

	local rotation = data.rotation or 0
	local path = getPath(data.url)
	if data.url:sub(1, 4) == "cef+" then
		local texture = loadBrowserTexture(data, {dimension = dimension, id = id})
		if texture then
			local texName = data.texture
			local shader, t = dxCreateShader(rotation > 0 and 'shaders/replacement_rot.fx' or 'shaders/replacement.fx', 0, 0, true, 'world,object')
			if shader then
				dxSetShaderValue(shader, 'Tex0', texture)

				if rotation > 0 then
					dxSetShaderValue(shader, "gUVRotAngle", math.rad(rotation))
				end

				engineApplyShaderToWorldTexture(shader, texName)

				loaded[id] = { texture = texture, shader = shader, texname = texName }
			else
				outputDebugString('creating shader for tex ' .. data.texture .. ' failed.', 2)
				destroyElement(texture)
			end
		else
			outputDebugString('creating texture for tex ' .. data.texture .. ' failed', 2)
		end
	elseif fileExists(path) then
		streaming[id] = nil

		-- file available locally, just need to really create it
		local texture = dxCreateTexture(path, "argb", true, "clamp", "2d", 1)
		if texture then
			local shader, t = dxCreateShader(rotation > 0 and 'shaders/replacement_rot.fx' or 'shaders/replacement.fx', 0, 0, true, 'world,object')
			if shader then
				dxSetShaderValue(shader, 'Tex0', texture)

				if rotation > 0 then
					dxSetShaderValue(shader, "gUVRotAngle", math.rad(rotation))
				end

				local texName = data.texture
				engineApplyShaderToWorldTexture(shader, texName)

				loaded[id] = { texture = texture, shader = shader, texname = texName }
			else
				outputDebugString('creating shader for tex ' .. data.texture .. ' failed.', 2)
				destroyElement(texture)
			end
		else
			outputDebugString('creating texture for tex ' .. data.texture .. ' failed', 2)
		end
	else
		if not streaming[id] then
			streaming[id] = true
			-- triggerServerEvent('frames:stream', resourceRoot, dimension, id)
			triggerLatentServerEvent('frames:stream', resourceRoot, dimension, id)
		end
	end
end

addEvent('frames:list', true)
addEventHandler('frames:list', resourceRoot,
	function(dimension, textures)
		-- outputDebugString('received updated texture list')
		savedTextures[dimension] = textures

		-- remove all current textures
		for k, v in pairs(loaded) do
			engineRemoveShaderFromWorldTexture(v.shader, v.texname)
			destroyElement(getElementData(v.texture, "window") or v.texture)
			destroyElement(v.shader)
		end
		loaded = {}

		-- applying all possible textures
		if getElementDimension(localPlayer) == dimension and textures then
			for k in pairs(textures) do
				addTexture(k)
			end
		end
	end)

-- file we asked for is there
addEvent('frames:file', true)
addEventHandler( 'frames:file', resourceRoot,
	function(id, url, content, size)
		local file = fileCreate(getPath(url))
		local written = fileWrite(file, content)
		fileClose(file)

		if written ~= size then
			fileDelete(getPath(url))
		else
			addTexture(id)
		end
	end, false)

addEvent('frames:removeOne', true)
addEventHandler('frames:removeOne', resourceRoot,
	function(interior, id, texName)

		local v = loaded[id]
		if v then
			engineRemoveShaderFromWorldTexture(v.shader, v.texname)
			destroyElement(getElementData(v.texture, "window") or v.texture)
			destroyElement(v.shader)

			loaded[id] = nil
		end

		local data = savedTextures[interior]
		if data and not texName then
			data[id] = nil
		end

		if texName then
			-- apply preview
			engineApplyShaderToWorldTexture ( hlReplacement, texName )
			hl = dxCreateTexture ( "files/hl.png" )

			if hl then
				dxSetShaderValue ( hlReplacement, "Tex0", hl )
				hlTexname = texName
				hlTexID = tonumber(id)

				triggerEvent("displayMesaage", localPlayer, "Highlighting texture:  "..texName, "success")
			end
		end
	end, false)

addEvent('frames:addOne', true)
addEventHandler('frames:addOne', resourceRoot,
	function(dimension, data)
		if not savedTextures[dimension] then
			savedTextures[dimension] = {}
		end
		savedTextures[dimension][data.id] = data
		addTexture(data.id)
	end)
