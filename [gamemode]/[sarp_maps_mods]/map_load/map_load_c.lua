TEST_OBJ_MAPIDS = true -- enables /nearbyobjs


local loaded = { removals = { }, objects = { }, blips = { } }
local loadingMaps = true

local trashobjects

function loadOneObject( obj, loaded, is_test, map_id, objID )
	if obj.radius then -- world object removal
		if removeWorldModel ( obj.model, obj.radius, obj.posX, obj.posY, obj.posZ , obj.interior ) then
			if obj.lodModel and tonumber( obj.lodModel ) and obj.lodModel ~= obj.model then
				if removeWorldModel ( obj.lodModel, obj.radius, obj.posX, obj.posY, obj.posZ , obj.interior ) then
					table.insert( loaded.removals, { obj.lodModel, obj.radius, obj.posX, obj.posY, obj.posZ , obj.interior } )
				end
			end
			table.insert( loaded.removals, { obj.model, obj.radius, obj.posX, obj.posY, obj.posZ , obj.interior } )
			if is_test then
				local blip = createBlip ( obj.posX, obj.posY, obj.posZ, 0, 1 )
				if blip then
					table.insert( loaded.blips, blip )
				end
			end
		end
	else

		if not trashobjects then
			trashobjects = exports["job-system"]:getTrashObjects()
		end
		if trashobjects[tonumber(obj.model)] then
			outputDebugString("Trash model "..obj.model.." on map #"..map_id..", obj #"..obj.index..". Remove manually", 1)
		else
			local created_object = createObject ( obj.model, obj.posX, obj.posY, obj.posZ , obj.rotX, obj.rotY, obj.rotZ )
			if created_object then

				if TEST_OBJ_MAPIDS then
					setElementData(created_object, "obj_id", obj.index)--testing
					setElementData(created_object, "map_id", map_id)--testing
				end

				local distance = obj.distance
				if distance and distance ~= "" and distance ~= 0 then
					local lod = createObject ( obj.model, obj.posX, obj.posY, obj.posZ , obj.rotX, obj.rotY, obj.rotZ, true )
					setLowLODElement(created_object, lod)
					engineSetModelLODDistance( obj.model, distance )
					table.insert( loaded.objects, lod )
				end

				local textures = obj.textures
				if textures then
					if type(textures)=="table" then
						for k, v in pairs(textures) do
							if type(v)=="table" then
								local texname, rmodel,rname = unpack(v)
								rmodel = tonumber(rmodel)
								if type(texname) == "string" and type(rmodel) == "number" and type(rname) == "string" then
									-- print("Calling replaceWithDefaultTexture", created_object, texname, rmodel, rname)
									local worked, msg = exports["item-texture"]:replaceWithDefaultTexture(created_object, texname, rmodel, rname)
									if not worked then
										outputDebugString("Obj texture failed: "..msg, 2)
									end
								end
							end
						end
					end
				end

				local w_textures = obj.w_textures
				if w_textures then
					if type(w_textures) == "table" then
						for texname, url in pairs(w_textures) do
							if type(texname) == "string" and type(url) == "string" then
								-- print("Calling addTexture", created_object, texname, url)
								local worked, msg = exports["item-texture"]:addTexture(created_object, texname, url)
								if not worked then
									outputDebugString("Obj w_texture failed: "..msg, 2)
								end
							end
						end
					end
				end

				setElementInterior( created_object, obj.interior )
				setElementDimension( created_object, obj.dimension )
				setObjectBreakable( created_object, obj.breakable == 1 )
				setElementCollisionsEnabled ( created_object, obj.collisions ~= 0 )
				setElementFrozen( created_object, obj.frozen == 1 )
				if obj.scale and tonumber( obj.scale ) then
					setObjectScale( created_object, obj.scale )
				end
				setElementDoubleSided ( created_object, obj.doublesided == 1 )
				if obj.alpha and tonumber( obj.alpha ) then
					setElementAlpha ( created_object, obj.alpha )
				end
				table.insert( loaded.objects, created_object )
				if is_test then
					local blip = createBlip ( obj.posX, obj.posY, obj.posZ, 0, 1 )
					if blip then
						-- if obj.interior and obj.interior ~= 0 then
						-- 	setElementInterior( blip, obj.interior)
						-- end
						-- if obj.dimension and obj.dimension ~= 0 then
						-- 	setElementDimension( blip, obj.dimension )
						-- end
						table.insert( loaded.blips, blip )
					end
				end
			else
				outputDebugString("bugged model "..obj.model.." on map #"..map_id..", obj #"..obj.index..". Remove manually", 1)
			end
		end
	end
end

function nearbyObjectsCmd(cmd, range, onlymapid)
	if not (exports.integration:isPlayerTrialAdmin(localPlayer) or exports.integration:isPlayerMTMember(localPlayer)) then return end

	if not TEST_OBJ_MAPIDS then
		return outputChatBox("This feature is disabled in the script: contact Fernando.", 255,0,0)
	end

	if not tonumber(range) or tonumber(range) < 1 or tonumber(range) > 100 then
		return outputChatBox("SYNTAX: /"..cmd.." [Range 1-100] [Only map ID]", 255,194,14)
	end
	range = tonumber(range)

	if onlymapid then
		if not tonumber(onlymapid) then
			return nearbyObjectsCmd(cmd)
		end
		onlymapid = tonumber(onlymapid)
	end

	local x,y,z = getElementPosition(localPlayer)
	local int,dim = getElementInterior(localPlayer), getElementDimension(localPlayer)

	outputChatBox("Nearby mapped objects:", 255,126,0)

	local count = 0

	for k, obj in ipairs(getElementsByType("object", root, true)) do
		
		if getElementDimension(obj)==dim and getElementInterior(obj)==int then

			local ox,oy,oz = getElementPosition(obj)
			if getDistanceBetweenPoints3D(ox,oy,oz,x,y,z) <= range then

				local map_id = getElementData(obj, "map_id")
				if (onlymapid and map_id == onlymapid) or (not onlymapid) then

					if not isElementLowLOD(obj) then

						local model = getElementModel(obj)
						local name = engineGetModelNameFromID(model) or "?"
						local distance = engineGetModelLODDistance(model) or "?"

						if map_id then
							local objid = getElementData(obj, "obj_id") or "?"
							outputChatBox(" - #"..objid.." "..model.." ("..name..") map ID: "..map_id.." | LOD distance: "..distance.." | "..ox..", "..oy..", "..oz, 255,194,14)
						else
							outputChatBox(" - "..model.." ("..name..") | LOD distance: "..distance.." | "..ox..", "..oy..", "..oz, 255,100,14)
						end
						count = count + 1
					end
				end
			end
		end
	end
	if count == 0 then
		outputChatBox(" None.", 255,194,14)
	end
end
addCommandHandler("nearbyobjects", nearbyObjectsCmd, false)
addCommandHandler("nearbyobjs", nearbyObjectsCmd, false)

function loadMap( contents, map_id, is_test )
	loaded = { removals = { }, objects = { }, blips = { } }

	-- if map is loaded, unload it first.
	if isMapLoaded( map_id ) then
		unloadMap( map_id )
	end
	-- then load it again.
	if contents then
		for _, obj in pairs( contents ) do
			loadOneObject( obj, loaded, is_test, map_id )
		end
	end
	-- outputConsole("Map_Load: #"..map_id.." loaded.")
	loaded_maps[ map_id ] = loaded

	local finished = checkFinishedLoading()
	if finished then
		loadingMaps = false
		-- outputConsole("Map_Load: Finished loading")
	end

	return loaded
end
addEvent( 'maps:loadMap', true )
addEventHandler( 'maps:loadMap', root, loadMap )

function unloadMap( map_id )
	local result = { objects = 0, removals = 0, blips = 0 }
	local loaded_map = isMapLoaded( map_id )
	if loaded_map then
		-- destroy all loaded map objects.
		for index, obj in pairs( loaded_map.objects ) do
			if isElement(obj) and destroyElement( obj ) then
				result.objects = result.objects + 1
			end
		end
		-- restore all removed world models.
		for index, obj in pairs( loaded_map.removals ) do
			if restoreWorldModel( unpack( obj ) ) then
				result.removals = result.removals + 1
			end
		end
		-- destroy all blips if any.
		for index, blip in pairs( loaded_map.blips ) do
			if isElement(blip) and destroyElement( blip ) then
				result.blips = result.blips + 1
			end
		end
		loaded_maps[ map_id ] = nil
	end
	return result
end
addEvent( 'maps:unloadMap', true )
addEventHandler( 'maps:unloadMap', root, unloadMap )

function isMapLoaded( map_id, is_temp )
	if loaded_maps[ map_id ] then
		if is_temp then
			return #loaded_maps[ map_id ].blips > 0 and loaded_maps[ map_id ] or false
		else
			return loaded_maps[ map_id ]
		end
	else
		return false
	end
end

function unloadAllMaps( is_test )
	local result = { }
	for map_id, map in pairs( loaded_maps ) do
		local res = { objects = 0, removals = 0, blips = 0 }
		if is_test then -- only unload testing maps.
			if #map.blips > 0 then -- is a testing map.
				res = unloadMap( map_id )
			end
		else
			res = unloadMap( map_id )
		end
		if res.objects > 0 or res.removals > 0 or res.blips > 0 then
			table.insert( result, res )
		end
	end
	return result
end

-- function requestServerMaps()
-- 	triggerServerEvent( 'maps:requestServerMaps', localPlayer )
-- end
-- addEvent( 'maps:requestServerMaps', true )
-- addEventHandler( 'maps:requestServerMaps', root, requestServerMaps)

-- Disabled by Fernando
-- addCommandHandler('loadmaps', function()
-- 	requestServerMaps()
-- end)

addEventHandler ( "onClientElementDataChange", resourceRoot,
function ( dataName, oldValue )
	if dataName == settings.element_data_name then
		local queue = getElementData( resourceRoot, settings.element_data_name )
		if queue and queue ~= oldValue then
			syncMaps(true)
		end
	end
end)

-- Fernando
function syncMaps(slowRefresh)
	local synced_maps = getElementData( resourceRoot, settings.element_data_name )
	if synced_maps then

		if not getElementData(localPlayer, "account:loggedin") then
			setTimer(syncMaps, 2000, 1)
			return
		end

		-- outputConsole("Map_Load: Loading maps")
		loadingMaps = true

		-- unload maps first.
		for map_id, _ in pairs( loaded_maps ) do
			if not synced_maps[ map_id ] and isMapLoaded( map_id ) then
				unloadMap( map_id )
			end
		end

		if slowRefresh then

			-- load every map one by one
			for map_id, _ in pairs( synced_maps ) do
				if not isMapLoaded( map_id ) then
					triggerLatentServerEvent( 'maps:requestServerMaps', localPlayer, map_id )
				end
			end

		else

			triggerLatentServerEvent( 'maps:requestServerMaps', localPlayer ) -- All
		end

	end
end


addEventHandler( 'onClientResourceStart', resourceRoot, function() syncMaps() end )
addEventHandler( 'onClientResourceStop', resourceRoot, function() unloadAllMaps(false) end )

-- Fernando
function checkFinishedLoading()
	local synced_maps = getElementData( resourceRoot, settings.element_data_name )
	if synced_maps then
		if table.size(synced_maps) == table.size(loaded_maps) then
			return true
		end
	end
	return false
end

-- Fernando
-- exported
function isLoadingMaps()
	return loadingMaps
end

function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end

-- Makes it so that vehicles don't get damaged when you're still loading maps
addEventHandler( "onClientVehicleDamage", root,
function (theAttacker, theWeapon, loss, damagePosX, damagePosY, damagePosZ, tireID)
	if not theAttacker and loadingMaps then cancelEvent() end
end)
