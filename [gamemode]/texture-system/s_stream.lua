mysql = exports.mysql
integration = exports.integration
global = exports.global

savedTextures = {}
textureItemID = 147

addEventHandler('onResourceStart', resourceRoot,
	function()
		local count = 0
		local result = mysql:query("SELECT * FROM interior_textures")
		local time = getTickCount()
		if result then
			while true do
				row = mysql:fetch_assoc(result)
				if not row then break end

				row.interior = tonumber(row.interior)
				row.id = tonumber(row.id)
				row.rotation = tonumber(row.rotation)
				if not savedTextures[row.interior] then
					savedTextures[row.interior] = {}
				end
				savedTextures[row.interior][row.id] = { id = row.id, texture = row.texture, url = row.url, rotation = row.rotation }

				count = count + 1
			end

			-- outputDebugString('Loaded ' .. count .. ' texture records for all interiors in ' .. math.ceil(getTickCount() - time) .. 'ms')
			mysql:free_result(result)
		end
	end)

local fileNames = {}
local errorLoading = false

-- Fernando:
-- store encrypted file names so they can be used in case of needing to clear cache
function encryptFileNameServer(url)
	local new = sha256(tostring(url))
	if new then addFilenameToList(new) end
	return new
end

function addFilenameToList(name)

	if errorLoading then return end
	fileNames[name] = true
end

addEventHandler( "onResourceStop", resourceRoot,
function ()
	-- Save the file names list to file
	local file
	if not fileExists(listFilePath) then
		file = xmlCreateFile(listFilePath, rootNodeName)
	else
		file = xmlLoadFile(listFilePath)
	end
	if not file then

		return print("Error(4) opening file: "..listFilePath)
	end

	local names = xmlNodeGetChildren(file)
	if not names then
		return print("Error(4) getting file names on parent: "..rootNodeName)
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


addEventHandler( "onResourceStart", resourceRoot,
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
		return print("Error(3) opening file: "..listFilePath)
	end

    local names = xmlNodeGetChildren(file)
    if not names then
    	errorLoading = true
    	xmlUnloadFile(file)
		return print("Error(3) getting file names on parent: "..rootNodeName)
    end

    local count = 0
    for k, n in pairs(names) do
    	local nn = xmlNodeGetName(n)
    	if tostring(nn) == tostring(entryNodeName) then
    		local nv = tostring(xmlNodeGetValue(n))
    		if nv then
    			local fn = string.format(cacheFileNameServer, nv)
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

    -- print("[texture-system] Found "..count.." cached files (server).")
end)

function flushTextureSystemCache(thePlayer)
	if not exports.integration:isPlayerScripter(thePlayer) then return end
	-- Deletes all cached files
	local count = 0
	for fileName,_ in pairs(fileNames) do
		local fn = string.format(cacheFileNameServer, fileName)
		if fileExists(fn) then
			fileDelete(fn)
			fileNames[fileName] = nil
			count = count + 1
		end
	end

	local delay = 10000
	outputChatBox("Flushed "..count.." interior textures (server). Restarting in "..(delay/1000).." seconds.", thePlayer, 122, 124, 255)

	-- Flush online clients
	for k, player in ipairs(getElementsByType("player")) do
		triggerClientEvent(player, "texture-system:flush_client", player)
	end

	setTimer(restartResource, delay, 1, getThisResource())
end
addCommandHandler("flushserver", flushTextureSystemCache, false, false)

function getPath(url)
	return string.format(cacheFileNameServer, encryptFileNameServer(url))
end


-- loads from an url
function loadFromURL(url, interior, id)
	fetchRemote(url, function(str, errno)
			if str == 'ERROR' then
				-- outputDebugString('clothing:stream - unable to fetch ' .. url)
			else
				local file = fileCreate(getPath(url))
				fileWrite(file, str)
				fileClose(file)

				local data = savedTextures[interior][id]
				if data and data.pending then
					-- triggerLatentClientEvent(data.pending, 'frames:file', resourceRoot, id, url, str, #str)
					triggerClientEvent(data.pending, 'frames:file', resourceRoot, id, url, str, #str)
					data.pending = nil
				end
			end
		end)
end


-- send frames to the client
addEvent( 'frames:stream', true )
addEventHandler( 'frames:stream', resourceRoot,
	function(interior, id)
		local interior = tonumber(interior)
		local id = tonumber(id)
		-- if its not a number, this'll fail
		if type(id) == 'number' and type(interior) == 'number' then
			local data = savedTextures[interior] and savedTextures[interior][id]
			if data then
				local path = getPath(data.url)
				if fileExists(path) then
					local file = fileOpen(path, true)
					if file then
						local size = fileGetSize(file)
						if tonumber(size) then
							local content = fileRead(file, size)

							if #content == size then
								-- triggerLatentClientEvent(client, 'frames:file', resourceRoot, id, data.url, content, size)
								triggerClientEvent(client, 'frames:file', resourceRoot, id, data.url, content, size)
							else
								outputDebugString('frames:stream - file ' .. path .. ' read ' .. #content .. ' bytes, but is ' .. size .. ' bytes long')
							end
							fileClose(file)
						end
					else
						outputDebugString('frames:stream - file ' .. path .. ' existed but could not be opened?')
					end
				else
					-- try to reload the file from the given url
					if data.pending then
						table.insert(data.pending, client)
					else
						data.pending = { client }
						loadFromURL(data.url, interior, id)
					end
				end
			else
				outputDebugString('frames:stream - frames #' .. interior .. '/' .. id .. ' do not exist.')
			end
		end
	end, false)

--
addEvent("frames:loadInteriorTextures", true)
addEventHandler("frames:loadInteriorTextures", root,
	function(dimension)
		-- outputDebugString(dimension)
		triggerClientEvent(client or source, 'frames:list', resourceRoot, dimension, savedTextures[dimension])
	end)
--

addEvent("frames:deleteall", true)
addEventHandler("frames:deleteall", resourceRoot,
	function(interior, dimension)
		if not dimension then dimension = getElementDimension(client) end
		if not interior then interior = getElementInterior(client) end

		------------------------------- Fernando --------------------------------------------------------------
		local admEditPerm = hasWorldEditPerm(client)
		local iOwnerPerm = legitimateOwner(client, dimension)

		if dimension == 0 and interior == 0 and not admEditPerm then
			outputChatBox("You do not have permission to edit the exterior world.", client, 187, 187, 187)
			if exports.integration:isPlayerTrialAdmin(client) then
				outputChatBox("You need to be on admin duty to gain access.", client, 222, 187, 222)
			end
		end

		if dimension > 0 then
			if not iOwnerPerm and not admEditPerm then
				outputChatBox("You do not have permission to edit textures in this interior.", client, 187, 187, 187)
				if exports.integration:isPlayerTrialAdmin(client) then
					outputChatBox("You need to be on admin duty to gain access.", client, 222, 187, 222)
				end
				return
			end
		end
		------------------------------------------------------------------------------------------------------

		local interior_textures = {}
		local count = 0
		local result = mysql:query("SELECT * FROM interior_textures WHERE interior = '" .. mysql:escape_string ( dimension ) .. "'")
		if result then
			while true do
				row = mysql:fetch_assoc(result)
				if not row then break end

				table.insert(interior_textures, tonumber(row.id))
				count = count + 1
			end

			mysql:free_result(result)
		end

		local success = mysql:query_free("DELETE FROM interior_textures WHERE interior = '" .. mysql:escape_string ( dimension ) .. "'" )
		if success then

			local givec = 0
			for k, id in pairs(interior_textures) do
				local data = savedTextures[dimension]
				if data and data[id] then
					local thisData = data[id]
					--give the removed texture as a picture frame item with the same values
					if not exports['item-system']:giveItem(client, textureItemID, tostring(thisData.url)..";"..tostring(thisData.texture)) then
						givec = givec + 1
					end
				end
			end


			savedTextures[dimension] = nil
			outputChatBox("Removed "..count.." textures in this interior ID #" .. dimension .. ". "..(givec ~= 0 and ("Failed to give you "..givec.." wallpaper items.") or ""), client, 0, 255, 0)

			-- sorta tell everyone who is inside
			for k,v in ipairs(getElementsByType"player") do
				if getElementDimension(v) == dimension then
					for k, id in pairs(interior_textures) do
						triggerClientEvent(v, 'frames:removeOne', resourceRoot, dimension, id)
					end
				end
			end
		else
			outputChatBox("Failed to remove all textures in interior ID #" .. dimension .. ".", client, 255, 0, 0)
		end
	end)


addEvent("frames:delete", true)
addEventHandler("frames:delete", resourceRoot,
	function(id, interior, dimension)
		--TODO: Get interior and dimension from the texture id instead of the player, to avoid potential abuse.
		if not dimension then dimension = getElementDimension(client) end
		if not interior then interior = getElementInterior(client) end

		------------------------------- Fernando --------------------------------------------------------------
		local admEditPerm = hasWorldEditPerm(client)
		local iOwnerPerm = legitimateOwner(client, dimension)

		if dimension == 0 and interior == 0 and not admEditPerm then
			outputChatBox("You do not have permission to edit the exterior world.", client, 187, 187, 187)
			if exports.integration:isPlayerTrialAdmin(client) then
				outputChatBox("You need to be on admin duty to gain access.", client, 222, 187, 222)
			end
		end

		if dimension > 0 then
			if not iOwnerPerm and not admEditPerm then
				outputChatBox("You do not have permission to edit textures in this interior.", client, 187, 187, 187)
				if exports.integration:isPlayerTrialAdmin(client) then
					outputChatBox("You need to be on admin duty to gain access.", client, 222, 187, 222)
				end
				return
			end
		end
		------------------------------------------------------------------------------------------------------

		local data = savedTextures[dimension]
		if not data or not data[id] then
			outputChatBox("Failed to get texture ID #"..id..".", client, 255, 0, 0)
		else
			local success = mysql:query_free("DELETE FROM interior_textures WHERE id = '" .. mysql:escape_string ( id ) .. "' AND interior = '" .. mysql:escape_string( dimension ) .. "'" )
			if success then

				-- sorta tell everyone who is inside
				for k,v in ipairs(getElementsByType"player") do
					if getElementDimension(v) == dimension then
						triggerClientEvent(v, 'frames:removeOne', resourceRoot, dimension, id)
					end
				end

				local thisData = data[id]
				--give the removed texture as a picture frame item with the same values
				if exports['item-system']:giveItem(client, textureItemID, tostring(thisData.url)..";"..tostring(thisData.texture)) then
					outputChatBox("Removed texture ID #" .. id .. " from this interior. You were given the wallpaper item.", client, 0, 255, 0)
				else
					outputChatBox("Removed texture ID #" .. id .. " from this interior. Failed to give you the wallpaper item.", client, 255, 255, 0)
				end
				savedTextures[dimension][id] = nil
			else
				outputChatBox("Failed to remove texture ID " .. id .. ".", client, 255, 0, 0)
			end
		end
	end)

--

addEvent("frames:updateURL", true)
addEventHandler("frames:updateURL", resourceRoot,
	function(id, url, interior, dimension)
		--TODO: Get interior and dimension from the texture id instead of the player, to avoid potential abuse.
		if not dimension then dimension = getElementDimension(client) end
		if not interior then interior = getElementInterior(client) end

		------------------------------- Fernando --------------------------------------------------------------
		local admEditPerm = hasWorldEditPerm(client)
		local iOwnerPerm = legitimateOwner(client, dimension)

		if dimension == 0 and interior == 0 and not admEditPerm then
			outputChatBox("You do not have permission to edit the exterior world.", client, 187, 187, 187)
			if exports.integration:isPlayerTrialAdmin(client) then
				outputChatBox("You need to be on admin duty to gain access.", client, 222, 187, 222)
			end
		end

		if dimension > 0 then
			if not iOwnerPerm and not admEditPerm then
				outputChatBox("You do not have permission to edit textures in this interior.", client, 187, 187, 187)
				if exports.integration:isPlayerTrialAdmin(client) then
					outputChatBox("You need to be on admin duty to gain access.", client, 222, 187, 222)
				end
				return
			end
		end
		------------------------------------------------------------------------------------------------------

		local data = savedTextures[dimension]
		if not data or not data[id] then
			outputChatBox("This isn't even your texture?", client, 255, 0, 0)
		else
			local success = mysql:query_free("UPDATE interior_textures SET url = '" .. mysql:escape_string(url) .. "' WHERE id = '" .. mysql:escape_string ( id ) .. "' AND interior = '" .. mysql:escape_string( dimension ) .. "'" )
			if success then
				outputChatBox("Updated Texture with ID " .. id .. ".", client, 0, 255, 0)

				local thisData = data[id]
				thisData.url = url

				-- sorta tell everyone who is inside
				for k,v in ipairs(getElementsByType"player") do
					if getElementDimension(v) == dimension then
						triggerClientEvent(v, 'frames:removeOne', resourceRoot, dimension, id)
						triggerClientEvent(v, 'frames:addOne', resourceRoot, dimension, thisData)
					end
				end

				savedTextures[dimension][id] = thisData
			else
				outputChatBox("Failed to update texture.", client, 255, 0, 0)
			end
		end
	end)

addEvent("frames:updateRotation", true)
addEventHandler("frames:updateRotation", resourceRoot,
	function(id, interior, dimension)
		--TODO: Get interior and dimension from the texture id instead of the player, to avoid potential abuse.
		if not dimension then dimension = getElementDimension(client) end
		if not interior then interior = getElementInterior(client) end

		------------------------------- Fernando --------------------------------------------------------------
		local admEditPerm = hasWorldEditPerm(client)
		local iOwnerPerm = legitimateOwner(client, dimension)

		if dimension == 0 and interior == 0 and not admEditPerm then
			outputChatBox("You do not have permission to edit the exterior world.", client, 187, 187, 187)
			if exports.integration:isPlayerTrialAdmin(client) then
				outputChatBox("You need to be on admin duty to gain access.", client, 222, 187, 222)
			end
		end

		if dimension > 0 then
			if not iOwnerPerm and not admEditPerm then
				outputChatBox("You do not have permission to edit textures in this interior.", client, 187, 187, 187)
				if exports.integration:isPlayerTrialAdmin(client) then
					outputChatBox("You need to be on admin duty to gain access.", client, 222, 187, 222)
				end
				return
			end
		end
		------------------------------------------------------------------------------------------------------


		local data = savedTextures[dimension]
		if not data or not data[id] then
			outputChatBox("This isn't even your texture?", client, 255, 0, 0)
		else
			local thisData = data[id]
			local currentRotation = thisData.rotation or 0
			currentRotation = (currentRotation + 90) % 360

			local success = mysql:query_free("UPDATE interior_textures SET rotation = '" .. mysql:escape_string(currentRotation) .. "' WHERE id = '" .. mysql:escape_string ( id ) .. "' AND interior = '" .. mysql:escape_string( dimension ) .. "'" )
			if success then
				outputChatBox("Updated Texture with ID " .. id .. ".", client, 0, 255, 0)

				thisData.rotation = currentRotation

				-- sorta tell everyone who is inside
				for k,v in ipairs(getElementsByType"player") do
					if getElementDimension(v) == dimension then
						triggerClientEvent(v, 'frames:removeOne', resourceRoot, dimension, id)
						triggerClientEvent(v, 'frames:addOne', resourceRoot, dimension, thisData)
					end
				end

				savedTextures[dimension][id] = thisData
			else
				outputChatBox("Failed to update texture.", client, 255, 0, 0)
			end
		end
	end)

-- exported
function newTexture(source, url, texture, interior, dimension)
	--TODO: Get interior and dimension from the texture id instead of the player, to avoid potential abuse.
	if not dimension then dimension = getElementDimension(source) end
	if not interior then interior = getElementInterior(source) end

	------------------------------- Fernando --------------------------------------------------------------
	local admEditPerm = hasWorldEditPerm(source)
	local iOwnerPerm = legitimateOwner(source, dimension)

	if dimension == 0 and interior == 0 and not admEditPerm then
		outputChatBox("You do not have permission to edit the exterior world.", source, 187, 187, 187)
		if exports.integration:isPlayerTrialAdmin(source) then
			outputChatBox("You need to be on admin duty to gain access.", source, 222, 187, 222)
		end
	end

	if dimension > 0 then
		if not iOwnerPerm and not admEditPerm then
			outputChatBox("You do not have permission to edit textures in this interior.", source, 187, 187, 187)
			if exports.integration:isPlayerTrialAdmin(source) then
				outputChatBox("You need to be on admin duty to gain access.", source, 222, 187, 222)
			end
			return
		end
	end
	------------------------------------------------------------------------------------------------------


	if url:sub(1, 4) == "cef+" then
		-- browser page
	elseif string.len(url) >= 50 then
		outputChatBox("URL is too long.", source, 255, 0 ,0)
		return
	end

	-- check if said texture is already replaced
	if savedTextures[dimension] then
		for k, v in pairs(savedTextures[dimension]) do
			if v.texture:lower() == texture:lower() then
				outputChatBox('This texture is already replaced, please remove it first with /texlist.', source, 255, 0, 0)
				return false
			end
		end
	end

	local id = mysql:query_insert_free("INSERT INTO interior_textures SET interior = '" .. mysql:escape_string(dimension) .. "', texture = '" .. mysql:escape_string(texture) .. "', url = '" .. mysql:escape_string(url) .. "'")
	if id then
		local row = { id = id, texture = texture, url = url, rotation = 0 }
		if not savedTextures[dimension] then
			savedTextures[dimension] = {}
		end
		savedTextures[dimension][id] = row

		for k, v in ipairs(getElementsByType"player") do
			if getElementDimension(v) == dimension then
				triggerClientEvent(v, 'frames:addOne', resourceRoot, dimension, row)
			end
		end

		outputChatBox ( "Texture successfully replaced! Use /texlist to list them.", source, 0, 255, 0 )
		return true
	end

	outputChatBox ( "Failed to replace texture.", source, 255, 0, 0 )
	return false
end
