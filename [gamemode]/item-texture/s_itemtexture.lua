
local busyCompressing
local secret = "fernando_is_awesome"
local urls = {
	scan = "http://localhost/sarp/public/mta/scan_dir",
	opt = "http://localhost/sarp/public/mta/optimize_png",
}

local totalOptimize = 0
local totalWorked = 0
local totalFailed = 0


pool = exports.pool
items = exports['item-system']
artifacts = exports.artifacts

local pending = {}
local optTimer
local added = {}
local addedElement = {}

local isInitializing = false
local clientsWaitingOnInitial = {}

local debugMode = false

addEventHandler('onResourceStart', resourceRoot,
	function()
		isInitializing = true

		-- Fernando 20/05/2021
		local artifactsData = artifacts:getArtifacts()
		for k,v in ipairs(getElementsByType("player")) do

			local playerArtifacts = artifacts:getPlayerArtifacts(v, true)
			for kartifact,v in ipairs(playerArtifacts) do
				local artifactElement = v.object
				local artifactID = kartifact

				local artifactTexture = artifactsData[artifactID].texture
				local artifactTextureName = artifactsData[artifactID].texname

				local setCustomTexture = v.customTex

				if artifactTextureName and artifactTexture then
					addTexture(artifactElement, artifactTextureName, artifactTexture, true)
				
				elseif setCustomTexture and type(setCustomTexture)=="table" then
					if setCustomTexture[1] and setCustomTexture[2] then
						addTexture(artifactElement, setCustomTexture[2], setCustomTexture[1], true)
					end
				end
			end
		end

		for k,v in ipairs(getElementsByType("vehicle")) do
			local textures = getElementData(v, "textures")
			if textures then
				if type(textures) == "table" then
					for k2,v2 in ipairs(textures) do
						if v2[1] and v2[2] then
							addTexture(v, v2[1], v2[2], true)
						end
					end
				end
			end
		end


		local itemworld = getResourceFromName("item-world")
		if itemworld then
			local itemworldroot = getResourceRootElement(itemworld)
			if itemworldroot then
				local worldItems = getElementsByType("object", itemworldroot)
				for k,v in ipairs(worldItems) do
					local itemID = tonumber(getElementData(v, "itemID")) or 0
					if itemID > 0 then
						local itemValue = getElementData(v, "itemValue")
						local metadata = getElementData(v, "metadata")
						local texture = items:getItemTexture(itemID, itemValue, metadata)
						if texture then
							for k2,v2 in ipairs(texture) do
								if v2[1] and v2[2] then
									addTexture(v, v2[2], v2[1], true)
								end
							end
						end
					end
				end
			end
		end

		-- in case of resource restart with players ingame
		if clientsWaitingOnInitial then
			setTimer(function()
				for k,player in pairs(clientsWaitingOnInitial) do
					if isElement(player) then
						triggerClientEvent(player, "item-texture:initialSync", resourceRoot, added)
					end
				end

				isInitializing = false

				clientsWaitingOnInitial = {}
			end, 5000, 1)
		end
	end)


local fileNames = {}
local errorLoading = false

-- Fernando:
-- store encrypted file names so they can be used in case of needing to clear cache
function encryptFileNameServer(url)
	
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

    -- print("[item-texture] Found "..count.." cached files (server).")
end)

function flushItemTextureCache(thePlayer)
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

	local delay = 2000
	outputChatBox("Flushed "..count.." object textures (server). Restarting in "..(delay/1000).." seconds.", thePlayer, 255, 122, 209)

	-- Flush online clients
	for k, player in ipairs(getElementsByType("player")) do
		triggerClientEvent(player, "item-texture:flush_client", player)
	end

	setTimer(restartResource, delay, 1, getThisResource())
end
addCommandHandler("flushserver", flushItemTextureCache, false, false)

function getPath(url)
	local fn = encryptFileNameServer(url)
	return string.format(cacheFileNameServer, fn), cacheFolder, fn
end


-- loads a texture from url
function loadFromURL(element, texName, url, theClient)
	fetchRemote(url, "textures", function(str, errno)
		if str == 'ERROR' then
			if isElement(element) then
				if getElementType(element) == 'vehicle' then
					removeVehicleTexture(element, texName)
				else
					removeTexture(element, texName)
				end
			end
		else
			local path, folder, filename = getPath(url)

			local file = fileCreate(path)
			fileWrite(file, str)
			fileClose(file)

			-- if GetFileExtension(filename) == ".png" and not string.find(filename, "temp") then
			-- 	-- optimize the image
			-- 	pending[url] = { {theClient}, folder, filename, element, texName, str, false}


			-- 	if isTimer(optTimer) then killTimer(optTimer) end
			-- 	optTimer = setTimer(function()

			-- 		optimizePngs(busyCompressing)

			-- 	end, 5000, 1)
			-- else
				-- skip optimization
				triggerClientEvent(theClient, 'item-texture:file', resourceRoot, element, texName, url, str, #str)
			-- end
		end
	end)
end

-- The client requested the texture because they don't have it cached
-- so the server is going to store it (if it hasn't already) in a file
-- and send it to the client for them to store it.
addEvent( 'item-texture:stream', true )
addEventHandler( 'item-texture:stream', resourceRoot,
	function(element, texName, url)
		local path = getPath(url)
		if fileExists(path) then

			local file = fileOpen(path, true)
			if file then
				local size = fileGetSize(file)
				if size <= 0 then
					fileClose(file)
					return
				end
				local content = fileRead(file, size)

				if #content == size then
					triggerClientEvent(client, 'item-texture:file', resourceRoot, element, texName, url, content, size)
				end
				fileClose(file)
			else
			end
		else
			-- try to reload the file from the given url
			if not pending[url] then
				loadFromURL(element, texName, url, client)
			else
				table.insert(pending[url][1], client) -- add another client waiting
			end
		end
	end, false)

-- exported
function addTexture(element, texName, url, serverOnly)
	table.insert(added, {element, texName, url})
	addedElement[element] = true
	if not serverOnly and not isInitializing then
		triggerClientEvent('item-texture:addOne', resourceRoot, element, texName, url)
	end
	return true
end

function removeTexture(element, texName)
	for k,v in ipairs(added) do
		if texName then
			if v[1] == element and v[2] == texName then
				table.remove(added, k)
				addedElement[element] = nil
			end
		else
			if v[1] == element then
				table.remove(added, k)
				addedElement[element] = nil
			end
		end
	end
	triggerClientEvent('item-texture:removeOne', resourceRoot, element, texName)
end

addEventHandler("onElementDestroy", root, function()
	if addedElement[source] then
		removeTexture(source)
	end
end)

addEvent("item-texture:syncNewClient", true)
addEventHandler("item-texture:syncNewClient", root, function()
	if isInitializing then
		table.insert(clientsWaitingOnInitial, client)
	else
		triggerClientEvent(client, 'item-texture:initialSync', resourceRoot, added)
	end
end)


-- currently triggered by the exported function validateFileFromURL
-- URL validation is already done
-- called from:
--   - admin-system (generic creation)
--	 - item-system (metadata editing)
function validateItemTexture(url)
	fetchRemote(url, 5, function(str, errno, client)
		if str == 'ERROR' then

			local text = "URL could not be reached. (ERROR #"..tostring(errno)..")"
			print("validateItemTexture("..url.."): url cant be reached")
			setTimer(triggerClientEvent, 2000, 1, client, 'item-texture:fileValidationResult', root, url, false, text)
		else

			local pathTEMP = 'sarp_cache_temp/' .. encryptFileNameServer(url)
			local file = fileCreate(pathTEMP)
			fileWrite(file, str)
			local filesize = fileGetSize(file)
			fileClose(file)
			fileDelete(pathTEMP)

			if filesize > maxFileSize then
				local text = "The filesize ("..tostring(math.ceil((tonumber(filesize))/1000)).." kb) exceeds the maximum allowed filesize for item textures ("..maxFileSizeTxt..")."

				print("validateFileFromURL("..url.."): filesize too big")
				setTimer(triggerClientEvent, 2000, 1, client, 'item-texture:fileValidationResult', root, url, false, text)
				return false
			else

				print("validateItemTexture("..url.."): good, sending back result..")
				setTimer(triggerClientEvent, 2000, 1, client, 'item-texture:fileValidationResult', root, url, true)
			end
		end
	end, "", true, client)
end
addEvent("item-texture:validateFile", true)
addEventHandler("item-texture:validateFile", resourceRoot, validateItemTexture)


-- Fernando 28/05/2021
-- Delete file from the server's cache to free up space

function unCacheTexture(url) -- Exported
	if not isURL(url) then
		return false
	end

	local path, folder, filename = getPath(url)
	if not fileExists(path) then
		return false
	end

	fileDelete(path)
	fileNames[path] = nil
	return true
end


function optimizePngs(addToQueue)
	busyCompressing = true

	local count = 0

	local queueName = "opng_"
	local url = urls.opt

	for texUrl, tab in pairs(pending) do

		if not tab[7] then -- already compressing

			pending[texUrl][7] = true

			count = count + 1
			local _, folder, filename= unpack(tab)

			local delay = count * 10000
			setTimer(function()

				local uid = (math.ceil(getTickCount()/count))
				local queue = queueName..tostring(uid)

				callRemote(url, queue, 10, 30000, resultImageOptimized,

					secret, -- secret key for validation
					texUrl, -- identifier to grab the player later
					"item-texture", -- resource name
					folder, -- path where the file is
					filename
				)
			end, delay, 1)


			-- setTimer(function() -- problematic when theres a lot of files/slow CPU
			-- 	-- expire the pending (just in case it fails)
			-- 	pending[texUrl] = nil
			-- 	print("Expired pending["..texUrl.."] as it failed to optimize.")
			-- end, delay+60000*2, 1)

		end
	end

	if not addToQueue then
		totalWorked = 0
		totalFailed = 0
		totalOptimize = count
		print("About to compress "..totalOptimize.." files.")
	else
		totalOptimize = totalOptimize +  count
		print("Added "..totalOptimize.." more files to compress.")
	end
end

function resultImageOptimized(result,_)
	if result ~= "ERROR" then

		if type(result) == "table" then

			local checkURL, res = unpack(result)
			local clientsWaiting, element, texName, str

			if pending[checkURL] then
				clientsWaiting, folder, filename, element, texName, str = unpack(pending[checkURL])
				pending[checkURL] = nil
			end

			if type(clientsWaiting) == "table" then
				for k, theClient in pairs(clientsWaiting) do

					-- image optimized, send result to client
					-- outputChatBox(res, theClient, 25,255,25)
					triggerClientEvent(theClient, 'item-texture:file', resourceRoot, element, texName, checkURL, str, #str)
				end

				totalWorked = totalWorked+1
			else
				iprint(clientsWaiting)

				totalFailed = totalFailed+1
			end
		end
	else
		print("resultImageOptimized "..result.." ".._)
		totalFailed = totalFailed+1
	end

	if (totalWorked+totalFailed) == totalOptimize then
		print("FINISHED: "..totalWorked.." successful ; "..totalFailed.. " failed")
		busyCompressing = false
	end
end

-- local waiting1 = {}
-- function scanTestCmd(thePlayer)
-- 	if not exports.integration:isPlayerScripter(thePlayer) then return end

-- 	local tick = getTickCount()
-- 	local url = urls.scan
-- 	local args = {
-- 		secret, -- secret key for validation
-- 		tick, -- identifier to grab the player later
-- 		"resource", -- we wanna scan inside a resource
-- 		{"\[sarp_items\]", "item-system"} -- path
-- 	}

-- 	waiting1[tick] = thePlayer
-- 	callRemote(url, 10, 10000, findFiles, unpack(args))
-- end
-- addCommandHandler("scantest", scanTestCmd, false,false)

-- function findFiles(result, _)
-- 	if result ~= "ERROR" then

-- 		if type(result) == "table" then

-- 			local tick, parentfolder, filesFound = unpack(result)

-- 			local thePlayer = waiting1[tonumber(tick)]
-- 			waiting1[tonumber(tick)] = nil

-- 			if type(filesFound)=="table" then

-- 				for k,v in pairs(filesFound) do

-- 					outputChatBox(v, thePlayer)
-- 				end
-- 			end
-- 		end
-- 	else
-- 		print("findFiles "..result.." ".._)
-- 	end
-- end