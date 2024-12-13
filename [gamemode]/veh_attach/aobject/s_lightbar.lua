l_bar = {}
vehOffsets = {

[596]= {0, 1.65, -0.35, 90, 0, 0},--pls
[598]= {0, 1.65, -0.35, 90, 0, 0},--plv
[560]= {0, 1.88, -0.365, 90, 0, 0},--sultan
[490]= {0, 2.2, -0.11, 90, 0, 0},--fbi rancher
-- [402]= {0, 1.3, -0.44, 0, 0, 0},--buffalo
[579]= {0, 1.5, 0.04, 90, 0, 0},--huntley
[552]= {0, 2.5, 0.15, 90, 0, 0},--utility van (pickup modded)
-- [599]= {0, 2.3, -0.27, 0, 0, 0},--prgr


}


local newObj = 3900

addEvent("police:addLightBar", true)
function addLightBar(exploded)

		if getElementType( source ) == "vehicle" then
			local id = getElementModel(source)
			if vehOffsets[id] ~= nil then
				if exports.global:hasItem(source, 278) then
					if l_bar[source] ~= nil then
						destroyElement(l_bar[source])
						l_bar[source] = nil
					end
					if l_bar[source] == nil then
						local dim = getElementDimension(source)
						local int = getElementInterior(source)
						local light = createObject (newObj, 0,0,-5)
						setElementData(light, "pd-aobject", true)
						setElementDimension(light, dim)
						setElementInterior(light, int)

						local x,y,z,rx,ry,rz = unpack(vehOffsets[id])

						if id == 560 then
							setObjectScale(light, 0.9)
						elseif id == 402 then
							setObjectScale(light, 0.9)
						elseif id == 552 then
							setObjectScale(light, 1.2)
						end

						-- setObjectScale(light, 1.15)

						y = y - 1.85
						z = z + 1.23
						-- rz = 180

						attachElements(light, source, x,y,z,rx,ry,rz)
						l_bar[source] = light
						setElementCollisionsEnabled(light, false)
					end
				else
					if l_bar[source] ~= nil then
						destroyElement(l_bar[source])
						l_bar[source] = nil
					end
				end
			end
		end

end
addEventHandler("police:addLightBar", getRootElement(), addLightBar)
addEventHandler("onVehicleRespawn", getRootElement(), addLightBar)
addEventHandler("onVehicleCreated", root, addLightBar)--event added in global/s_vehicle_globals.lua

-- fix for sometimes it having collision for no reason
-- and bugging your camera
-- Fernando
addEventHandler( "onVehicleEnter", getRootElement(),
function (thePlayer, seat, jacked)
	if l_bar[source] then
		setElementCollisionsEnabled(l_bar[source], false)
	end
end)


function addLightBarOnStart()
	local vehicles = exports.pool:getPoolElementsByType("vehicle")
	for k, arrayVehicle in ipairs(vehicles) do
		triggerEvent("police:addLightBar", arrayVehicle)
	end
end

addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()),
    function()
        setTimer (addLightBarOnStart, 1000, 1)
	end
)

function destroyLightOnVehicleDestroy()
    if (getElementType(source) == "vehicle") then
        if l_bar[source] ~= nil then
            destroyElement(l_bar[source])
            l_bar[source] = nil
        end
    end
end
addEventHandler("onElementDestroy", getRootElement(), destroyLightOnVehicleDestroy)

function destroyLightOnVehicleExplode()
    if l_bar[source] ~= nil then
        destroyElement(l_bar[source])
        l_bar[source] = nil
    end
end
addEventHandler("onVehicleExplode", getRootElement(), destroyLightOnVehicleExplode)
