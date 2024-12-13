dmv_sgn = {}

learnerOffs = {
	[445]= {0, -0.45, 0.92, 0, 0, 90},--admiral
	[547]= {0, -0.3, 0.98, 0, 0, 90},--primo
	[410]= {0, -0.3, 0.99, 0, 0, 90},--manana
	[458]= {0, -0.3, 0.83, 0, 0, 90},--solair
	[405]= {0, -0.3, 0.845, 0, 0, 90},--sentinel
	[516]= {0, -0.3, 0.956, 0, 0, 90},--nebula
	[579]= {0, -0.48, 1.335, 0, 0, 90},--huntley

}

addEvent("dmv:addSign", true)
function addLearnerSign(exploded)

		if getElementType( source ) == "vehicle" then
			local id = getElementModel(source)
			if learnerOffs[id] ~= nil then
				if exports.global:hasItem(source, 274) then
					if dmv_sgn[source] ~= nil then
						destroyElement(dmv_sgn[source])
						dmv_sgn[source] = nil
					end
					if dmv_sgn[source] == nil then
						local x, y, z, rx, ry, rz =  getElementPosition(source)
						local dim = getElementDimension(source)
						local int = getElementInterior(source)
						light = createObject (3897, x, y, z)
						setElementData(light, "pd-aobject", true)
						--setObjectScale(light, 1.1)
						setElementDimension(light, dim)
						setElementInterior(light, int)
						attachElements(light, source, unpack(learnerOffs[id]))
						dmv_sgn[source] = light
						setElementCollisionsEnabled(light, false)
					end
				else
					if dmv_sgn[source] ~= nil then
						destroyElement(dmv_sgn[source])
						dmv_sgn[source] = nil
					end
				end
			end
		end

end
addEventHandler("dmv:addSign", getRootElement(), addLearnerSign)
addEventHandler("onVehicleRespawn", getRootElement(), addLearnerSign)
addEventHandler("pd-refreshAttachments", root, addLearnerSign)

function addSignDMVOnStart()
	local vehicles = exports.pool:getPoolElementsByType("vehicle")
	for k, arrayVehicle in ipairs(vehicles) do
		triggerEvent("dmv:addSign", arrayVehicle)
	end
end

addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()),
 function()
	 setTimer (addSignDMVOnStart, 5000, 1)
end
)

function destroySignDMVOnVehicleDestroy()
	if (getElementType(source) == "vehicle") then
		if dmv_sgn[source] ~= nil then
			destroyElement(dmv_sgn[source])
			dmv_sgn[source] = nil
		end
	end
end
addEventHandler("onElementDestroy", getRootElement(), destroySignDMVOnVehicleDestroy)

function destroySignDMVOnVehicleExplode()
        if dmv_sgn[source] ~= nil then
            destroyElement(dmv_sgn[source])
            dmv_sgn[source] = nil
        end
end
addEventHandler("onVehicleExplode", getRootElement(), destroySignDMVOnVehicleExplode)
