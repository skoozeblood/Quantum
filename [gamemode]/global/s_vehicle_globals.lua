function getVehiclesOwnedByCharacter(thePlayer)
	local dbid = tonumber(getElementData(thePlayer, "dbid"))
	
	local carids = { }
	local numcars = 0
	local indexcars = 1
	for key, value in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
		local owner = tonumber(getElementData(value, "owner"))

		if (owner) and (owner==dbid) then
			local id = getElementData(value, "dbid")
			carids[numcars+1] = id
			numcars = numcars + 1
		end
	end
	return numcars, carids
end

function canPlayerBuyVehicle(thePlayer)
	if (isElement(thePlayer)) then
		if getElementData(thePlayer, "loggedin") == 1 then
			local maxvehicles = getElementData(thePlayer, "maxvehicles") or 0
			local novehicles, veharray = getVehiclesOwnedByCharacter(thePlayer)
			if (novehicles < maxvehicles) then
				return true
			end
			return false, "Too much vehicles" 
			
		end
		return false, "Player not logged in"
	end
	return false, "Element not found"
end

function createVehicleNew(model, x,y,z, rx,ry,rz, plate)
	local moddedVehicles = getElementData(getRootElement(), "moddedVehicles") or {}
	for k, v in pairs(moddedVehicles) do

		local _model = v.modelid
		local name = v.title

		if tonumber(_model) == tonumber(model) then
			local base = v.basemodel
			local veh = exports.vehicle_load:createVehicleHere(base, x,y,z, rx,ry,rz, plate)
			if veh then

				setElementData(veh, vehDatas.model, model)
				setElementData(veh, vehDatas.base, base)
				setElementData(veh, vehDatas.name, name)
				
				return veh
			else
				return false
			end
		end
	end
	return exports.vehicle_load:createVehicleHere(model, x,y,z, rx,ry,rz, plate)
end