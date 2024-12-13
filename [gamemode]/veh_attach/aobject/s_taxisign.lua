pl_bar = {}

--taxi signs by Fernando
PolicevehOffsets = {
	[579]= {0, 0, 1.285, 0, 0, 90},--huntley
	[596]= {0, -0.08, 0.905, 0, 0, 90},--police ls
	[426]= {0, -0.08, 0.905, 0, 0, 90},--premier
	[479]= {0, -0.08, 1.03, 0, 0, 90},--regina
	[516]= {0, -0.08, 0.915, 0, 0, 90},--nebula
	[560]= {0, 0.2, 0.885, 0, 0, 90},--sultan
	[445]= {0, 0.04, 0.885, 0, 0, 90},--admiral
	[418]= {0, 0.6, 1.07, 0, 0, 90},--moonbeam
	[580]= {0, 0.3, 1.11, 0, 0, 90},--stafford
	[551]= {0, -0.05, 0.943, 0, 4, 90},--merit
	[585]= {0, -0.4, 1.065, 0, 0, 90},--emperor
	[492]= {0, -0.4, 0.93, 0, 0, 90},--greenwood
	[490]= {0, 0.15, 1.15, 0, 0, 90},--fbi rancher
	[466]= {0, -0.3, 0.92, 0, 0, 90},--glendale
	[561]= {0, -0.45, 0.88, 0, 0, 0},--stratum
	[507]= {0, -0.45, 0.865, 0, 0, 90},--elegant
	[421]= {0, -0.3, 0.77, 0, 0, 90},--washington
	[566]= {0, -0.3, 0.908, 0, 0, 90},--tahoma
	[405]= {0, -0.25, 0.8, 0, 0, 90},--sentinel
	[420]= {0, 0.05, 0.8745, 0, 4, 90},--taxi (sedan mod)
	[438]= {0, 0.65, 0.84, 0, 0, 90},--cabbie (civilian cabbie)
	[540]= {0, 0, 0.822, 0, 0, 90},--vincent
	[547]= {0, 0, 0.955, 0, 0, 90},--primo
	[404]= {0, 0, 0.99, 0, 0, 90},--perennial
	[458]= {0, -0.2, 0.796, 0, 0, 90},--solair


	[596]= {0, 0, 0.87, 0, 0, 90},--police LS -> works
	[597]= {0, 0, 0.87, 0, 0, 90},--police SF -> works
	[598]= {0, 0, 0.91, 0, 0, 90},--police LV
	[599]= {0, 0, 0.97, 0, 0, 90},--police hunter

}


--exported
function isTaxiSignCompatible(theVehicle)
	return PolicevehOffsets[getElementModel(theVehicle)]
end
--exported
function getTaxiSignOffs()
	return PolicevehOffsets
end

addEvent("taxi:addSign", true)
function addTaxiSign(exploded)
		if getElementType( source ) == "vehicle" then
			local id = getElementModel(source)
			if PolicevehOffsets[id] ~= nil then
				if exports.global:hasItem(source, 275) or exports.global:hasItem(source, 276) then
					if pl_bar[source] ~= nil then
						destroyElement(pl_bar[source])
						pl_bar[source] = nil
					end
					if pl_bar[source] == nil then
						local x, y, z, rx, ry, rz =  getElementPosition(source)
						local dim = getElementDimension(source)
						local int = getElementInterior(source)
						if exports.global:hasItem(source, 276) then
							light = createObject (3893, x, y, z)
						elseif exports.global:hasItem(source, 275) then
							light = createObject (3894, x, y, z)
						end
					setElementData(light, "pd-aobject", true)
						setObjectScale(light, 0.7)
						setElementDimension(light, dim)
						setElementInterior(light, int)
						attachElements(light, source, unpack(PolicevehOffsets[id]))
						pl_bar[source] = light
						setElementCollisionsEnabled(light, false)
					end
				else
					if pl_bar[source] ~= nil then
						destroyElement(pl_bar[source])
						pl_bar[source] = nil
					end
				end
			end
		end

end
addEventHandler("taxi:addSign", getRootElement(), addTaxiSign)
addEventHandler("onVehicleRespawn", getRootElement(), addTaxiSign)
addEventHandler("onVehicleCreated", root, addTaxiSign)--event added in global/s_vehicle_globals.lua

function addSignBarOnStart()
	local vehicles = exports.pool:getPoolElementsByType("vehicle")
	for k, arrayVehicle in ipairs(vehicles) do
		triggerEvent("taxi:addSign", arrayVehicle)
	end
end

addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()),
    function()
        setTimer (addSignBarOnStart, 500, 1)
	end
)

function destroySignOnVehicleDestroy()
    if (getElementType(source) == "vehicle") then
        if pl_bar[source] ~= nil then
            destroyElement(pl_bar[source])
            pl_bar[source] = nil
        end
    end
end
addEventHandler("onElementDestroy", getRootElement(), destroySignOnVehicleDestroy)

function destroySignOnVehicleExplode()
    if pl_bar[source] ~= nil then
        destroyElement(pl_bar[source])
        pl_bar[source] = nil
    end
end
addEventHandler("onVehicleExplode", getRootElement(), destroySignOnVehicleExplode)

function taxiVehicles(thePlayer, commandName)
	outputChatBox("You can install a taxi sign on any 4-door vehicle.", thePlayer, 255, 194, 14)
end
addCommandHandler("taxiveh", taxiVehicles, false, false)
addCommandHandler("taxivehs", taxiVehicles, false, false)
