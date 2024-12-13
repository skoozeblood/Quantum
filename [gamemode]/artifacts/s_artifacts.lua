-- Fernando: 18/05/2021
-- support for infinite objects
-- major artifacts revamp

addEvent('artifacts:hideOnPlayer', true)--set alpha to 0
addEvent('artifacts:showOnPlayer', true)-- set alpha back to 255

addEvent('artifacts:hideAllOnPlayer', true)--set alpha to 0
addEvent('artifacts:showAllOnPlayer', true)-- set alpha back to 255

addEvent('artifacts:removeAllOnPlayer', true) -- remove all artifacts wearing

addEvent("artifacts:syncPositions", true) -- sync client saved positions to server

addEvent('artifacts:add', true)-- add 1
addEvent('artifacts:remove', true)--remove 1
addEvent('artifacts:toggle', true)--add/remove

local artifacts = {} -- [player][artifact] = obj, visible
local playerPositions = {} -- [player][skinid][artifact] = {x, y, z, rx, ry, rz, scale}

local farX, farY, farZ = 2937.111328125, 2929.818359375, 14.88894367218--far away in LV

function removeAllOnPlayer(player, readd)
	--Remove all artifacts on a given player
	exports.pAttach:detachAll(player)
	for artifact, v in pairs(artifacts[player] or {}) do
		if(isElement(v.obj)) then
			destroyElement(v.obj)
			artifacts[player][artifact] = nil
		end
	end

	-- outputServerLog("All artifacts removed from "..getPlayerName(player))
	artifacts[player] = {}
	syncPlayerArtifacts(player)

	if readd then
		setTimer(function()
			triggerEvent("item-system:addPlayerArtifacts", player, player)
		end, 500, 1)
	end
end
addEventHandler('artifacts:removeAllOnPlayer', getRootElement(), removeAllOnPlayer)

function hideAllOnPlayer(player)
	for artifact, v in pairs(artifacts[player] or {}) do
		if (isElement(v.obj) and (not v.invisible)) and (not v.hidden) then--not hidden by player on purpose already
			hideOnPlayer(player, artifact)
		end
	end
end
addEventHandler('artifacts:hideAllOnPlayer', getRootElement(), hideAllOnPlayer)

function showAllOnPlayer(player)
	for artifact, v in pairs(artifacts[player] or {}) do
		if ((v.invisible)) and (not v.hidden) then--not hidden by player on purpose already
			showOnPlayer(player ,artifact)
		end
	end
end
addEventHandler('artifacts:showAllOnPlayer', getRootElement(), showAllOnPlayer)

function hideOnPlayer(player, artifact)
	if not artifacts[player] then return end
	local a = artifacts[player][artifact]
	if not a then return end

	if (isElement(a.obj) and (not a.invisible)) and (not a.hidden) then--not hidden by player on purpose already
		exports.pAttach:detach(a.obj)
		destroyElement(a.obj)
		artifacts[player][artifact].invisible = {a.customTex, a.itemName} -- save this to re-add later
	end
end
addEventHandler('artifacts:hideOnPlayer', getRootElement(), hideOnPlayer)

function showOnPlayer(player ,artifact)
	if not artifacts[player] then return end
	local a = artifacts[player][artifact]
	if not a then return end

	if ((a.invisible)) and (not a.hidden) then--not hidden by player on purpose already
		local customItemTexture, itemName = unpack(a.invisible)
		artifacts[player][artifact] = nil -- clear to readd
		addArtifact(player, artifact, customItemTexture, itemName)
	end
end
addEventHandler('artifacts:showOnPlayer', getRootElement(), showOnPlayer)


function addArtifact(player, artifact, customItemTexture, itemName)
	--Start to wear an artifact the player is not already wearing
	if player and artifact then
		if artifacts[player] and artifacts[player][artifact] then
			return
		else
			--get artifact data
			local data = g_artifacts[artifact]
			if not data then
				print("Unknown artifact: "..artifact)
				return false
			end

			local x,y,z = getElementPosition(player)
			local object = createObject(default_obj, farX, farY, farZ)
			setElementData(object, "artifact:name", artifact)

			setElementData(object, "sarp_items:artifact", artifact)
			if not data.colEnabled then
				setElementCollisionsEnabled(object, false)
			else
				setElementCollisionsEnabled(object, true)
			end
			setElementDoubleSided(object, data.ds)
			setElementInterior(object, getElementInterior(player))
			setElementDimension(object, getElementDimension(player))

			local x,y,z,rx,ry,rz = unpack(data.pos)
			local scale = data.scale

			local isHidden = false

			local playerPos = playerPositions[player]
			if playerPos then
				local skinID = getElementData(player, "skinID") or getElementModel(player)
				local forSkin = playerPos[skinID]
				if forSkin then
					local thisPos = forSkin[artifact]
					if thisPos then
						x,y,z,rx,ry,rz,scale,hidden = unpack(thisPos)
						-- outputChatBox("Loaded saved position for "..artifact..".", player,0,255,0)

						if hidden then
							isHidden = skinID
						end
					end
				end
			end

			setObjectScale(object, scale)
			-- outputChatBox("Add "..artifact, player)

			if not artifacts[player] then
				artifacts[player] = {}
			end

			artifacts[player][artifact] = {}
			artifacts[player][artifact].obj = object
			artifacts[player][artifact].hidden = isHidden
			
			artifacts[player][artifact].itemName = itemName

			if isHidden then
				destroyElement(object)
				triggerClientEvent(player, "displayMesaage", player, "Your "..(itemName or artifact).." is hidden for skin #"..isHidden..".", "info")
			else
				if not exports.pAttach:attach(object, player, data.bone,x,y,z,rx,ry,rz) then
					destroyElement(object)
					artifacts[player][artifact] = nil
					return
				end
				
				for k, player in ipairs(getElementsWithinRange(x,y,z, 100, "player", getElementInterior(player), getElementDimension(player))) do
					triggerClientEvent(player, "loadArtifactObject", object)
				end

				local texture = data.texture
				local texname = data.texname

					-- defined in g_artifacts
				if texture and texname then
					exports["item-texture"]:addTexture(object, texname, texture)
					-- from item-system metadata
				elseif customItemTexture then
					if type(customItemTexture) == "table" then
						exports["item-texture"]:addTexture(object, customItemTexture[2], customItemTexture[1])
						artifacts[player][artifact].customTex = customItemTexture
					end
				end
			end

			syncPlayerArtifacts(player)
		end
	end
end
addEventHandler('artifacts:add', getRootElement(), addArtifact)

function removeArtifact(player, artifact)
	--Removing an artifact the player is wearing
	if player and artifact then
		if not artifacts[player] or not artifacts[player][artifact] then
			return
		else
			local obj = artifacts[player][artifact].obj
			if isElement(obj) then
				exports.pAttach:detach(obj)
    			destroyElement(obj)
			end
			artifacts[player][artifact] = nil

			syncPlayerArtifacts(player)
		end
	end
end
addEventHandler('artifacts:remove', getRootElement(), removeArtifact)

function toggleArtifact(player, artifact, customItemTexture, itemName)
	--Used for toggling an artifact, independent on current state.
	-- This is what you for example want to use from item-system
	-- when clicking an item to wear or take off

	if player and artifact then
		if not artifacts[player] or not artifacts[player][artifact] then
			addArtifact(player, artifact, customItemTexture, itemName)
		else
			removeArtifact(player, artifact)
		end
	end
end
addEventHandler('artifacts:toggle', getRootElement(), toggleArtifact)

function checkFloatingArtifacts()
	if getElementType(source)=="player" then
		removeAllOnPlayer(source)
	end
end
--When to remove all objects from a player:
addEventHandler("onCharacterLogout", getRootElement(), checkFloatingArtifacts)
addEventHandler("onPlayerQuit", getRootElement(), checkFloatingArtifacts)

function getPlayerArtifacts(player)
	-- returns a table of all articrafts the player is wearing
	-- (table contains the IDs of the artifacts worn as strings)

	local tableWithElements = {}

	if artifacts[player] then
		for name, v in pairs(artifacts[player]) do
			if(isElement(v.obj)) then
				tableWithElements[name] = v.obj
			end
		end
	end

	return tableWithElements
end

function syncPlayerArtifacts(player)
	-- so the client knows which artifacts people are wearing directly
	for k, pl in ipairs(getElementsByType("player")) do
		triggerClientEvent(pl, "syncWearingArtifacts", pl, player, artifacts[player] or {})
	end
end

function isPlayerWearingArtifact(player, artifact)
	--returns boolean wether player is wearing the specified artifact or not
	if artifacts[player] and artifacts[player][artifact] and isElement(artifacts[player][artifact].obj) then
		return true
	end
	return false
end

function syncPlayerPositions(player, tab)
	playerPositions[player] = tab
end
addEventHandler("artifacts:syncPositions", root, syncPlayerPositions)

-- addCommandHandler("testweapon", function(player)
-- 	if not exports.integration:isPlayerScripter(player) then return end
--     local object = createObject(356, 0, 0, 0)
--     exports.pAttach:attach(object, player, "weapon", 0, 0, 0, 0, 0, 0)
-- end)
-- addCommandHandler("testbackpack", function(player)
-- 	if not exports.integration:isPlayerScripter(player) then return end
--     local object = createObject(371, 0, 0, 0)
--     exports.pAttach:attach(object, player, "backpack", 0, -0.15, 0, 90, 0, 0)
-- end)