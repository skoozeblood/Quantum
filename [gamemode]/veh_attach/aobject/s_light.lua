leite = {}
LIGHTvehOffsets = {
	[490]= {0.5, 1.2, 0.6, 0, 0, 0},
	[426]= {0.5, 0.8, 0.35, 0, 0, 0},
	[596]= {0.5, 0.8, 0.35, 0, 0, 0},
	[597]= {0.5, 0.8, 0.35, 0, 0, 0},
	[598]= {-0.5, -1.54, 0.43, 0, 0, 0},
	--[598]= {0.5, 0.75, 0.4, 0, 0, 0},
	[560]= {0.45, 0.85, 0.4, 0, 0, 0},
	[579]= {0.55, 0.6, 0.6, 0, 0, 0},
	[400]= {-0.55, 0.4, 1.02, 0, 0, 0},
	[445]= {0.5, 0.65, 0.38, 0, 0, 0},
}


function togglePoliceLight(player_)

	local veh, player

	if player_ and isElement(player_) and getElementType(player_)=="player" then

		player = player_
		if (getElementData(player, "restrain") or 0) == 1 then
			return
		end

		veh = getPedOccupiedVehicle(player)
	end

	if source and isElement(source) and getElementType(source)=="vehicle" then
		-- triggered by event
		player = false
		veh = source

		if getElementData(veh, "plight") then
			setElementData(veh, "plight", false)
			if isElement(leite[veh]) then destroyElement(leite[veh]) end
		else
			return
		end
	end

	if veh then

		local id = getElementModel(veh)
		if exports.global:hasItem(veh, 61) then
			if LIGHTvehOffsets[id] ~= nil then
				if getElementData(veh, "plight") then

					if isElement(leite[veh]) then destroyElement(leite[veh]) end
					leite[veh] = nil

					setElementData(veh, "plight", false)

					if player then
						outputConsole("Police light turned off.", player)
					end
				else
					local dim = getElementDimension(veh)
					local int = getElementInterior(veh)
					local x, y, z, rx, ry, rz =  getElementPosition(veh)
					local light = createObject (1936, x, y, z)
					setElementDimension(light, dim)
					setElementInterior(light, int)
					attachElements(light, veh, unpack(LIGHTvehOffsets[id]))
					leite[veh] = light
					setElementCollisionsEnabled(light, false)
					setElementData(veh, "plight", true)
					setElementData(light, "pd-aobject", true)

					if player then
						outputConsole("Police light turned on.", player, 0,255,0)
					end
				end
			else
				if player then
					outputChatBox("There's no police light positioned for this vehicle yet :( Contact Fernando.", player, 255, 0 ,0)
				end
			end
		end
	end
end
addCommandHandler("toglight", togglePoliceLight)

function destroyPLightOnVehicleDestroy()
        if (getElementType(source) == "vehicle") then
            if leite[source] ~= nil then
				destroyElement(leite[source])
				leite[source] = nil
            end
        end
end
addEventHandler("onElementDestroy", getRootElement(), destroyPLightOnVehicleDestroy)

function destroyPLightOnVehicleExplode()
        if leite[source] ~= nil then
			destroyElement(leite[source])
			leite[source] = nil
        end
end
addEventHandler("onVehicleExplode", getRootElement(), destroyPLightOnVehicleExplode)
