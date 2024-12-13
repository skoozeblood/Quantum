pushb = {}
pushOffs = {
[596]= {0, 2.31, -0.18, 0, 0, 0},--police ls
[598]= {0, 2.33, -0.1, 0, 0, 0},--police lv
[560]= {0, 2.46, -0.135, 0, 0, 0},--sultan
[402]= {0, 2.46, -0.16, 0, 0, 0},--buffalo
[579]= {0, 2.225, -0.085, 0, 0, 0},--huntley
[552]= {0, 3.1, 0.3, 0, 0, 0},--utility van
}
addEvent("police:addpushbarBar", true)
function addpushbarBar(exploded)
	if getElementType( source ) == "vehicle" then
		local id = getElementModel(source)
		if pushOffs[id] ~= nil then
			if exports.global:hasItem(source, 273) then
				if pushb[source] ~= nil then
					destroyElement(pushb[source])
					pushb[source] = nil
				end
				if pushb[source] == nil then
					local dim = getElementDimension(source)
					local int = getElementInterior(source)
					local x, y, z, rx, ry, rz =  getElementPosition(source)
					local pushbar = createObject (1858, x, y, z)

					setElementData(pushbar, "pd-aobject", true)
					if getElementModel(source) == 579 then
						setObjectScale(pushbar, 1.15)
					end
					setElementDimension(pushbar, dim)
					setElementInterior(pushbar, int)
					pushb[source] = pushbar
					setElementCollisionsEnabled(pushbar, false)
					attachElements(pushbar, source, unpack(pushOffs[id]))
				end
			else
				if pushb[source] ~= nil then
					destroyElement(pushb[source])
					pushb[source] = nil
				end
			end
		end
	end
end
addEventHandler("police:addpushbarBar", getRootElement(), addpushbarBar)
addEventHandler("onVehicleRespawn", getRootElement(), addpushbarBar)
addEventHandler("onVehicleCreated", root, addpushbarBar)--event added in global/s_vehicle_globals.lua

function addpushbarBarOnStart()
	local vehicles = exports.pool:getPoolElementsByType("vehicle")
	for k, arrayVehicle in ipairs(vehicles) do
		triggerEvent("police:addpushbarBar", arrayVehicle)
	end
end

addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()),
    function()
        setTimer (addpushbarBarOnStart, 500, 1)
	end
)

function destroypushbarOnVehicleDestroy()
    if (getElementType(source) == "vehicle") then
        if pushb[source] ~= nil then
            destroyElement(pushb[source])
            pushb[source] = nil
        end
    end
end
addEventHandler("onElementDestroy", getRootElement(), destroypushbarOnVehicleDestroy)

function destroypushbarOnVehicleExplode()
    if pushb[source] ~= nil then
        destroyElement(pushb[source])
        pushb[source] = nil
    end
end
addEventHandler("onVehicleExplode", getRootElement(), destroypushbarOnVehicleExplode)