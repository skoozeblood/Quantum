local mysql = exports.mysql

fuellessVehicle = { [594]=true, [537]=true, [538]=true, [569]=true, [590]=true, [606]=true, [607]=true, [610]=true, [590]=true, [569]=true, [611]=true, [584]=true, [608]=true, [435]=true, [450]=true, [591]=true, [472]=true, [473]=true, [493]=true, [595]=true, [484]=true, [430]=true, [453]=true, [452]=true, [446]=true, [454]=true, [497]=true, [509]=true, [510]=true, [481]=true }

function syncFuelOnEnter(thePlayer)
	triggerClientEvent(thePlayer, "syncFuel", source, tonumber(getElementData(source, "fuel")))
end
addEventHandler("onVehicleEnter", getRootElement(), syncFuelOnEnter)

function fuelDepleting()
	local vehicles = getElementsByType("vehicle")
	for k, veh in ipairs(vehicles) do
		local model = getElementModel(veh)
		if not (fuellessVehicle[model]) then
			local engine = getElementData(veh, "engine")
			if engine == 1 then
				local fuel = getElementData(veh, "fuel")
				if fuel > 0 then
					local oldx = getElementData(veh, "oldx")
					local oldy = getElementData(veh, "oldy")
					local oldz = getElementData(veh, "oldz")
					local olddim = getElementData(veh, "olddim")

					local x, y, z = getElementPosition(veh)
					local dim = getElementDimension(veh)

					local ignore = (dim ~= olddim) --or math.abs(oldy - y) > 3000 or math.abs(oldx - x) > 3000

					if not ignore then
						local distance = getDistanceBetweenPoints2D(x, y, oldx, oldy)
						if (distance < 10) then
							distance = 6  -- fuel leaking away when not moving
						end
						local handlingTable = getModelHandling(model)
						local mass = handlingTable["mass"]

						newFuel = ((distance/800) + (mass/20000))
						newFuel = fuel - ((newFuel/100)*getMaxFuel(model))

						exports.anticheat:changeProtectedElementDataEx(veh, "fuel", newFuel, false)

						local controller = getVehicleController(veh)
						local driver = (controller and getElementType(controller)=="player") and controller or false

						local newfuelperc = math.floor((tonumber(newFuel)/getMaxFuel(veh))*100)
						if newfuelperc < 1 then
							newFuel = 0
							setVehicleEngineState(veh, false)
							exports.anticheat:changeProtectedElementDataEx(veh, "engine", 0, true)
							exports.anticheat:changeProtectedElementDataEx(veh, "vehicle:radio", 0, true)
							exports.anticheat:changeProtectedElementDataEx(veh, "fuel", 0, false)
							if driver then toggleControl(driver, 'brake_reverse', false) end
						end
						if driver then
							triggerClientEvent(driver, "syncFuel", veh, newFuel)
						end
					end
					exports.anticheat:changeProtectedElementDataEx(veh, "oldx", x, false)
					exports.anticheat:changeProtectedElementDataEx(veh, "oldy", y, false)
					exports.anticheat:changeProtectedElementDataEx(veh, "oldz", z, false)
					exports.anticheat:changeProtectedElementDataEx(veh, "olddim", dim, false)
				end
			end
		end
	end
end
setTimer(fuelDepleting, 30000, 0)
