spotl = {}
SpotlOFFSETS = {
	[560]= {-0.065, 0.81, 0.475, 0, 0, 0},--sultan
	[579]= {-0.13, 0.53, 0.6, 0, 0, -10},--huntley
	[598]= {-0.06, 0.73, 0.475, 0, 0, 0},--police lv
	[596]= {-0.0835, 0.73, 0.42, 0, 0, 0},--police ls
}
local aoffs = {-0.82,0.275,0}--actual "light" position


addEvent("police:addspotlightBar", true)
function addspotlightBar(exploded)

		if getElementType( source ) == "vehicle" then
			
			local id = getElementModel(source)
			local sploff = SpotlOFFSETS[id]

			if sploff then
				if exports.global:hasItem(source, 272) then
					if spotl[source] ~= nil then
						destroyElement(spotl[source])
						spotl[source] = nil
					end
					if spotl[source] == nil then
						local dim = getElementDimension(source)
						local int = getElementInterior(source)
						local x, y, z, rx, ry, rz =  getElementPosition(source)
						spotlight = createObject (1859, x, y, z)
						setElementData(spotlight, "pd-aobject", true)
						setElementDimension(spotlight, dim)
						setElementInterior(spotlight, int)
						local ox,oy,oz, orx,ory,orz = unpack(sploff)
						attachElements(spotlight, source, ox,oy,oz, orx,ory,orz)
						spotl[source] = spotlight
						setElementCollisionsEnabled(spotlight, false)
					end
				else
					if spotl[source] ~= nil then
						destroyElement(spotl[source])
						spotl[source] = nil
					end
				end
			end
		end

end
addEventHandler("police:addspotlightBar", getRootElement(), addspotlightBar)
addEventHandler("onVehicleRespawn", getRootElement(), addspotlightBar)
addEventHandler("onVehicleCreated", root, addspotlightBar)--event added in global/s_vehicle_globals.lua

function addspotlightBarOnStart()
	local vehicles = exports.pool:getPoolElementsByType("vehicle")
	for k, arrayVehicle in ipairs(vehicles) do
		triggerEvent("police:addspotlightBar", arrayVehicle)
	end
end

addEventHandler ( "onResourceStart", getResourceRootElement(getThisResource()),
    function()
        setTimer (addspotlightBarOnStart, 2000, 1)
	end
)


function destroyspotlight()
    if (getElementType(source) == "vehicle") then
        if spotl[source] ~= nil then
            destroyElement(spotl[source])
            spotl[source] = nil
        end
        destroySpotlight_light(source)
    end
end
addEventHandler("onElementDestroy", getRootElement(), destroyspotlight)
addEventHandler("onVehicleExplode", getRootElement(), destroyspotlight)


-- TODO: dr_flashlight for spitlight
local spotlightsOn = {}

function destroySpotlight_light(veh)
    if spotlightsOn[veh] then
    	spotlightsOn[veh] = nil
    end
end

function turnonSpitlight_light(veh)
	if not spotlightsOn[veh] then
    	spotlightsOn[veh] = true
    end
end

function togSpotlight(thePlayer, cmd, etc)
	if etc and etc == "syntax" then
		return outputChatBox("SYNTAX: /"..cmd.." - Turns the spotlight on/off inside a cop car", thePlayer, 255,194,14)
	end

	local vehicle = getPedOccupiedVehicle(thePlayer)
	if not vehicle then
		return togSpotlight(thePlayer, cmd, "syntax")
	end

	if not exports.global:hasItem(vehicle, 272) then
		return outputChatBox("This vehicle does not have the spotlight item.", thePlayer,255,100,100)
	end

	local id = getElementModel(vehicle)
	local sploff = SpotlOFFSETS[id]
	if not sploff then
		return outputChatBox("This vehicle does not have any spotlight attachment position defined.", thePlayer,255,100,100)
	end


	local spl = spotlightsOn[vehicle]
	if spl then
		destroySpotlight_light(vehicle)
	else
		turnonSpitlight_light(vehicle)
	end

end
addCommandHandler("togSpotlight", togSpotlight, false,false)
addCommandHandler("spotlight", togSpotlight, false,false)