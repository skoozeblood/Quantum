-- Fernando / May 2020
tow_hk = {}

towHookOffs = {
	[552]= {0.05, -2.55, -0.08, 0, 95, 90},--utility van (modded pickup)
	[505]= {0.05, -2.84, -0.46, 0, 90, 90},--samoa (Rancher Lure)
	[599]= {0.05, -2.15, -0.55, 0, 80, 90},--(Police Ranger)
	[470]= {0.05, -2.5, -0.62, 0, 80, 90},--(Patriot)
	[490]= {0.05, -3, -0.4, 0, 70, 90},--(FBI Rancher)

}

addEvent("veh:addTowHook", true)
function addTowHook(exploded)
		if getElementType( source ) == "vehicle" then
			local id = getElementModel(source)
			if towHookOffs[id] ~= nil then
				if exports.global:hasItem(source, 130) or id == 552 then
					if tow_hk[source] ~= nil then
						destroyElement(tow_hk[source])
						tow_hk[source] = nil
					end
					if tow_hk[source] == nil then
						local x, y, z, rx, ry, rz =  getElementPosition(source)
						local dim = getElementDimension(source)
						local int = getElementInterior(source)
						obj = createObject (16332, x, y, z)
						setObjectScale(obj, 1.1)
						setElementDoubleSided(obj, true)
						setElementDimension(obj, dim)
						setElementInterior(obj, int)
						attachElements(obj, source, unpack(towHookOffs[id]))
						tow_hk[source] = obj
						setElementCollisionsEnabled(obj, false)
					setElementData(obj, "pd-aobject", true)
					end
				else
					if tow_hk[source] ~= nil then
						destroyElement(tow_hk[source])
						tow_hk[source] = nil
					end
				end
			end
		end

end
addEventHandler("veh:addTowHook", getRootElement(), addTowHook)
addEventHandler("onVehicleRespawn", getRootElement(), addTowHook)
addEventHandler("onVehicleCreated", root, addTowHook)--event added in global/s_vehicle_globals.lua

function addTowHookOnStart()
	local vehicles = exports.pool:getPoolElementsByType("vehicle")
	for k, arrayVehicle in ipairs(vehicles) do
		triggerEvent("veh:addTowHook", arrayVehicle)
	end
end

addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()),
 function()
	 setTimer(addTowHookOnStart, 1000, 1)
end
)

function destroySignDMVOnVehicleDestroy()
	if (getElementType(source) == "vehicle") then
		if tow_hk[source] ~= nil then
			destroyElement(tow_hk[source])
			tow_hk[source] = nil
		end
	end
end
addEventHandler("onElementDestroy", getRootElement(), destroySignDMVOnVehicleDestroy)

function destroySignDMVOnVehicleExplode()
        if tow_hk[source] ~= nil then
                destroyElement(tow_hk[source])
                tow_hk[source] = nil
        end
end
addEventHandler("onVehicleExplode", getRootElement(), destroySignDMVOnVehicleExplode)
