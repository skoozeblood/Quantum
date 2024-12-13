rambar = {}
BarvehOffsets = {
	[596]= {0, 2.37, -0.18, 0, 0, 0},--police ls
	[598]= {0, 2.5, -0.14, 0, 0, 0},--police lv
	[579]= {0, 2.4, -0.038, 0, 0, 0},--huntley
	[402]= {0, 2.5, -0.21, 0, 0, 0},--buffalo
	[490]= {0, 3.16, -0.038, 0, 0, 0},--fbi rancher
	[489]= {0, 2.59, -0.02, 0, 0, 0},--normal rancher
	[552]= {0, 3.1, 0.3, 0, 0, 0},--utility van (pickup mod)
}

function rescale(id, dabar)
	if id == 426 then
		setObjectScale(dabar, 1.06)
	elseif id == 579 then
		setObjectScale(dabar, 1.076)
	elseif id == 490 or id == 489 then --ranchers
		setObjectScale(dabar, 1.16)
	elseif id == 552 then
		setObjectScale(dabar, 1.11)
	elseif id == 598 then
		setObjectScale(dabar, 1.076)
	end
end

addEvent("police:adddabarBar", true)
function adddabarBar(exploded)

		if getElementType( source ) == "vehicle" then
			local id = getElementModel(source)
			if BarvehOffsets[id] ~= nil then
				if exports.global:hasItem(source, 271) then
					if rambar[source] ~= nil then
						destroyElement(rambar[source])
						rambar[source] = nil
					end
					if rambar[source] == nil then
						local dim = getElementDimension(source)
						local int = getElementInterior(source)
						local x, y, z, rx, ry, rz =  getElementPosition(source)
						local dabar = createObject (1860, x, y, z)
					setElementData(dabar, "pd-aobject", true)
						rescale(id, dabar)
						setElementDimension(dabar, dim)
						setElementInterior(dabar, int)
						attachElements(dabar, source, unpack(BarvehOffsets[id]))
						rambar[source] = dabar
						setElementCollisionsEnabled(dabar, false)
					end
				else
					if rambar[source] ~= nil then
						destroyElement(rambar[source])
						rambar[source] = nil
					end
				end
			end
		end

end
addEventHandler("police:adddabarBar", getRootElement(), adddabarBar)
addEventHandler("onVehicleRespawn", getRootElement(), adddabarBar)
addEventHandler("onVehicleCreated", root, adddabarBar)--event added in global/s_vehicle_globals.lua

function adddabarBarOnStart()
	local vehicles = exports.pool:getPoolElementsByType("vehicle")
	for k, arrayVehicle in ipairs(vehicles) do
		triggerEvent("police:adddabarBar", arrayVehicle)
	end
end

addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()),
    function()
        setTimer (adddabarBarOnStart, 5000, 1)
	end
)

function destroydabarOnVehicleDestroy()
    if (getElementType(source) == "vehicle") then
        if rambar[source] ~= nil then
            destroyElement(rambar[source])
            rambar[source] = nil
        end
    end
end
addEventHandler("onElementDestroy", getRootElement(), destroydabarOnVehicleDestroy)

function destroydabarOnVehicleExplode()
    if rambar[source] ~= nil then
        destroyElement(rambar[source])
        rambar[source] = nil
    end
end
addEventHandler("onVehicleExplode", getRootElement(), destroydabarOnVehicleExplode)
