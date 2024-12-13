local debugMode = false

queueList = {}
-- interval = 500
interval = 200

local loaded = {}
local unshaded = {}
local streaming = {}

local fileNames = {}
local errorLoading = false

local pending_local = {}

-- store encrypted file names so they can be used in case of needing to clear cache
function encryptFileNameClient(url)
	
	local ext = GetFileExtension(url)
	local new = removeExtension(ext, url)
	new = md5(new)
	new = new..ext
	addFilenameToList(new)
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

    -- print("[item-texture] Found "..count.." cached files.")
end)

function flushItemTextureCache()

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
	for element, vv in pairs(loaded) do
		local v = vv[1]
		if type(v)=="table" then
			if isElement(v.shader) and isElement(v.texture) then
				if isElement(element) then engineRemoveShaderFromWorldTexture(v.shader, v.texname, element) end
				destroyElement(v.shader)
				destroyElement(v.texture)
			end
		end
	end
	loaded = {}
	unshaded = {}
	streaming = {}

	outputChatBox("Flushed "..count.." loaded object textures.", 110, 255, 158)

	triggerLatentServerEvent('item-texture:syncNewClient', resourceRoot)
end
addEvent("item-texture:flush_client", true)
addEventHandler("item-texture:flush_client", root, flushItemTextureCache)
addCommandHandler("flush", flushItemTextureCache, false, false)


function getPath(url)
	return string.format(cacheFileName, encryptFileNameClient(url))
end


-- lag spikes are generated here. Suddenly 200 ticks
function addTexture(element, texName, url) --[Exported]

	if not isElement(element) then
		return false, "Invalid element"
	end
	if not (type(texName)=="string") then
		return false, "Invalid texName"
	end
	if not (type(url)=="string") then
		return false, "Invalid URL"
	end
	if url == "" or url==" " then return false, "Empty URL" end

	local isLocalFile = false
	if not isURL(url) then
		if not fileExists(url) then -- ain't a local path
			return false, "Not an URL (incorrect)"
		else
			isLocalFile = true
		end
	end

	if not unshaded[element] then unshaded[element] = {} end
	if not isElementStreamedIn(element) then
		table.insert(unshaded[element], {texName, url})
		return true
	end
	if unshaded[element] then
		for k,v in ipairs(unshaded[element]) do
			if v[1] == texName then
				-- table.remove(unshaded[element], k)
				unshaded[element][k] = nil
			end
		end
	end

	math.randomseed(os.time())

	if not streaming[element] then streaming[element] = {} end
	local path = isLocalFile and url or getPath(url)
	if fileExists(path) then

		streaming[element][texName] = nil
		local data
		if loaded[element] then
			for k,v in ipairs(loaded[element]) do
				if v.texname == texName then
					data = v
					break
				end
			end
		end
		if data then --shader exist
			local shader = data.shader
			local oldTex = data.texture
			--local newTex = dxCreateTexture(path, "argb", true, "clamp", "2d", 1)
			local newTex = dxCreateTexture(path)
			destroyElement(oldTex)
			data.texture = newTex
			dxSetShaderValue(shader, "gTexture", newTex)
			engineApplyShaderToWorldTexture(shader, texName, element)
		else
			--local texture = dxCreateTexture(path, "argb", true, "clamp", "2d", 1)
			local texture = dxCreateTexture(path) -- This is where fps drop happen. Big file gets loaded in.
			if texture then
				local shader = dxCreateShader('shaders/replacement.fx', 0, 0, true, 'world,object,vehicle')
				if shader then
					dxSetShaderValue(shader, 'theTexture', texture)
					engineApplyShaderToWorldTexture(shader, texName, element)
					
					if not loaded[element] then
						loaded[element] = {}
					end
					table.insert(loaded[element], { texname = texName, texture = texture, shader = shader, url = url })
				else
					destroyElement(texture)
				end

				-- apply vehdirt texture ontop / Fernando
				-- if getElementType(element) == "vehicle" then
				-- 	triggerEvent("handleDirtShader", element, element, getElementData(element, "veh.dirtLevel") or 1)
				-- end
			end
		end
	else
		if not streaming[element][texName] then
			-- request texture image from server
			streaming[element][texName] = true
			if isElementLocal(element) then
				local randomLocalElementID = math.random(1000000,9999999)
				pending_local[randomLocalElementID] = element
				triggerServerEvent('item-texture:stream', resourceRoot, randomLocalElementID, texName, url)
			else
				triggerServerEvent('item-texture:stream', resourceRoot, element, texName, url)
			end
		end
	end

	return true
end

function removeTexture(element, texName)
	if texName then
		if unshaded[element] then
			local count = 0
			for k,v in ipairs(unshaded[element]) do
				if v[1] == texName then
					-- table.remove(unshaded[element], k)
					unshaded[element][k] = nil
					count = count + 1
				end
			end
			if count > 0 then
				return true
			end
		end
		local loadedEntryNum
		if loaded[element] then
			for k,v in ipairs(loaded[element]) do
				if v.texname == texName then
					data = v
					loadedEntryNum = k
					break
				end
			end
		end
		if data and loadedEntryNum then
			if isElement(element) then engineRemoveShaderFromWorldTexture(data.shader, texName, element) end
			destroyElement(data.texture)
			destroyElement(data.shader)
			-- table.remove(loaded[element], loadedEntryNum) -- less optimized, I think
			loaded[element][loadedEntryNum] = nil
			return true
		end
	else
		if unshaded[element] then unshaded[element] = {} end
		if loaded[element] then
			for k,v in ipairs(loaded[element]) do
				if isElement(element) then engineRemoveShaderFromWorldTexture(v.shader, v.texname, element) end
				destroyElement(v.texture)
				destroyElement(v.shader)
			end
			loaded[element] = nil
			return true
		end
	end
	return false
end

-- file we asked for is there
addEvent('item-texture:file', true)
addEventHandler( 'item-texture:file', resourceRoot,
	function(element, texName, url, content, size)
		local file = fileCreate(getPath(url))
		local written = fileWrite(file, content)
		fileClose(file)

		if written ~= size then
			fileDelete(getPath(url))
		else
			if type(element)=="number" then
				element = pending_local[element]
				if not element then
					outputDebugString("Failed to fetch pending local element", 2)
					return
				end
			end
			addTexture(element, texName, url)
		end
	end, false)

addEvent('item-texture:removeOne', true)
addEventHandler('item-texture:removeOne', getRootElement(),--Fernando
	function(element, texName)
		removeTexture(element, texName)
	end
)

addEvent('item-texture:addOne', true)
addEventHandler('item-texture:addOne', resourceRoot,
    function(element, texName, url)
        addTexture(element, texName, url)
    end)

-- exported
-- called from:
--   - admin-system (generic creation)
--	 - item-system (metadata editing)
function validateFileFromURL(url)
	local valid, err = isImageURLValid(url)
	if not valid then
		-- url, result, message
		print("validateFileFromURL("..url.."): not an url")
		setTimer(triggerEvent, 2000, 1, 'item-texture:fileValidationResult', root, url, false, err)
		return false
	end

	local path = getPath(url)
	if fileExists(path) then --file already exists, so we can simply check filesize
		local file = fileOpen(path, true)
		local filesize = fileGetSize(file)
		fileClose(file)
		if filesize > maxFileSize then
			local text = "The filesize ("..tostring(math.ceil((tonumber(filesize))/1000)).." kb) exceeds the maximum allowed filesize for item textures ("..maxFileSizeTxt..")."

			print("validateFileFromURL("..url.."): filesize too big")
			-- url, result, message
			setTimer(triggerEvent, 2000, 1, "item-texture:fileValidationResult", root, url, false, text)

			fileDelete(path)
			return false
		else
			-- approved
			print("validateFileFromURL("..url.."): immediately approved")
			return true
		end
	else --we need to get info from server
		print("validateFileFromURL("..url.."): asking server..")
		setTimer(triggerServerEvent, 2000, 1, "item-texture:validateFile", resourceRoot, url)
		return false
	end
end
addEvent("item-texture:fileValidationResult", true)

function godebug(cmd)
	if exports.integration:isPlayerScripter(localPlayer) then
		debugMode = not debugMode
		outputChatBox("item-texture debug set to "..tostring(debugMode))
	end
end
addCommandHandler("debugitemtexture", godebug)


function queueTimer()
	loadQueue = setTimer(function()
		
		local sent = false
		for i=1, #queueList do
			if queueList[i] then
				if not isElement(queueList[i].element) or not isElementStreamedIn(queueList[i].element) then
					-- table.remove(queueList, i)
					queueList[i] = nil
				elseif not sent then
					local vehData = queueList[i]
					if vehData then
						if isElementStreamedIn(vehData.element) then
							addTexture(vehData.element, vehData.first, vehData.second)
						end
						queueList[i] = nil
						sent = true
					end
				end
			end
		end
	end, interval, 0)
end

addEventHandler("onClientElementStreamIn", getRootElement(), function()
    local elementType = getElementType( source )
	if elementType == "object" or elementType == "vehicle" then
		if unshaded[source] and #unshaded[source] > 0 then -- meaning it has textures
			for i=1, #unshaded[source] do
				local v = unshaded[source][i]
				local size = #queueList
				if v then
					queueList[size+1] = {element=source, first=v[1], second=v[2]}
					if not isTimer(loadQueue) or loadQueue == nil then
						queueTimer()
					end
				end
			end
			if elementType == "object" then
				if(getElementData(source, "gate")) then
	        		setObjectBreakable(source, false)
	        	end
	        end
		end
	end
end)

addEventHandler("onClientElementStreamOut", getRootElement(),
function ( )
   local elementType = getElementType( source )
   if elementType == "object" or elementType == "vehicle" then

		local loopSize = #queueList
		for i=1, loopSize do
			if queueList[i] then
				if queueList[i].element == source then
					-- table.remove(queueList, i)
					queueList[i] = nil
					break
				end
			end
		end
    end
end)

addEventHandler( "onClientElementDestroy", root, 
function () 
	local elementType = getElementType( source )
	if elementType == "object" or elementType == "vehicle" then
		for i=1, #queueList do
			if queueList[i] then
				if queueList[i].element == source then
					-- table.remove(queueList, i)
					queueList[i] = nil
					break
				end
			end
		end

		if loaded[source] and #loaded[source] > 0 then

    		for k,v in pairs(loaded[source]) do

    			local texname = v.texname
				local url = v.url
				-- print(v.texname)

				removeTexture(source, texname)
				if not unshaded[source] then
					unshaded[source] = {}
				end
				table.insert(unshaded[source], {texname, url})
    		end
    	end
	end
end)


addEvent('item-texture:initialSync', true)
addEventHandler('item-texture:initialSync', resourceRoot, function(cacheTable)
	for k,v in ipairs(cacheTable) do
		addTexture(v[1], v[2], v[3])
	end
	setElementData(localPlayer, "item-texture:loading", nil)
end)

local startTimer

addEventHandler('onClientResourceStart', resourceRoot, function(res)
	
	setElementData(localPlayer, "item-texture:loading", true)
	startTimer = setTimer(function()
		if not getElementData(localPlayer, "account:loggedin") then return end

		triggerLatentServerEvent('item-texture:syncNewClient', resourceRoot)
		killTimer(startTimer)
	end, 2000, 0)
	
end)


-- Hide ped shadow
local shader = dxCreateShader("shaders/pedshadow.fx")
local texture = dxCreateTexture(1, 1)
dxSetShaderValue(shader, "reTexture", texture)

engineApplyShaderToWorldTexture(shader, "shad_ped")



-- Blank/Transparent decals

local decals = {
	"muddywater", --no muddy water!!!
	"vehiclegrunge256", --no dirt

	"vehiclepoldecals128", --police decals
	"newsvan92decal128", --news van logo
	"sanmav92blue64", --news helicopter logo
	"sanmav92blue64b", --news helicopter tailnumber
	"sweeper92decal128", --sweeper logo
	"polmav92sadecal64", --police maverick logo
	"polmav92decal64b", --police maverick tailnumber
	"trash92decal128", --logo for trashmaster and utility truck
	"cement92logo", --cement truck logo
	"dozer92logo128", --bulldozer logo
	"bus92decals128", --bus logo
	"coach92decals128", --coach logo
	"dodo92decal128b", --dodo tailnumber
	"lsfd92badge64", --fire truck logo
	"firetruk92num64", --fire truck number
	"firetruk92decal", --fire truck markings
	"fireLA92decalb", --fire ladder markings
	"ambulan92decal128", --ambulance markings

	"Police", --enforcer mod
	"State police", --enforcer mod
	"San Andreas State", --enforcer mod
	"SAPD", --enforcer mod

	"lenco", --fbi truck bearcat mod
	"lenco2", --fbi truck bearcat mod
	"lspd", --fbi truck bearcat mod
	"lspddecals", --fbi truck bearcat mod
}

decalTex = dxCreateTexture("shaders/trans.png")
decalShad = dxCreateShader("shaders/decal.fx")
dxSetShaderValue(decalShad, "decal", decalTex)
for k, v in ipairs(decals) do
	engineApplyShaderToWorldTexture(decalShad, v)
end



-- New (by Fernando)

local replaceShaders_Elements = {}
local texMemory = {}

addEventHandler( "onClientElementDestroy", root, 
function ()
	if getElementType(source) ~= "object" then return end
	if not replaceShaders_Elements[source] then return end
	for k,v in pairs(replaceShaders_Elements[source]) do
		local shader, texname, rmodel, rname = unpack(v)
		if isElement(shader) then
            engineRemoveShaderFromWorldTexture(shader, texname, source)
			destroyElement(shader)
			-- print("Destroyed shader for "..texname.." on:",source)
		end
	end
	replaceShaders_Elements[source] = nil
end)

function getTexture(model,name)
    if texMemory[name] then return texMemory[name] end

    local tex
    for name,texture in pairs(engineGetModelTextures(model,name)) do
        tex = texture
        break
    end
    texMemory[name] = tex
    return tex
end

function replaceWithDefaultTexture(element, texname, rmodel, rname) --[Exported]
	if not isElement(element) then
		return false, "Invalid element passed arg(1)"
	end
	if getElementType(element) ~= "object" then
		return false, "Element passed on an object arg(1)"
	end
	if type(texname)~= "string" then
		return false, "Invalid texname passed arg(2)"
	end
	if type(rmodel)~= "number" then
		return false, "Invalid rmodel passed arg(3)"
	end
	if type(rname)~= "string" then
		return false, "Invalid rname passed arg(4)"
	end

	local allocatedIDs = exports["sarp-map-mods"]:getAllocatedMapModIDs()
	for newid,allocated_id in pairs(allocatedIDs) do
        if newid == rmodel then
            rmodel = allocated_id
            -- print(newid, "Found allocated id:",rmodel)
            break
        end
    end

    local texs = replaceShaders_Elements[element]
    local foundrname
    if texs then
        for k,v in pairs(replaceShaders_Elements[element]) do
            local shader,texname1,rmodel1,rname1 = unpack(v)
            if texname1 == texname then
                foundrname = rname1
                break
            end
        end
    end

    if foundrname then
		return false, texname.." is already replaced with "..foundrname
    end

    if rname == texname then
        return false, "Can't replace a texture with the same one ("..texname..")"
    end

    local shader = dxCreateShader("shaders/replacement.fx")
    if isElement(shader) then
        local theTexture = getTexture(rmodel, rname)
        if isElement(theTexture) then
            if not replaceShaders_Elements[element] then
                replaceShaders_Elements[element] = {}
            end

            dxSetShaderValue(shader, "theTexture", theTexture);
            engineApplyShaderToWorldTexture(shader, texname, element)
            table.insert(replaceShaders_Elements[element], {shader, texname, rmodel, rname})
            return true
        else
            destroyElement(shader)
            return false, "Failed to get texture for "..rname.." ("..rmodel..")"
        end
    else
    	return false, "Failed to create shader replacement.fx"
    end
end