
-- Night objects remove
-- Fernando

local nightWindows = {9934,9933,9932,9886,6196,6195,6194,6193,6192,5059,5058,5057,4222,4221,4220,4219,4218,4217,
4216,4215,4214,4213,4212,13493,13485,13484,13461,10147,10146,10058,10057,4715,4716,4717,4720,4721,4722,4723,4725,4739,
4740,4741,4742,4743,4744,4745,4746,4747,4748,4749,4750,4751,4752,5661,5662,5665,5990,5991,5992,
7206,7207,7208,7221,7222,7280,7333,9088,9089,9125,9154,9277,9278,9279,9280,9281,9282,9283,9885,
 8502,9159,7233,8981,14628,3437,8371,8370,17957,17956,17955,17954,9129,9128,9127,9126,
9124,9123,9122,9121,8372,7944,7943,7942,7892,7332,7331,7226,7097,14561,14811,7268,9094,9095,11412,11411,11410,11324,14605,
14473,14470,14460,14406,7290,7314,7289,7266,7264,7220,7072,8395,9104,9175,8982,7666,7230,9100,9101,8840,7232,1462}

for _,obj in ipairs (nightWindows) do
	removeWorldModel (obj, 999999, 0, 0, 0)
end


--Traffic Lights
removeWorldModel(1283, 999999, 0, 0, 0)
removeWorldModel(1315, 999999, 0, 0, 0)
removeWorldModel(1284, 999999, 0, 0, 0)
removeWorldModel(1350, 999999, 0, 0, 0)
removeWorldModel(1351, 999999, 0, 0, 0)
removeWorldModel(3855, 999999, 0, 0, 0)
removeWorldModel(3516, 999999, 0, 0, 0)

-- Blue Gas Bottles
removeWorldModel(1370, 999999, 0, 0, 0)



local threads = { }
local threadTimer = nil
local percent = 0
local total

function getMapObjects( map_id )
	local qh = dbQuery( exports.mysql:getConn('mta'), "SELECT * FROM maps_objects WHERE map_id=?", map_id )
	local res, nums, id = dbPoll( qh, 100000 )
	if res then

		for _, obj in ipairs( res ) do
			-- 'textures' JSON
			if (not obj.textures) or (obj.textures == "") or obj.textures == mysql_null() then
				obj.textures = nil
			else
				obj.textures = fromJSON(obj.textures) or nil
			end
			-- 'w_textures' JSON
			if (not obj.w_textures) or (obj.w_textures == "") or obj.w_textures == mysql_null() then
				obj.w_textures = nil
			else
				obj.w_textures = fromJSON(obj.w_textures) or nil
			end
		end

		return res
	else
		dbFree( qh )
	end
end

function loadMap( map_id, mass_load )
	-- if map is loaded, unload it first.
	if isMapLoaded( map_id ) then
		unloadMap( map_id, mass_load )
	end
	loaded_maps[ map_id ] = getMapObjects( map_id )
	if not mass_load then
		updateMapsLoadingQueue()
	end
	return loaded_maps[ map_id ]
end

function isMapLoaded( map_id )
	return loaded_maps[ map_id ]
end

function unloadMap( map_id, mass_load )
	loaded_maps[ map_id ] = nil
	if not mass_load then
		updateMapsLoadingQueue()
	end
	return true
end

function unloadAllMaps( )
	loaded_maps = { }
	updateMapsLoadingQueue()
	return true
end

function removeBuggedObject()
end

function requestServerMaps( map_id, reload )
	if map_id then
		if reload then
			triggerClientEvent( source, 'maps:loadMap', source, loadMap( map_id ), map_id )
		else
			if isMapLoaded( map_id ) then
				-- triggerLatentClientEvent( source, 'maps:loadMap', 1000000, source, loaded_maps[ map_id ], map_id )
				triggerClientEvent( source, 'maps:loadMap', source, loaded_maps[ map_id ], map_id )
			end
		end
	else
		for map_id, map in pairs( loaded_maps ) do
			-- triggerLatentClientEvent( source, 'maps:loadMap', 1000000, source, map, map_id )
			triggerClientEvent( source, 'maps:loadMap', source, map, map_id )
		end
	end
end
addEvent( 'maps:requestServerMaps', true )
addEventHandler( 'maps:requestServerMaps', root, requestServerMaps )

function loadAllMaps()
	local online_players = #getElementsByType( 'player' )
	local qh = dbQuery( exports.mysql:getConn('mta'), "SELECT o.* FROM maps m LEFT JOIN maps_objects o ON m.id=o.map_id WHERE m.approved=1 AND m.enabled=1" )
	local res, nums, id = dbPoll( qh, 100000 )
	if res and nums > 0 then
		total = nums
		loaded_maps = { }
		for _, obj in ipairs( res ) do

			-- 'textures' JSON
			if (not obj.textures) or (obj.textures == "") or obj.textures == mysql_null() then
				obj.textures = nil
			else
				obj.textures = fromJSON(obj.textures) or nil
			end
			-- 'w_textures' JSON
			if (not obj.w_textures) or (obj.w_textures == "") or obj.w_textures == mysql_null() then
				obj.w_textures = nil
			else
				obj.w_textures = fromJSON(obj.w_textures) or nil
			end

			loaded_maps[ obj.map_id ] = loaded_maps[ obj.map_id ] or { }
			table.insert( loaded_maps[ obj.map_id ], obj )
		end
		-- outputDebugString( "[MAPS] Started loading "..total.." mapping objects. Finishing in "..exports.global:formatMoney( ((settings.load_speed+(online_players*100))*total)/1000/settings.load_speed_multipler ).." second(s)" )
		updateMapsLoadingQueue( true )
	else
		dbFree( qh )
	end
end


addEventHandler( 'onResourceStart', resourceRoot, function()
	if settings.startup_enabled then
		setTimer( loadAllMaps, settings.startup_delay, 1 )
	end
end)

--[[ alternative approach.
function loadAllMaps()
	local online_players = #getElementsByType( 'player' )
	local qh = dbQuery( exports.mysql:getConn('mta'), "SELECT m.*, (SELECT COUNT(o.id) FROM maps_objects o WHERE o.map_id=m.id) AS object_count FROM maps m WHERE m.approved=1 AND m.enabled=1 ORDER BY object_count" )
	local res, nums, id = dbPoll( qh, 100000 )
	if res and nums > 0 then
		total = nums
		for _, map in ipairs( res ) do
			local co = coroutine.create( loadMap )
			table.insert( threads, { co, map.id, true } )
		end
		threadTimer = setTimer( resumeThreads, settings.load_speed+(online_players*100), 0 )
		triggerLatentClientEvent( 'hud:loading', resourceRoot, 'Loading maps', { max=total, cur=0 } )
	else
		dbFree( qh )
	end
end
]]

-- function resumeThreads()
-- 	for i, co in ipairs( threads ) do
-- 		coroutine.resume( unpack(co) )
-- 		table.remove( threads, i )

-- 		-- loading
-- 		local loaded = total-#threads
-- 		local new_perc = math.ceil( loaded/total*100 )
-- 		if percent ~= new_perc then
-- 			percent = new_perc
-- 			triggerLatentClientEvent( 'hud:loading', resourceRoot, 'Loading maps', { max=total, cur=loaded } )
-- 		end

-- 		if i == settings.load_speed_multipler then
-- 			break
-- 		end
-- 	end

-- 	if #threads <= 0 then
-- 		killTimer(threadTimer)
-- 		threadTimer = nil
-- 		triggerLatentClientEvent( 'hud:loading', resourceRoot, 'Loading maps', { max=total, cur=total } )
-- 		outputDebugString( "[MAPS] Finished loading "..total.." mappings." )
-- 		updateMapsLoadingQueue()
-- 	end
-- end

function updateMapsLoadingQueue( forced )
	local q = { }
	for map_id, map_data in pairs( loaded_maps ) do
		if map_data then
			q[ map_id ] = true
		end
	end
	if forced or getElementData( resourceRoot, settings.element_data_name ) ~= q then
		return setElementData( resourceRoot, settings.element_data_name, q, true )
	end
end


-- Single use only
function clearTrashObjs(thePlayer, cmd)
	if not exports.integration:isPlayerScripter(thePlayer) then return end

	local trashobjs = exports["job-system"]:getTrashObjects()
	for id,_ in pairs(trashobjs) do
		dbExec( exports.mysql:getConn('mta'), "DELETE FROM maps_objects WHERE model=? AND radius IS NULL", id )
	end
	outputChatBox("Done.", thePlayer, 0,255,0)
end
-- addCommandHandler("delmaptrash", clearTrashObjs, false,false)