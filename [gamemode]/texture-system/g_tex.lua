-------------------------------- Fernando --------------------------------

local cacheFolder = "sarp_cache/"
local fileExt = ".sarp"

cacheFileNameServer = cacheFolder.."%s"..fileExt
cacheFileName = "@"..cacheFolder.."%s"..fileExt

listFilePath = "@"..cacheFolder.."file_list.xml"
rootNodeName, entryNodeName = "list", "file"


function hasWorldEditPerm(thePlayer)
	if not isElement(thePlayer) then
		thePlayer = getLocalPlayer()
	end

	if ((exports.integration:isPlayerTrialAdmin(thePlayer) and exports.global:isAdminOnDuty(thePlayer))
		or (exports.integration:isPlayerScripter(thePlayer) and exports.global:isStaffOnDuty(thePlayer))
		or (exports.integration:isPlayerFMTLeader(thePlayer) and exports.global:isFMTOnDuty(thePlayer))
		or (exports.integration:isPlayerMTMember(thePlayer) and exports.global:isMTOnDuty(thePlayer))) then
		return true
	end


	return false
end


function legitimateOwner(player, interiorID)

	local vehicleInteriorOwned = false

	if interiorID > 20000 then

		local vdbid = interiorID - 20000


		local theVehicle  = nil

		for i,c in ipairs(getElementsByType("vehicle")) do
			if (getElementData(c, "dbid") == tonumber(vdbid)) then
				theVehicle = c
				break
			end
		end

		if theVehicle then

			local faction = getElementData(theVehicle, "faction") or 0
			local owner = getElementData(theVehicle, "owner") or 0

			if faction > 0 then
				vehicleInteriorOwned = exports["faction-system"]:isPlayerFactionLeader(player, faction)
			else
				vehicleInteriorOwned = getElementData(player, "dbid") == owner or exports.global:hasItem ( player, 3, vdbid )
			end
		end
	end

	local interiorOwned = false

	for i,c in ipairs(getElementsByType("interior")) do
		if getElementData(c,"dbid") == interiorID then
			local status = getElementData(c, "status")
			if status then
				local faction = status.faction or 0
				local owner = status.owner or 0

				if faction > 0 then
					interiorOwned = exports["faction-system"]:isPlayerFactionLeader(player, faction)
				else
					interiorOwned = (getElementData(player, "dbid")==owner) or exports.global:hasItem ( player, 4, interiorID ) or exports.global:hasItem ( player, 5, interiorID )
				end
			end
		end
	end

	-- outputDebugString("debug- owns int: "..(interiorOwned and "yes" or "no"))
	-- outputDebugString("debug- owns veh: "..(vehicleInteriorOwned and "yes" or "no"))

	return (interiorID >= 1 and (interiorOwned or vehicleInteriorOwned))
end
