local mysql = exports.mysql

armoredCars = { [427]=true, [528]=true, [432]=true, [601]=true, [428]=true } -- Enforcer, FBI Truck, Rhino, SWAT Tank, Securicar
totalTempVehicles = 0
vehiclesSpawnedHere = {}
respawnTimer = nil


local trailerModels = {[606]=true,[607]=true,[610]=true,[584]=true,[611]=true,[608]=true,[435]=true,[450]=true,[591]=true}

local dmv_faction = exports["license-system"]:getDMVFID()
local towingID = 4

function getVehicleName(vehicle)
	return exports.global:getVehicleName(vehicle)
end

--Fernando
function forceMaintenance(thePlayer, commandName, vehID)

	if exports.integration:isPlayerVMTMember(thePlayer) or exports.integration:isPlayerTrialAdmin(thePlayer) then

		if not vehID or not tonumber(vehID) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Vehicle ID]", thePlayer, 255, 194, 14)
			outputChatBox("Forcefully does the vehicle maintenance -> next one will be in 2,500 km", thePlayer, 255, 255, 14)
			return
		end

		local theVehicle = exports.pool:getElement("vehicle", vehID)
		if not theVehicle then
			outputChatBox("No vehicle found with ID #"..vehID..".", thePlayer, 255,0,0)
			return
		end

		local odometer = math.floor(getElementData(theVehicle, "odometer") / 1000)

		exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:maintenance", odometer + 2500, true)
		exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:lastMaintenance", odometer, true)

		outputChatBox("Vehicle maintenance for #"..vehID.." done at "..odometer.." km.", thePlayer, 0,255,0)

	end
end
addCommandHandler("vehmaintenance", forceMaintenance)
addCommandHandler("forcemaintenance", forceMaintenance)
addCommandHandler("forcevehmaintenance", forceMaintenance)


--Fernando
function adminDisableEngine(thePlayer, commandName, vehID)

	if exports.integration:isPlayerVMTMember(thePlayer) or exports.integration:isPlayerTrialAdmin(thePlayer) then

		if not vehID or not tonumber(vehID) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Vehicle ID]", thePlayer, 255, 194, 14)
			outputChatBox("Disables/enables the vehicle's engine permanently.", thePlayer, 255, 255, 14)
			return
		end

		local theVehicle = exports.pool:getElement("vehicle", vehID)
		if not theVehicle then
			outputChatBox("No vehicle found with ID #"..vehID..".", thePlayer, 255,0,0)
			return
		end

		local e_disabled = getElementData(theVehicle, "e_disabled")
		local engine = getElementData(theVehicle, "engine")

		if e_disabled == 1 then
			mysql:query_free("UPDATE vehicles SET e_disabled = '0' WHERE id='" .. mysql:escape_string(vehID) .. "'")
			outputChatBox("Engine of vehicle ID #"..vehID.." is now no longer disabled.", thePlayer, 0, 255, 0)

			exports.anticheat:changeProtectedElementDataEx(theVehicle, "e_disabled", 0, true)
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "enginebroke", 0, false)

			exports.global:sendMessageToStaff("["..string.upper(commandName).."]: "..getElementData(thePlayer, "account:username").." has enabled engine of vehicle #"..vehID..".", true)
			addVehicleLogs(vehID, 'DISABLE ENGINE off', thePlayer)
			exports.discord:sendDiscordMessage("veh-logs", ":gear: **"..getElementData(thePlayer, "account:username").."** has ``enabled engine`` of **vehicle #"..vehID.."**.")
		else
			mysql:query_free("UPDATE vehicles SET e_disabled = '1' WHERE id='" .. mysql:escape_string(vehID) .. "'")
			outputChatBox("Engine of vehicle ID #"..vehID.." is now permanently disabled.", thePlayer, 255, 255, 0)

			setVehicleEngineState(theVehicle, false)
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "e_disabled", 1, true)
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "enginebroke", 1, false)
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "engine", 0, true)
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:radio", 0, true)

			exports.global:sendMessageToStaff("["..string.upper(commandName).."]: "..getElementData(thePlayer, "account:username").." has permanently disabled engine of vehicle #"..vehID..".", true)
			addVehicleLogs(vehID, 'DISABLE ENGINE on', thePlayer)
			exports.discord:sendDiscordMessage("veh-logs", ":gear: **"..getElementData(thePlayer, "account:username").."** has ``permanently disabled engine`` of **vehicle #"..vehID.."**.")

		end
	end
end
addCommandHandler("togeengine", adminDisableEngine)
addCommandHandler("disableengine", adminDisableEngine)
addCommandHandler("atoggleengine", adminDisableEngine)
addCommandHandler("atogengine", adminDisableEngine)
addCommandHandler("adisableengine", adminDisableEngine)

function respawnTheVehicle(vehicle)-- a bit useless, could just use onVehicleRespawn in vehicle-sys
	setElementCollisionsEnabled( vehicle, true )
	respawnVehicle( vehicle )

	if armoredCars[ getElementModel( vehicle ) ] or getElementData(vehicle, "bulletproof") == 1 then
		setVehicleDamageProof(vehicle, true)
	else
		setVehicleDamageProof(vehicle, false)
	end
	if (trailerModels[getElementModel(vehicle)]) then
		setElementFrozen(vehicle,false)
		setTimer(setElementFrozen, 2000, 1, vehicle, true)
	end
end


function getAttachedStuff(thePlayer, command, ID)
	local theVehicle
	if not tonumber(ID) then
		theVehicle = exports.pool:getElement("vehicle", tonumber(ID))
	else
		theVehicle = getPedOccupiedVehicle(thePlayer)
	end

	if not theVehicle then
		return outputChatBox("SYNTAX: /"..command.." [Vehicle ID]", thePlayer, 255,194,14)
	end
	
	local count = 0
	outputChatBox("Vehicle #"..ID.." attachments: ",thePlayer,255,194,14)

	for k, v in ipairs ( getAttachedElements(theVehicle) or {} ) do
		if ( getElementType ( v ) == "object" ) then
			outputChatBox("   - Object ID " .. getElementModel(v), thePlayer,255,126,0)
			count = count + 1
		end
	end
	if count == 0 then
		outputChatBox("   None.", thePlayer, 255,126,0)
	end
end
addCommandHandler("vatt", getAttachedStuff)
addCommandHandler("vattachments", getAttachedStuff)

--MAXIME
function reloadVehicleByAdmin(thePlayer, commandName, vehID)
	if exports.integration:isPlayerTrialAdmin( thePlayer ) or exports.integration:isPlayerVMTMember(thePlayer) then
		local veh = false
		if not vehID or not tonumber(vehID) or (tonumber(vehID) % 1 ~= 0 ) then
			veh = getPedOccupiedVehicle(thePlayer) or false
			if veh then
				vehID = getElementData(veh, "dbid") or false
				if not vehID then
					outputChatBox( "You must be in a vehicle.", thePlayer, 255, 194, 14)
					outputChatBox("Or use SYNTAX: /"..commandName.." [Vehicle ID]", thePlayer, 255, 194, 14)
					return false
				end
			end
		end

		if not vehID or not tonumber(vehID) or (tonumber(vehID) % 1 ~= 0 ) then
			outputChatBox( "You must be in a vehicle.", thePlayer, 255, 194, 14)
			outputChatBox("Or use SYNTAX: /"..commandName.." [Vehicle ID]", thePlayer, 255, 194, 14)
			return false
		end

		--[[
		local vehs = getElementsByType("vehicle")
		for i, v in pairs (vehs) do
			if getElementData(v,"dbid") == tonumber(vehID) then
				destroyElement(theVehicle)
				break
			end
		end
		]]


		if exports.integration:isPlayerVMTMember(thePlayer) then
			-- Discord log
			exports.discord:sendDiscordMessage("veh-logs", ":recycle: **"..getElementData(thePlayer, "account:username").."** has ``reloaded`` vehicle ``ID #"..vehID.."``.")
		end

		addVehicleLogs(tonumber(vehID), commandName, thePlayer)
		exports.logs:dbLog(thePlayer, 4, { veh, thePlayer }, commandName)

		reloadVehicle2(tonumber(vehID))
		outputChatBox("[VEHICLE MANAGER] Vehicle ID#"..vehID.." reloaded.", thePlayer)
		
		return true
	end
end
addCommandHandler("reloadveh", reloadVehicleByAdmin)
addCommandHandler("reloadvehicle", reloadVehicleByAdmin)


function togVehReg(admin, command, target, status)
	if (exports.integration:isPlayerTrialAdmin(admin)) then
		if not (target) or not (status) then
			outputChatBox("SYNTAX: /" .. command .. " [Veh ID] [0- Off, 1- On]", admin, 255, 194, 14)
		else
			local username = getPlayerName(admin):gsub("_"," ")
			local pv = exports.pool:getElement("vehicle", tonumber(target))

			if (pv) then
					local vid = getElementData(pv, "dbid")
					local stat = tonumber(status)
					if isElementAttached(pv) then
					detachElements(pv)
					end
					if (stat == 0) then
						mysql:query_free("UPDATE vehicles SET registered = '0' WHERE id='" .. mysql:escape_string(vid) .. "'")
						exports.anticheat:changeProtectedElementDataEx(pv, "registered", 0)
						outputChatBox("You have toggled the registration to unregistered on vehicle #" .. vid .. ".", admin)

						addVehicleLogs(getElementData(pv, "dbid"), command.." OFF", admin)
						exports.logs:dbLog(admin, 4, { pv, admin }, command.." OFF")
					elseif (stat == 1) then
						mysql:query_free("UPDATE vehicles SET registered = '1' WHERE id='" .. mysql:escape_string(vid) .. "'")
						exports.anticheat:changeProtectedElementDataEx(pv, "registered", 1)
						outputChatBox("You have toggled the registration to registered on vehicle #" .. vid .. ".", admin)

						addVehicleLogs(getElementData(pv, "dbid"), command.." ON", admin)
						exports.logs:dbLog(admin, 4, { pv, admin }, command.." ON")
					end
				else
					outputChatBox("That's not a vehicle.", admin, 255, 194, 14)
				end
			end
		end
	end
addCommandHandler("togregistration", togVehReg)
addCommandHandler("togreg", togVehReg)
addCommandHandler("togvehreg", togVehReg)
addCommandHandler("togvehregistration", togVehReg)

function togVehPlate(admin, command, target, status)
	if (exports.integration:isPlayerTrialAdmin(admin)) then
		if not (target) or not (status) then
			outputChatBox("SYNTAX: /" .. command .. " [Veh ID] [0- Off, 1- On]", admin, 255, 194, 14)
		else
			local username = getPlayerName(admin):gsub("_"," ")
			local pv = exports.pool:getElement("vehicle", tonumber(target))

			if (pv) then
					local vid = getElementData(pv, "dbid")
					local stat = tonumber(status)
					if isElementAttached(pv) then
					detachElements(pv)
					end
					if (stat == 0) then
						mysql:query_free("UPDATE vehicles SET show_plate = '0' WHERE id='" .. mysql:escape_string(vid) .. "'")

						exports.anticheat:changeProtectedElementDataEx(pv, "show_plate", 0)

						outputChatBox("You have toggled the plates to off, on vehicle #" .. vid .. ".", admin)

						addVehicleLogs(getElementData(pv, "dbid"), command.." OFF", admin)
						exports.logs:dbLog(admin, 4, { pv, admin }, command.." OFF")
					elseif (stat == 1) then
						mysql:query_free("UPDATE vehicles SET show_plate = '1' WHERE id='" .. mysql:escape_string(vid) .. "'")
						exports.anticheat:changeProtectedElementDataEx(pv, "show_plate", 1)
						outputChatBox("You have toggled the plates to on, on vehicle #" .. vid .. ".", admin)

						addVehicleLogs(getElementData(pv, "dbid"), command.." ON", admin)
						exports.logs:dbLog(admin, 4, { pv, admin }, command.." ON")
					end
				else
					outputChatBox("That's not a vehicle.", admin, 255, 194, 14)
				end
			end
		end
	end
addCommandHandler("togplate", togVehPlate)
addCommandHandler("togvehplate", togVehPlate)

function togVehVin(admin, command, target, status)
	if (exports.integration:isPlayerTrialAdmin(admin)) then
		if not (target) or not (status) then
			outputChatBox("SYNTAX: /" .. command .. " [Veh ID] [0- Off, 1- On]", admin, 255, 194, 14)
		else
			local username = getPlayerName(admin):gsub("_"," ")
			local pv = exports.pool:getElement("vehicle", tonumber(target))

			if (pv) then
					local vid = getElementData(pv, "dbid")
					local stat = tonumber(status)
					if isElementAttached(pv) then
					detachElements(pv)
					end
					if (stat == 0) then
						mysql:query_free("UPDATE vehicles SET show_vin = '0' WHERE id='" .. mysql:escape_string(vid) .. "'")

						exports.anticheat:changeProtectedElementDataEx(pv, "show_vin", 0)

						outputChatBox("You have toggled the VIN to off, on vehicle #" .. vid .. ".", admin)

						addVehicleLogs(getElementData(pv, "dbid"), command.." OFF", admin)
						exports.logs:dbLog(admin, 4, { pv, admin }, command.." OFF")
					elseif (stat == 1) then
						mysql:query_free("UPDATE vehicles SET show_vin = '1' WHERE id='" .. mysql:escape_string(vid) .. "'")
						exports.anticheat:changeProtectedElementDataEx(pv, "show_vin", 1)

						outputChatBox("You have toggled the VIN to on, on vehicle #" .. vid .. ".", admin)

						addVehicleLogs(getElementData(pv, "dbid"), command.." ON", admin)
						exports.logs:dbLog(admin, 4, { pv, admin }, command.." ON")
					end
				else
					outputChatBox("That's not a vehicle.", admin, 255, 194, 14)
				end
			end
		end
	end
addCommandHandler("togvin", togVehVin)
addCommandHandler("togvehvin", togVehVin)

local spinOutTimers = {}

function spinCarOut(thePlayer, commandName, targetPlayer, round)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		if not targetPlayer then
			outputChatBox("SYNTAX: /" .. commandName .. " [Player Partial Name/ID] [Rounds (max 100)]", thePlayer, 255, 194, 14)
		else
			if not round or not tonumber(round) or tonumber( round ) % 1 ~= 0 or tonumber( round ) > 100 then
				round = 1
			end
			local targetPlayer = exports.global:findPlayerByPartialNick(thePlayer, targetPlayer)
			local targetVehicle = getPedOccupiedVehicle(targetPlayer)
			if not targetVehicle then
				outputChatBox("This player isn't in a vehicle!", thePlayer, 255, 0, 0)
			else
				if isTimer(spinOutTimers[targetVehicle]) then killTimer(spinOutTimers[targetVehicle]) end
				spinOutTimers[targetVehicle] = setTimer(function(veh)

					local remaining, executesRemaining, timeInterval = getTimerDetails(spinOutTimers[veh]) -- Get the timers details

					if isElement(veh) then
						setElementAngularVelocity ( veh, 0, 0, 0.2 )
						-- print("Spinout "..executesRemaining)

						if executesRemaining == 1 then
							spinOutTimers[veh] = nil
							-- print("Finished cleared")
						end
					else
						killTimer(spinOutTimers[veh])
						spinOutTimers[veh] = nil
						-- print("Veh gone cleared")
					end
				end, 50, tonumber(round), targetVehicle)

				outputChatBox("You've spun out "..getPlayerName(targetPlayer):gsub("_", " ").."'s vehicle "..tostring(round).." round"..(round == 1 and "" or "s")..".", thePlayer, 0,255,0)
			end
		end
	end
end
addCommandHandler("spinout", spinCarOut, false, false)


-- unflip and flip cmds

function isAdm(thePlayer)
	return exports.global:isVMTOnDuty(thePlayer) or exports.global:isAdminOnDuty(thePlayer)
end

-- /unflip
function unflipCar(thePlayer, commandName, targetPlayer)

	local foundPackage = exports["faction-system"]:getCurrentFactionDuty(thePlayer)
	if isAdm(thePlayer) or foundPackage == towingID then
		if not targetPlayer or not isAdm(thePlayer) then
			local veh = getPedOccupiedVehicle(thePlayer)
			if not veh then
				outputChatBox("You are not in vehicle.", thePlayer, 255, 0, 0)
			else

				local speed = getElementSpeed(veh, "km/h")
				if speed > 10 then
					return outputChatBox("Stop your vehicle to do this.", thePlayer, 255, 0, 0)
				end

				local rx, ry, rz = getVehicleRotation(veh)
				setVehicleRotation(veh, 0, ry, rz)
				outputChatBox("Your car was unflipped!", thePlayer, 0, 255, 0)
				addVehicleLogs(getElementData(veh, "dbid"), commandName, thePlayer)
			end
		else
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, targetPlayer)
			if targetPlayer then
				local logged = getElementData(targetPlayer, "loggedin")
				local username = getPlayerName(thePlayer):gsub("_"," ")
				if (logged==0) then
					outputChatBox("Player is not logged in.", thePlayer, 255, 0, 0)
				else
					local pveh = getPedOccupiedVehicle(targetPlayer)
					if pveh then
						local rx, ry, rz = getVehicleRotation(pveh)
						setVehicleRotation(pveh, 0, ry, rz)
						if getElementData(thePlayer, "hiddenadmin") == 1 then
							outputChatBox("Your car was unflipped by a Hidden Admin.", targetPlayer, 0, 255, 0)
						else
							outputChatBox("Your car was unflipped by " .. username .. ".", targetPlayer, 0, 255, 0)
						end
						outputChatBox("You unflipped " .. targetPlayerName:gsub("_"," ") .. "'s car.", thePlayer, 0, 255, 0)

						addVehicleLogs(getElementData(pveh, "dbid"), commandName, thePlayer)
						exports.logs:dbLog(thePlayer, 4, { pveh, thePlayer }, command)
					else
						outputChatBox(targetPlayerName:gsub("_"," ") .. " is not in a vehicle.", thePlayer, 255, 0, 0)
					end
				end
			end
		end
	else
		outputChatBox("You need to be an on-duty admin/VMT or "..exports["faction-system"]:getFactionName(towingID).." member on duty.", thePlayer, 255, 0, 0)
	end
end
addCommandHandler("unflip", unflipCar, false, false)

-- /flip
function flipCar(thePlayer, commandName, targetPlayer)
	local foundPackage = exports["faction-system"]:getCurrentFactionDuty(thePlayer)

	if isAdm(thePlayer) or foundPackage == towingID then
		if not targetPlayer or not isAdm(thePlayer) then
			local veh = getPedOccupiedVehicle(thePlayer)
			if not veh then
				outputChatBox("You are not in a vehicle.", thePlayer, 255, 0, 0)
			else
				local speed = getElementSpeed(veh, "km/h")
				if speed > 10 then
					return outputChatBox("Stop your vehicle to do this.", thePlayer, 255, 0, 0)
				end

				local rx, ry, rz = getVehicleRotation(veh)
				setVehicleRotation(veh, 180, ry, rz)
				outputChatBox("Your car was flipped!", thePlayer, 0, 255, 0)
				addVehicleLogs(getElementData(veh, "dbid"), commandName, thePlayer)
			end
		else
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, targetPlayer)
			if targetPlayer then
				local logged = getElementData(targetPlayer, "loggedin")
				local username = getPlayerName(thePlayer):gsub("_"," ")

				if (logged==0) then
					outputChatBox("Player is not logged in.", thePlayer, 255, 0, 0)
				else
					local pveh = getPedOccupiedVehicle(targetPlayer)
					if pveh then
						local rx, ry, rz = getVehicleRotation(pveh)
						setVehicleRotation(pveh, 180, ry, rz)
						if getElementData(thePlayer, "hiddenadmin") == 1 then
							outputChatBox("Your car was flipped by a Hidden Admin.", targetPlayer, 0, 255, 0)
						else
							outputChatBox("Your car was flipped by " .. username .. ".", targetPlayer, 0, 255, 0)
						end
						outputChatBox("You flipped " .. targetPlayerName:gsub("_"," ") .. "'s car.", thePlayer, 0, 255, 0)

						addVehicleLogs(getElementData(pveh, "dbid"), commandName, thePlayer)
						exports.logs:dbLog(thePlayer, 4, { pveh, thePlayer }, command)
					else
						outputChatBox(targetPlayerName:gsub("_"," ") .. " is not in a vehicle.", thePlayer, 255, 0, 0)
					end
				end
			end
		end
	else
		outputChatBox("You need to be an on-duty admin/VMT or "..exports["faction-system"]:getFactionName(towingID).." member on duty.", thePlayer, 255, 0, 0)
	end
end
addCommandHandler("flip", flipCar, false, false)

-- /veh
-- Now even allows spawning vehicle addons  Fernando  29/10/2021
function createTempVehicle(thePlayer, commandName, vehShopID)
	if (commandName == "veh" and (
	exports.integration:isPlayerTrialAdmin(thePlayer)
	or exports.integration:isPlayerScripter(thePlayer)
	or exports.integration:isPlayerVMTMember(thePlayer)
	))
	or
	(commandName == "tempveh" and (
	exports.integration:isPlayerTrialAdmin(thePlayer)
	or exports.integration:isPlayerFMTMember(thePlayer)
	))
	then

		if not vehShopID or not tonumber(vehShopID) then
			outputChatBox("SYNTAX: /" .. commandName .. " [ID from /vehlib]", thePlayer, 255, 194, 14)
			return false
		else
			vehShopID = tonumber(vehShopID)
		end

		local vehShopData = getInfoFromVehShopID(vehShopID)
		if not vehShopData then
			return createTempVehicle(thePlayer, commandName)
		end


		local vehicleID = vehShopData.vehmtamodel
		if not vehicleID or not tonumber(vehicleID) then -- vehicle is specified as name
			-- outputDebugString("VEHICLE MANAGER / createTempVehicle / FAILED TO FETCH VEHSHOP DATA")
			outputChatBox("Ops.. Something went wrong.", thePlayer, 255, 0, 0)
			return
		else
			vehicleID = tonumber(vehicleID)
		end

		local r = getPedRotation(thePlayer)
		local x, y, z = getElementPosition(thePlayer)
		z = z +0.5

		local plate = tostring( getElementData(thePlayer, "account:id") )
		if #plate < 8 then
			plate = " " .. plate
			while #plate < 8 do
				plate = string.char(math.random(string.byte('A'), string.byte('Z'))) .. plate
				if #plate < 8 then
				end
			end
		end

		local veh = exports.global:createVehicleNew(vehicleID, x, y, z, 0, 0, r, plate)
		if not (veh) then
			outputChatBox("Ops.. Something went wrong.", thePlayer, 255, 0, 0)
			return false
		end

		local c1,c2,c3,c4 = exports["carshop-system"]:getRColor(vehicleID)
		setVehicleColor(veh, c1,c2,c3,c4)

		if (armoredCars[vehicleID]) then
			setVehicleDamageProof(veh, true)
		end

		vehiclesSpawnedHere[veh] = true
		totalTempVehicles = totalTempVehicles + 1
		local dbid = (-totalTempVehicles)
		exports.pool:allocateElement(veh, dbid)

		--setVehicleColor(veh, col1, col2, col1, col2)

		setElementInterior(veh, getElementInterior(thePlayer))
		setElementDimension(veh, getElementDimension(thePlayer))

		setVehicleOverrideLights(veh, 1)
		exports.anticheat:changeProtectedElementDataEx(veh, "lights", 1, true)
		setVehicleFuelTankExplodable(veh, false)
		vehShopData.vehvariant = tonumber(vehShopData.vehvariant)
		vehShopData.vehyear = tonumber(vehShopData.vehyear)
		setVehicleVariant(veh, (vehShopData.vehvariant == -1 and 255 or vehShopData.vehvariant), 255)

		exports.anticheat:changeProtectedElementDataEx(veh, "dbid", dbid)
		exports.anticheat:changeProtectedElementDataEx(veh, "fuel", exports["fuel-system"]:getMaxFuel(veh), false)
		exports.anticheat:changeProtectedElementDataEx(veh, "Impounded", 0)
		exports.anticheat:changeProtectedElementDataEx(veh, "engine", 1, true)
		setVehicleEngineState(veh, true)
		exports.anticheat:changeProtectedElementDataEx(veh, "oldx", x, false)
		exports.anticheat:changeProtectedElementDataEx(veh, "oldy", y, false)
		exports.anticheat:changeProtectedElementDataEx(veh, "oldz", z, false)
		exports.anticheat:changeProtectedElementDataEx(veh, "faction", -1)
		exports.anticheat:changeProtectedElementDataEx(veh, "owner", -1, false)
		exports.anticheat:changeProtectedElementDataEx(veh, "job", 0, false)
		exports.anticheat:changeProtectedElementDataEx(veh, "handbrake", 0, true)

		--Custom properties
		exports.anticheat:changeProtectedElementDataEx(veh, "year", vehShopData.vehyear, true)
		exports.anticheat:changeProtectedElementDataEx(veh, "brand", vehShopData.vehbrand, true)
		exports.anticheat:changeProtectedElementDataEx(veh, "maximemodel", vehShopData.vehmodel, true)
		exports.anticheat:changeProtectedElementDataEx(veh, "variant", vehShopData.vehvariant, true)
		exports.anticheat:changeProtectedElementDataEx(veh, "vehicle_shop_id", vehShopData.id, true)
		exports.anticheat:changeProtectedElementDataEx(veh, "fueldata", (vehShopData.fueldata ~= mysql_null() and fromJSON(vehShopData.fueldata) or {}), true)
		exports.anticheat:changeProtectedElementDataEx(veh, "vehlib_enabled", true, true)

		--Load Handlings
		local loaded, reason = loadHandlingToVeh(veh, vehShopData.handling)
		if not loaded then
			print("Failed to load handling for tempveh spawned #"..dbid..": "..reason)
		end

		triggerEvent("onVehicleCreated", veh) -- Fernando  08/11/2021  Used across various scripts

		exports.logs:dbLog(thePlayer, 6, thePlayer, dbid, "created with ID " .. dbid, "ve")
		outputChatBox(getVehicleName(veh) .. " spawned with #ffffffID " .. dbid .. ".", thePlayer, 255, 194, 14, true)

		if commandName == "tempveh" then
			if exports.global:giveItem(thePlayer, 3, dbid) then
				outputChatBox("You received a vehicle key for this car. /delveh when done.", thePlayer, 0,255,0)
			end
		end

		if exports.integration:isPlayerVMTMember(thePlayer) then
			-- Discord log
			exports.discord:sendDiscordMessage("veh-logs", ":construction: **"..getElementData(thePlayer, "account:username").."** spawned a ``temporary`` **"..vehShopData.vehyear.." "..vehShopData.vehbrand.." "..vehShopData.vehmodel.."** (``ID #"..dbid..")``.")
		end

		if not getPedOccupiedVehicle(thePlayer) then
			warpPedIntoVehicle2(thePlayer, veh, 0)
		end
	end
end
addEvent("cmd:tempveh", true)
addEventHandler("cmd:tempveh", root, createTempVehicle)
addCommandHandler("veh", createTempVehicle, false, false)
addCommandHandler("tempveh", createTempVehicle, false, false)

-- Now even allows spawning vehicle addons  Fernando  29/10/2021
function makeDefaultVehicle(thePlayer, commandName, ...)

	if exports.integration:isPlayerTrialAdmin(thePlayer)
	or exports.integration:isPlayerScripter(thePlayer)
	or exports.integration:isPlayerVMTMember(thePlayer)
	then
		if not (...) then
			return outputChatBox("SYNTAX: /"..commandName.." [MTA Model ID/Name]", thePlayer, 255,194,14)
		end
		local text = table.concat({...}, " ")
		
		local modelID, name
		if tonumber(text) then
			modelID = tonumber(text)
			name = exports.global:getVehicleNameFromModelNew(modelID)
		else
			modelID = exports.global:getVehicleModelFromNameNew(text)
			name = text
		end
		if not name or not modelID then
			triggerClientEvent(thePlayer, "copyPosToClipboard", thePlayer, "https://wiki.multitheftauto.com/wiki/Vehicle_IDs")
			outputChatBox("Invalid vehicle Model ID/Name '"..text.."'.", thePlayer, 255,25,25)
			outputChatBox("MTA Wiki - Vehicles link copied to clipboard.", thePlayer, 255,124,25)
			return
		end

		local x,y,z = getElementPosition(thePlayer)
		local rx,ry,rz = getElementRotation(thePlayer)
		local veh = exports.global:createVehicleNew(modelID, x,y,z, rx,ry,rz)
		if veh then

			local c1,c2,c3,c4 = exports["carshop-system"]:getRColor(modelID)
			setVehicleColor(veh, c1,c2,c3,c4)

			vehiclesSpawnedHere[veh] = true
			totalTempVehicles = totalTempVehicles + 1
			local dbid = (-totalTempVehicles)
			exports.pool:allocateElement(veh, dbid)

			setElementInterior(veh, getElementInterior(thePlayer))
			setElementDimension(veh, getElementDimension(thePlayer))

			setVehicleOverrideLights(veh, 1)
			exports.anticheat:changeProtectedElementDataEx(veh, "lights", 1, true)
			setVehicleFuelTankExplodable(veh, false)

			exports.anticheat:changeProtectedElementDataEx(veh, "dbid", dbid)
			exports.anticheat:changeProtectedElementDataEx(veh, "fuel", 100, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "Impounded", 0)
			exports.anticheat:changeProtectedElementDataEx(veh, "engine", 1, true)
			setVehicleEngineState(veh, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "faction", -1)
			exports.anticheat:changeProtectedElementDataEx(veh, "owner", -1, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "job", 0, false)
			exports.anticheat:changeProtectedElementDataEx(veh, "handbrake", 0, true)

			--Custom properties
			exports.anticheat:changeProtectedElementDataEx(veh, "year", "", true)
			exports.anticheat:changeProtectedElementDataEx(veh, "brand", name, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "maximemodel", "(#"..modelID..")", true)

			exports.anticheat:changeProtectedElementDataEx(veh, "variant", -1, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "vehicle_shop_id", -1, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "fueldata", {}, true)
			exports.anticheat:changeProtectedElementDataEx(veh, "vehlib_enabled", true, true)

			triggerEvent("onVehicleCreated", veh) -- Fernando  08/11/2021  Used across various scripts


			outputChatBox("Created test vehicle: "..name.." (#"..modelID..").", thePlayer, 14,255,14)

			if not getPedOccupiedVehicle(thePlayer) then
				warpPedIntoVehicle2(thePlayer, veh, 0)
			end
		end
	end
end
addCommandHandler("gtaveh", makeDefaultVehicle, false, false)
addCommandHandler("mtaveh", makeDefaultVehicle, false, false)

function blowVehicleCmd(thePlayer, commandName, vehID)
	if exports["integration"]:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) then

		local theVehicle
		if not tonumber(vehID) then
			theVehicle = getPedOccupiedVehicle(thePlayer)
		else
			theVehicle = exports.pool:getElement("vehicle", tonumber(vehID))
		end

		if not theVehicle then
			return outputChatBox("SYNTAX: /"..commandName.." [Optional: Vehicle ID]", thePlayer, 255,194,14)
		end

		if blowVehicle(theVehicle) then
			outputChatBox("Vehicle #"..getElementData(theVehicle, "dbid").." has been blown up.", thePlayer, 0,255,0)
		else
			outputChatBox("Failed to blow up vehicle #"..getElementData(theVehicle, "dbid").."!", thePlayer, 255,255,0)
		end
	end
end
addCommandHandler("blowveh", blowVehicleCmd, false, false)
addCommandHandler("blowvehicle", blowVehicleCmd, false, false)


-- /oldcar
function getOldCarID(thePlayer, commandName, targetPlayerName)
	local showPlayer = thePlayer
	if exports.integration:isPlayerTrialAdmin(thePlayer) and targetPlayerName then
		targetPlayer = exports.global:findPlayerByPartialNick(thePlayer, targetPlayerName)
		if targetPlayer then
			if getElementData(targetPlayer, "loggedin") == 1 then
				thePlayer = targetPlayer
			else
				outputChatBox("Player is not logged in.", thePlayer, 255, 0, 0)
				return
			end
		else
			return
		end
	end

	local oldvehid = getElementData(thePlayer, "lastvehid")
	local oldtrailerid = getElementData(thePlayer, "lasttrailerid")

	if not (oldvehid) then
		outputChatBox("You have not been in a vehicle yet.", showPlayer, 255, 0, 0)
	else
		outputChatBox("Last Vehicle ID: " .. tostring(oldvehid) .. ".", showPlayer, 255, 194, 14)
	end
	if (oldtrailerid) then
		outputChatBox("Last Veh Attached ID: " .. tostring(oldtrailerid) .. ".", showPlayer, 255, 215, 14)
	end
end
addCommandHandler("oc", getOldCarID, false, false)
addCommandHandler("oldcar", getOldCarID, false, false)
addCommandHandler("oldveh", getOldCarID, false, false)

-- /thiscar
function getCarID(thePlayer, commandName)
	local veh = getPedOccupiedVehicle(thePlayer)

	if (veh) then
		local dbid = getElementData(veh, "dbid")
		outputChatBox("Current Vehicle ID: " .. dbid, thePlayer, 255, 194, 14)
	else
		outputChatBox("You are not in a vehicle.", thePlayer, 255, 0, 0)
	end
end
addCommandHandler("thiscar", getCarID, false, false)
addCommandHandler("thisveh", getCarID, false, false)

-- /gotocar
function gotoCar(thePlayer, commandName, id)
	if exports.integration:isPlayerTrialAdmin(thePlayer)
		or exports.integration:isPlayerVMTMember(thePlayer)
		or exports.integration:isPlayerSupporter(thePlayer)
	then

		if not (id) then
			outputChatBox("SYNTAX: /" .. commandName .. " [id]", thePlayer, 255, 194, 14)
		else
			local theVehicle = exports.pool:getElement("vehicle", tonumber(id))
			if theVehicle then
				local rx, ry, rz = getVehicleRotation(theVehicle)
				local x, y, z = getElementPosition(theVehicle)
				z = z +2

				if (isPedInVehicle(thePlayer)) then
					local veh = getPedOccupiedVehicle(thePlayer)
					setElementAngularVelocity(veh, 0, 0, 0)
					setElementInterior(thePlayer, getElementInterior(theVehicle))
					setElementDimension(thePlayer, getElementDimension(theVehicle))
					setElementInterior(veh, getElementInterior(theVehicle))
					setElementDimension(veh, getElementDimension(theVehicle))
					setElementPosition(veh, x, y, z + 1)
					setElementRotation(veh, rx,ry,rz)
					warpPedIntoVehicle ( thePlayer, veh )
					setTimer(setElementAngularVelocity, 50, 20, veh, 0, 0, 0)
				else
					setElementPosition(thePlayer, x, y, z)
					setElementRotation(thePlayer, rx,ry,rz)
					setElementInterior(thePlayer, getElementInterior(theVehicle))
					setElementDimension(thePlayer, getElementDimension(theVehicle))
				end

				exports.logs:dbLog(thePlayer, 6, theVehicle, commandName)

				addVehicleLogs(id, commandName, thePlayer)

				outputChatBox("Teleported to vehicle #"..id..".", thePlayer, 255, 194, 14)

				if exports.integration:isPlayerVMTMember(thePlayer) then
					-- Discord log
					exports.discord:sendDiscordMessage("veh-logs", ":race_car: **"..getElementData(thePlayer, "account:username").."** has teleported to vehicle ``ID #"..id.."``.")
				end

				local dimension = getElementDimension(thePlayer)
				triggerEvent ( "frames:loadInteriorTextures", thePlayer, dimension ) --
				exports["interior-manager"]:addInteriorLogsIfExists(dimension, commandName.." "..id, thePlayer)
			else
				outputChatBox("Invalid Vehicle ID. Maybe it's despawned? Try /checkveh "..id, thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("gotocar", gotoCar, false, false)
addCommandHandler("gotoveh", gotoCar, false, false)
addCommandHandler("gtc", gotoCar, false, false)
addCommandHandler("gtv", gotoCar, false, false)

-- for fun
function gotoRandomCar(thePlayer, cmd)
		math.randomseed(os.time())

	if exports.integration:isPlayerSeniorAdmin(thePlayer)
		or exports.integration:isPlayerScripter(thePlayer)
	then
		outputChatBox("Teleporting to random vehicle...", thePlayer, 187,187,187)
		local highestID = 0
		local ids = {}

		for k, veh in ipairs(getElementsByType("vehicle")) do
			local dbid = getElementData(veh, "dbid") or 0
			if dbid > 0 then
				ids[dbid] = true
				if dbid > highestID then
					highestID = dbid
				end
			end
		end

		local randomID
		while not (randomID) do
			local temp = math.random(1,highestID)
			if ids[temp] then
				randomID = temp
			end
		end

		gotoCar(thePlayer, "gtc", randomID)
	end
end
addCommandHandler("gtvrandom", gotoRandomCar, false, false)

-- /getcar
function getCar(thePlayer, commandName, id, warpIntoIt)
	if exports.integration:isPlayerTrialAdmin(thePlayer)
	or exports.integration:isPlayerVMTMember(thePlayer)
	or exports.integration:isPlayerSupporter(thePlayer)
	then
		if not (id) then
			outputChatBox("SYNTAX: /" .. commandName .. " [id]", thePlayer, 255, 194, 14)
		else
			local theVehicle = exports.pool:getElement("vehicle", tonumber(id))
			if theVehicle then
				local r = getPedRotation(thePlayer)
				local x, y, z = getElementPosition(thePlayer)
				setElementPosition(thePlayer, x,y,z+2)

				setElementData(theVehicle, "v:teleporting", true)

				setElementSpeed(theVehicle, "km/h", 0)

				if (getElementHealth(theVehicle)==0) then
					spawnVehicle(theVehicle, x, y, z, 0, 0, r)
				else
					setElementPosition(theVehicle, x, y, z)
					setVehicleRotation(theVehicle, 0, 0, r)
				end

				setElementInterior(theVehicle, getElementInterior(thePlayer))
				setElementDimension(theVehicle, getElementDimension(thePlayer))

				exports.logs:dbLog(thePlayer, 6, theVehicle, commandName)

				addVehicleLogs(id, commandName, thePlayer)

				outputChatBox("Vehicle #"..id.." teleported to your location.", thePlayer, 255, 194, 14)
				if warpIntoIt then
					local x,y,z = getElementPosition(thePlayer)
					local rx,ry,rz = getElementRotation(thePlayer)
					setElementPosition(theVehicle, x,y,z)
					setElementRotation(theVehicle, rx,ry,rz)
					warpPedIntoVehicle2(thePlayer, theVehicle)
				end
				if exports.integration:isPlayerVMTMember(thePlayer) then
					-- Discord log
					exports.discord:sendDiscordMessage("veh-logs", ":red_car: **"..getElementData(thePlayer, "account:username").."** has teleported vehicle ``ID #"..id.."`` to them.")
				end

				setTimer(function()
					removeElementData(theVehicle, "v:teleporting")
				end, 1000,1)
			else
				outputChatBox("Invalid Vehicle ID. Maybe it's despawned? Try /checkveh "..id, thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("gc", getCar, false, false)
addCommandHandler("gv", getCar, false, false)
addCommandHandler("getcar", getCar, false, false)
addCommandHandler("getveh", getCar, false, false)

addCommandHandler("goc", function(thePlayer)
	-- get old car shortcut
	local oldvehid = getElementData(thePlayer, "lastvehid")
	if oldvehid then
		getCar(thePlayer, "goc", oldvehid, true)
	else
		outputChatBox("You have not been in a vehicle yet.", thePlayer, 255, 0, 0)
	end
end, false, false)

-- This command teleports the specified vehicle to the specified player, /sendcar
function sendCar(thePlayer, commandName, id, toPlayer)
	if exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer) then
		if not (id) or not (toPlayer) then
			outputChatBox("SYNTAX: /" .. commandName .. " [vehicle id] [player ID]", thePlayer, 255, 194, 14)
		else
			local theVehicle = exports.pool:getElement("vehicle", tonumber(id))
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, toPlayer)
			if theVehicle and targetPlayer then
				if getElementHealth(theVehicle)==0 then
					return outputChatBox("Vehicle #"..id.." is blown up.", thePlayer, 255,100,100)
				end

				local r = getPedRotation(targetPlayer)
				local x, y, z = getElementPosition(targetPlayer)
				setElementPosition(targetPlayer, x,y,z+2)

				setElementPosition(theVehicle, x, y, z)
				setVehicleRotation(theVehicle, 0, 0, r)

				setElementInterior(theVehicle, getElementInterior(targetPlayer))
				setElementDimension(theVehicle, getElementDimension(targetPlayer))

				exports.logs:dbLog(thePlayer, 6, theVehicle, commandName.." to "..targetPlayerName)

				addVehicleLogs(id, commandName, thePlayer)

				outputChatBox("Vehicle teleported to the player "..targetPlayerName, thePlayer, 255, 194, 14)
				if getElementData(thePlayer, "hiddenadmin") == 1 then
					outputChatBox("An hidden admin has teleported a vehicle to you.", targetPlayer, 255, 194, 14)
				else
					outputChatBox(exports.global:getPlayerFullIdentity(thePlayer).." has teleported a vehicle to you.", targetPlayer, 255, 194, 14)
				end
			else
				outputChatBox("Invalid Vehicle ID. Maybe it's despawned? Try /checkveh "..id, thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("sendcar", sendCar, false, false)
addCommandHandler("sendvehto", sendCar, false, false)
addCommandHandler("sendveh", sendCar, false, false)

function sendPlayerToVehicle(thePlayer, commandName, toPlayer, id)
	if exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer) then
		if not (id) or not (toPlayer) then
			outputChatBox("SYNTAX: /" .. commandName .. " [player ID] [vehicle id]", thePlayer, 255, 194, 14)
		else
			local theVehicle = exports.pool:getElement("vehicle", tonumber(id))
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, toPlayer)
			if theVehicle then
				local rx, ry, rz = getVehicleRotation(theVehicle)
				local x, y, z = getElementPosition(theVehicle)
				z = z +2

				setElementPosition(targetPlayer, x, y, z)
				-- setPedRotation(targetPlayer, rz)
				setElementRotation(targetPlayer, 0,0, rz, "default", true)
				setElementInterior(targetPlayer, getElementInterior(theVehicle))
				setElementDimension(targetPlayer, getElementDimension(theVehicle))

				exports.logs:dbLog(thePlayer, 6, theVehicle, commandName.." from "..targetPlayerName)

				addVehicleLogs(id, commandName, thePlayer)

				outputChatBox("Player "..targetPlayerName.." teleported to vehicle.", thePlayer, 255, 194, 14)
				if getElementData(thePlayer, "hiddenadmin") == 1 then
					outputChatBox("An hidden admin has teleported you to a vehicle.", targetPlayer, 255, 194, 14)
				else
					outputChatBox(exports.global:getPlayerFullIdentity(thePlayer).." has teleported a you to a vehicle.", targetPlayer, 255, 194, 14)
				end
			else
				outputChatBox("Invalid Vehicle ID. Maybe it's despawned? Try /checkveh "..id, thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("sendtoveh", sendPlayerToVehicle, false, false)

function getNearbyVehicles(thePlayer, commandName)
	if exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerVMTMember(thePlayer) or exports.integration:isPlayerSupporter(thePlayer) then
		outputChatBox("Nearby Vehicles:", thePlayer, 255, 126, 0)
		local count = 0

		for index, nearbyVehicle in ipairs( exports.global:getNearbyElements(thePlayer, "vehicle") ) do
			local thisvehid = getElementData(nearbyVehicle, "dbid")
			if thisvehid then
				local vehicleID = getElementData(nearbyVehicle, "vehicle_shop_id")
				local vehicleName = exports.global:getVehicleName(nearbyVehicle)
				local owner = getElementData(nearbyVehicle, "owner")
				local faction = getElementData(nearbyVehicle, "faction")
				count = count + 1

				local ownerName = ""

				if faction then
					if (faction>0) then
						local theTeam = exports.pool:getElement("team", faction)
						if theTeam then
							ownerName = getTeamName(theTeam)
						end
					elseif (owner==-1) then
						ownerName = "Admin Temp Vehicle"
					elseif (owner>0) then
						ownerName = exports['cache']:getCharacterName(owner, true)
					else
						ownerName = "Civilian"
					end
				else
					ownerName = "Car Dealership"
				end

				if (thisvehid) then
					outputChatBox("   " .. vehicleName .. " (VEHLIB ID " .. vehicleID ..") with DBID: " .. thisvehid .. ". Owner: " .. ownerName, thePlayer, 255, 126, 0)
				end
			end
		end

		if (count==0) then
			outputChatBox("   None.", thePlayer, 255, 126, 0)
		end
	end
end
addCommandHandler("nearbyvehicles", getNearbyVehicles, false, false)
addCommandHandler("nearbyvehs", getNearbyVehicles, false, false)

function delNearbyVehicles(thePlayer, commandName)
	if exports.integration:isPlayerAdmin(thePlayer)  then
		outputChatBox("Deleting Nearby Vehicles:", thePlayer, 255, 126, 0)
		local count = 0

		for index, nearbyVehicle in ipairs( exports.global:getNearbyElements(thePlayer, "vehicle") ) do
			local thisvehid = getElementData(nearbyVehicle, "dbid")
			if thisvehid then
				local vehicleID = getElementModel(nearbyVehicle)
				local vehicleName = exports.global:getVehicleName(nearbyVehicle)
				local owner = getElementData(nearbyVehicle, "owner")
				local faction = getElementData(nearbyVehicle, "faction")
				count = count + 1

				local ownerName = ""

				if faction then
					if (faction>0) then
						local theTeam = exports.pool:getElement("team", faction)
						if theTeam then
							ownerName = getTeamName(theTeam)
						end
					elseif (owner==-1) then
						ownerName = "Admin Temp Vehicle"
					elseif (owner>0) then
						ownerName = exports['cache']:getCharacterName(owner, true)
					else
						ownerName = "Civilian"
					end
				else
					ownerName = "Car Dealership"
				end

				if (thisvehid) then
					deleteVehicle(thePlayer, "delveh", thisvehid)
					--twice
					deleteVehicle(thePlayer, "delveh", thisvehid)

				end
			end
		end

		if (count==0) then
			outputChatBox("   None was deleted.", thePlayer, 255, 126, 0)
		elseif count == 1 then
			outputChatBox("   One vehicle were deleted.", thePlayer, 255, 126, 0)
		else
			outputChatBox("   "..count.." vehicles were deleted.", thePlayer, 255, 126, 0)
		end
	end
end
addCommandHandler("delnearbyvehs", delNearbyVehicles, false, false)
addCommandHandler("delnearbyvehicles", delNearbyVehicles, false, false)

function permdelNearbyVehicles(thePlayer, commandName)
	if exports.integration:isPlayerAdmin(thePlayer)  then
		outputChatBox("Deleting Nearby Vehicles:", thePlayer, 255, 126, 0)
		local count = 0

		for index, nearbyVehicle in ipairs( exports.global:getNearbyElements(thePlayer, "vehicle") ) do
			local thisvehid = getElementData(nearbyVehicle, "dbid")
			if thisvehid then
				local vehicleID = getElementModel(nearbyVehicle)
				local vehicleName = exports.global:getVehicleName(nearbyVehicle)
				local owner = getElementData(nearbyVehicle, "owner")
				local faction = getElementData(nearbyVehicle, "faction")
				count = count + 1

				local ownerName = ""

				if faction then
					if (faction>0) then
						local theTeam = exports.pool:getElement("team", faction)
						if theTeam then
							ownerName = getTeamName(theTeam)
						end
					elseif (owner==-1) then
						ownerName = "Admin Temp Vehicle"
					elseif (owner>0) then
						ownerName = exports['cache']:getCharacterName(owner, true)
					else
						ownerName = "Civilian"
					end
				else
					ownerName = "Car Dealership"
				end

				if (thisvehid) then
					deleteVehicle(thePlayer, "delveh", thisvehid)
					removeVehicle(thePlayer, "removeveh", thisvehid)
				end
			end
		end

		if (count==0) then
			outputChatBox("   None was deleted.", thePlayer, 255, 126, 0)
		elseif count == 1 then
			outputChatBox("   One vehicle were deleted.", thePlayer, 255, 126, 0)
		else
			outputChatBox("   "..count.." vehicles were deleted.", thePlayer, 255, 126, 0)
		end
	end
end
addCommandHandler("permdelnearbyvehs", permdelNearbyVehicles, false, false)

function respawnCmdVehicle(thePlayer, commandName, id)
	if commandName=="server" or ((exports.integration:isPlayerTrialAdmin(thePlayer)) or exports.integration:isPlayerVMTMember(thePlayer) or exports.integration:isPlayerSupporter(thePlayer)) then
		if not (id) then
			outputChatBox("SYNTAX: /respawnveh [id]", thePlayer, 255, 194, 14)
		else
			local theVehicle = exports.pool:getElement("vehicle", tonumber(id))
			if theVehicle then
				if isElementAttached(theVehicle) then
					detachElements(theVehicle)
					setElementCollisionsEnabled(theVehicle, true) -- Adams
				end
				setVehicleEngineState(theVehicle, false)
				exports.anticheat:changeProtectedElementDataEx(theVehicle, "engine", 0, true)
				exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:radio", 0, true)

				if exports["vehicle-manager"]:isVehicleDestroyed(theVehicle) then
					triggerEvent("A:saveDescriptions", theVehicle, "", theVehicle)
				end

				local dbid = getElementData(theVehicle,"dbid")
				if (dbid<0) then -- TEMP vehicle
					fixVehicle(theVehicle) -- Can't really respawn this, so just repair it
					if armoredCars[ getElementModel( theVehicle ) ] or getElementData(theVehicle, "bulletproof") == 1 then
						setVehicleDamageProof(theVehicle, true)
					else
						setVehicleDamageProof(theVehicle, false)
					end
					setVehicleWheelStates(theVehicle, 0, 0, 0, 0)
					exports.anticheat:changeProtectedElementDataEx(theVehicle, "enginebroke", 0, false)
				else
					if thePlayer then -- else it's another script calling this function
						if exports.integration:isPlayerVMTMember(thePlayer) then
							-- Discord log
							exports.discord:sendDiscordMessage("veh-logs", ":round_pushpin: **"..getElementData(thePlayer, "account:username").."** has respawned vehicle ``ID #"..dbid.."``.")
						end
						exports.logs:dbLog(thePlayer, 6, theVehicle, "RESPAWN")
						addVehicleLogs(id, commandName, thePlayer)
						
						outputChatBox("Vehicle respawned.", thePlayer, 255, 194, 14)
					end

					respawnTheVehicle(theVehicle)
					setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
					setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))

					if getElementData(theVehicle, "job")>0 and getElementData(theVehicle,"Impounded") == 0 then
						setVehicleLocked(theVehicle, false)
					else
						setVehicleLocked(theVehicle, true)
					end

				end
			else
				outputChatBox("Invalid Vehicle ID. Maybe it's despawned? Try /checkveh "..id, thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("respawnveh", respawnCmdVehicle, false, false)
addEvent("cmd:respawnveh", true)
addEventHandler("cmd:respawnveh", root, respawnCmdVehicle)

function respawnGuiVehicle(theVehicle)
	local thePlayer = source
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) or exports.integration:isPlayerVMTMember(thePlayer) then

		if isElementAttached(theVehicle) then
			detachElements(theVehicle)
			setElementCollisionsEnabled(theVehicle, true)
		end
		setVehicleEngineState(theVehicle, false)
		exports.anticheat:changeProtectedElementDataEx(theVehicle, "engine", 0, true)
		exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:radio", 0, true)
		
		if exports["vehicle-manager"]:isVehicleDestroyed(theVehicle) then
			triggerEvent("A:saveDescriptions", theVehicle, "", theVehicle)
		end
		local dbid = getElementData(theVehicle,"dbid")
		if (dbid<0) then -- TEMP vehicle
			fixVehicle(theVehicle) -- Can't really respawn this, so just repair it
			if armoredCars[ getElementModel( theVehicle ) ] or getElementData(theVehicle, "bulletproof") == 1 then
				setVehicleDamageProof(theVehicle, true)
			else
				setVehicleDamageProof(theVehicle, false)
			end
			setVehicleWheelStates(theVehicle, 0, 0, 0, 0)
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "enginebroke", 0, false)
		else
			if exports.integration:isPlayerVMTMember(thePlayer) then
				-- Discord log
				exports.discord:sendDiscordMessage("veh-logs", ":round_pushpin: **"..getElementData(thePlayer, "account:username").."** has respawned vehicle ``ID #"..dbid.."``.")
			end

			exports.logs:dbLog(thePlayer, 6, theVehicle, "RESPAWN")

			local id = tonumber(getElementData(theVehicle, "dbid"))
			addVehicleLogs(id, "respawnveh", thePlayer)

			respawnTheVehicle(theVehicle)
			setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
			setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))

			if getElementData(theVehicle, "job")>0 and getElementData(theVehicle,"Impounded") == 0 then
				setVehicleLocked(theVehicle, false)
			else
				setVehicleLocked(theVehicle, true)
			end
		end
	end
end
addEvent("vehicle-manager:respawn", true)
addEventHandler("vehicle-manager:respawn", getRootElement(), respawnGuiVehicle)

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end
function respawnAllVehicles(thePlayer, commandName, timeToRespawn)
	if exports.integration:isPlayerSeniorAdmin( thePlayer ) then
		if commandName then
			if isTimer(respawnTimer) then
				outputChatBox("There is already an active Vehicle Respawn. /respawnstop to stop it first.", thePlayer, 255, 0, 0)
			else
				timeToRespawn = tonumber(timeToRespawn) or 30
				timeToRespawn = timeToRespawn == 0 and 0 or timeToRespawn < 10 and 10 or timeToRespawn
				for k, arrayPlayer in ipairs(exports.global:getAdmins()) do
					local logged = getElementData(arrayPlayer, "loggedin")
					if (logged) then
						if exports.integration:isPlayerAdmin(arrayPlayer) then
							outputChatBox( "AdmCmd: " .. getPlayerName(thePlayer):gsub("_"," ") .. " executed a vehicle respawn.", arrayPlayer, 255, 0, 0)
						end
					end
				end

				outputChatBox("-~- All vehicles will be respawned in "..timeToRespawn.." seconds! -~-", getRootElement(), 142, 97, 255)
				executeCommandHandler("ann", thePlayer, "All vehicles will be respawned in "..timeToRespawn.." seconds!")
				outputChatBox("You can stop it by typing /respawnstop!", thePlayer)
				respawnTimer = setTimer(respawnAllVehicles, timeToRespawn*1000, 1, thePlayer)
			end
			return
		end
		local tick = getTickCount()
		local vehicles = getElementsByType("vehicle")--exports.pool:getPoolElementsByType("vehicle")
		local counter = 0
		local tempcounter = 0
		local tempoccupied = 0
		local radioCounter = 0
		local occupiedcounter = 0
		local unlockedcivs = 0
		local notmoved = 0
		local deleted = 0

		local dimensions = { }
		for k, p in ipairs(getElementsByType("player")) do
			dimensions[ getElementDimension( p ) ] = true
		end

		for k, theVehicle in ipairs(vehicles) do
			if isElement( theVehicle ) and not getElementData(theVehicle, "carshop") then
				local dbid = getElementData(theVehicle, "dbid")
				if not (dbid) or (dbid<0) then -- TEMP vehicle
					local driver = getVehicleOccupant(theVehicle)
					local pass1 = getVehicleOccupant(theVehicle, 1)
					local pass2 = getVehicleOccupant(theVehicle, 2)
					local pass3 = getVehicleOccupant(theVehicle, 3)

					if (pass1) or (pass2) or (pass3) or (driver) or (getVehicleTowingVehicle(theVehicle)) then--or #getAttachedElements(theVehicle) > 0
						tempoccupied = tempoccupied + 1
					else
						destroyElement(theVehicle)
						tempcounter = tempcounter + 1
					end
				else
					local driver = getVehicleOccupant(theVehicle)
					local pass1 = getVehicleOccupant(theVehicle, 1)
					local pass2 = getVehicleOccupant(theVehicle, 2)
					local pass3 = getVehicleOccupant(theVehicle, 3)

					if (pass1) or (pass2) or (pass3) or (driver) or (getVehicleTowingVehicle(theVehicle)) then--or #getAttachedElements(theVehicle) > 0
						occupiedcounter = occupiedcounter + 1
					else
						if isVehicleBlown(theVehicle) then --or isElementInWater(theVehicle) then
							local bulletProof = false
							if isVehicleDamageProof(theVehicle) then
								bulletProof = true
							end
							fixVehicle(theVehicle)
							if exports["vehicle-manager"]:isVehicleDestroyed(theVehicle) then
								triggerEvent("A:saveDescriptions", theVehicle, "", theVehicle)
							end
							if armoredCars[ getElementModel( theVehicle ) ] or bulletProof or getElementData(theVehicle, "bulletproof") == 1 then
								setVehicleDamageProof(theVehicle, true)
							else
								setVehicleDamageProof(theVehicle, false)
							end
							for i = 0, 5 do
								setVehicleDoorState(theVehicle, i, 4) -- all kind of stuff missing
							end
							setElementHealth(theVehicle, 300) -- lowest possible health
							exports.anticheat:changeProtectedElementDataEx(theVehicle, "enginebroke", 1, false)
						end

						if getElementData(theVehicle, "job")>0 and getElementData(theVehicle,"Impounded") == 0 then
							if isElementAttached(theVehicle) then
								detachElements(theVehicle)
								setElementCollisionsEnabled(theVehicle, true) -- Adams
							end
							respawnVehicle(theVehicle)
							setVehicleLocked(theVehicle, false)
							unlockedcivs = unlockedcivs + 1
						else
							local checkx, checky, checkz = getElementPosition( theVehicle )
							if getElementData(theVehicle, "respawnposition") then
								local x, y, z, rx, ry, rz = unpack(getElementData(theVehicle, "respawnposition"))

								if (round(checkx, 6) == x) and (round(checky, 6) == y) then
									notmoved = notmoved + 1
								else
									if isElementAttached(theVehicle) then
										detachElements(theVehicle)
									end
									setElementCollisionsEnabled(theVehicle, true)
									if getElementData(theVehicle, "vehicle:radio") ~= 0 then
										exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:radio", 0, true)
										radioCounter = radioCounter + 1
									end
									setVehicleEngineState(theVehicle, false)
									exports.anticheat:changeProtectedElementDataEx(theVehicle, "engine", 0, true)
									setElementPosition(theVehicle, x, y, z)
									setVehicleRotation(theVehicle, rx, ry, rz)
									setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
									setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))

									counter = counter + 1
								end
							end
						end
						if (trailerModels[getElementModel(theVehicle)]) then
							setTimer(setElementFrozen, 2000, 1, theVehicle, true)
						end
						-- fix faction vehicles
						if getElementData(theVehicle, "faction") ~= -1 then
							fixVehicle(theVehicle)
							if exports["vehicle-manager"]:isVehicleDestroyed(theVehicle) then
								triggerEvent("A:saveDescriptions", theVehicle, "", theVehicle)
							end
							if (getElementData(theVehicle, "Impounded") == 0) then
								exports.anticheat:changeProtectedElementDataEx(theVehicle, "enginebroke", 0, true)
								exports.anticheat:changeProtectedElementDataEx(theVehicle, "handbrake", 1, true)
								setTimer(setElementFrozen, 2000, 1, theVehicle, true)
								if armoredCars[ getElementModel( theVehicle ) ] or getElementData(theVehicle, "bulletproof") == 1 then
									setVehicleDamageProof(theVehicle, true)
								else
									setVehicleDamageProof(theVehicle, false)
								end
							end
						end
					end
				end
			end
		end
		local timeTaken = (getTickCount() - tick)/1000
		outputChatBox("-~- All Vehicles Respawned -~-", getRootElement(), 255, 194, 14)
		executeCommandHandler("ann",thePlayer, "All vehicles were respawned!")
		outputChatBox("Respawned " .. counter .. "/" .. counter + notmoved .. " vehicles. (" .. occupiedcounter .. " Occupied)", thePlayer)
		outputChatBox("Deleted " .. tempcounter .. " temporary vehicles. (" .. tempoccupied .. " Occupied)", thePlayer)
		outputChatBox("Reset " .. radioCounter .. " car radios.", thePlayer)
		outputChatBox("Unlocked and Respawned " .. unlockedcivs .. " job/dmv vehicles.", thePlayer)
		outputChatBox("Deleted " .. deleted .. " vehicles parked in carshops.", thePlayer)
		outputChatBox("All that in " .. timeTaken .." seconds.", thePlayer)
	end
end
addCommandHandler("respawnall", respawnAllVehicles, false, false)

function respawnVehiclesStop(thePlayer, commandName)
	if (exports.integration:isPlayerSeniorAdmin( thePlayer )) and isTimer(respawnTimer) then
		killTimer(respawnTimer)
		respawnTimer = nil
		if commandName then
			local name = getPlayerName(thePlayer):gsub("_", " ")
			if getElementData(thePlayer, "hiddenadmin") == 1 then
				name = "Hidden Admin"
			end
			outputChatBox( "*** " .. name .. " cancelled the vehicle respawn ***", getRootElement(), 255, 194, 14)
		end
	end
end
addCommandHandler("respawnstop", respawnVehiclesStop, false, false)

function respawnAllCivVehicles(thePlayer, commandName)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) or (exports.integration:isPlayerScripter(thePlayer)) then
		local vehicles = exports.pool:getPoolElementsByType("vehicle")
		local counter = 0

		for k, theVehicle in ipairs(vehicles) do
			local dbid = getElementData(theVehicle, "dbid")
			if dbid and dbid > 0 then
				if (getElementData(theVehicle, "job") or 0) > 0 then
					local driver = getVehicleOccupant(theVehicle)
					local pass1 = getVehicleOccupant(theVehicle, 1)
					local pass2 = getVehicleOccupant(theVehicle, 2)
					local pass3 = getVehicleOccupant(theVehicle, 3)

					if not pass1 and not pass2 and not pass3 and not driver and not getVehicleTowingVehicle(theVehicle) then
						if isElementAttached(theVehicle) then
							detachElements(theVehicle)
						end
						respawnTheVehicle(theVehicle)
						setVehicleEngineState(theVehicle, false)
						exports.anticheat:changeProtectedElementDataEx(theVehicle, "engine", 0, true)
						setVehicleLocked(theVehicle, false)
						setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
						setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))
						exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:radio", 0, true)
						amount = exports["fuel-system"]:getMaxFuel(getElementModel(theVehicle))
						exports.anticheat:changeProtectedElementDataEx(theVehicle, "fuel", amount, false)
						counter = counter + 1

						outputChatBox("Respawned jobveh: "..exports.global:getVehicleName(theVehicle).." (#"..dbid..")", thePlayer)
					end
				end
			end
		end
		outputChatBox(counter.." job vehicles were respawned.", thePlayer, 142, 97, 255)
	end
end
addCommandHandler("respawnciv", respawnAllCivVehicles, false, false)
addCommandHandler("respawnjob", respawnAllCivVehicles, false, false)

function respawnAllInteriorVehicles(thePlayer, commandName, repair)
	local repair = tonumber( repair ) == 1 and exports.global:isAdminOnDuty(thePlayer)
	local dimension = getElementDimension(thePlayer)
	if dimension > 0 and ( exports.global:hasItem(thePlayer, 4, dimension) or exports.global:hasItem(thePlayer, 5, dimension) ) or exports.global:isAdminOnDuty(thePlayer) then
		local vehicles = exports.pool:getPoolElementsByType("vehicle")
		local counter = 0

		for k, theVehicle in ipairs(vehicles) do
			if getElementData(theVehicle, "dimension") == dimension then
				local dbid = getElementData(theVehicle, "dbid")
				if dbid and dbid > 0 then
					local driver = getVehicleOccupant(theVehicle)
					local pass1 = getVehicleOccupant(theVehicle, 1)
					local pass2 = getVehicleOccupant(theVehicle, 2)
					local pass3 = getVehicleOccupant(theVehicle, 3)

					if not pass1 and not pass2 and not pass3 and not driver and not getVehicleTowingVehicle(theVehicle)then
						local checkx, checky, checkz = getElementPosition( theVehicle )
						if getElementData(theVehicle, "respawnposition") then
							local x, y, z, rx, ry, rz = unpack(getElementData(theVehicle, "respawnposition"))

							if (round(checkx, 6) ~= x) or (round(checky, 6) ~= y) then

								if repair then
									respawnTheVehicle(theVehicle)
									fixVehicle(theVehicle)
									if exports["vehicle-manager"]:isVehicleDestroyed(theVehicle) then
										triggerEvent("A:saveDescriptions", theVehicle, "", theVehicle)
									end
									if armoredCars[ getElementModel( theVehicle ) ] or getElementData(theVehicle, "bulletproof") == 1 then
										setVehicleDamageProof(theVehicle, true)
									else
										setVehicleDamageProof(theVehicle, false)
									end
									setVehicleEngineState(theVehicle, false)
									exports.anticheat:changeProtectedElementDataEx(theVehicle, "engine", 0, true)
									exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:radio", 0, true)
									setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
									setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))
								else
									setElementPosition(theVehicle, x, y, z)
									setVehicleRotation(theVehicle, rx, ry, rz)
									setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
									setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))
								end
								counter = counter + 1
							end
						end
					end
				end
			end
		end
		outputChatBox("Respawned " .. counter .. " vehicles inside property #"..dimension..".", thePlayer)
	else
		outputChatBox( "This is not your property.", thePlayer, 255, 0, 0 )
	end
end
addCommandHandler("respawnint", respawnAllInteriorVehicles, false, false)

function respawnDistrictVehicles(thePlayer, commandName)
	if exports.integration:isPlayerTrialAdmin( thePlayer ) then
		local zoneName = exports.global:getElementZoneName(thePlayer)
		local vehicles = exports.pool:getPoolElementsByType("vehicle")
		local counter = 0

		for k, theVehicle in ipairs(vehicles) do
			local vehicleZoneName = exports.global:getElementZoneName(theVehicle)
			if (zoneName == vehicleZoneName) then
				local dbid = getElementData(theVehicle, "dbid")
				if dbid and dbid > 0 then
					local driver = getVehicleOccupant(theVehicle)
					local pass1 = getVehicleOccupant(theVehicle, 1)
					local pass2 = getVehicleOccupant(theVehicle, 2)
					local pass3 = getVehicleOccupant(theVehicle, 3)

					if not pass1 and not pass2 and not pass3 and not driver and not getVehicleTowingVehicle(theVehicle) then
						local checkx, checky, checkz = getElementPosition( theVehicle )
						if getElementData(theVehicle, "respawnposition") then
							local x, y, z, rx, ry, rz = unpack(getElementData(theVehicle, "respawnposition"))

							if (round(checkx, 6) ~= x) or (round(checky, 6) ~= y) then
								respawnTheVehicle(theVehicle)
								fixVehicle(theVehicle)
								if exports["vehicle-manager"]:isVehicleDestroyed(theVehicle) then
									triggerEvent("A:saveDescriptions", theVehicle, "", theVehicle)
								end
								setVehicleEngineState(theVehicle, false)
								exports.anticheat:changeProtectedElementDataEx(theVehicle, "engine", 0, true)
								exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:radio", 0, true)
								setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
								setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))

								counter = counter + 1
							end
						end
					end
				end
			end
		end
		exports.global:sendMessageToAdmins("AdmWrn: ".. getPlayerName(thePlayer) .." respawned " .. counter .. " district vehicles in '"..zoneName.."'.", thePlayer)
	end
end
addCommandHandler("respawndistrict", respawnDistrictVehicles, false, false)

function addPaintjob(thePlayer, commandName, target, paintjobID)
	if exports.integration:isPlayerTrialAdmin(thePlayer)  then
		if not (target) or not (paintjobID) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Partial Player Nick] [Paintjob ID]", thePlayer, 255, 194, 14)
		else
			local username = getPlayerName(thePlayer)
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, target)

			if targetPlayer then
				if not (isPedInVehicle(targetPlayer)) then
					outputChatBox("That player is not in a vehicle.", thePlayer, 255, 0, 0)
				else
					local theVehicle = getPedOccupiedVehicle(targetPlayer)
					paintjobID = tonumber(paintjobID)
					if paintjobID == getVehiclePaintjob(theVehicle) then
						outputChatBox("This Vehicle already has this paintjob.", thePlayer, 255, 0, 0)
					else
						local success = setVehiclePaintjob(theVehicle, paintjobID)

						if (success) then

							addVehicleLogs(getElementData(theVehicle,"dbid"), commandName.." "..paintjobID, thePlayer)

							exports.logs:dbLog(thePlayer, 6, { targetPlayer, theVehicle  }, "PAINTJOB ".. paintjobID )
							outputChatBox("Paintjob #" .. paintjobID .. " added to " .. targetPlayerName .. "'s vehicle.", thePlayer)
							outputChatBox("Admin " .. username .. " added Paintjob #" .. paintjobID .. " to your vehicle.", targetPlayer)
							exports['savevehicle-system']:saveVehicleMods(theVehicle)
						else
							outputChatBox("Invalid Paintjob ID, or this vehicle doesn't support this paintjob.", thePlayer, 255, 0, 0)
						end
					end
				end
			end
		end
	end

end
addCommandHandler("setpaintjob", addPaintjob, false, false)


function setVariant(thePlayer, commandName, id, variant1)
	if exports.integration:isPlayerTrialAdmin(thePlayer)  or exports.integration:isPlayerScripter(thePlayer)  or exports.integration:isPlayerVMTMember(thePlayer) then
		if not tonumber(id) or not tonumber(variant1) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Vehicle ID] [Variant 1]", thePlayer, 255, 194, 14)
			outputChatBox("Sets an unique variant for this vehicle that will override the one in /vehlib.",thePlayer,255,126,0)
		else
			id = tonumber(id)
			for i,c in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
				if (getElementData(c, "dbid") == id) then
					theVehicle = c
					break
				end
			end
			local username = getPlayerName(thePlayer)

			if theVehicle then
				variant1 = tonumber(variant1) or -1

				if exports['vehicle-system']:isValidVariant(getElementModel(theVehicle), variant1) then

					local a, b = getVehicleVariant(theVehicle)

					variant1 = (variant1 == -1 and 255 or variant1)

					if a == variant1 then
						outputChatBox("This vehicle already has this variant.", thePlayer, 255, 0, 0)
					else
						local success = setVehicleVariant(theVehicle, variant1, 255)

						if id > 0 then
							if (success) and mysql:query_free("UPDATE `vehicles` SET `variant1`='"..variant1.."' WHERE `id`='" .. mysql:escape_string(id) .. "'") then

								outputChatBox("Variant " .. variant1 .. "/255 set to vehicle #" .. getElementData(theVehicle,"dbid") .. ".", thePlayer)
								outputChatBox("This vehicle now has an unique variant that will override the one in Vehlib.",thePlayer,255,255,0)

								addVehicleLogs(getElementData(theVehicle,"dbid"), commandName.." "..variant1, thePlayer)
							else
								outputChatBox("Error setting variant.", thePlayer, 255, 0, 0)
							end
						else
							if success then
								outputChatBox("Variant " .. variant1 .. "/255 set to temp vehicle #" .. getElementData(theVehicle,"dbid") .. ".", thePlayer)
							else
								outputChatBox("Error setting variant.", thePlayer, 255, 0, 0)
							end
						end
					end
				else
					outputChatBox(variant1 .. "/255 is not a valid variant for this " .. getVehicleName(theVehicle) .. ".", thePlayer, 255, 0, 0)
				end
			else
				outputChatBox("Vehicle (#"..id..") not found.", thePlayer, 255, 0, 0)
			end
		end
	end

end
addCommandHandler("setvariant", setVariant, false, false)

function setSecurity(thePlayer, commandName, id, stype, level)
	if exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer)  or exports.integration:isPlayerVMTMember(thePlayer) then
		if not tonumber(id) or not tonumber(stype) or not tonumber(level) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Vehicle ID] [Security Type] [Level]", thePlayer, 255, 194, 14)
			outputChatBox("Security values: [1] Alarm, [2] Lock, [3] Anti-Theft",thePlayer, 255, 194, 14)
			outputChatBox("Level values: Usually between 0-4",thePlayer, 255, 194, 14)
		else
			id = tonumber(id)
			stype = tonumber(stype)
			level = tonumber(level)

			if stype<1 or stype>3 then
				outputChatBox("Give the correct corresponding number: [1] Alarm, [2] Lock, [3] Anti-Theft",thePlayer,255,0,0)
				return
			end
			local name = "Alarm"
			if stype == 2 then
				name = "Lock"
			elseif stype == 3 then
				name = "Anti-Theft"
			end

			local securityLvls = exports["job-system"]:getSecurityLevels()
			if not securityLvls[stype][level] then

				local valid = ""
				for k,price in pairs(securityLvls[stype]) do
					valid = valid.." "..k
				end
				outputChatBox("Valid "..name.." levels are: "..valid,thePlayer,255,0,0)
				return
			end

			for i,c in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
				if (getElementData(c, "dbid") == tonumber(id)) then
					theVehicle = c
					break
				end
			end

			if theVehicle then
				local playerName = exports.global:getPlayerName(thePlayer)

				if name == "Alarm" then
					exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:level:alarm", level, true)
				elseif name == "Lock" then
					exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:level:lock", level, true)
				elseif name == "Anti-Theft" then
					exports.anticheat:changeProtectedElementDataEx(theVehicle, "vehicle:level:theft", level, true)
				end
				exports['savevehicle-system']:saveVehicleMods(theVehicle)
				outputChatBox("Vehicle #"..getElementData(theVehicle,"dbid").." "..name.." level set to: "..level, thePlayer, 0,255,0)
			else
				outputChatBox("Vehicle not found. Is it a permanent vehicle?", thePlayer, 255, 0, 0)
			end
		end
	end

end
addCommandHandler("setsecurity", setSecurity, false, false)
addCommandHandler("setvehsecurity", setSecurity, false, false)
addCommandHandler("setsecuritylevel", setSecurity, false, false)
addCommandHandler("setvehsecuritylevel", setSecurity, false, false)


--------------- Upgrades ---------------
		-- Fernando 09/03/2021 --


function addUpgrade(thePlayer, commandName, target, upgradeID)
	if exports.integration:isPlayerTrialAdmin(thePlayer) then
		if not (target) or not (upgradeID) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Partial Player Nick] [Upgrade ID]", thePlayer, 255, 194, 14)
		else
			local username = getPlayerName(thePlayer)
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, target)

			if targetPlayer then
				if not (isPedInVehicle(targetPlayer)) then
					outputChatBox("That player is not in a vehicle.", thePlayer, 255, 0, 0)
				else
					if upgradeID and tonumber(upgradeID) and exports['shop-system']:getDisabledUpgrades()[tonumber(upgradeID)] then
						outputChatBox("This item is temporarily disabled.", thePlayer, 255, 0, 0)
						return false
					end
					local theVehicle = getPedOccupiedVehicle(targetPlayer)
					local success = addVehicleUpgrade(theVehicle, upgradeID)

					if not (success == false) then
						exports.logs:dbLog(thePlayer, 6, { targetPlayer, theVehicle  }, "ADDUPGRADE ".. upgradeID .. " "..	getVehicleUpgradeSlotName(upgradeID))

						addVehicleLogs(getElementData(theVehicle,"dbid"), commandName.." "..upgradeID, thePlayer)

						outputChatBox(getVehicleUpgradeSlotName(upgradeID) .. " upgrade added to " .. targetPlayerName .. "'s vehicle.", thePlayer)
						outputChatBox("Admin " .. username .. " added upgrade " .. getVehicleUpgradeSlotName(upgradeID) .. " to your vehicle.", targetPlayer)

						exports['savevehicle-system']:saveVehicleMods(theVehicle)
						exports['savevehicle-system']:saveVehicle(theVehicle)
					else
						outputChatBox("Invalid Upgrade ID, or this vehicle doesn't support this upgrade.", thePlayer, 255, 0, 0)
					end
				end
			end
		end
	end
end
addCommandHandler("addupgrade", addUpgrade, false, false)


function resetUpgrades(thePlayer, commandName, target)
	if exports.integration:isPlayerTrialAdmin(thePlayer) then
		if not (target) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Partial Player Nick]", thePlayer, 255, 194, 14)
		else
			local username = getPlayerName(thePlayer)
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, target)

			if targetPlayer then
				if not (isPedInVehicle(targetPlayer)) then
					outputChatBox("That player is not in a vehicle.", thePlayer, 255, 0, 0)
				else
					local theVehicle = getPedOccupiedVehicle(targetPlayer)
					exports.logs:dbLog(thePlayer, 6, { targetPlayer, theVehicle  }, "RESETUPGRADES" )

					addVehicleLogs(getElementData(theVehicle,"dbid"), commandName, thePlayer)

					local failed, rcount = 0, 0
					for key, value in ipairs(getVehicleUpgrades(theVehicle)) do
						if not removeVehicleUpgrade(theVehicle, value) then
							failed=failed+1
						else
							rcount=rcount+1
						end
					end
					setVehiclePaintjob(theVehicle, 3)
					outputChatBox("Removed "..rcount.." upgrades from " .. targetPlayerName .. "'s vehicle.", thePlayer, 0, 255, 0)

					exports['savevehicle-system']:saveVehicleMods(theVehicle)
					exports['savevehicle-system']:saveVehicle(theVehicle)

					if failed > 0 then
						outputChatBox(failed.." upgrades failed to remove.", thePlayer, 255,0,0)
					end
				end
			end
		end
	end
end
addCommandHandler("resetupgrades", resetUpgrades, false, false)

function deleteUpgrade(thePlayer, commandName, target, id)
	if exports.integration:isPlayerTrialAdmin(thePlayer)   then
		if not (target) or not id then
			outputChatBox("SYNTAX: /" .. commandName .. " [Partial Player Nick] [Upgrade ID]", thePlayer, 255, 194, 14)
		else
			local username = getPlayerName(thePlayer)
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, target)

			if targetPlayer then
				if not (isPedInVehicle(targetPlayer)) then
					outputChatBox("That player is not in a vehicle.", thePlayer, 255, 0, 0)
				else
					local theVehicle = getPedOccupiedVehicle(targetPlayer)
					exports.logs:dbLog(thePlayer, 6, { targetPlayer, theVehicle  }, "DELETEUPGRADE ".. id )

					addVehicleLogs(getElementData(theVehicle,"dbid"), commandName.." "..id, thePlayer)

					local result = removeVehicleUpgrade(theVehicle, id)
					if result then
						outputChatBox("Removed upgrade ".. id .." from " .. targetPlayerName .. "'s vehicle.", thePlayer, 0, 255, 0)

						exports['savevehicle-system']:saveVehicleMods(theVehicle)
						exports['savevehicle-system']:saveVehicle(theVehicle)
					else
						outputChatBox("Something went wrong with removing upgrade ".. id .." from " .. targetPlayerName .. "'s vehicle.", thePlayer, 0, 255, 0)
					end
				end
			end
		end
	end
end
addCommandHandler("deleteupgrade", deleteUpgrade, false, false)
addCommandHandler("delupgrade", deleteUpgrade, false, false)

-----------------------------[FIX VEH]---------------------------------
function fixPlayerVehicle(thePlayer, commandName, target, targetVehicle_)
	if (exports.integration:isPlayerTrialAdmin(thePlayer))
	or exports.integration:isPlayerVMTMember(thePlayer) then

		local targetVehicle = (targetVehicle_ and isElement(targetVehicle_) and getElementType(targetVehicle_) == "vehicle") and targetVehicle_ or false
		if not (target) then
			if not targetVehicle then
				outputChatBox("SYNTAX: /" .. commandName .. " [Partial Player Nick]", thePlayer, 255, 194, 14)
				return
			end
		end

		local username = getPlayerName(thePlayer)
		local targetPlayer, targetPlayerName
		if not targetVehicle then
			targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, target)
		end

		if targetPlayer or targetVehicle then
			if targetPlayer and (getElementData(targetPlayer, "loggedin")==0) then
				outputChatBox("Player is not logged in.", thePlayer, 255, 0, 0)
			else
				local veh = targetVehicle or getPedOccupiedVehicle(targetPlayer)
				if (veh) then

					fixVehicle(veh)
					setVehicleDamageProof(veh, false)
					if (getElementData(veh, "Impounded") == 0) then
						exports.anticheat:changeProtectedElementDataEx(veh, "enginebroke", 0, false)
						if armoredCars[ getElementModel( veh ) ] or getElementData(veh, "bulletproof") == 1 then
							setVehicleDamageProof(veh, true)
						end
					end
					for i = 0, 5 do
						setVehicleDoorState(veh, i, 0) -- repair all doors
					end
					for i = 0, 5 do
						setVehicleDoorOpenRatio(veh, i, 0) -- close all doors
					end

					exports.logs:dbLog(thePlayer, 6, { targetPlayer, veh  }, "FIXVEH")

					setVehicleWheelStates(veh, 0, 0, 0, 0)

					if exports["vehicle-manager"]:isVehicleDestroyed(veh) then
						triggerEvent("A:saveDescriptions", veh, "", veh)
					end

					addVehicleLogs(getElementData(veh,"dbid"), commandName, thePlayer)

					if targetPlayerName then
						outputChatBox("You repaired " .. targetPlayerName .. "'s vehicle.", thePlayer)
						outputChatBox("Your vehicle was repaired by "..exports.global:getPlayerAdminTitle(thePlayer)..".", targetPlayer, 0, 255, 0)
					else
						outputChatBox("You repaired vehicle #"..getElementData(veh, "dbid")..".", thePlayer)
					end

					if exports.integration:isPlayerVMTMember(thePlayer) then
						-- Discord log
						exports.discord:sendDiscordMessage("veh-logs", ":screwdriver: **"..getElementData(thePlayer, "account:username").."** repaired vehicle ``ID #"..getElementData(veh,"dbid").."``.")
					end
				else
					outputChatBox("That player is not in a vehicle.", thePlayer, 255, 0, 0)
				end
			end
		end
	end
end
addEvent("cmd:fixveh", true)
addEventHandler("cmd:fixveh", root, fixPlayerVehicle)
addCommandHandler("fixveh", fixPlayerVehicle, false, false)

-----------------------------[SET CAR HP]---------------------------------
function setCarHP(thePlayer, commandName, target, hp)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		if not (target) or not (hp) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Partial Player Nick] [Health]", thePlayer, 255, 194, 14)
		else
			local username = getPlayerName(thePlayer)
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, target)

			if targetPlayer then
				local logged = getElementData(targetPlayer, "loggedin")
				if (logged==0) then
					outputChatBox("Player is not logged in.", thePlayer, 255, 0, 0)
				else
					local veh = getPedOccupiedVehicle(targetPlayer)
					if (veh) then
						local sethp = setElementHealth(veh, tonumber(hp))

						if (sethp) then
							outputChatBox("You set " .. targetPlayerName .. "'s vehicle health to " .. hp .. ".", thePlayer)
							--exports.logs:logMessage("[/SETCARHP] " .. getElementData(thePlayer, "account:username") .. "/".. getPlayerName(thePlayer) .." set ".. targetPlayerName .. "his car to hp: " .. hp , 4)
							exports.logs:dbLog(thePlayer, 6, { targetPlayer, veh  }, "SETVEHHP ".. hp )

							addVehicleLogs(getElementData(veh,"dbid"), commandName.." "..hp, thePlayer)
						else
							outputChatBox("Invalid health value.", thePlayer, 255, 0, 0)
						end
					else
						outputChatBox("That player is not in a vehicle.", thePlayer, 255, 0, 0)
					end
				end
			end
		end
	end
end
addCommandHandler("setvehhp", setCarHP, false, false)
addCommandHandler("setcarhp", setCarHP, false, false)

function fixAllVehicles(thePlayer, commandName)
	if (exports.integration:isPlayerSeniorAdmin(thePlayer)) then
		local username = getPlayerName(thePlayer)
		for key, value in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
			fixVehicle(value)
			if exports["vehicle-manager"]:isVehicleDestroyed(value) then
				triggerEvent("A:saveDescriptions", value, "", value)
			end
			setVehicleDamageProof(value, false)
			if (not getElementData(value, "Impounded")) then
				exports.anticheat:changeProtectedElementDataEx(value, "enginebroke", 0, false)
				if armoredCars[ getElementModel( value ) ] or getElementData(value, "bulletproof") == 1 then
					setVehicleDamageProof(value, true)
				end
			end
		end
		--outputChatBox("All vehicles repaired by Admin " .. username .. ".")
		executeCommandHandler("ann", thePlayer, "All vehicles repaired by "..exports.global:getPlayerAdminTitle(thePlayer) .. ".")
		exports.logs:dbLog(thePlayer, 6, { targetPlayer }, "FIXALLVEHS")
	end
end
addCommandHandler("fixvehs", fixAllVehicles)

-----------------------------[FUEL VEH]---------------------------------
function fuelPlayerVehicle(thePlayer, commandName, target, amount)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		if not (target) or not (amount) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Partial Player Nick] [Amount in Liters, 0=Full]", thePlayer, 255, 194, 14)
		else
			local username = getPlayerName(thePlayer)
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, target)
			--local amount = math.floor(tonumber(amount) or 0)

			if targetPlayer then
				local logged = getElementData(targetPlayer, "loggedin")
				if (logged==0) then
					outputChatBox("Player is not logged in.", thePlayer, 255, 0, 0)
				else
					local veh = getPedOccupiedVehicle(targetPlayer)
					if (veh) then
						amount = tonumber(amount)
						if exports["fuel-system"]:getMaxFuel(getElementModel((veh))) < amount or amount==0 then
							amount = exports["fuel-system"]:getMaxFuel(getElementModel(veh))
						end
						exports.anticheat:changeProtectedElementDataEx(veh, "fuel", amount, false)
						triggerClientEvent(targetPlayer, "syncFuel", veh, getElementData(veh, "fuel"))
						outputChatBox("You refueled " .. targetPlayerName .. "'s vehicle.", thePlayer)
						outputChatBox("Your vehicle was refueled by "..exports.global:getPlayerAdminTitle(thePlayer)..".", targetPlayer, 0, 255, 0)
						exports.logs:dbLog(thePlayer, 6, { targetPlayer, veh  }, "FUELVEH")

						addVehicleLogs(getElementData(veh,"dbid"), commandName, thePlayer)

					else
						outputChatBox("That player is not in a vehicle.", thePlayer, 255, 0, 0)
					end
				end
			end
		end
	end
end
addCommandHandler("fuelveh", fuelPlayerVehicle, false, false)

function fuelAllVehicles(thePlayer, commandName)
	if (exports.integration:isPlayerSeniorAdmin(thePlayer)) then
		local username = getPlayerName(thePlayer)
		for key, value in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
			exports.anticheat:changeProtectedElementDataEx(value, "fuel", exports["fuel-system"]:getMaxFuel(getElementModel(value)), false)
		end
		executeCommandHandler("ann", thePlayer, "All vehicles refuelled by Admin " .. exports.global:getPlayerAdminTitle(thePlayer) .. ".")
		exports.logs:dbLog(thePlayer, 6, { thePlayer  }, "FUELVEHS" )
	end
end
addCommandHandler("fuelvehs", fuelAllVehicles, false, false)

-----------------------------[SET COLOR]---------------------------------
function setPlayerVehicleColor(thePlayer, commandName, target, ...)
	if (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer)) then
		if not tonumber(target) or not (...) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Vehicle ID] [Colors ...]", thePlayer, 255, 194, 14)
		else
			local username = getPlayerName(thePlayer)
			for i,c in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
				if (getElementData(c, "dbid") == tonumber(target)) then
					theVehicle = c
					break
				end
			end

			if theVehicle then
				-- parse colors
				local colors = {...}
				local col = {}
				for i = 1, math.min( 4, #colors ) do
					local r, g, b = getColorFromString(#colors[i] == 6 and ("#" .. colors[i]) or colors[i])
					if r and g and b then
						col[i] = {r=r, g=g, b=b}
					elseif tonumber(colors[1]) and tonumber(colors[1]) >= 0 and tonumber(colors[1]) <= 255 then
						col[i] = math.floor(tonumber(colors[i]))
					else
						outputChatBox("Invalid color: " .. colors[i], thePlayer, 255, 0, 0)
						return
					end
				end
				if not col[2] then col[2] = col[1] end
				if not col[3] then col[3] = col[1] end
				if not col[4] then col[4] = col[2] end

				local set = false
				if type( col[1] ) == "number" then
					set = setVehicleColor(theVehicle, col[1], col[2], col[3], col[4])
				else
					set = setVehicleColor(theVehicle, col[1].r, col[1].g, col[1].b, col[2].r, col[2].g, col[2].b, col[3].r, col[3].g, col[3].b, col[4].r, col[4].g, col[4].b)
				end

				if set then
					outputChatBox("Vehicle's color was set.", thePlayer, 0, 255, 0)
					exports['savevehicle-system']:saveVehicleMods(theVehicle)
					exports.logs:dbLog(thePlayer, 6, {  theVehicle  }, "SETVEHICLECOLOR ".. table.concat({...}, " ") )

					addVehicleLogs(getElementData(theVehicle,"dbid"), commandName..table.concat({...}, " "), thePlayer)

				else
					outputChatBox("Invalid Color ID.", thePlayer, 255, 194, 14)
				end
			else
				outputChatBox("Vehicle is not found. Is it a permanent vehicle?", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setcolor", setPlayerVehicleColor, false, false)
addCommandHandler("setvehcolor", setPlayerVehicleColor, false, false)
-----------------------------[GET COLOR]---------------------------------
function getAVehicleColor(thePlayer, commandName, carid)
	if (exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer)) then
		if not (carid) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Car ID]", thePlayer, 255, 194, 14)
		else
			local acar = nil
			for i,c in ipairs(getElementsByType("vehicle")) do
				if (getElementData(c, "dbid") == tonumber(carid)) then
					acar = c
				end
			end
			if acar then
				local col =  { getVehicleColor(acar, true) }
				outputChatBox("Vehicle's colors are:", thePlayer)
				outputChatBox("1. " .. col[1].. "," .. col[2] .. "," .. col[3] .. " = " .. ("#%02X%02X%02X"):format(col[1], col[2], col[3]), thePlayer)
				outputChatBox("2. " .. col[4].. "," .. col[5] .. "," .. col[6] .. " = " .. ("#%02X%02X%02X"):format(col[4], col[5], col[6]), thePlayer)
				outputChatBox("3. " .. col[7].. "," .. col[8] .. "," .. col[9] .. " = " .. ("#%02X%02X%02X"):format(col[7], col[8], col[9]), thePlayer)
				outputChatBox("4. " .. col[10].. "," .. col[11] .. "," .. col[12] .. " = " .. ("#%02X%02X%02X"):format(col[10], col[11], col[12]), thePlayer)
			else
				outputChatBox("Invalid Car ID.", thePlayer, 255, 194, 14)
			end
		end
	end
end
addCommandHandler("getcolor", getAVehicleColor, false, false)
addCommandHandler("getvehcolor", getAVehicleColor, false, false)

function removeVehicle(thePlayer, commandName, id)
	if exports.integration:isPlayerSeniorAdmin(thePlayer) then
		local dbid = tonumber(id)
		if not dbid or dbid%1~=0 or dbid <=0 then
			outputChatBox("SYNTAX: /" .. commandName .. " [ID]", thePlayer, 255, 194, 14)
			return false
		end

		local query1 = mysql:query("SELECT `deleted` FROM `vehicles` WHERE id='" .. mysql:escape_string(dbid) .. "'")
		local row = {}
		if query1 then
			row = mysql:fetch_assoc(query1) or false
			mysql:free_result(query1)
		end
		if not row then
			outputChatBox(" No such vehicle with ID #"..dbid.." found in Database.", thePlayer, 255, 0, 0)
			return false
		elseif row["deleted"] == "0" then
			outputChatBox(" Please use /delveh "..dbid.." first.", thePlayer, 255, 0, 0)
			return false
		else
			local theVehicle = exports["vehicle-system"]:loadOneVehicle(dbid, true)
			if theVehicle then
				outputChatBox("Deleted "..(clearVehicleInventory(theVehicle) or "0").." item(s) from vehicle's inventory.",thePlayer)
			else
				outputChatBox("Failed to clear vehicle's inventory.",thePlayer, 255,0,0)
				outputDebugString("[VEH MANAGER] Failed to clear vehicle's inventory.")
			end

			destroyElement(theVehicle)
			mysql:query_free("DELETE FROM `vehicles` WHERE `id`='" .. mysql:escape_string(dbid) .. "'")
			mysql:query_free("DELETE FROM `vehicles_custom` WHERE `id`='" .. mysql:escape_string(dbid) .. "'")
			mysql:query_free("DELETE FROM `vehicle_logs` WHERE `vehID`='" .. mysql:escape_string(dbid) .. "'")
			mysql:query_free("DELETE FROM `vehicle_notes` WHERE `vehid`='" .. mysql:escape_string(dbid) .. "'")

			exports["item-system"]:deleteAll(3, dbid )
			for k, theObject in ipairs(getElementsByType("object", getResourceRootElement(getResourceFromName("item-world")))) do
				if getElementData(theObject, "id") then
					local itemID = tonumber(getElementData(theObject, "itemID"))
					local itemValue = tonumber(getElementData(theObject, "itemValue"))
					if itemID == 3 and itemValue == tonumber(dbid) then
						destroyElement(theObject)
					end
				end
			end
			mysql:query_free("DELETE FROM worlditems WHERE itemid='3' AND itemvalue='" .. mysql:escape_string(dbid) .. "'")

			local adminUsername = getElementData(thePlayer, "account:username")
			local hiddenAdmin = getElementData(thePlayer, "hiddenadmin")
			local adminTitle = exports.global:getPlayerAdminTitle(thePlayer)

			if hiddenAdmin == 0 then
				exports.global:sendMessageToAdmins("[VEHICLE]: "..adminTitle.." ("..adminUsername..") has removed vehicle ID: #" .. dbid .. " completely from SQL.")
			else
				exports.global:sendMessageToAdmins("[VEHICLE]: A hidden admin has removed vehicle ID: #" .. dbid .. " completely from SQL.")
			end
			return true
		end
	else
		outputChatBox("You don't have permission to permanently remove vehicles from DB.", thePlayer, 255, 0, 0)
	end
end
addCommandHandler("removeveh", removeVehicle, false, false)
addCommandHandler("removevehicle", removeVehicle, false, false)

function clearVehicleInventory(theVehicle)
	if theVehicle then
		local count = 0
		for key, item in pairs(exports["item-system"]:getItems(theVehicle)) do
			exports.global:takeItem(theVehicle, item[1], item[2])
			count = count + 1
		end
		return count
	else
		outputDebugString("[VEH MANAGER] / vehicle commands / clearVehicleInventory() / element not found.")
		return false
	end
end

function adminClearVehicleInventory(thePlayer, commandName, vehicle)
	if exports.integration:isPlayerTrialAdmin(thePlayer) then
		vehicle = tonumber(vehicle)
		if vehicle and (vehicle%1==0) then
			for _, theVehicle in pairs(getElementsByType("vehicle")) do
				if getElementData(theVehicle, "dbid") == vehicle then
					vehicle = theVehicle
					break
				end
			end
		end

		if not isElement(vehicle) then
			vehicle = getPedOccupiedVehicle(thePlayer) or false
		end

		if not vehicle then
			outputChatBox("SYNTAX: /" .. commandName .. " [ID]     -> Clear all items in a vehicle inventory.", thePlayer, 255, 194, 14)
			outputChatBox("SYNTAX: /" .. commandName .. "          -> Clear all items in current vehicle inventory.", thePlayer, 255, 194, 14)
			return false
		end

		outputChatBox("Deleted "..(clearVehicleInventory(vehicle) or "0").." item(s) from vehicle's inventory.",thePlayer)

	else
		outputChatBox("Only Admins can perform this command. Operation cancelled.", thePlayer, 255,0,0)
	end
end
addCommandHandler("clearvehinv", adminClearVehicleInventory, false, false)
addCommandHandler("clearvehicleinventory", adminClearVehicleInventory, false, false)

function restoreVehicle(thePlayer, commandName, id)
	if exports.integration:isPlayerTrialAdmin(thePlayer) 	then
		local dbid = tonumber(id)
		if not (dbid) then
			outputChatBox("SYNTAX: /" .. commandName .. " [ID]", thePlayer, 255, 194, 14)
		else
			local theVehicle = exports.pool:getElement("vehicle", dbid)
			local adminUsername = getElementData(thePlayer, "account:username")
			local hiddenAdmin = getElementData(thePlayer, "hiddenadmin")
			local adminTitle = exports.global:getPlayerAdminTitle(thePlayer)
			local adminID = getElementData(thePlayer, "account:id")
			if not theVehicle then
				if mysql:query_free("UPDATE `vehicles` SET `deleted`='0', `chopped`='0' WHERE `id`='" .. mysql:escape_string(dbid) .. "'") then
					exports["vehicle-system"]:loadOneVehicle(dbid )
					outputChatBox("   Restoring vehicle ID #"..dbid.."...", thePlayer)
					setTimer(function()
						outputChatBox("   Restoring vehicle ID #"..dbid.."...Done!", thePlayer)
						local theVehicle1 = exports.pool:getElement("vehicle", dbid)
						exports.logs:dbLog(thePlayer, 6, { theVehicle1 }, "RESTOREVEH" )
						addVehicleLogs(dbid, commandName, thePlayer)

						local vehicleID = getElementModel(theVehicle1)
						local vehicleName = exports.global:getVehicleName(theVehicle1)
						local owner = getElementData(theVehicle1, "owner")
						local faction = getElementData(theVehicle1, "faction")
						local ownerName = ""
						if faction then
							if (faction>0) then
								local theTeam = exports.pool:getElement("team", faction)
								if theTeam then
									ownerName = getTeamName(theTeam)
								end
							elseif (owner==-1) then
								ownerName = "Admin Temp Vehicle"
							elseif (owner>0) then
								ownerName = exports['cache']:getCharacterName(owner, true)
							else
								ownerName = "Civilian"
							end
						else
							ownerName = "Car Dealership"
						end

						if hiddenAdmin == 0 then
						exports.global:sendMessageToAdmins("[VEHICLE]: "..adminTitle.." ("..adminUsername..") has restore a " .. vehicleName .. " (ID: #" .. dbid .. " - Owner: " .. ownerName..").")
						else
							exports.global:sendMessageToAdmins("[VEHICLE]: A hidden admin has restore a " .. vehicleName .. " (ID: #" .. dbid .. " - Owner: " .. ownerName..").")
						end
					end, 2000,1)

				else
					outputChatBox(" Database Error!", thePlayer, 255, 0, 0)
				end
			else
				outputChatBox(" Vehicle ID #"..dbid.." is existed in game, please use /delveh first.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("restoreveh", restoreVehicle, false, false)
addCommandHandler("restorevehicle", restoreVehicle, false, false)

function deleteVehicle(thePlayer, commandName, id)
	if exports.integration:isPlayerTrialAdmin(thePlayer)
	or exports.integration:isPlayerVMTMember(thePlayer)
	or exports.integration:isPlayerFMTMember(thePlayer)
	then

		local dbid = tonumber(id)
		if not (dbid) then
			outputChatBox("SYNTAX: /" .. commandName .. " [ID]", thePlayer, 255, 194, 14)
		else
			local theVehicle = exports.pool:getElement("vehicle", dbid)
			local adminUsername = getElementData(thePlayer, "account:username")
			local hiddenAdmin = getElementData(thePlayer, "hiddenadmin")
			local adminTitle = exports.global:getPlayerAdminTitle(thePlayer)
			local adminID = getElementData(thePlayer, "account:id")
			if theVehicle then
				local protected, details = exports['vehicle-system']:isProtected(theVehicle)
	            if protected then
	                outputChatBox("This vehicle is protected and can not be deleted. Protection remaining: "..details..".", thePlayer, 255,0,0)
	                return false
	            end

	            if dbid > 0 and
	            not (exports.integration:isPlayerVMTLeader(thePlayer)
	            or exports.integration:isPlayerAdmin(thePlayer))
	            then
	            	return outputChatBox("Only Admin+ or VMT Leader can delete non-temporary vehicles.", thePlayer, 255,126,0)
	            end

	            local active, details2, secs = exports['vehicle-system']:isActive(theVehicle)
	            --outputChatBox(exports.data:load(getElementData(thePlayer, "account:id").."/"..commandName))
				local vehicleID = getElementModel(theVehicle)
				local vehicleName = exports.global:getVehicleName(theVehicle)
				local owner = getElementData(theVehicle, "owner")
				local faction = getElementData(theVehicle, "faction")
				local ownerName = ""
				if faction then
					if (faction>0) then
						local theTeam = exports.pool:getElement("team", faction)
						if theTeam then
							ownerName = getTeamName(theTeam)
						end
					elseif (owner==-1) then
						ownerName = "Admin Temp Vehicle"
					elseif (owner>0) then
						ownerName = exports['cache']:getCharacterName(owner, true)
					else
						ownerName = "Civilian"
					end
				else
					ownerName = "Car Dealership"
				end

				if (dbid<0) then -- TEMP vehicle
					
					exports["item-system"]:deleteAll(3, dbid )

					for k, theObject in ipairs(getElementsByType("object", getResourceRootElement(getResourceFromName("item-world")))) do
						if getElementData(theObject, "id") then
							local itemID = tonumber(getElementData(theObject, "itemID"))
							local itemValue = tonumber(getElementData(theObject, "itemValue"))
							if itemID == 3 and itemValue == tonumber(dbid) then
								destroyElement(theObject)
							end
						end
					end
					mysql:query_free("DELETE FROM worlditems WHERE itemid='3' AND itemvalue='" .. mysql:escape_string(dbid) .. "'")

					destroyElement(theVehicle)
					exports.discord:sendDiscordMessage("veh-logs", ":negative_squared_cross_mark: **"..getElementData(thePlayer, "account:username").."** has deleted a ``temporary vehicle`` ``(ID: #" .. dbid .. ")``.")

					outputChatBox("   Deleted a " .. vehicleName .. " (Temp ID: #" .. dbid .. ").", thePlayer, 14, 255, 0)
				else

					local textures = getElementData(theVehicle, "textures") or {{}}
					for k, tex in pairs(textures) do
						local url = tex[2]
						if url then
							exports["item-texture"]:unCacheTexture(url)
						end
					end

					if not exports["item-system"]:clearItems(theVehicle) then
						return outputChatBox("Error clearing vehicle #"..dbid.."'s inventory.", thePlayer, 255,100,100)
					end

					exports["item-system"]:deleteAll(3, dbid )

					mysql:query_free("UPDATE `vehicles` SET `deleted`='"..tostring(adminID).."', deletedDate=NOW(), textures='"..toJSON({{}}).."' WHERE `id`='" .. mysql:escape_string(dbid) .. "'")
					mysql:query_free("DELETE FROM `mdc_vehcrimes` WHERE vehid = '" .. mysql:escape_string(dbid) .. "'")
					mysql:query_free("DELETE FROM `vehicles_custom` WHERE `id`='" .. mysql:escape_string(dbid) .. "'")

					exports.logs:dbLog(thePlayer, 6, { theVehicle }, "DELVEH" )

					if hiddenAdmin == 0 then
						exports.global:sendMessageToAdmins("[VEHICLE]: "..adminTitle.." ("..adminUsername..") has deleted a " .. vehicleName .. " (ID: #" .. dbid .. ") - Owner: " .. ownerName..".")
					else
						exports.global:sendMessageToAdmins("[VEHICLE]: A hidden admin has deleted a " .. vehicleName .. " (ID: #" .. dbid .. ") - Owner: " .. ownerName..".")
					end
					addVehicleLogs(dbid, commandName, thePlayer)

					-- Discord log
					exports.discord:sendDiscordMessage("veh-logs", ":negative_squared_cross_mark: **"..getElementData(thePlayer, "account:username").."** has deleted a ``" .. vehicleName .. "`` ``(ID: #" .. dbid .. ")`` - Owner: **" .. ownerName.."**.")

					for k, theObject in ipairs(getElementsByType("object", getResourceRootElement(getResourceFromName("item-world")))) do
						if getElementData(theObject, "id") then
							local itemID = tonumber(getElementData(theObject, "itemID"))
							local itemValue = tonumber(getElementData(theObject, "itemValue"))
							if itemID == 3 and itemValue == tonumber(dbid) then
								destroyElement(theObject)
							end
						end
					end
					mysql:query_free("DELETE FROM worlditems WHERE itemid='3' AND itemvalue='" .. mysql:escape_string(dbid) .. "'")

					destroyElement(theVehicle)
					outputChatBox("   Deleted a " .. vehicleName .. " (ID: #" .. dbid .. " - Owner: " .. ownerName.."), and wiped its textures.", thePlayer, 255, 126, 0)
				end
			else
				outputChatBox("No vehicles with that ID found.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("delveh", deleteVehicle, false, false)
addCommandHandler("delcar", deleteVehicle, false, false)
addCommandHandler("deletevehicle", deleteVehicle, false, false)

-- DELTHISVEH
function deleteThisVehicle(thePlayer, commandName)
	local veh = getPedOccupiedVehicle(thePlayer)
	local dbid = getElementData(veh, "dbid")
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		if not (isPedInVehicle(thePlayer)) then
			outputChatBox("You are not in a vehicle.", thePlayer, 255, 0, 0)
		else
			deleteVehicle(thePlayer, "delveh", dbid)
		end
	else
		outputChatBox("You do not have the permission to delete permanent vehicles.", thePlayer, 255, 0, 0)
	end
end
addCommandHandler("delthisveh", deleteThisVehicle, false, false)

function setVehicleFaction(thePlayer, theCommand, vehicleID, factionID)
	if exports.integration:isPlayerTrialAdmin(thePlayer)  then
		if not (vehicleID) or not (factionID) or not tonumber(vehicleID) or not tonumber(factionID) then
			outputChatBox("SYNTAX: /" .. theCommand .. " [vehicleID] [factionID]", thePlayer, 255, 194, 14)
		else
			vehicleID = tonumber(vehicleID)
			factionID = tonumber(factionID)

			local owner = -1
			local theVehicle = exports.pool:getElement("vehicle", vehicleID)
			local factionElement = exports.pool:getElement("team", factionID)

			if theVehicle then
				if (tonumber(factionID) == -1) then
					owner = getElementData(thePlayer, "account:character:id")
				else
					if not factionElement then
						outputChatBox("No faction with that ID found.", thePlayer, 255, 0, 0)
						return
					end
				end

				local max_vehicles = getElementData(factionElement, "max_vehicles") or 5
				local cur = (#(exports.global:getVehiclesOwnedByFaction(factionElement)))
				if cur >= max_vehicles then
					return outputChatBox(getTeamName(factionElement).." has already reached the maximum number of vehicles ("..cur.."/"..max_vehicles..").", thePlayer, 255,0,0)
				end

				-- Fernando: VEH REGISTRATION HISTORY
				local regTable = getElementData(theVehicle, "regHistory") or {}
				table.insert(regTable, {factionID==-1 and owner or -factionID, tostring(os.date("%x", os.time()))})
				local regHistory = toJSON(regTable)
				-- [i] = owner, registered today;
				-- saved in JSON format.

				mysql:query_free("UPDATE `vehicles` SET `owner`='".. mysql:escape_string(owner) .."', regHistory='"..mysql:escape_string(regHistory).."', `faction`="..factionID .. " WHERE id = '" .. mysql:escape_string(vehicleID) .. "'")

				reloadVehicle2(tonumber(vehicleID))

				exports['item-system']:deleteAll(3, vehicleID)
				for k, theObject in ipairs(getElementsByType("object", getResourceRootElement(getResourceFromName("item-world")))) do
					if getElementData(theObject, "id") then
						local itemID = tonumber(getElementData(theObject, "itemID"))
						local itemValue = tonumber(getElementData(theObject, "itemValue"))
						if itemID == 3 and itemValue == tonumber(vehicleID) then
							destroyElement(theObject)
							mysql:query_free("DELETE FROM worlditems WHERE itemid='3' AND itemvalue='" .. mysql:escape_string(vehicleID) .. "'")
						end
					end
				end

				exports.anticheat:changeProtectedElementDataEx(newVehicleElement, "veh:forsale", {}, true)
				exports['savevehicle-system']:saveVehicle(newVehicleElement)

				outputChatBox("Set vehicle #"..vehicleID.." to faction #"..factionID..".", thePlayer, 0,255,0)

				exports.logs:dbLog(thePlayer, 4, { pveh, newVehicleElement }, theCommand.." "..factionID)
				addVehicleLogs(vehicleID, theCommand.." "..factionID, thePlayer)
			else
				outputChatBox("No vehicle with that ID found.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setvehiclefaction", setVehicleFaction)
addCommandHandler("setvehfaction", setVehicleFaction)


function setFactionVehicle(thePlayer, theCommand, factionID)
	if exports.integration:isPlayerTrialAdmin(thePlayer)  then
		if not tonumber(factionID) then
			outputChatBox("SYNTAX: /" .. theCommand .. " [factionID] inside a vehicle", thePlayer, 255, 194, 14)
		else
			factionID = tonumber(factionID)

			local theVehicle = getPedOccupiedVehicle(thePlayer)
			local vehicleID = getElementData(theVehicle, "dbid")
			local factionElement = exports.pool:getElement("team", factionID)

			local owner = -1
			if theVehicle and vehicleID > 0 then

				if (tonumber(factionID) == -1) then
					owner = getElementData(thePlayer, "account:character:id")
				else
					if not factionElement then
						outputChatBox("No faction with that ID found.", thePlayer, 255, 0, 0)
						return
					end
				end

				local max_vehicles = getElementData(factionElement, "max_vehicles") or 5
				local cur = (#(exports.global:getVehiclesOwnedByFaction(factionElement)))
				if cur >= max_vehicles then
					return outputChatBox(getTeamName(factionElement).." has already reached the maximum number of vehicles ("..cur.."/"..max_vehicles..").", thePlayer, 255,0,0)
				end

				-- Fernando: VEH REGISTRATION HISTORY
				local regTable = getElementData(theVehicle, "regHistory") or {}
				table.insert(regTable, {factionID==-1 and owner or -factionID, tostring(os.date("%x", os.time()))})
				local regHistory = toJSON(regTable)
				-- [i] = owner, registered today;
				-- saved in JSON format.

				mysql:query_free("UPDATE `vehicles` SET `owner`='".. mysql:escape_string(owner) .."', regHistory='"..mysql:escape_string(regHistory).."', `faction`="..factionID .. " WHERE id = '" .. mysql:escape_string(vehicleID) .. "'")

				reloadVehicle2(tonumber(vehicleID))

				exports['item-system']:deleteAll(3, vehicleID)
				for k, theObject in ipairs(getElementsByType("object", getResourceRootElement(getResourceFromName("item-world")))) do
					if getElementData(theObject, "id") then
						local itemID = tonumber(getElementData(theObject, "itemID"))
						local itemValue = tonumber(getElementData(theObject, "itemValue"))
						if itemID == 3 and itemValue == tonumber(vehicleID) then
							destroyElement(theObject)
							mysql:query_free("DELETE FROM worlditems WHERE itemid='3' AND itemvalue='" .. mysql:escape_string(vehicleID) .. "'")
						end
					end
				end

				exports.anticheat:changeProtectedElementDataEx(newVehicleElement, "veh:forsale", {}, true)
				exports['savevehicle-system']:saveVehicle(newVehicleElement)

				outputChatBox("Set vehicle #"..vehicleID.." to faction #"..factionID..".", thePlayer, 0,255,0)

				exports.logs:dbLog(thePlayer, 4, { pveh, newVehicleElement }, theCommand.." "..factionID)
				addVehicleLogs(vehicleID, theCommand.." "..factionID, thePlayer)
			else
				outputChatBox("You need to be inside a vehicle.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setfactionvehicle", setFactionVehicle)
addCommandHandler("setfactionveh", setFactionVehicle)

--Adding/Removing tint
function setVehTint(admin, command, target, status)
	if exports.integration:isPlayerTrialAdmin(admin) then
		if not (target) or not (status) then
			outputChatBox("SYNTAX: /" .. command .. " [player] [0- Off, 1- On]", admin, 255, 194, 14)
		else
			local username = getPlayerName(admin):gsub("_"," ")
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(admin, target)

			if (targetPlayer) then
				local pv = getPedOccupiedVehicle(targetPlayer)
				if (pv) then
					local vid = getElementData(pv, "dbid")
					local stat = tonumber(status)
					if (stat == 1) then

						if vid > 0 then
							mysql:query_free("UPDATE vehicles SET tintedwindows = '1' WHERE id='" .. mysql:escape_string(vid) .. "'")
							addVehicleLogs(vid, command.." on", admin)
						end

						for i = 0, getVehicleMaxPassengers(pv) do
							local player = getVehicleOccupant(pv, i)
							if (player) then
								triggerEvent("setTintName", pv, player)
							end
						end

						exports.anticheat:changeProtectedElementDataEx(pv, "tinted", true, true)
						triggerClientEvent("tintWindows", pv)
						outputChatBox("You have added tint to vehicle #" .. vid .. ".", admin)

						for k, arrayPlayer in ipairs(getElementsByType("player")) do
							local logged = getElementData(arrayPlayer, "loggedin")
							if (logged==1) then
								if exports.integration:isPlayerTrialAdmin(arrayPlayer) then
									outputChatBox( "AdmWrn: " .. getPlayerName(admin):gsub("_"," ") .. " added tint to vehicle #" .. vid .. ".", arrayPlayer, 255, 25, 25)
								end
							end
						end

						exports.logs:dbLog(admin, 6, {pv, targetPlayer}, "SETVEHTINT 1" )
					elseif (stat == 0) then

						if vid > 0 then
							mysql:query_free("UPDATE vehicles SET tintedwindows = '0' WHERE id='" .. mysql:escape_string(vid) .. "'")
							addVehicleLogs(vid, command.." off", admin)
						end

						for i = 0, getVehicleMaxPassengers(pv) do
							local player = getVehicleOccupant(pv, i)
							if (player) then
								triggerEvent("resetTintName", pv, player)
							end
						end

						exports.anticheat:changeProtectedElementDataEx(pv, "tinted", false, true)
						triggerClientEvent("tintWindows", pv)
						outputChatBox("You have removed tint from vehicle #" .. vid .. ".", admin)
						exports.logs:dbLog(admin, 4, {pv, targetPlayer}, "SETVEHTINT 0" )

						for k, arrayPlayer in ipairs(getElementsByType("player")) do
							local logged = getElementData(arrayPlayer, "loggedin")
							if (logged==1) then
								if exports.integration:isPlayerTrialAdmin(arrayPlayer) then
									outputChatBox( "AdmWrn: " .. getPlayerName(admin):gsub("_"," ") .. " removed tint from vehicle #" .. vid .. ".", arrayPlayer, 255, 25, 25)
								end
							end
						end
					end
				else
					outputChatBox("Player not in a vehicle.", admin, 255, 0, 0)
				end
			end
		end
	end
end
addCommandHandler("setvehtint", setVehTint)

function setVehiclePlate(thePlayer, theCommand, vehicleID, ...)
	if exports.integration:isPlayerTrialAdmin(thePlayer)  then
		if not (vehicleID) or not (...) then
			outputChatBox("SYNTAX: /" .. theCommand .. " [vehicleID] [Text]", thePlayer, 255, 194, 14)
		else
			local theVehicle = exports.pool:getElement("vehicle", vehicleID)
			if theVehicle then
				--if exports['vehicle-system']:hasVehiclePlates(theVehicle) then
					local plateText = table.concat({...}, " ")
					if (exports.vehicleplate:checkPlate(plateText)) then
						local cquery = mysql:query_fetch_assoc("SELECT COUNT(*) as no FROM `vehicles` WHERE `plate`='".. mysql:escape_string(plateText).."'")
						if (tonumber(cquery["no"]) == 0) then
							local insertnplate = mysql:query_free("UPDATE vehicles SET plate='" .. mysql:escape_string(plateText) .. "' WHERE id = '" .. mysql:escape_string(vehicleID) .. "'")
							
							reloadVehicle2(tonumber(vehicleID))
							outputChatBox("Vehicle #"..vehicleID.."'s plate set to: "..plateText, thePlayer)
							addVehicleLogs(vehicleID, theCommand.." "..plateText, thePlayer)
						else
							outputChatBox("This plate is already in use! =( umadbro?", thePlayer, 255, 0, 0)
						end
					else
						outputChatBox("Invalid plate text specified.", thePlayer, 255, 0, 0)
					end
				--else
				--	outputChatBox("This vehicle doesn't have any plates.", thePlayer, 255, 0, 0)
				--end
			else
				outputChatBox("No vehicles with that ID found.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setvehicleplate", setVehiclePlate)
addCommandHandler("setvehplate", setVehiclePlate)

-- Exported
function warpPedIntoVehicle2(player, car, ...)
	local dimension = getElementDimension(player)
	local interior = getElementInterior(player)

	setElementDimension(player, getElementDimension(car))
	setElementInterior(player, getElementInterior(car))
	if warpPedIntoVehicle(player, car, ...) then
		exports.anticheat:changeProtectedElementDataEx(player, "realinvehicle", 1, false)
		return true
	else
		local x,y,z = getElementPosition(car)
		setElementPosition(player, x,y,z+2)
		setElementDimension(player, dimension)
		setElementInterior(player, interior)
	end
	return false
end

function enterCar(thePlayer, commandName, targetPlayerName, targetVehicle, seat)
	if exports.integration:isPlayerTrialAdmin(thePlayer) then
		targetVehicle = tonumber(targetVehicle)
		seat = tonumber(seat)
		if targetPlayerName and targetVehicle then
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, targetPlayerName)
			if targetPlayer then
				local theVehicle = exports.pool:getElement("vehicle", targetVehicle)
				if theVehicle then
					if seat then
						local occupant = getVehicleOccupant(theVehicle, seat)
						if occupant then
							removePedFromVehicle(occupant)
							outputChatBox("Admin " .. getPlayerName(thePlayer):gsub("_", " ") .. " has put " .. targetPlayerName .. " onto your seat.", occupant)
							exports.anticheat:changeProtectedElementDataEx(occupant, "realinvehicle", 0, false)
						end

						if warpPedIntoVehicle2(targetPlayer, theVehicle, seat) then

							outputChatBox("Admin " .. getPlayerName(thePlayer):gsub("_", " ") .. " has warped you into this " .. getVehicleName(theVehicle) .. ".", targetPlayer)
							outputChatBox("You warped " .. targetPlayerName .. " into " .. getVehicleName(theVehicle) .. " #" .. targetVehicle .. ".", thePlayer)
						else
							outputChatBox("Unable to warp " .. targetPlayerName .. " into " .. getVehicleName(theVehicle) .. " #" .. targetVehicle .. ".", thePlayer, 255, 0, 0)
						end
					else
						local found = false
						local maxseats = getVehicleMaxPassengers(theVehicle) or 2
						for seat = 0, maxseats  do
							local occupant = getVehicleOccupant(theVehicle, seat)
							if not occupant then
								found = true
								if warpPedIntoVehicle2(targetPlayer, theVehicle, seat) then
									outputChatBox("Admin " .. getPlayerName(thePlayer):gsub("_", " ") .. " has warped you into this " .. getVehicleName(theVehicle) .. ".", targetPlayer)
									outputChatBox("You warped " .. targetPlayerName .. " into " .. getVehicleName(theVehicle) .. " #" .. targetVehicle .. ".", thePlayer)
								else
									outputChatBox("Unable to warp " .. targetPlayerName .. " into " .. getVehicleName(theVehicle) .. " #" .. targetVehicle .. ".", thePlayer, 255, 0, 0)
								end
								break
							end
						end

						if not found then
							outputChatBox("No free seats.", thePlayer, 255, 0, 0)
						end
					end

					addVehicleLogs(targetVehicle, commandName.." "..targetPlayerName, thePlayer)
				else
					outputChatBox("Vehicle not found", thePlayer, 255, 0, 0)
				end
			end
		else
			outputChatBox("SYNTAX: /" .. commandName .. " [player] [car ID] [seat]", thePlayer, 255, 194, 14)
		end
	end
end
addCommandHandler("entercar", enterCar, false, false)
addCommandHandler("enterveh", enterCar, false, false)
addCommandHandler("entervehicle", enterCar, false, false)

function switchSeat(thePlayer, commandName, seat)
	--if true then
	--	outputChatBox("This command is temporarily disabled.", thePlayer, 255, 0, 0)
	--	return false
	--end
	if not tonumber(seat) then
		outputChatBox("SYNTAX: /" .. commandName .. " [Seat]" ,thePlayer, 255, 194, 14)
	else
		seat = tonumber(seat)
		local theVehicle = getPedOccupiedVehicle(thePlayer)
		if theVehicle then

			local maxSeats = getVehicleMaxPassengers(theVehicle)
			if seat <= maxSeats then
				local occupant = getVehicleOccupant(theVehicle, seat)
				if not occupant then
					if seat == 0 then
						if not getElementData(thePlayer, "license.car.cangetin") and getElementData(theVehicle, "faction") == dmv_faction then
							outputChatBox("(( This DoL vehicle is for the Driving Test only. ))", thePlayer, 255, 194, 14)
							return false
						end

						local job = getElementData(theVehicle, "job")
						if job ~= 0 then -- Fixed your script, Maxime. - Adams
							outputChatBox("(( This vehicle is for Job System only. ))", thePlayer, 255, 194, 14)
							return false
						end
					end

					warpPedIntoVehicle2(thePlayer, theVehicle, seat)
					outputChatBox("You switched into seat "..seat..".", thePlayer, 0, 255, 0)
				else
					outputChatBox("Unable to switch seats.", thePlayer, 255, 0, 0)
				end
			else
				outputChatBox("Unable to switch seats.", thePlayer, 255, 0, 0)
			end
		else
			outputChatBox("Unable to switch seats.", thePlayer, 255, 0, 0)
		end
	end
end
-- addCommandHandler("switchseat", switchSeat, false, false)


function setOdometer(thePlayer, theCommand, unit_, vehicleID, odometer)
	if exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerVMTMember(thePlayer) then
		if not tonumber(unit_) or not tonumber(vehicleID) or not tonumber(odometer) then
			outputChatBox("SYNTAX: /" .. theCommand .. " [1: km/h or 2: mph] [vehicleID] [amount]", thePlayer, 255, 194, 14)
			--outputChatBox("Remember to add three extra digits at the end. If desired odometer value is 222, write 222000", thePlayer, 255, 194, 14)
		else

			unit_ = tonumber(unit_)
			local multiply
			if unit_ == 2 then
				multiply = 1.609 --given in mph, so * 1,609
				outputChatBox("Inputting "..odometer.." mph which is equivalent to "..odometer * multiply.." km/h.", thePlayer, 187, 187, 187)
			elseif unit_ == 1 then
				multiply = 1 --kmh dont multiply
			else
				return outputChatBox("SYNTAX: /" .. theCommand .. " [1: km/h or 2: mph] [vehicleID] [amount]", thePlayer, 255, 194, 14)
			end

			local theVehicle = exports.pool:getElement("vehicle", vehicleID)
			if theVehicle then
				odometer = tonumber(odometer) * multiply
				local maxO = 999999999 * multiply
				if odometer > maxO then
					return outputChatBox("Must be less than "..maxO..".", thePlayer, 255,0,0)
				end

				local oldOdometer = tonumber(getElementData(theVehicle, 'odometer'))
				local actualOdometer = tonumber(odometer) * 1000
				if oldOdometer and exports.mysql:query_free("UPDATE vehicles SET odometer='" .. exports.mysql:escape_string(actualOdometer) .. "' WHERE id = '" .. exports.mysql:escape_string(vehicleID) .. "'") then
					addVehicleLogs(tonumber(vehicleID), "setodometer " .. odometer .. " (from " .. math.floor(oldOdometer/1000) .. ")", thePlayer)

					exports.anticheat:changeProtectedElementDataEx(theVehicle, 'odometer', actualOdometer, false )

					outputChatBox("Vehicle #"..vehicleID.."'s odometer set to " .. odometer .. " KM.", thePlayer, 0, 255, 0)
					exports.discord:sendDiscordMessage("veh-logs", ":1234: **"..getElementData(thePlayer, "account:username").."** changed vehicle ``ID: #" .. vehicleID .. "`` odometer to: **" .. odometer.." km**.")

					for _, v in pairs(getVehicleOccupants(theVehicle)) do
						triggerClientEvent(v, "realism:distance", theVehicle, actualOdometer)
					end
				end
			else
				outputChatBox("No vehicle found with ID "..vehicleID..".", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("setodometer", setOdometer)

function damageproofVehicle(thePlayer, theCommand, theFaggot)
	if exports.integration:isPlayerLeadAdmin(thePlayer) then
		if not (theFaggot) then
			outputChatBox("SYNTAX: /" .. theCommand .. " [Target Player Nick / ID]", thePlayer, 255, 194, 14)
		else
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, theFaggot)
			if not targetPlayer then return end

			local targetVehicle = getPedOccupiedVehicle(targetPlayer)
			if not targetVehicle then
				outputChatBox(targetPlayerName.." is not in a vehicle.", thePlayer, 255, 0, 0)
				return
			end
			if targetVehicle then
				local vehID = getElementData(targetVehicle, "dbid")
				if isVehicleDamageProof(targetVehicle) then
					exports.mysql:query_free("UPDATE `vehicles` SET `bulletproof`='0' WHERE `id`='"..vehID.."'")
					setVehicleDamageProof(targetVehicle, false)
					exports.anticheat:setEld(targetVehicle, "bulletproof", 0 )
					outputChatBox("This vehicle is no longer damageproof.", targetPlayer)
					outputChatBox("Vehicle ID " .. vehID .. " is no longer damageproof.", thePlayer, 255,255,0)
					exports.logs:dbLog(getElementData(thePlayer, "dbid"), 4, targetVehicle, " Removed vehicle damage proof ", "ac")
				else
					setVehicleDamageProof(targetVehicle, true)
					exports.anticheat:setEld(targetVehicle, "bulletproof", 1 )
					exports.mysql:query_free("UPDATE `vehicles` SET `bulletproof`='1' WHERE `id`='"..vehID.."'")
					outputChatBox("This vehicle is now damageproof.", targetPlayer)
					outputChatBox("Vehicle ID " .. vehID .. " is now damageproof.", thePlayer, 0,255,0)
					exports.logs:dbLog(getElementData(thePlayer, "dbid"), 4, targetVehicle, " Enabled vehicle damage proof ", "ac")
				end
			end
		end
	end
end
addCommandHandler("setdamageproof", damageproofVehicle)
addCommandHandler("setbulletproof", damageproofVehicle)
addCommandHandler("sbp", damageproofVehicle)
addCommandHandler("sdp", damageproofVehicle)


function getElementSpeed(theElement, unit)
    -- Check arguments for errors
    assert(isElement(theElement), "Bad argument 1 @ getElementSpeed (element expected, got " .. type(theElement) .. ")")
    local elementType = getElementType(theElement)
    assert(elementType == "player" or elementType == "ped" or elementType == "object" or elementType == "vehicle" or elementType == "projectile", "Invalid element type @ getElementSpeed (player/ped/object/vehicle/projectile expected, got " .. elementType .. ")")
    assert((unit == nil or type(unit) == "string" or type(unit) == "number") and (unit == nil or (tonumber(unit) and (tonumber(unit) == 0 or tonumber(unit) == 1 or tonumber(unit) == 2)) or unit == "m/s" or unit == "km/h" or unit == "mph"), "Bad argument 2 @ getElementSpeed (invalid speed unit)")
    -- Default to m/s if no unit specified and 'ignore' argument type if the string contains a number
    unit = unit == nil and 0 or ((not tonumber(unit)) and unit or tonumber(unit))
    -- Setup our multiplier to convert the velocity to the specified unit
    local mult = (unit == 0 or unit == "m/s") and 50 or ((unit == 1 or unit == "km/h") and 180 or 111.84681456)
    -- Return the speed by calculating the length of the velocity vector, after converting the velocity to the specified unit
    return (Vector3(getElementVelocity(theElement)) * mult).length
end

function setElementSpeed(element, unit, speed)
    local unit    = unit or 0
    local speed   = tonumber(speed) or 0
	local acSpeed = getElementSpeed(element, unit)
	if (acSpeed) then -- if true - element is valid, no need to check again
		local diff = speed/acSpeed
		if diff ~= diff then return false end -- if the number is a 'NaN' return false.
        local x, y, z = getElementVelocity(element)
		return setElementVelocity(element, x*diff, y*diff, z*diff)
	end

	return false
end



-- Testing: check respawn positions
-- local testRespawnPos = false

-- addEventHandler( "onElementDataChange", root, 
-- function (theKey, oldValue, newValue) 
-- 	if theKey == "respawnposition" and testRespawnPos then
-- 		local dbid = getElementData(source, "dbid") or "?"
-- 		if type(newValue) == "table" then
-- 			local x,y,z,rx,ry,rz = unpack(newValue)
-- 			outputChatBox("[#"..dbid.."] New respawn position ("..x..","..y..","..z..", "..rx..","..ry..","..rz..")")
-- 		else
-- 			outputChatBox("[#"..dbid.."] New respawn position ("..tostring(newValue)..")")
-- 		end
-- 	end
-- end)

-- function testRespawnPositions(thePlayer, cmd)
-- 	if not exports.integration:isPlayerScripter(thePlayer) then return end
-- 	testRespawnPos = not testRespawnPos
-- 	outputChatBox("Testing vehicle respawn positions: "..(testRespawnPos and "YES" or "NO"), thePlayer,255,126,0)
-- end
-- addCommandHandler("trp", testRespawnPositions, false, false)

-- Auto cleanup of temp vehicles
-- Fernando 01/11/2021

addEventHandler( "onElementDestroy", root, 
function ()
	if getElementType(source) ~= "vehicle" then return end
	if vehiclesSpawnedHere[source] then
		vehiclesSpawnedHere[source] = nil
	end
end)

addEventHandler( "onResourceStop", resourceRoot, 
function (stoppedResource, wasDeleted)
	for veh,_  in pairs(vehiclesSpawnedHere) do
		destroyElement(veh)
	end
end)

-------


function vPrices(thePlayer, cmd, updown, perc)
	if exports.integration:isPlayerScripter(thePlayer)
	or exports.integration:isPlayerLeadAdmin(thePlayer) then

		local function showOutput()
			outputChatBox("SYNTAX: /"..cmd.." [1: Increase, 2: Decrease] [Percentage number]", thePlayer ,255,194,14)
		end

		if not updown or not tonumber(updown) then
			showOutput()
			return
		end
		updown = tonumber(updown)

		if not perc or not tonumber(perc) then
			showOutput()
			return
		end
		perc = tonumber(perc)


		if updown < 1 or updown > 2 then
			outputChatBox("Please enter Increase (1) or Decrease (2) before the percentage.", thePlayer, 255, 0, 0)
			showOutput()
			return
		end

		if perc <= 0 or perc >= 50 then
			outputChatBox("Percentage must be positive and smaller than 50.", thePlayer, 255, 0, 0)
			showOutput()
			return
		end
		
		outputChatBox("Updating vehlib prices, please wait...", thePlayer, 187,187,187)

		local worked = false

		mQuery1 = mysql:query("SELECT `id`, `vehprice` FROM `vehicles_shop`")
		while true do
			local row = mysql:fetch_assoc(mQuery1)
			if not row then break end

			local id = tonumber(row["id"])
			local oldprice = tonumber(row["vehprice"])

			local newprice
			if updown == 1 then
				newprice = oldprice + ((oldprice * perc)/100)
			else
				newprice = oldprice - ((oldprice * perc)/100)
			end
			newprice = exports.global:roundNumber(newprice)

			if newprice and mysql:query("UPDATE vehicles_shop SET vehprice = "..newprice.." WHERE id = "..id.."") then
				worked = true
			end
		end
		if worked then
			if updown == 1 then
				outputChatBox("Increased all vehicle prices of "..perc.."%.", thePlayer, 0,255,126)
			else
				outputChatBox("Decreased all vehicle prices of "..perc.."%.", thePlayer, 0,255,0)
			end
		else
			outputChatBox("Error updating vehicle taxes.", thePlayer, 255,0,0)
		end
	end
end
addCommandHandler("vprices", vPrices, false, false)
addCommandHandler("vehprices", vPrices, false, false)

function taxes(thePlayer, cmd, perc)
	if exports.integration:isPlayerScripter(thePlayer)
	or exports.integration:isPlayerLeadAdmin(thePlayer) then

		local function showOutput()
			outputChatBox("SYNTAX: /"..cmd.." [Percentage number]", thePlayer ,255,194,14)
			outputChatBox("Sets all vehicle taxes to values that are percentages of the dealership prices.", thePlayer ,255,126,14)
		end

		if not perc or not tonumber(perc) then
			showOutput()
			return
		end
		perc = tonumber(perc)


		if perc <= 0 or perc >= 10 then
			outputChatBox("Percentage must be positive and smaller than 10.", thePlayer, 255, 0, 0)
			showOutput()
			return
		end

		outputChatBox("Updating vehlib taxes, please wait...", thePlayer, 187,187,187)

		local worked = false

		mQuery1 = mysql:query("SELECT `id`, `vehprice`, `vehtax` FROM `vehicles_shop`")
		while true do
			local row = mysql:fetch_assoc(mQuery1)
			if not row then break end

			local id = tonumber(row["id"])
			local price = tonumber(row["vehprice"])

			local tax = exports.global:roundNumber((price * perc)/100)
			if mysql:query("UPDATE vehicles_shop SET vehtax = "..tax.." WHERE id = "..id.."") then
				worked = true
			end
		end
		if worked then
			outputChatBox("Updated all vehicle taxes to "..perc.."% of the price.", thePlayer, 0,255,0)
		else
			outputChatBox("Error updating vehicle taxes.", thePlayer, 255,0,0)
		end
	end
end
addCommandHandler("vtaxes", taxes, false, false)
addCommandHandler("vehtaxes", taxes, false, false)
