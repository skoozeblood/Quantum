mysql = exports.mysql
activePreviews = {}

function addVehicleTexture(theVehicle, texName, texURL, isPreview, playr) --Fernando
	-- local thePlayer = source
	if(not theVehicle or not texName or not texURL) then
		return false
	end
	if not getElementType(theVehicle) == "vehicle" then
		return false
	end
	-- if (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer)) then
		if string.len(texURL) >= 50 then
			outputChatBox("URL Length is too long! Maybe use a host like Imgur.", thePlayer, 255, 0, 0)
		return end

		multipleTextures = {}
		if texName == "License Plate (plateback1/2/3)" then
			table.insert(multipleTextures,"plateback1")
			table.insert(multipleTextures,"plateback2")
			table.insert(multipleTextures,"plateback3")
		end

		if #multipleTextures > 0 then
			for i=1,#multipleTextures do

				local tName = multipleTextures[i]

				if isPreview then
					if not activePreviews[playr] then
						activePreviews[playr]={}
					end
					activePreviews[playr] = {theVehicle, tName}
				end

				local mysql = exports.mysql
				local textures = getElementData(theVehicle, "textures") or {}
				table.insert(textures, {tName, texURL})
				local vehID = tonumber(getElementData(theVehicle, "dbid")) or 0
				if vehID > 0 then
					local newdata = toJSON(textures)
					mysql:query_free("UPDATE vehicles SET textures='".. mysql:escape_string(newdata).. "' WHERE id='"..mysql:escape_string(vehID).."'")
				end
				exports.anticheat:changeProtectedElementDataEx(theVehicle, "textures", textures, true)
				addTexture(theVehicle, tName, texURL)
			end
		else
			if isPreview then
				if not activePreviews[playr] then
					activePreviews[playr]={}
				end
				activePreviews[playr] = {theVehicle, texName}
			end

			local mysql = exports.mysql
			local textures = getElementData(theVehicle, "textures") or {}
			table.insert(textures, {texName, texURL})
			local vehID = tonumber(getElementData(theVehicle, "dbid")) or 0
			if vehID > 0 then
				local newdata = toJSON(textures)
				mysql:query_free("UPDATE vehicles SET textures='".. mysql:escape_string(newdata).. "' WHERE id='"..mysql:escape_string(vehID).."'")
			end
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "textures", textures, true)
			addTexture(theVehicle, texName, texURL)
		end
	-- end
end
addEvent("vehtex:addTexture", true)
addEventHandler("vehtex:addTexture", getRootElement(), addVehicleTexture)


-- when adding a texture permanently
-- or trying to preview it
-- URL validation is already done
function validateVehicleTexture(theVehicle, texName, url, topreview)

	fetchRemote(url, 5, function(str, errno, client)
		if str == 'ERROR' then

			local text = "URL could not be reached. Please check that you entered the correct URL and that the URL is reachable. (ERROR #"..tostring(errno)..")"

			if not topreview then
				triggerClientEvent(client, 'vehtex:fileValidationResult', resourceRoot, theVehicle, texName, url, false, text)
			else
				triggerClientEvent(client, 'vehtex:fileValidationResult:PREVIEW', resourceRoot, theVehicle, texName, url, false, text)
			end
		else

			local pathTEMP = 'sarp_cache_temp/' .. encryptFileNameServer(url)
			local file = fileCreate(pathTEMP)
			fileWrite(file, str)
			local filesize = fileGetSize(file)
			fileClose(file)
			fileDelete(pathTEMP)

			if filesize > maxFileSize then
				local text = "The filesize ("..tostring(math.ceil((tonumber(filesize))/1000)).." kb) exceeds the maximum allowed filesize for vehicle textures ("..maxFileSizeTxt..")."
				if not topreview then
					triggerClientEvent(client, 'vehtex:fileValidationResult', resourceRoot, theVehicle, texName, url, false, text)
				else
					triggerClientEvent(client, 'vehtex:fileValidationResult:PREVIEW', resourceRoot, theVehicle, texName, url, false, text)
				end

			else
				outputChatBox("File validated! Please wait as the image will now be compressed & optimized..", client,200,200,200)
				if not topreview then
					triggerClientEvent(client, 'vehtex:fileValidationResult', resourceRoot, theVehicle, texName, url, true, false)
				else
					triggerClientEvent(client, 'vehtex:fileValidationResult:PREVIEW', resourceRoot, theVehicle, texName, url, true, false)
				end
			end
		end
	end, "", true, client)
end
addEvent("vehtex:validateFile", true)
addEventHandler("vehtex:validateFile", resourceRoot, validateVehicleTexture)


addEventHandler('onResourceStart', resourceRoot,
	function()

		-- Reload the plate textures from the file in case any of them has had their URL updated.
		setTimer(function()
			for k, veh in ipairs(getElementsByType("vehicle")) do
				refreshLicensePlateTexture(veh)
			end
		end, 10000, 1)
	end)

function hasCustomPlate(theVehicle)
	local currentTextures = getElementData(theVehicle, "textures")
	if currentTextures then
		for k,v in ipairs(currentTextures) do
			if string.find(tostring(v[1]), "plateback") then
				return true
			end
		end
	end

	return false
end

function refreshLicensePlateTexture(theVehicle)
	if isElement(theVehicle) and getElementType(theVehicle)=="vehicle" then

		local dbid = getElementData(theVehicle, "dbid") or 0
		if dbid > -1 then
			local id = getElementData(theVehicle, "vehicle:platetex")
			if id and tonumber(id) and tonumber(id)~=0 then
				id = tonumber(id)

				local url = plateTextures[id][2]
				if url then

					if hasCustomPlate(theVehicle) then -- remove it first
						removeVehicleTexture(theVehicle, "License Plate (plateback1/2/3)")
					end
					setTimer(function()
						addVehicleTexture(theVehicle, "License Plate (plateback1/2/3)", url)
					end, 1500, 1)
					return true

				else return false end
			else
				if hasCustomPlate(theVehicle) then -- remove the custom one first, if it doesnt have another one then no need to touch
					removeVehicleTexture(theVehicle, "License Plate (plateback1/2/3)")
				end
				return true
			end
		else return false end
	else return false end
end

function setLicensePlateTexture(theVehicle, id)
	id = tonumber(id)
	vehID = tonumber(getElementData(theVehicle,"dbid"))

	if vehID > -1 then
		exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:platetex", id, true)
		exports["savevehicle-system"]:saveVehicleMods(theVehicle)
		setTimer(function()
			refreshLicensePlateTexture(theVehicle)
		end, 1000, 1)
		return true
	else return false end
end
addEvent("vehtex:setPlate", true)
addEventHandler("vehtex:setPlate", getRootElement(), setLicensePlateTexture)

function adminSetPlateTexture(thePlayer, cmd, vehID, number)
	if exports.integration:isPlayerTrialAdmin(thePlayer) then
		if not (tonumber(vehID)) or not (tonumber(number)) then
			outputChatBox("SYNTAX: "..cmd.." [Vehicle ID] [Custom Plate #]",thePlayer,255,194,14)
			outputChatBox("  Type /customplates for a list of plate design IDs.",thePlayer,255,100,0)
			return
		end
		vehID = tonumber(vehID)
		number = tonumber(number)

		if (number ~= 0 and (not plateTextures[number])) then
			outputChatBox("Wrong ID! Type /customplates for a list of plate design IDs.",thePlayer,255,50,0)
			return
		end

		local theVehicle = nil
		for i,c in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
			if (getElementData(c, "dbid") == tonumber(vehID)) then
				theVehicle = c
				break
			end
		end

		if theVehicle then
			if setLicensePlateTexture(theVehicle, number) then
				if number > 0 then
					outputChatBox("'"..plateTextures[number][1].."' design applied for vehicle #"..vehID..".",thePlayer,0,255,0)
				else
					outputChatBox("Default plate set for vehicle #"..vehID..".",thePlayer,0,255,0)
				end
			end
		else
			outputChatBox("Vehicle not found. Is it a permanent vehicle?", thePlayer, 255, 0, 0)
		end
	end
end
addCommandHandler("setcustomplate", adminSetPlateTexture)
addCommandHandler("setplatetexture", adminSetPlateTexture)
addCommandHandler("setplate", adminSetPlateTexture)

function listPlates(thePlayer, cmd)
	if exports.integration:isPlayerTrialAdmin(thePlayer) then
		outputChatBox("Custom license plate design IDs:", thePlayer, 255,194,14)

		outputChatBox(" [0]  Default Plate (no texture)", thePlayer, 150,150,150)
		for k,plate in pairs(plateTextures) do
			outputChatBox(" ["..k.."]  "..plate[1], thePlayer, 200,200,200)
		end
	end
end
addCommandHandler("customplates", listPlates)
addCommandHandler("plates", listPlates)

function removeVehicleTexture(theVehicle, texName, isPreview, playr) --Fernando
	-- local thePlayer = source
	if(not theVehicle or not texName) then
		return false
	end
	if not getElementType(theVehicle) == "vehicle" then
		return false
	end
	-- if (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer)) then
		local mysql = exports.mysql

		multipleTextures = {}
		if texName == "License Plate (plateback1/2/3)" then
			table.insert(multipleTextures,"plateback1")
			table.insert(multipleTextures,"plateback2")
			table.insert(multipleTextures,"plateback3")
		end

		if #multipleTextures > 0 then
			for i=1,#multipleTextures do

				local tName = multipleTextures[i]

				local textures = getElementData(theVehicle, "textures") or {}
				for k,v in ipairs(textures) do
					if(v[1] == tName) then
						table.remove(textures, k)
						break
					end
				end

				if isPreview then
					if activePreviews[playr] then
						activePreviews[playr]= nil
					end
				end

				local vehID = tonumber(getElementData(theVehicle, "dbid")) or 0
				if vehID > 0 then
					local newdata = toJSON(textures)
					mysql:query_free("UPDATE vehicles SET textures='".. mysql:escape_string(newdata).. "' WHERE id='"..mysql:escape_string(vehID).."'")
				end
				exports.anticheat:changeProtectedElementDataEx(theVehicle, "textures", textures, true)
				removeTexture(theVehicle, tName)
			end
		else
			local textures = getElementData(theVehicle, "textures") or {}
			for k,v in ipairs(textures) do
				if(v[1] == texName) then
					table.remove(textures, k)
					break
				end
			end

			if isPreview then
				if activePreviews[playr] then
					activePreviews[playr]= nil
				end
			end

			local vehID = tonumber(getElementData(theVehicle, "dbid")) or 0
			if vehID > 0 then
				local newdata = toJSON(textures)
				mysql:query_free("UPDATE vehicles SET textures='".. mysql:escape_string(newdata).. "' WHERE id='"..mysql:escape_string(vehID).."'")
			end
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "textures", textures, true)
			removeTexture(theVehicle, texName)
		end
	-- end
end
addEvent("vehtex:removeTexture", true)
addEventHandler("vehtex:removeTexture", getRootElement( ), removeVehicleTexture)

function removePreviewing()
	if isElement(source) and getElementType(source)=="player" then

		if activePreviews[source] then
			local veh = activePreviews[source][1]
			local tname = activePreviews[source][2]
			removeVehicleTexture(veh,tname)
			activePreviews[source]= nil
		end

	end
end
addEventHandler("accounts:characters:change", root, removePreviewing)
addEventHandler("onPlayerQuit", root, removePreviewing)

-- Wipes textures from DB & item-texture cache of deleted vehicles.
-- Single-use only pretty much; as it will now be automated when a vehicle is deleted.
function clearDeletedVehicleTextures(thePlayer)
	if not exports.integration:isPlayerScripter(thePlayer) then return end

	local result = mysql:query("SELECT id, textures FROM vehicles WHERE textures != '"..toJSON({{}}).."' AND deleted != '0'")
	if result then
		local count = 0
		local count2 = 0

		repeat
			row = mysql:fetch_assoc(result)
			if row then
				local textures = fromJSON(row.textures) or {}
				local dbid = tonumber(row.id)

				for k, tex in pairs(textures) do
					local url = tex[2]
					if url then
						if unCacheTexture(url) then
							count2 = count2 +1
						end
					end
				end

				if mysql:query_free( "UPDATE vehicles SET textures='" .. toJSON({{}}) .. "' WHERE id=" .. dbid) then
					count = count + 1
				end
			end
		until not row
		mysql:free_result(result)

		outputChatBox("Uncached "..count2.." textures on "..count.." deleted vehicles.", thePlayer, 0,255,0)
		if count2 > 0 and count > 0 then
			outputChatBox("Restarting item-texture in 5 seconds...", thePlayer, 255,126,14)
			setTimer(restartResource, 5000, 1, getThisResource())
		end
	end
end
addCommandHandler("cdvt", clearDeletedVehicleTextures)

-- Wipes items from DB that are inside deleted vehicle inventories.
-- Single-use only pretty much; as vehicle inventories now get cleared when deleted (bug fixed).
function clearItemsInDeletedVehicles(thePlayer)
	if not exports.integration:isPlayerScripter(thePlayer) then return end
	local count = 0
	local count2 = 0

	local vehs = {}
	for k, veh in ipairs(getElementsByType("vehicle")) do
		local dbid = (getElementData(veh, "dbid") or 0)
		if dbid > 0 then
			vehs[dbid] = true
		end
	end

	local todel = {}

	local result2 = mysql:query("SELECT `index`,`owner`,`metadata` FROM `items` WHERE `type`='2' AND `destroyed` = '0' ORDER BY `index` ASC")
	if result2 then
		repeat
			row2 = mysql:fetch_assoc(result2)
			if row2 then
				if not vehs[tonumber(row2.owner)] then
					
					local metadata = row2.metadata ~= mysql_null() and fromJSON(row2.metadata) or {}
					for k,v in pairs(metadata) do
						if k == "url" then
							exports["item-texture"]:unCacheTexture(v)
							metadata[k] = nil
						end
					end

					table.insert(todel, {row2.index, metadata})
				else
					count2 = count2 +1
				end
			end
		until not row2
		mysql:free_result(result2)
	end

	for k,v in pairs(todel) do
		local index,metadata = unpack(v)
		if mysql:query_free( "UPDATE items SET destroyed=1, destroyedDate=NOW(), destroyedReason='clearItemsInDeletedVehicles', metadata='"..mysql:escape_string(toJSON(metadata)).."' WHERE `index` = '" .. index .. "' LIMIT 1" ) then
			count = count + 1
		else
			outputChatBox("Failed to delete "..index, thePlayer, 255,25,25)
		end
	end

	outputChatBox("Deleted "..count.." items inside deleted vehicles.", thePlayer, 0,255,255)
	outputChatBox("Found "..count2.." items which remain inside existing vehicles.", thePlayer, 0,255,0)
end
addCommandHandler("cidv", clearItemsInDeletedVehicles)