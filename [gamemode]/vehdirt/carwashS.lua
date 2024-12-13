-- Fernando
-- SARP December 2020


function washVeh(vehicle, payBank)
	local player = source
	if not isElement(player) or getElementType(player)~="player" then
		return
	end
	if not isElement(vehicle) or getElementType(vehicle)~="vehicle" then
		return
	end

	-- shouldnt happen, but just to make sure
	if payBank then
		if not exports.bank:takeBankMoney(player, washPrice) then
			return outputChatBox("You cannot afford to wash your vehicle.", player, 255,0,0)
		end
	else
		if not exports.global:takeMoney(player, washPrice) then
			return outputChatBox("You cannot afford to wash your vehicle.", player, 255,0,0)
		end
	end

	triggerClientEvent(player, "vehdirt:washVeh", player, vehicle)
	outputChatBox("You paid $"..washPrice..(payBank and " (bank)" or "").." for a car wash.", player, 255,194,14)
	if payBank then
		exports.bank:addBankTransactionLog(getElementData(player, 'dbid'), 0, washPrice, 3, 'Car Wash')
	end

	-- show everyone the water effects
	for k, p in pairs(getElementsByType("player")) do
		triggerClientEvent(p, "vehdirt:doSprayEffects", player, vehicle)
	end
end
addEvent("vehdirt:buyCarWash", true)
addEventHandler("vehdirt:buyCarWash", root, washVeh)
