local debugModelOutput = false

rightclick = exports.rightclick
integration = exports.integration
itemworld = exports['item-world']
item = exports['item-system']
localPlayer = getLocalPlayer()

local noMenuFor = {
	[0] = true, --nothing
}
local noPickupFor = {
}
local noPropertiesFor = {

}

function clickObject(button, state, absX, absY, wx, wy, wz, element)
	rightclick = exports.rightclick
	integration = exports.integration
	itemworld = exports['item-world']
	item = exports['item-system']

	--outputDebugString("You clicked a "..tostring(getElementType(element)).." ("..tostring(getElementModel(element))..")")
	if getElementData(localPlayer, "exclusiveGUI") then
		--outputDebugString("rightclick abort: exclusiveGUI")
		return
	end
	if (element) and (getElementType(element)=="object") and (button=="right") and (state=="down") then
		local x, y, z = getElementPosition(getLocalPlayer())
		local eX, eY, eZ = getElementPosition(element)
		local minX, minY, minZ, maxX, maxY, maxZ = getElementBoundingBox(element)
		local addDistance = 0 --compensate for object size
		if minX then
			local boundingBoxBiggestDist = 0
			if minX > boundingBoxBiggestDist then
				boundingBoxBiggestDist = minX
			end
			if minY > boundingBoxBiggestDist then
				boundingBoxBiggestDist = minY
			end
			if maxX > boundingBoxBiggestDist then
				boundingBoxBiggestDist = maxX
			end
			if maxY > boundingBoxBiggestDist then
				boundingBoxBiggestDist = maxY
			end
			addDistance = boundingBoxBiggestDist
		end
		local maxDistance = 3 + addDistance
		if (getDistanceBetweenPoints3D(x, y, z, wx, wy, wz)<=maxDistance) then
			local rcMenu
			local row = {}

			if getElementParent(getElementParent(element)) == getResourceRootElement(getResourceFromName("item-world")) then
				local itemID = tonumber(getElementData(element, "itemID")) or 0
				if noMenuFor[itemID] then return end

				local itemValue = getElementData(element, "itemValue") or 1
				local metadata = getElementData(element, "metadata") or {}
				local itemName = tostring(item:getItemName(itemID, itemValue, metadata))
				local worldItemID = getElementData(element, "id")

				local ex,ey,ez = getElementPosition(element)

				if itemworld:can(localPlayer, "use", element) then
					if itemID == 81 then --fridge
						if not rcMenu then rcMenu = rightclick:create(itemName) end
						row.a = rightclick:addrow("Open fridge")
						addEventHandler("onClientGUIClick", row.a,  function (button, state)
							if not getElementData ( localPlayer, "exclusiveGUI" ) then
								triggerServerEvent( "openFreakinInventory", getLocalPlayer(), element, absX, absY )
							end
						end, false)
					elseif itemID == 103 then --shelf
						if not rcMenu then rcMenu = rightclick:create(itemName) end
						row.a = rightclick:addrow("Browse shelf")
						addEventHandler("onClientGUIClick", row.a,  function (button, state)
							if not getElementData ( localPlayer, "exclusiveGUI" ) then
								triggerServerEvent( "openFreakinInventory", getLocalPlayer(), element, absX, absY )
							end
						end, false)
					elseif item:isStorageItem(itemID, itemValue) then -- Storage
						if not rcMenu then rcMenu = rightclick:create(itemName) end
						row.a = rightclick:addrow("Browse storage")
						addEventHandler("onClientGUIClick", row.a,  function (button, state)
							if not getElementData ( localPlayer, "exclusiveGUI" ) then
								triggerServerEvent( "openFreakinInventory", getLocalPlayer(), element, absX, absY )
							end
						end, false)
					elseif itemID == 166 then --video system
						if not rcMenu then rcMenu = rightclick:create(itemName) end
						if item:hasItem(element, 165) then --if disc in
							row.a = rightclick:addrow("Eject disc")
							addEventHandler("onClientGUIClick", row.a,  function (button, state)
								-- triggerServerEvent("clubtec:vs1000:ejectDisc", getLocalPlayer(), element)
							end, false)
						end
						row.b = rightclick:addrow("Control")
						addEventHandler("onClientGUIClick", row.b,  function (button, state)
							-- triggerServerEvent("clubtec:vs1000:gui", getLocalPlayer(), element)
						end, false)
					elseif itemID == 54 or itemID == 176 then -- Ghettoblaster
						if not rcMenu then rcMenu = rightclick:create(itemName) end
						row.a = rightclick:addrow("Edit sound")
						addEventHandler("onClientGUIClick", row.a,  function (button, state)
							triggerEvent("item:showMenu", getLocalPlayer(), element, absX, absY)
						end, false)
					elseif itemID == 96 then

						if not rcMenu then rcMenu = rightclick:create(itemName) end
						row.a = rightclick:addrow("Use")
						addEventHandler("onClientGUIClick", row.a,  function (button, state)

							if getDistanceBetweenPoints3D(x, y, z, ex,ey,ez) > 2 then
								return outputChatBox("You're too far from the laptop!", 187,187,187)
							end

							triggerEvent("useCompItem", localPlayer)
							triggerServerEvent("computers:on", localPlayer)
						end, false)
					elseif exports["item-system"]:isVendingMachine(itemID, itemValue, metadata) then -- Vending machine

						if not rcMenu then rcMenu = rightclick:create(itemName) end
						row.a = rightclick:addrow("Use")
						addEventHandler("onClientGUIClick", row.a,  function (button, state)
							triggerServerEvent("openVendingMachineMenu", localPlayer, worldItemID, metadata, element)
						end, false)

						if exports["item-system"]:canManageVendingMachine(localPlayer, worldItemID, metadata) then

							row.managevm = rightclick:addrow("Manage")
							addEventHandler("onClientGUIClick", row.managevm,  function (button, state)
								triggerServerEvent("manageVendingMachine", localPlayer, worldItemID, metadata, element)
							end, false)
						end
						if exports["item-system"]:canEditVendingMachine(localPlayer, worldItemID, metadata) then

							row.editvm = rightclick:addrow("Edit")
							addEventHandler("onClientGUIClick", row.editvm,  function (button, state)
								triggerEvent("makeVendingMachineGUI", localPlayer, element, metadata)
							end, false)
						end

					elseif(exports.sittablechairs:isSittableChair(element)) then
						if(exports.sittablechairs:canSitOnChair(element)) then
							if not rcMenu then rcMenu = rightclick:create(itemName) end
							row.a = rightclick:addrow("Sit")
							addEventHandler("onClientGUIClick", row.a,  function (button, state)
								exports.sittablechairs:attemptToSitOnChair(element)
							end, false)
						end
					end
				end

				local adm = exports.global:isAdminOnDuty(localPlayer)
				local mto = exports.global:isMTOnDuty(localPlayer)

				local creator = tonumber(getElementData(element, "creator")) or 0 -- // Fernando
				if (getElementDimension(element) ~= 0 or adm or creator == getElementData(localPlayer, "dbid")
				or getElementData(localPlayer, "givemoveitem"))
				and itemworld:can(localPlayer, "move", element)
				and not item:isProtected(localPlayer, element)
					then

					if not rcMenu then rcMenu = rightclick:create(itemName) end
					row.move = rightclick:addrow("Move")
					addEventHandler("onClientGUIClick", row.move,  function (button, state)
						triggerEvent("item:move", root, element)
					end, false)
				end
				if not noPickupFor[itemID] and itemworld:can(localPlayer, "pickup", element) and not item:isProtected(localPlayer, element) then
					if not rcMenu then rcMenu = rightclick:create(itemName) end
					row.pickup = rightclick:addrow("Pick up")
					addEventHandler("onClientGUIClick", row.pickup,  function (button, state)
						if itemID ~= 223 and itemID ~= 103 and itemID ~= 314 then
							-- is not: storage generic, shelf, vending machine
							if item:hasSpaceForItem(localPlayer, itemID, itemValue, metadata) then
								triggerServerEvent("pickupItem", getLocalPlayer(), element)
							else
								outputChatBox("You lack the space in your inventory to pick this item up.", 255, 0, 0)
							end
						else
							areYouSure(element, "pickup")
						end
					end, false)
				end
				if not noPropertiesFor[itemID] and itemworld:canEditItemProperties(localPlayer, element) then
					if not rcMenu then rcMenu = rightclick:create(itemName) end
					row.properties = rightclick:addrow("Properties")
					addEventHandler("onClientGUIClick", row.properties,  function (button, state)
						triggerEvent("showItemProperties", localPlayer, element)
					end, false)
				end


				if #exports["item-system"]:getEditableMetadataFor(localPlayer, nil, itemID, metadata) > 0 then
					if not rcMenu then rcMenu = rightclick:create(itemName) end
					row.metadata = rightclick:addrow("Metadata")
					addEventHandler("onClientGUIClick", row.metadata,  function (button, state)
						triggerEvent("item-system:openMetadataEditor", localPlayer, {itemID, itemValue, worldItemID, "editing metadata for worlditem!", metadata}, element)
					end, false)
				end


				local target_valid = exports["fernando-targets"]:isValidWorldItemTarget(element)
				if target_valid then
					if exports["fernando-targets"]:isDefinedWorldItemTarget(element) then

						if exports["fernando-targets"]:isTargetOwner(localPlayer, element) then -- is target owner or admin on duty

							if not rcMenu then rcMenu = rightclick:create(itemName) end
							row.target = rightclick:addrow("Target Settings")
							addEventHandler("onClientGUIClick", row.target,  function ()
								triggerServerEvent("fernando-targets:defineTarget", localPlayer, element, true)
							end, false)

							if metadata["target_fall"] == true then
								row.togfall = rightclick:addrow(metadata["target_isup"] == true and "Place Down" or "Place Up")
								addEventHandler("onClientGUIClick", row.togfall,  function ()
									triggerServerEvent("fernando-targets:togTargetFall", localPlayer, element, metadata["target_isup"] == false, true)
								end, false)
							end

						end
					else
						if not rcMenu then rcMenu = rightclick:create(itemName) end
						row.target = rightclick:addrow("Define Target")
						addEventHandler("onClientGUIClick", row.target, function()
							triggerServerEvent("fernando-targets:defineTarget", localPlayer, element)
						end, false)
					end
				end


				if adm or mto then

					if not rcMenu then rcMenu = rightclick:create(itemName) end
					if adm then

						row.delItem = rightclick:addRow("ADM: Delete Item")
						addEventHandler("onClientGUIClick", row.delItem, function()
							areYouSure(element, "delete")
						end, false)
					end

					row.copyPos = rightclick:addRow("ADM: Copy Position")
					addEventHandler("onClientGUIClick", row.copyPos, function()
						local x,y,z = getElementPosition(element)
						local rx, ry, rz = getElementRotation(element)
						local dimension = getElementDimension(element)
						local interior = getElementInterior(element)


						outputChatBox("Position: " .. x .. ", " .. y .. ", " .. z, 255, 50, 125)
						outputChatBox("Rotation: " .. rx .. ", " .. ry .. ", " .. rz, 255, 50, 100)
						outputChatBox("Interior: " .. interior .. " and Dimension: "..dimension, 255, 50, 150)

						local prepairedText = ""..x..", "..y..", "..z..", "..rx..", "..ry..", "..rz..""
						outputChatBox("'"..prepairedText.."' - copied to clipboard.", 200, 200, 200)
						triggerEvent("copyPosToClipboard", localPlayer, prepairedText)
					end, false)
				end
			else
				if(exports.sittablechairs:isSittableChair(element)) then
					if(exports.sittablechairs:canSitOnChair(element)) then
						if not rcMenu then rcMenu = rightclick:create("Chair") end
						row.a = rightclick:addrow("Sit")
						addEventHandler("onClientGUIClick", row.a,  function (button, state)
							exports.sittablechairs:attemptToSitOnChair(element)
						end, false)
					end
				end
			end


			local model = getElementModel(element)
			if(model == 2517) then --SHOWERS
				if not rcMenu then  rcMenu = exports.rightclick:create("Shower") end
				if showering[1] then
					row.a = exports.rightclick:addrow("Stop showering")
					addEventHandler("onClientGUIClick", row.a,  function (button, state)
						takeShower(element)
					end, false)
				else
					row.a = exports.rightclick:addrow("Take a shower")
					addEventHandler("onClientGUIClick", row.a,  function (button, state)
						takeShower(element)
					end, false)
				end
			--[[elseif(model == 2964) then --Pool table / Billiard
				if not rcMenu then  rcMenu = exports.rightclick:create("Pool Table") end
				row.a = exports.rightclick:addrow("New Game")
				addEventHandler("onClientGUIClick", row.a,  function (button, state)
					outputDebugString("object-interaction: triggering billiard")
					--exports['minigame-billiard'].startNewGame(element, getLocalPlayer())
					triggerServerEvent("sendLocalMeAction", getLocalPlayer(), getLocalPlayer(), "test message")
					triggerServerEvent("billiardnewgame", getLocalPlayer(), getLocalPlayer(), "test message")
					local result = triggerServerEvent("newBilliardGame", getLocalPlayer(), element)
					outputDebugString("server trigger "..tostring(result)..", "..tostring(element))

				end, true)
			--]]
			elseif(model == 2146) then --Stretcher (ES)
				if not rcMenu then  rcMenu = exports.rightclick:create("Stretcher") end
				row.a = exports.rightclick:addrow("Take Stretcher")
				addEventHandler("onClientGUIClick", row.a,  function (button, state)
					triggerServerEvent("stretcher:takeStretcher", localPlayer, element)
				end, true)
			elseif(model == 962) then --Airport gate control box
				local airGateID = getElementData(element, "airport.gate.id")
				if airGateID then
					if not rcMenu then  rcMenu = exports.rightclick:create("Control Box") end
					row.a = exports.rightclick:addrow("Control Gate")
					addEventHandler("onClientGUIClick", row.a,  function (button, state)
						triggerEvent("airport-gates:controlGUI", getLocalPlayer(), element)
					end, false)
				end
			elseif(model == 1819) then --Airport fuel
				local airFuel = getElementData(element, "airport.fuel")
				if airFuel then
					outputDebugString("Air fuel: TODO")
				end
			else
				if debugModelOutput then
					lastDebugModelElement = element
					outputChatBox("Model ID "..tostring(model))
					outputChatBox("Breakable: "..tostring(isObjectBreakable(element)))
					--[[
					local mapsres = getResourceDynamicElementRoot(getResourceFromName("maps"))
					local objectParent = getElementParent(getElementParent(element))
					if getElementType(objectParent) == "resource" then
						if mapsres == objectParent then
							outputChatBox("From resource: maps")
						end
					end
					--]]
					local objectIdentity = getElementData(element, "id")
					if objectIdentity then
						outputChatBox("ID: "..tostring(objectIdentity))
					end
					--outputDebugString("parent type = "..tostring(getElementType(objectParent)))
					--if getElementType(objectParent) == "resource" then
						--local objectResourceName = tostring(getResourceName(getResourceRootElement(objectParent)))
						--outputChatBox("Parent: "..objectResourceName)
						--if objectResourceName == "maps" then
							local objectPosX, objectPosY, objectPosZ = getElementPosition(element)
							local objectRotX, objectRotY, objectRotZ = getElementRotation(element)
							local mapformat = '<object id="object" breakable="'..tostring(isObjectBreakable(element))..'" interior="'..tostring(getElementInterior(element))..'" alpha="'..tostring(getElementAlpha(element))..'" model="'..tostring(model)..'" doublesided="'..tostring(getElementData(element, "doublesided") and true)..'" scale="'..tostring(getObjectScale(element) or 0)..'" dimension="'..tostring(getElementDimension(element))..'" posX="'..tostring(objectPosX)..'" posY="'..tostring(objectPosY)..'" posZ="'..tostring(objectPosZ)..'" rotX="'..tostring(objectRotX)..'" rotY="'..tostring(objectRotY)..'" rotZ="'..tostring(objectRotZ)..'"></object>'
							outputConsole(mapformat)
						--end
					--end
				end
			end
		end
	end
end
addEventHandler("onClientClick", getRootElement(), clickObject, true)

function cmdRightClickItem(commandName, itemID)
	if not tonumber(itemID) then
		return outputChatBox("SYNTAX: /" .. commandName .. " [World Item ID from /nearbyitems]", 255, 194, 14)
	end
	itemID = tonumber(itemID)

	local object = nil

	for key, value in ipairs(getElementsByType("object", getResourceRootElement(getResourceFromName("item-world")))) do
		local dbid = getElementData(value, "id")
		if dbid and dbid == itemID then
			object = value
			break
		end
	end

	if object then
		local wx, wy, wz = getElementPosition(object)
		triggerEvent("f_toggleCursor", localPlayer, true)
		triggerEvent("onClientClick", object, "right", "down", 0.5, 0.5, wx, wy, wz, object)
	else
		outputChatBox("Invalid item ID.", 255, 0, 0)
	end
end
addCommandHandler("rcitem", cmdRightClickItem, false)
addCommandHandler("rightclickitem", cmdRightClickItem, false)
addCommandHandler("rcobject", cmdRightClickItem, false)
addCommandHandler("rightclickobject", cmdRightClickItem, false)
addCommandHandler("clickitem", cmdRightClickItem, false)
addCommandHandler("clickobject", cmdRightClickItem, false)

function areYouSure( element, action )
	local SCREEN_X, SCREEN_Y = guiGetScreenSize()
	local check = { }
	local width = 400 -- The width of our window
	local height = 140 -- The height of our window
	local x = SCREEN_X / 2 - width / 2
	local y = SCREEN_Y / 2 - height / 2

	if action == "pickup" then

		check.window = guiCreateWindow( x, y, width, height, "Pickup Item", false )
		check.message = guiCreateLabel( 10, 30, width - 20, 20, "Are you sure you want to pick up this item?", false, check.window )
		check.this = guiCreateLabel(10, 50, width - 20, 30, "This will destroy all items stored in its inventory.", false, check.window)

	elseif action == "delete" then

		check.window = guiCreateWindow( x, y, width, height, "Destroy Item", false )
		check.message = guiCreateLabel( 10, 30, width - 20, 20, "Are you sure you want to delete this item?", false, check.window )
		check.this = guiCreateLabel(10, 50, width - 20, 30, "If necessary it can be restored afterwards.", false, check.window)
	end
	guiLabelSetHorizontalAlign( check.this, "center", true)
	guiLabelSetHorizontalAlign( check.message, "center", true)

	check.closeButton = guiCreateButton( 10, 87, width / 2 - 15, 40, "Cancel", false, check.window )
	guiSetProperty(check.closeButton, "NormalTextColour", "FF00FF00")
	addEventHandler( "onClientGUIClick", check.closeButton,
		function ()
			destroyElement( check.window )
			setElementData(localPlayer, "exclusiveGUI", false)
			check = { }
		end
	)

	check.deleteButton = guiCreateButton( width / 2 + 5, 87, width / 2 - 15, 40, "Yes, proceed", false, check.window )
	addEventHandler( "onClientGUIClick", check.deleteButton,
		function ()

			if action == "pickup" then

				triggerServerEvent("pickupItem", localPlayer, element)

			elseif action == "delete" then

				triggerServerEvent("delitem:cmd", localPlayer, localPlayer, "delitem", getElementData(element, "id"))
			end

			destroyElement( check.window )
			setElementData(localPlayer, "exclusiveGUI", false)
			check = { }
		end
	)

	setTimer(setElementData, 250, 1, localPlayer, "exclusiveGUI", true)
	triggerEvent("f_toggleCursor", localPlayer, true)
end

function debugToggleModelOutput(thePlayer, commandName)
	--if exports.integration:isPlayerScripter(thePlayer) then
		debugModelOutput = not debugModelOutput
		outputChatBox("DBG: ModelOutput set to "..tostring(debugModelOutput))
	--end
end
addCommandHandler("debugmodeloutput", debugToggleModelOutput)

function debugDeleteLastModel(thePlayer, commandName)
	if debugModelOutput then
		--if exports.integration:isPlayerScripter(thePlayer) then
		if exports.integration:isPlayerTrialAdmin(thePlayer) then
			if lastDebugModelElement then
				if isElement(lastDebugModelElement) then
					destroyElement(lastDebugModelElement)
				end
			end
			debugModelOutput = not debugModelOutput
			outputChatBox("DBG: ModelOutput set to "..tostring(debugModelOutput))
		end
	end
end
addCommandHandler("deletelastdebugmodel", debugDeleteLastModel)

addEventHandler("onClientObjectBreak", root,
	function()
		--local isBreakable = isObjectBreakable(source)
		--if not isBreakable then
			cancelEvent()
		--end
		--outputDebugString("object-interaction/c_objects_rightclick: Object breakable "..tostring(isBreakable))
	end
)

function refreshCalls(res)
	rightclick = exports.rightclick
	integration = exports.integration
	itemworld = exports['item-world']
	item = exports['item-system']
end
addEventHandler("onClientResourceStart", getRootElement(), refreshCalls)
