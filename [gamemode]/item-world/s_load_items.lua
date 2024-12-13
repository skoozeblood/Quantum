function setElementData(...)
	return anticheat:changeProtectedElementDataEx(...)
end

function loadOneWorldItem(row)
	if row then
		local id = tonumber(row["id"])
		local itemID = tonumber(row["itemid"])
		local itemValue = tonumber(row["itemvalue"]) or row["itemvalue"]
		local x = tonumber(row["x"])
		local y = tonumber(row["y"])
		local z = tonumber(row["z"])
		local dimension = tonumber(row["dimension"])
		local interior = tonumber(row["interior"])
		local rx2 = tonumber(row["rx"]) or 0
		local ry2 = tonumber(row["ry"]) or 0
		local rz2 = tonumber(row["rz"]) or 0
		local creator = tonumber(row["creator"])
		local createdDate = tostring(row["creationdate"])
		local protected = tonumber(row["protected"])
		local permUse = tonumber(row["perm_use"])
		local permMove = tonumber(row["perm_move"])
		local permPickup = tonumber(row["perm_pickup"])
		local permUseData = fromJSON(type(row["perm_use_data"])== "string" and row["perm_use_data"] or "")
		local permMoveData = fromJSON(type(row["perm_move_data"])== "string" and row["perm_move_data"] or "")
		local permPickupData = fromJSON(type(row["perm_pickup_data"])== "string" and row["perm_pickup_data"] or "")
		local useExactValues = tonumber(row["useExactValues"])
		local metadata = type(row["metadata"]) == "string" and fromJSON(row["metadata"]) or nil
		
		if itemID < 0 then
			itemID = -itemID
			local modelid = 2969
			if itemValue == 100 then
				modelid = 1242
			elseif itemValue == 42 then
				modelid = 2690
			else
				modelid = weaponmodels[itemID]
			end

			local obj = createItem(id, -itemID, itemValue, modelid, x, y, z - 0.1, 75, -10, rz2)
			if isElement(obj) then
				exports.pool:allocateElement(obj)
				setElementDimension(obj, dimension)
				setElementInterior(obj, interior)
				setElementData(obj, "creator", creator)
				setElementData(obj, "createdDate", createdDate)

				if protected and protected ~= 0 then
					setElementData(obj, "protected", protected)
				end

				if metadata then
					anticheat:changeProtectedElementDataEx(obj, "metadata", metadata)
				end
			end
		else
			local modelid, specialObject = exports['item-system']:getItemModel(itemID, itemValue, metadata)

			local rx = 0
			local ry = 0
			local rz = 0
			local zoffset = 0

			if useExactValues ~= 1 then
				rx, ry, rz, zoffset = exports['item-system']:getItemRotInfo(itemID)
			end
			local obj = createItem(id, itemID, itemValue, modelid, x, y, z + ( zoffset or 0 ), rx+rx2, ry+ry2, rz+rz2, specialObject)

			if isElement(obj) then
				exports.pool:allocateElement(obj, itemID, true)
				setElementDimension(obj, dimension)
				setElementInterior(obj, interior)
				setElementData(obj, "creator", creator)
				setElementData(obj, "createdDate", createdDate)

				if protected and protected ~= 0 then
					setElementData(obj, "protected", protected)
				end
				if useExactValues ~= 0 then
					setElementData(obj, "useExactValues", true)
				end

				local permissions = { use = permUse, move = permMove, pickup = permPickup, useData = permUseData, moveData = permMoveData, pickupData = permPickupData }
				anticheat:changeProtectedElementDataEx(obj, "worlditem.permissions", permissions)

				if metadata then
					anticheat:changeProtectedElementDataEx(obj, "metadata", metadata)
				end

				local scale = exports['item-system']:getItemScale(itemID, itemValue, metadata)
				if scale then
					setObjectScale(obj, scale)
				end

				local dblSided = exports['item-system']:getItemDoubleSided(itemID, itemValue, metadata)
				if dblSided then
					setElementDoubleSided(obj, true)
				end

				local colEnabled = exports['item-system']:getItemCollisionsEnabled(itemID, itemValue, metadata)
				if not colEnabled then
					setElementCollisionsEnabled(obj, colEnabled)
				end

				local texture = exports["item-system"]:getItemTexture(itemID, itemValue, metadata)
				if texture then
					for k,tex in ipairs(texture) do
																		--texname, url
						if not exports["item-texture"]:addTexture(obj, tex[2], tex[1]) then
							-- print("failed add tex #"..id)
						end
					end
				end
			end
		end
	end
end

local mysql = exports.mysql
function loadWorldItems()

	-- not using this inactivity scanner stuff atm - Fernando

	-- local ticks = getTickCount( )
	-- local itemInactivityScannerMode = tonumber(get("inactivityscanner_items"))
	--[[
		MODES:
		0 - off
		1 - delete all items after 30 days
		2 - delete exterior items only after 30 days (avoid deleting interior items)
		Storage items ID 81 (fridge), 103 (fridge), 223 (storage generic) and 231 (shipping container) are excempt from deletion
		Other excempt items: 169 (keyless digital door lock)
		Notes (ID 72) will delete after 3 days.
	]]
	-- if itemInactivityScannerMode then
	-- 	if itemInactivityScannerMode == 1 then
	-- 		dbExec(mysql:getConn('mta'), "DELETE FROM `worlditems` WHERE `protected`='0' AND `itemID` NOT IN(81, 103, 169, 223, 231) AND ( (DATEDIFF(NOW(), creationdate) > 30 ) OR (DATEDIFF(NOW(), creationdate) > 3 AND `itemID` = 72) ) " )
	-- 	elseif itemInactivityScannerMode == 2 then
	-- 		dbExec(mysql:getConn('mta'), "DELETE FROM `worlditems` WHERE `protected`='0' AND `itemID` NOT IN(81, 103, 169, 223, 231) AND (interior=0) AND ( (DATEDIFF(NOW(), creationdate) > 30 ) OR (DATEDIFF(NOW(), creationdate) > 3 AND `itemID` = 72) ) " )
	-- 	end
	-- end

	local g_items = exports["item-system"]:getAllItems()
	dbQuery(function(qh)
		local res, rows, err = dbPoll(qh,0)
		if rows > 0 then
			local delay = 0
			local timerDelay = 50

			for k,v in pairs(res) do
				if g_items[tonumber(v.itemid)] then
					loadOneWorldItem(v)--load all instantly causing game freeze for anyone IG
				else
					if exports.mysql:query_free("DELETE FROM `worlditems` WHERE `id`='" .. v.id.."' LIMIT 1") then
						outputDebugString("item-world: ItemID #"..v.itemid.." doesn't exist. DELETED FROM DB")
					end
				end
			end

			setTimer(function()
				triggerEvent("trash:loadTrash", resourceRoot)
			end, 15000, 1)
		end
	end, mysql:getConn('mta'), "SELECT * FROM worlditems WHERE deleted=0") -- Fernando
end
addEventHandler("onResourceStart", resourceRoot, loadWorldItems)

-- Fernando // exported
function reloadOneItem(dbid)
	if not dbid or not tonumber(dbid) then return false end
	dbid = tonumber(dbid)

	local object
	for k, obj in ipairs(getElementsByType("object", resourceRoot)) do
		if getElementData(obj, "id") == dbid then
			object = obj
			break
		end
	end

	if object then
		destroyElement(object)
	end

	-- Fernando
	dbQuery(function(qh)
		local res, rows, err = dbPoll(qh,0)
		if rows > 0 then
			loadOneWorldItem(res[1])
		end
	end, mysql:getConn('mta'), "SELECT * FROM worlditems WHERE deleted=0 AND id=? LIMIT 1", dbid)

	return true
end
addEvent("item-world:reloadOneItem", true)
addEventHandler("item-world:reloadOneItem", root, reloadOneItem)

function reloadOneItemCmd(thePlayer, cmd, id)
	if not exports.integration:isPlayerScripter(thePlayer) then return end
	if not tonumber(id) then return outputChatBox("SYNTAX: /"..cmd.." [Worlditem ID]",thePlayer,255,194,14) end

	reloadOneItem(id)
	outputChatBox("Reloaded world item: "..id, thePlayer,25,255,25)
end
addCommandHandler("reloadworlditem", reloadOneItemCmd, false,false)
addCommandHandler("reloadwi", reloadOneItemCmd, false,false)
