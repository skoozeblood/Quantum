function giveDuplicatedKey(thePlayer, itemID, value, cost, pedName)
	if thePlayer and itemID and value and cost then

		itemID = tonumber(itemID)
		value = tonumber(value)

		-- if exports["interior-system"]:isRentingAt(thePlayer, tonumber(value)) then
		-- 	outputChatBox("Uh oh! Duplcating a key to a property that you are renting is against the rules!", thePlayer,255,0,0)
		-- 	return
		-- end
		exports.global:giveItem(thePlayer, itemID, value)
		exports.global:takeMoney(thePlayer, cost)

		local validKeys = {
			[4] = "door key",
			[5] = "door key",
			[73] = "door key",
			[3] = "vehicle key",
			[98] = "garage remote",
			[151] = "ramp remote",
		}
		local kt = validKeys[itemID]

		triggerEvent('sendAme', thePlayer, "hands "..pedName.." some dollar bills.")
		exports.global:sendLocalText(thePlayer, "* " .. tostring(pedName) .. " gives "..tostring(getPlayerName(thePlayer)):gsub("_"," ").." a shiny new "..kt..".", 255, 51, 102, 30, {}, true)

	end
end
addEvent("locksmithNPC:givekey", true)
addEventHandler("locksmithNPC:givekey", resourceRoot, giveDuplicatedKey)
