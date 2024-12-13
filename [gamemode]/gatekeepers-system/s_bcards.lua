-- Fernando / SARP 2021

function makeBizCard(thePlayer, amount, text, price)
	if thePlayer and tonumber(amount) and text and tonumber(price) then

		if not exports.global:hasSpaceForItem(thePlayer, 55, 1) then
			return triggerClientEvent(thePlayer, "displayMesaage", thePlayer, "You don't have enough space in your inventory for 1 card.", 'error')
		end

		if exports.global:takeMoney(thePlayer, price * amount) then

			local countfailed = 0
			for i=1, amount do
				if not exports.global:giveItem(thePlayer, 55, text) then
					countfailed = countfailed + 1
				end
			end

			outputChatBox("You have created "..amount-countfailed.." business cards.", thePlayer, 0,255,0)
			if countfailed > 0 then
				if exports.global:giveMoney(thePlayer, price * countfailed) then
					outputChatBox("You didn't have inventory space for "..countfailed.." business cards so you only paid $"..exports.global:formatMoney((price)*(amount-countfailed))..".",thePlayer, 255,0,0)
				end
			end
		end
	end
end
addEvent("bcardsNPC:make", true)
addEventHandler("bcardsNPC:make", resourceRoot, makeBizCard)
