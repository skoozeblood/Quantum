addEvent( 'maps:managerTabSync', true )
addEventHandler( 'maps:managerTabSync', resourceRoot, function( tabID, dontShowPopUp )
	if tabID == 1 then -- my reqs
		dbQuery( function( qh, client, tabID )
			local res, nums, id = dbPoll( qh, 0 )
			if res then
				-- triggerLatentClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'ok', res, dontShowPopUp )
				triggerClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'ok', res, dontShowPopUp )
			else
				dbFree( qh )
				triggerClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'Error code 21 occurred while synchronizing data.', nil, dontShowPopUp )
			end
		end , { client, tabID }, exports.mysql:getConn('mta'), "SELECT m.*, m.reviewer AS reviewer FROM maps m WHERE uploader=? ORDER BY m.approved, m.enabled, m.id DESC", getElementData( client, 'account:id' ) )
	elseif tabID == 3 then --mgmt
		dbQuery( function( qh, client, tabID )
			local res, nums, id = dbPoll( qh, 0 )
			if res then
				-- triggerLatentClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'ok', res, dontShowPopUp )
				triggerClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'ok', res, dontShowPopUp )
			else
				dbFree( qh )
				triggerClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'Error code 21 occurred while synchronizing data.', nil, dontShowPopUp )
			end
		end , { client, tabID }, exports.mysql:getConn('mta'), "SELECT m.*, m.reviewer AS reviewer_name, m.uploader AS uploader_name FROM maps m ORDER BY m.approved, m.enabled, m.type DESC" )
	end
end)

addEvent( 'maps:submitExteriorMapRequest', true )
addEventHandler( 'maps:submitExteriorMapRequest', resourceRoot, function( name, url, who, what, why, map )
	if not canAdminMaps( client ) then
		local check = dbQuery( exports.mysql:getConn('mta'), "SELECT COUNT(id) AS count FROM maps WHERE approved=0 AND type='exterior' AND uploader=?", getElementData( client, 'account:id' ) )
		local res1, nums1, id1 = dbPoll( check, 10000 )
		if res1 and nums1 > 0 then
			if res1[1].count >= settings.external_map_max_concurrent_requests then
				return not triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, "You currently have "..res1[1].count.." maps pending approval. Please wait or cancel your previous requests." )
			end
		else
			dbFree( check )
			triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, 'Internal Error. Code 34.' )
		end
	end

	local done, why_failed = submitExteriorMapRequest ( name, url, who, what, why, map, client )
	triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, done and 'ok' or why_failed )
	if done then
		exports.discord:sendDiscordMessage("map-logs", ":purple_square: **"..exports.global:getPlayerName(client).." ("..getElementData(client, "account:username")..")** has submitted a new exterior map request named: **"..name.."**.")
	end
end )

--Fernando
addEvent( 'maps:submitInteriorMapRequest', true )
addEventHandler( 'maps:submitInteriorMapRequest', resourceRoot, function( name, url, who, what, why, map )
	if not canAdminMaps( client ) then
		local check = dbQuery( exports.mysql:getConn('mta'), "SELECT COUNT(id) AS count FROM maps WHERE approved=0 AND type='interior' AND uploader=?", getElementData( client, 'account:id' ) )
		local res1, nums1, id1 = dbPoll( check, 10000 )
		if res1 and nums1 > 0 then
			if res1[1].count >= settings.external_map_max_concurrent_requests then
				return not triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, "You currently have "..res1[1].count.." maps pending approval. Please wait or cancel your previous requests." )
			end
		else
			dbFree( check )
			triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, 'Internal Error. Code 34.' )
		end
	end

	local done, why_failed = submitInteriorMapRequest ( name, url, who, what, why, map, client )
	triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, done and 'ok' or why_failed )
	if done then
		exports.discord:sendDiscordMessage("map-logs", ":purple_square: **"..getElementData(client, "account:username").."** has submitted a new interior map request named: "..name..".")
	end
end )

-- Fernando
function checkIntCustomAlready(int_id)
	local response = false
	local message = ""

	local check = dbQuery( exports.mysql:getConn('mta'), "SELECT id FROM maps WHERE enabled=1 AND type='interior' AND purposes=?", int_id)
	local res1, nums1 = dbPoll( check, 10000 )
	if res1 and nums1 > 0 then
		if res1[1].id then
			response = true
			message = "Error. Interior ID #"..int_id.." already has a custom interior map."
		end
	end

	return response, message
end

addEvent( 'maps:updateReq', true )
addEventHandler( 'maps:updateReq', resourceRoot, function ( tabid, name, url, who, what, why, id )
	dbQuery( function( qh, client, tabid )
		local res, nums, id = dbPoll( qh, 0 )
		if res and nums > 0 then
			triggerClientEvent( client, 'maps:updateMyReqResponse', resourceRoot, 'ok', tabid )
			exports.discord:sendDiscordMessage("map-logs", ":blue_square: **"..getElementData(client, "account:username").."** has updated data for map ID #"..id..".")
		else
			triggerClientEvent( client, 'maps:updateMyReqResponse', resourceRoot, 'Errors occurred while updating map data. Code 64.' )
		end
	end , { client, tabid }, exports.mysql:getConn('mta'), "UPDATE maps SET name=?, preview=?, used_by=?, purposes=?, reasons=? WHERE id=?", name, url, who, what, why, id )
end )

addEvent( 'maps:delReq', true )
addEventHandler( 'maps:delReq', resourceRoot, function ( tabID, id )
	dbQuery( function( qh, client, tabID, id )
		local res, nums, id1 = dbPoll( qh, 0 )
		if res and nums > 0 then
			triggerClientEvent( client, 'maps:updateMyReqResponse', resourceRoot, 'ok', tabID )
			dbExec( exports.mysql:getConn('mta'), "DELETE FROM maps_objects WHERE map_id=?", id )
			exports.discord:sendDiscordMessage("map-logs", ":red_square: **"..getElementData(client, "account:username").."** has deleted map ID #"..id..".")
		else
			triggerClientEvent( client, 'maps:updateMyReqResponse', resourceRoot, 'Errors occurred while deleting map data. Code 73.' )
		end
	end , { client, tabID, id }, exports.mysql:getConn('mta'), "DELETE FROM maps WHERE id=?", id )
end )

addEvent( 'maps:testMap', true )
addEventHandler( 'maps:testMap', resourceRoot, function ( map_id )
	local res = exports.map_load:getMapObjects( map_id )
	if res then
		-- triggerLatentClientEvent( client, 'maps:testMap', resourceRoot, 'ok', res, map_id )
		triggerClientEvent( client, 'maps:testMap', resourceRoot, 'ok', res, map_id )
	else
		triggerClientEvent( client, 'maps:testMap', resourceRoot, 'Errors occurred while querying map contents. Code 97.' )
	end
end)

-- Fernando
addEvent( 'maps:gotoMap', true )
addEventHandler( 'maps:gotoMap', resourceRoot, function ( map_id )
	local res = exports.map_load:getMapObjects( map_id )
	if res then
		outputChatBox("You will now be teleported to the map. Warning: You may fall or get stuck.", client, 0,255,0)
		outputChatBox("Make sure the map is already enabled or you are previewing it.", client, 255,255,0)
		local int, dim, x,y,z
		for _, obj in pairs( res ) do
			if not obj.radius then
				int = obj.interior
				dim = obj.dimension
				x,y,z = obj.posX, obj.posY, obj.posZ
				break
			end
		end
		local player = client
		setTimer(function()
			setElementPosition(player, x,y,z)
			setElementDimension(player, dim)
			setElementInterior(player, int)
			exports["interior-manager"]:addInteriorLogsIfExists(dim, "Teleported to map (custom int)", player)
			triggerEvent ( "frames:loadInteriorTextures", player, dim )
		end, 2000, 1)
	else
		triggerClientEvent( client, 'maps:testMap', resourceRoot, 'Errors occurred while querying map contents. Code 97.' )
	end
end)

addEvent( 'maps:approveRequest', true )
addEventHandler( 'maps:approveRequest', resourceRoot, function( map_id, note, accepting )
	note = getCurrentTimeString().." "..exports.global:getPlayerFullIdentity( client, 1 )..": "..(accepting and "ACCEPTED" or "DECLINED")..". "..note.."\n"
	dbQuery( function( qh, client, map_id, note )
		local res, nums, id = dbPoll( qh, 0 )
		if res and nums > 0 then
			triggerClientEvent( client, 'maps:approveRequest', resourceRoot, 'ok', map_id, accepting )

			exports.discord:sendDiscordMessage("map-logs", ":"..(accepting and "green" or "brown").."_square: **"..getElementData(client, "account:username").."** has "..(accepting and "accepted" or "declined").." map ID #"..map_id..".\nNote: "..note)
			notifyPlayer( map_id, "Your map addition request status updates.", "Hello <Username>!\n\nYour map addition request #" .. map_id .. " has been "..(accepting and "ACCEPTED" or "DECLINED")..".\n\n"..note.."\nSincerely,\nMapping Team" )
		else
			dbFree( qh )
			triggerClientEvent( client, 'maps:approveRequest', resourceRoot, 'Errors occurred while processing request. Code 110.' )
		end
	end , { client, map_id, note }, exports.mysql:getConn('mta'), "UPDATE maps SET approved=?, note=CONCAT(note, ?), reviewer=? WHERE id=?", accepting and 1 or 2, note, getElementData( client, 'account:id' ), map_id  )
end)

addEvent( 'maps:implement', true )
addEventHandler( 'maps:implement', resourceRoot, function( map_id, implementing, map_type, int_id)

	if implementing and map_type == "interior" then
		local exists, why_failed = checkIntCustomAlready(int_id)
		if exists then
			triggerClientEvent( client, 'maps:implement', resourceRoot, why_failed )
			return
		end
	end

	local note = getCurrentTimeString().." "..exports.global:getPlayerFullIdentity( client, 1 )..": "..(implementing and "Implemented map." or "Disabled map.").."\n"
	dbQuery( function( qh, client, map_id, note )
		local res, nums, id = dbPoll( qh, 0 )
		if res and nums > 0 then
			if implementing and exports.map_load:loadMap( map_id ) or exports.map_load:unloadMap( map_id ) then
				triggerClientEvent( client, 'maps:implement', resourceRoot, 'ok', map_id, implementing )
				exports.discord:sendDiscordMessage("map-logs", ":"..(implementing and "white_large" or "orange").."_square: **"..getElementData(client, "account:username").."** has "..(implementing and "implemented" or "disabled").." map ID #"..map_id..".")
				notifyPlayer( map_id, "Your map status updates.", "Hello <Username>!\n\nYour map #" .. map_id .. " has been "..(implementing and "IMPLEMENTED" or "DISABLED")..".\n\n"..note.."\nSincerely,\nMapping Team" )
			else
				triggerClientEvent( client, 'maps:implement', resourceRoot, 'Errors occurred while '..(implementing and 'implementing' or 'disabling')..' the map. Code 122.' )
			end
		else
			dbFree( qh )
			triggerClientEvent( client, 'maps:implement', resourceRoot, 'Errors occurred while '..(implementing and 'implementing' or 'disabling')..' the map. Code 124.' )
		end
	end , { client, map_id, note }, exports.mysql:getConn('mta'), "UPDATE maps SET enabled=?, approved=1, note=CONCAT(note, ?) WHERE id=?", implementing and 1 or 0, note, map_id )
end )


addCommandHandler("editmapobject", function(thePlayer, cmd, mapid, id, property, ...)
	if not exports.integration:isPlayerScripter(thePlayer) then return end
	
	outputChatBox("WARNING: NO VALIDATION BEFORE UPDATING MYSQL DB", thePlayer, 255,0,0)
	outputChatBox("Corresponding map is reloaded after one of its objects is updated", thePlayer, 255,126,0)

	id = tonumber(id)
	mapid = tonumber(mapid)
	if not mapid or not id or not property or not (...) then
		return outputChatBox("SYNTAX: /"..cmd.." [Map ID] [Object Index] [Column] [Value]", thePlayer, 255,194,14)
	end

	local value = table.concat({...}, " ")
	if exports.mysql:query_free("UPDATE `maps_objects` SET `"..property.."`='"..value.."' WHERE `map_id`='"..mapid.."' AND `index`='"..id.."' ") then
		outputChatBox("Updated obj index #"..id..": "..property..": "..value, thePlayer, 0,255,0)
		outputChatBox("Use /reloadmap "..mapid.." to reload it", thePlayer, 100,255,0)
		
	else
		outputChatBox("Failed", thePlayer, 255,0,0)
	end

end, false, false)

addCommandHandler("reloadmap", function(thePlayer, cmd, id)
	if not exports.integration:isPlayerScripter(thePlayer) then return end

	id = tonumber(id)
	if not id then
		return outputChatBox("SYNTAX: /"..cmd.." [Map ID]", thePlayer, 255,194,14)
	end
	local res = exports.mysql:query_fetch_assoc("SELECT `id` FROM `maps` WHERE `id`='"..id.."'  LIMIT 1")
	if not res then
		return outputChatBox("Invalid map ID "..id, thePlayer, 255,0,0)
	end

	for k, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "account:loggedin") then
			outputChatBox("Map ID #"..id.." was reloaded by a scripter.", player,255,255,0)
			triggerEvent( 'maps:requestServerMaps', player, id, true )
		end
	end
end, false, false)