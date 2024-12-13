local mysql = exports.mysql
local fuelCanItemID = 57
local fuelCanMaxFill = 10 --value

function doesFactionPayForFuel(id)
	local facType = exports["faction-system"]:getFactionType(id)
	if facType then
		if facType == 2
		or facType == 3
		or facType == 4
		or facType == 5
		or facType == 6
		or facType == 7
		then
			return true
		end
	end
	return false
end

playerTimers = {}

FUEL_PRICE = 1.10--default

local price_choose = {
	10, 20, 40, 60
}

addEventHandler( "onResourceStart", resourceRoot, 
function (startedResource)
	FUEL_PRICE = exports.global:getSettingValue("fuel_price")
end)

function startTalkToPed ()

	thePed = source
	thePlayer = client


	if not (thePlayer and isElement(thePlayer)) then
		return
	end

	local posX, posY, posZ = getElementPosition(thePlayer)
	local pedX, pedY, pedZ = getElementPosition(thePed)
	if not (getDistanceBetweenPoints3D(posX, posY, posZ, pedX, pedY, pedZ)<=7) then
		return
	end


	if isTimer(playerTimers[thePlayer]) then
		return outputChatBox("Please wait..", thePlayer, 187,187,187)
	end


	local convState = getElementData(thePlayer, "ped:convoState")
	local currSlot = getElementData(thePlayer, "languages.current")
	local currLang = getElementData(thePlayer, "languages.lang" .. currSlot) -- currLang
	local languageSkill = exports['language-system']:getSkillFromLanguage(thePlayer, 1)
	if (languageSkill < 60) or (currLang ~= 1) then
			processMessage(thePed, "I'm sorry? I don't quite understand you...")
			outputChatBox("You need to have at least 60% English language skill (F6 to check).", thePlayer, 255,194,14)
			setConvoState(thePlayer, 0)
		return
	end
	if not (isPedInVehicle(thePlayer)) or (isPedInVehicle(thePlayer) and getVehicleType(getPedOccupiedVehicle(thePlayer)) == "BMX") then
		processMessage(thePed, "How can I help you?")
		setConvoState(thePlayer, 3)
		local responseArray = { "I'd like to fill up my fuelcan.", "Nothing, sorry for disturbing!", "Do you happen to have a lighter?" }
		triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
	else
		local theVehicle = getPedOccupiedVehicle(thePlayer)
		if (exports['vehicle-system']:isVehicleWindowUp(theVehicle)) then
			outputChatBox("You might want to lower your window first, before talking to anyone outside the vehicle.", thePlayer, 255,0,0)
			return
		end
		-- processMeMessage(thePed, "leans against " .. getPlayerName(thePlayer):gsub("_"," ") .. "'s vehicle.", thePlayer )
		triggerEvent('sendAme', thePed, "leans against " .. getPlayerName(thePlayer):gsub("_"," ") .. "'s vehicle.")
		processMessage(thePed, "How may I help you?")
		setConvoState(thePlayer, 1)
		local responseArray = { "I'd like to fill up my vehicle.", "Nothing, sorry for disturbing!", "Do you happen to have a lighter?", "Don't you lean against my vehicle!" }
		triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
	end
end
addEvent( "fuel:startConvo", true )
addEventHandler( "fuel:startConvo", getRootElement(), startTalkToPed )

function talkToPed(answer, answerStr)
	thePed = source
	thePlayer = client

	if not (thePlayer and isElement(thePlayer)) then
		return
	end

	local posX, posY, posZ = getElementPosition(thePlayer)
	local pedX, pedY, pedZ = getElementPosition(thePed)
	if not (getDistanceBetweenPoints3D(posX, posY, posZ, pedX, pedY, pedZ) <= 7) then
		return
	end

	local convState = getElementData(thePlayer, "ped:convoState")
	local currSlot = getElementData(thePlayer, "languages.current")
	local currLang = getElementData(thePlayer, "languages.lang" .. currSlot)
	processMessage(thePlayer, answerStr, currLang)
	if (convState == 1) then -- "Hey, how could I help you?"
		local languageSkill = exports['language-system']:getSkillFromLanguage(thePlayer, 1)
		if (languageSkill < 60) or (currLang ~= 1) then
			processMessage(thePed, "I'm sorry? I don't quite understand you...", 1)
			outputChatBox("You need to have at least 60% English language skill (F6 to check).", thePlayer, 255,194,14)
			setConvoState(thePlayer, 0)
			return
		end

		if (answer == 1) then -- "Ehm, fill my tank up, please."
			if not (isPedInVehicle(thePlayer)) then
				processMessage(thePed, "Ehm...")
				setConvoState(thePlayer, 0)
				return
			end
			local theVehicle = getPedOccupiedVehicle(thePlayer)
			if (getElementData(theVehicle, "engine") == 1) then
				processMessage(thePed, "Do you mind turning your engine off?")
				local responseArray = { "Of course, just a second.", "Do I really have to do that?", "Eh, WHAT?" }
				triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
				setConvoState(thePlayer, 2)
				return
			elseif getElementData(theVehicle, 'fuel') > (getMaxFuel(getElementModel(theVehicle))- (0.01*getMaxFuel(getElementModel(theVehicle)))) then
				processMessage(thePed, "Looks pretty full to me.")
			else
				processMessage(thePed, "Sure... How would you like to pay?")
				local factionVehicle = getElementData(theVehicle, "faction")
				if (exports["faction-system"]:isPlayerInFaction(thePlayer, factionVehicle) and doesFactionPayForFuel(factionVehicle)) or getElementData(theVehicle, "job")>0 then
					local responseArray = { "Business Card", false, "Sorry what?" }
					triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
				elseif getATMCardFromATMMachine(thePlayer) then
					local responseArray = { "Cash please!", "I'll use my bank account.", "Sorry what?" }
					triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
				else
					local responseArray = { "Cash please!", false, "Sorry what?" }
					triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
				end
				setConvoState(thePlayer, 4)
				--processMessage(thePed, "Sure... we could arrange that.")
				--pedWillFillVehicle(thePlayer, thePed)
			end
		elseif (answer == 2) then -- "No thanks."
			processMessage(thePed, "Okay, fine. Hop by when you need some fuel.")
			setConvoState(thePlayer, 0)
		elseif (answer == 3) then -- "Do you have a sigarette for me?"
			processMessage(thePed, "Uhm, no. You could check the twenty-four seven.")
			setConvoState(thePlayer, 0)
		elseif (answer == 4) then -- stop leaning against my car
			processMessage(thePed, "Okay, okay... Take it easy.")
			--processMeMessage(thePed, "pushes himself up again, standing on his feet.", thePlayer )
			triggerEvent('sendAme', thePed, "pushes himself up again, standing on his feet.")
			processMessage(thePed, "Well, should I fill it up or not?.")
			local responseArray = {  "Go ahead.", "No, not anymore." }
			triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			setConvoState(thePlayer, 1)
		end
	elseif (convState == 2) then -- "Could you please turn your engine off?"
		if (answer == 1) then -- "Sure, no problemo." / "Ok, okay.."
			if not (isPedInVehicle(thePlayer)) then
				processMessage(thePed, "Ehm...")
				setConvoState(thePlayer, 0)
				return
			end
			local theVehicle = getPedOccupiedVehicle(thePlayer)
			triggerEvent("toggleEngine", thePlayer, thePlayer)

			processMessage(thePed, "Alright thanks! How would you like to pay?")
			if getATMCardFromATMMachine(thePlayer) then
				local responseArray = { "Cash please!", "I'll use my bank account.", "Sorry what?" }
				triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			else
				local responseArray = { "Cash please!", false, "Sorry what?" }
				triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			end
			setConvoState(thePlayer, 4)
		elseif (answer == 2) then -- "Can't you do it with the engine running?"
			--processMeMessage(thePed, "sighs.",thePlayer )
			triggerEvent('sendAme', thePed, "sighs.")
			processMessage(thePed, "Ehm... no. I don't want to die. So, shutting it off or not?")
			local responseArray = {  "Go ahead.", false, false, "Ugh, shut up then."  }
			triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			setConvoState(thePlayer, 2)
		elseif (answer == 3) then -- "Eh, WHAT?"
			processMessage(thePed, "I've asked: Could you turn off your engine?")
			local responseArray = {  "Ok, okay..", false,false, "Ugh, no."  }
			triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			setConvoState(thePlayer, 2)
		elseif answer == 4 then -- "Ugh, shut up then." / "Ugh, no."
			processMessage(thePed, "Okay, okay... Take it easy. Get lost.")
			setConvoState(thePlayer, 0)
		end
	elseif (convState == 3) then
		if answer == 1 then -- Could you fill my fuelcan?

			local itemSlot, itemValue = hasNonFullFuelCan(thePlayer)
			if (itemSlot) then

				processMessage(thePed, "Sure. Let's do it.")
				triggerEvent('sendAme', thePed, "attaches the hose to the tanker, rolling it out.")
				triggerEvent('sendAme', thePed, "twists the cap of the fuelcan, hosing in and filling it slowly.")
				playerTimers[thePlayer] = setTimer(pedWillFillFuelCan, 3500, 1, thePlayer, thePed)
			else
				local itemSlot, itemValue = hasAnyFuelCan(thePlayer)
				if itemSlot and itemValue >= fuelCanMaxFill then
					processMessage(thePed, "Your fuel can's already full.")
					setConvoState(thePlayer, 0)
					return
				end

				processMessage(thePed, "You'll need an fuelcan for this. Get one from the twenty-four seven.")
				setConvoState(thePlayer, 0)
			end
		elseif answer == 2 then -- No thanks
			processMessage(thePed, "Okay, have a pleasant day.")
			setConvoState(thePlayer, 0)
		elseif answer == 3 then -- do you have a cigarette for me?
			processMessage(thePed, "Uhm, no. You could check the twenty-four seven.")
			setConvoState(thePlayer, 0)
		elseif answer == 4 then -- I like your suit
			processMessage(thePed, "Eh, thanks... I guess.")
			setConvoState(thePlayer, 0)
		end
	elseif (convState == 4) then -- How would you like to pay?
		if answer == 1 or answer == 2 then  -- Bank = 2 Cash = 1
			if answer == 2 and answerStr ~= "accepted" then
				triggerClientEvent(thePlayer, "fuel:requestATMInterfacePIN", thePed, thePlayer, exports.global:getElementZoneName(thePlayer))
				setConvoState(thePlayer, 4)
				return
			end
			processMessage(thePed, "Alrighty then, how much are you putting in?")
			local responseArray = {}
			for k,price_c in pairs(price_choose) do
				table.insert(responseArray, "$"..price_c)
			end
			table.insert(responseArray, "Fill her up!")
			triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			exports.anticheat:changeProtectedElementDataEx(thePlayer, "ped:Type", answer, false)
			setConvoState(thePlayer, 5)
		elseif answer == 3 then
			processMessage(thePed, "I asked you how you want to pay for your gas.")
			local theVehicle = getPedOccupiedVehicle(thePlayer)
			local factionVehicle = getElementData(theVehicle, "faction")
			if (exports["faction-system"]:isPlayerInFaction(thePlayer, factionVehicle) and doesFactionPayForFuel(factionVehicle)) or getElementData(theVehicle, "job")>0 then
				local responseArray = { "Business Card", false, "Sorry what?", "Just nevermind.."}
				triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			elseif getATMCardFromATMMachine(thePlayer) then
				local responseArray = { "Cash please!", "I'll use my bank account.", "Sorry what?", "Just nevermind.." }
				triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			else
				local responseArray = { "Cash please!", false, "Sorry what?", "Just nevermind.." }
				triggerClientEvent(thePlayer, "fuel:convo", thePed, responseArray)
			end
			setConvoState(thePlayer, 4)
		elseif answer == 4 then
			processMessage(thePed, "Alright whatever then..")
			setConvoState(thePlayer, 0)
		end
	elseif (convState == 5) then
		if not (isPedInVehicle(thePlayer)) then
			processMessage(thePed, "Ehm...")
			setConvoState(thePlayer, 0)
			return
		end

		local pedAmount = price_choose[answer] or 0
		exports.anticheat:changeProtectedElementDataEx(thePlayer, "ped:amount", pedAmount, false)
		
		local theVehicle = getPedOccupiedVehicle(thePlayer)
		if getElementData(theVehicle, 'fuel') > (getMaxFuel(getElementModel(theVehicle))- (0.01*getMaxFuel(getElementModel(theVehicle)))) then
			processMessage(thePed, "Looks pretty full to me.")
		else
			pedWillFillVehicle(thePlayer, thePed)
		end
	end
end
addEvent( "fuel:convo", true )
addEventHandler( "fuel:convo", getRootElement(), talkToPed )

function hasNonFullFuelCan(thePlayer)
	local itemSlot, itemValue, itemIndex

	for k, item in ipairs(exports["item-system"]:getItems(thePlayer)) do
		if item[1] == fuelCanItemID then
			if tonumber(item[2]) < fuelCanMaxFill then
				itemSlot = tonumber(k)
				itemValue = tonumber(item[2])
				itemIndex = tonumber(item[3])
				break
			end
		end
	end

	return itemSlot, itemValue, itemIndex
end

function hasAnyFuelCan(thePlayer)
	local itemSlot, itemValue, itemIndex

	for k, item in ipairs(exports["item-system"]:getItems(thePlayer)) do
		if item[1] == fuelCanItemID then
			if tonumber(item[2]) >= fuelCanMaxFill then
				itemSlot = tonumber(k)
				itemValue = tonumber(item[2])
				itemIndex = tonumber(item[3])
				break
			end
		end
	end

	return itemSlot, itemValue, itemIndex
end

function pedWillFillFuelCan(thePlayer, thePed)
	if not (thePlayer and isElement(thePlayer)) then
		return
	end
	local posX, posY, posZ = getElementPosition(thePlayer)
	local pedX, pedY, pedZ = getElementPosition(thePed)
	if not (getDistanceBetweenPoints3D(posX, posY, posZ, pedX, pedY, pedZ) <= 7) then
		exports['chat-system']:localShout(thePed, "do", "Fine, no fuel for you!")
		return
	end


	local itemSlot, itemValue, itemIndex = hasNonFullFuelCan(thePlayer)
	if not itemSlot then
		processMessage(thePed, "Eh, where did your fuel can go?")
		return
	end

	local theLitres = fuelCanMaxFill - math.ceil(itemValue)

	local currentTax = exports.global:getTaxAmount("tax_fuel")
	local price_beforetax = exports.global:roundNumber(theLitres * FUEL_PRICE)
	local tax = exports.global:roundNumber(currentTax*FUEL_PRICE)
	local fuelCost = exports.global:roundNumber(price_beforetax + tax)

	if not exports.global:hasMoney(thePlayer, fuelCost) then
		processMessage(thePed, "Yeah, this costs like $" .. fuelCost .. ", y'know?")
		return
	end

	local new = itemValue + theLitres
	-- outputChatBox("INDEX "..itemIndex.." - SLOT "..itemSlot.." ID "..fuelCanItemID.." VALUE "..itemValue, thePlayer,0,255,0)
	-- outputChatBox("NEW VALUE "..new, thePlayer)

	local worked, reason = exports['item-system']:updateItemValue(thePlayer, itemSlot, new)
	if not (worked) then
		outputChatBox("Something went wrong, please report this bug ("..reason..")", thePlayer,255,0,0)
		return
	end


	exports.global:takeMoney(thePlayer, fuelCost)
	exports.global:payTaxToGov(0, tax, "tax_fuel", "Business: "..getElementZoneName(thePlayer).." Gas Station | Item: "..theLitres.."L of Gas | Price before tax: $"..exports.global:formatMoney(price_beforetax))

	outputChatBox("Your fuel can has been filled and now has 10L of gas.", thePlayer,0,255,0)
	outputChatBox("Approach a vehicle and right click it to use the fuel can.", thePlayer,255,194,14)
	local info = {
			{"Gas Station Receipt"},
			{""},
			{"    " .. (theLitres) .. "L of Gas    -    " .. fuelCost .. "$"},
		}
	triggerClientEvent(thePlayer, "hudOverlay:drawOverlayTopRight", thePlayer, info )
end

function pedWillFillVehicle(thePlayer, thePed)
	if not (thePlayer and isElement(thePlayer)) then
		return
	end
	local amount = getElementData(thePlayer, "ped:amount")
	local moneyType = getElementData(thePlayer, "ped:Type")

	playerTimers[thePlayer] = setTimer(pedWillFuelTheVehicle, 5000, 1, thePlayer, thePed, amount, moneyType)
end

function pedWillFuelTheVehicle(thePlayer, thePed, amount, moneyType)
	if not (thePlayer and isElement(thePlayer)) then
		return
	end
	local posX, posY, posZ = getElementPosition(thePlayer)
	local pedX, pedY, pedZ = getElementPosition(thePed)
	if not (getDistanceBetweenPoints3D(posX, posY, posZ, pedX, pedY, pedZ) <= 7) then
		exports['chat-system']:localShout(thePed, "do", "HEY IDIOT, WANT TO DIE? ASSHOLE!")
		return
	end

	local theVehicle = getPedOccupiedVehicle(thePlayer)
	local fuelType = getVehicleHandling(theVehicle).engineType


	if (getVehicleEngineState(theVehicle) == true) then
		exports['chat-system']:localShout(thePed, "do", "HEY IDIOT, WANT TO DIE? ASSHOLE!")
		--processDoMessage(thePlayer, "The vehicle explodes", thePlayer)
		--blowVehicle (theVehicle, false )
		return
	end

	if not (isPedInVehicle(thePlayer) == true) then
		processMessage(thePed, "Ehm...")
		setConvoState(thePlayer, 0)
		return
	end

	local theLitres = calculateFuelPrice(thePlayer, thePed, amount, moneyType)
	local currentTax = exports.global:getTaxAmount("tax_fuel")
	local price_beforetax = exports.global:roundNumber(theLitres * FUEL_PRICE)
	local tax = exports.global:roundNumber(currentTax*FUEL_PRICE)
	local fuelCost = exports.global:roundNumber(price_beforetax + tax)

	-- print("L:",theLitres,"tax:",tax.." ("..(currentTax*100).."%)","price_before:",price_beforetax,"price_after:",fuelCost)

	if moneyType == 1 then
		money = exports.global:getMoney(thePlayer)
	else
		money = getElementData(thePlayer, "bankmoney")
	end
	local factionVehicle = getElementData(theVehicle, "faction")
	local vehJob = (getElementData(theVehicle, "job") or 0)

	local fuelCompanyID = 0
	local fuelStationName = getElementZoneName(thePlayer) or ""

	local factionPaid = false
	if ( exports["faction-system"]:isPlayerInFaction(thePlayer, factionVehicle) and doesFactionPayForFuel(factionVehicle)
		) or vehJob>0 then

		local theTeam
		if vehJob <= 0 then
			theTeam = exports["faction-system"]:getFactionFromID(factionVehicle)
		else
			theTeam = exports["faction-system"]:getFactionFromID(3)
		end

		if exports.global:takeMoney(theTeam, fuelCost, true) then
			processMessage(thePed, "Here's the receipt for your employer.")
			exports.bank:addBankTransactionLog(-getElementData( theTeam, "id" ), fuelCompanyID, fuelCost, 9, "FUEL "..theLitres.."L", fuelStationName )

			factionPaid = true
		end
	end

	if not factionPaid then
		if (fuelCost > 0 and money > 0) then
			if moneyType == 1 then
				if exports.global:takeMoney(thePlayer, fuelCost) then
					processMessage(thePed, "Here is your receipt.")
				else
					processMessage(thePed, "How were you gonna pay for this? Punk!")
					return
				end
			else
				if exports.bank:updateBankMoney(thePlayer, getElementData(thePlayer, "dbid"), fuelCost, "minus") then
					exports.bank:addBankTransactionLog(getElementData( thePlayer, "dbid" ), fuelCompanyID, fuelCost, 9, "FUEL "..theLitres.."L", fuelStationName )
					processMessage(thePed, "Here is your receipt.")
				else
					processMessage(thePed, "Your card has been rejected...")
					return
				end
			end
		else
			processMessage(thePed, "How about paying this huh?! Punk!")
			return
		end
	end

	exports.global:payTaxToGov(0, tax, "tax_fuel", "Business: "..getElementZoneName(thePlayer).." Gas Station | Item: "..theLitres.."L of Gas | Price before tax: $"..exports.global:formatMoney(price_beforetax))
	local loldFuel = getElementData(theVehicle, "fuel")
	local newFuel = loldFuel+theLitres
	amount = tonumber(amount)
	exports.anticheat:changeProtectedElementDataEx(theVehicle, "fuel", newFuel, false)
	triggerClientEvent(thePlayer, "syncFuel", theVehicle, newFuel)

	local info = {
			{"Gas Station Receipt"},
			{""},
		}


	table.insert(info, {"    " .. (theLitres) .. "L of "..fuelType.."    -    " .. fuelCost .. "$"})
	if factionPaid then
		table.insert(info, {"    Paid by "..tostring(exports["faction-system"]:getFactionName(factionVehicle))})
	end

	table.insert(info, {"    "..exports.global:getVehicleName(theVehicle).." - "..exports.global:round(newFuel, 2).."/"..exports.global:round(getMaxFuel(theVehicle), 2).." L"})
	triggerClientEvent(thePlayer, "hudOverlay:drawOverlayTopRight", thePlayer, info )

	-- give shop owner a portion of fuel price
	-- local shopLink = tonumber( getElementData( thePed, 'shop_link') )
	-- outputDebugString( 'Shop Link: ' .. shopLink )
	-- if shopLink > 0 then
	-- 	local money = math.floor( tonumber( fuelCost ) * 0.4 ) -- give 40% to shop owner
	-- 	outputDebugString( 'Money: ' .. money )
	-- 	local findShop = exports.mysql:query('SELECT `id`, `sIncome` FROM `shops` WHERE `shoptype` = 15 AND `dimension` = ' .. getElementData( thePed, 'shop_link') .. ' LIMIT 1')

	-- 	local row = exports.mysql:fetch_assoc( findShop )
	-- 	if row then
	-- 		for index, shopPed in pairs( getElementsByType( 'ped')) do
	-- 			if tonumber( getElementData( shopPed, "dbid") ) == tonumber( row.id ) and getElementData( shopPed, "ped:type" ) == 'shop' then
	-- 				outputDebugString( 'Shop ID: ' .. row.id )
	-- 				exports.anticheat:changeProtectedElementDataEx( shopPed, "sIncome", tonumber( row.sIncome ) + money )
	-- 			end
	-- 		end
	-- 		exports.mysql:query_free( "UPDATE `shops` SET `sIncome` = `sIncome` + " .. money .. " WHERE `id` = " .. row.id )
	-- 	end
	-- 	mysql:free_result( findShop )
	-- end
end

function setConvoState(thePlayer, state)
	exports.anticheat:changeProtectedElementDataEx(thePlayer, "ped:convoState", state, false)
end

function processMessage(thePed, message, language)
	if not (language) then
		language = 1
	end
	exports['chat-system']:localIC(thePed, message, language)
end

function processMeMessage(thePed, message, source)
	local name = getElementData(thePed, "name") or getPlayerName(thePed)
	exports['global']:sendLocalText(source, " *" ..  string.gsub(name, "_", " ").. ( message:sub( 1, 1 ) == "'" and "" or " " ) .. message, 255, 51, 102)
end

function processDoMessage(thePed, message, source)
	local name = getElementData(thePed, "name") or getPlayerName(thePed)
	exports['global']:sendLocalText(source, " * " .. message .. " *      ((" .. name:gsub("_", " ") .. "))", 255, 51, 102)
end

function calculateFuelPrice(thePlayer, thePed, amount, moneyType)
	local theVehicle = getPedOccupiedVehicle(thePlayer)
	local litresAffordable = getMaxFuel(getElementModel(theVehicle))
	local MAX_FUEL = getMaxFuel(getElementModel(theVehicle))
	local currFuel = tonumber(getElementData(theVehicle, "fuel"))
	local money = 0

	local currentTax = exports.global:getTaxAmount("tax_fuel")
	local price_beforetax = FUEL_PRICE
	local tax = exports.global:roundNumber(currentTax*FUEL_PRICE)
	local cost = price_beforetax + tax

	if moneyType == 2 then
		local money = getElementData(thePlayer, "bankmoney")

		if amount ~= 0 then
			litresAffordable = (amount/cost)
		else
			litresAffordable = (money/cost)
		end

		if (litresAffordable>MAX_FUEL) then
			litresAffordable=MAX_FUEL
		end
	else
		local factionVehicle = getElementData(theVehicle, "faction")
		if (exports["faction-system"]:isPlayerInFaction(thePlayer, factionVehicle) and doesFactionPayForFuel(factionVehicle)) or getElementData(theVehicle, "job")>0 then
			local theTeam = exports["faction-system"]:getFactionFromID(factionVehicle)
			money = exports.global:getMoney(theTeam)
		else
			money = exports.global:getMoney(thePlayer)
		end

		if amount ~= 0 then
			litresAffordable = (amount/cost)
		else
			litresAffordable = (money/cost)
		end

		if (litresAffordable>MAX_FUEL) then
			litresAffordable=MAX_FUEL
		end
	end

	if (litresAffordable+currFuel>MAX_FUEL) then
		litresAffordable = MAX_FUEL - currFuel
	end
	return exports.global:roundNumber(litresAffordable)
end

function createFuelPed(skin, posX, posY, posZ, rotZ, name, int, dim, id, shop_link)
	theNewPed = createPed (50, posX, posY, posZ)
	skin = tonumber(skin)
	if exports["sarp-new-mods"]:isCustomMod(skin, "ped") then
		setElementData(theNewPed, "skinID", skin)
	else
		if not setElementModel(theNewPed, skin) then
			setElementModel(theNewPed, 50)
		end
	end
	exports.pool:allocateElement(theNewPed)
	-- setPedRotation (theNewPed, rotZ)
	setElementRotation(theNewPed, 0,0, rotZ, "default", true)
	setElementFrozen(theNewPed, true)
	--setPedAnimation(theNewPed, "FOOD", "FF_Sit_Loop",  -1, true, false, true)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "talk",1, true)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "name", name:gsub("_", " "), true)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "rpp.npc.name", name:gsub("_", " "), true)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "rpp.npc.type", "fuel", true)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "ped:type", "fuel", true)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "ped:fuelped",true, true)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "shop_link", shop_link, true)

	-- For the language system
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "languages.lang1" , 1, false)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "languages.lang1skill", 100, false)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "languages.lang2" , 2, false)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "languages.lang2skill", 100, false)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "languages.current", 1, false)
	setElementInterior(theNewPed, int)
	setElementDimension(theNewPed, dim)
	exports.anticheat:changeProtectedElementDataEx(theNewPed, "dbid",id, true)
	--createBlip(posX, posY, posZ, 55, 2, 255, 0, 0, 255, 0, 300)
	return theNewPed
end

function makeFuelPed(thePlayer, commandName, skin, ...)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		outputChatBox("SYNTAX: /" .. commandName .. " [skin, default = 50, -1 = random] [Firstname Lastname, default = random]", thePlayer, 255, 194, 14)

		local skin = tonumber(skin)
		if not skin then
			skin = 50
		elseif skin == -1 then
			skin = exports.global:getRandomSkin()
		end

		local gender = exports["ped-system"]:getGenderFromSkin(skin)

		local x, y, z = getElementPosition(thePlayer)
		local dimension = getElementDimension(thePlayer)
		local interior = getElementInterior(thePlayer)
		local rotation = getPedRotation(thePlayer)

		local pedName = table.concat({...}, "_") or false

		if not pedName or pedName== "" or (tonumber(pedName) and tonumber(pedName) == -1) then
			if gender == 0 then
				pedName = exports.global:createRandomMaleName()
			else
				pedName = exports.global:createRandomFemaleName()
			end

			pedName = string.gsub(pedName, " ", "_")
		end

		local id = false
		id = mysql:query_insert_free("INSERT INTO `fuelpeds` SET `name`='"..exports.global:toSQL(pedName).."', `posX`='" .. mysql:escape_string(x) .. "', `posY`='" .. mysql:escape_string(y) .. "', `posZ`='" .. mysql:escape_string(z) .. "', dimension='" .. mysql:escape_string(dimension) .. "', interior='" .. mysql:escape_string(interior) .. "', `rotZ`='" .. mysql:escape_string(rotation) .. "', `skin`='".. mysql:escape_string(skin).."' ")

		if (id) then
			createFuelPed(skin ~= -1 and skin or 50, x,y,z,rotation,pedName,interior,dimension,id, 0)
			-- exports.logs:logMessage("[/"..commandName.."] " .. getElementData(thePlayer, "account:username") .. "/".. getPlayerName(thePlayer) .." did make fuel ped id " .. id .. ".", 4)
		else
			outputChatBox("Error creating fuel ped.", thePlayer, 255, 0, 0)
		end
	end
end
addCommandHandler("makefuelped", makeFuelPed, false, false)
addCommandHandler("makefuel", makeFuelPed, false, false)
addCommandHandler("makefuelnpc", makeFuelPed, false, false)

function onServerStart()
	local sqlHandler = mysql:query("SELECT * FROM fuelpeds WHERE `deletedBy` = 0 ")
	if (sqlHandler) then
		while true do
			local row = mysql:fetch_assoc( sqlHandler )
			if not row then break end
			local thePed = createFuelPed(tonumber(row["skin"]),tonumber(row["posX"]),tonumber(row["posY"]),tonumber(row["posZ"]), tonumber(row["rotZ"]), row["name"], tonumber(row["interior"]), tonumber(row["dimension"]), tonumber(row["id"]), tonumber( row["shop_link"]))
		end
	end
	mysql:free_result(sqlHandler)
end
addEventHandler("onResourceStart", getResourceRootElement(getThisResource()), onServerStart)


function getNearByFuelPeds(thePlayer, commandName) --maxime
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		local posX, posY, posZ = getElementPosition(thePlayer)
		outputChatBox("Nearby Fuel NPC(s):", thePlayer, 255, 126, 0)
		local count = 0

		local dimension = getElementDimension(thePlayer)

		for k, thePed in ipairs(getElementsByType("ped", resourceRoot)) do
			local pedType = getElementData(thePed, "ped:type")
			if (pedType) then
				if (pedType=="fuel") then
					local x, y = getElementPosition(thePed)
					local distance = getDistanceBetweenPoints2D(posX, posY, x, y)
					local cdimension = getElementDimension(thePed)
					if (distance<=10) and (dimension==cdimension) then
						local dbid = getElementData(thePed, "dbid")
						local pedName = getElementData(thePed, "name")
						local shopLink = tonumber(  getElementData(thePed, "shop_link") )
						outputChatBox("   Fuel NPC ID #" .. dbid .. ", name: "..tostring(pedName):gsub("_", " ") .. ( shopLink > 0 and ' shop link: ' .. shopLink or ''), thePlayer, 255, 126, 0)
						count = count + 1
					end
				end
			end
		end

		if (count==0) then
			outputChatBox("   None.", thePlayer, 255, 126, 0)
		end
	end
end
addCommandHandler("nearbyfuels", getNearByFuelPeds, false, false)
addCommandHandler("nearbynpcs", getNearByFuelPeds, false, false)

function gotoFuelPed(thePlayer, commandName, shopID) --maxime
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		if not tonumber(shopID) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Shop ID]", thePlayer, 255, 194, 14)
		else
			local possibleShops = getElementsByType("ped", resourceRoot)
			local foundShop = false
			for _, shop in ipairs(possibleShops) do
				if getElementData(shop,"ped:type") == "fuel" and (tonumber(getElementData(shop, "dbid")) == tonumber(shopID)) then
					foundShop = shop
					break
				end
			end

			if not foundShop then
				outputChatBox("No shop founded with ID #"..shopID, thePlayer, 255, 0, 0)
				return false
			end

			local x, y, z = getElementPosition(foundShop)
			local dim = getElementDimension(foundShop)
			local int = getElementInterior(foundShop)
			local rot = getElementRotation(foundShop)
			startGoingToShop(thePlayer, x,y,z,rot,int,dim,shopID)
		end
	end
end
addCommandHandler("gotofuel", gotoFuelPed, false, false)
addCommandHandler("gotofuelped", gotoFuelPed, false, false)
addCommandHandler("gotofuelnpc", gotoFuelPed, false, false)

function startGoingToShop(thePlayer, x,y,z,r,interior,dimension,shopID) --maxime
	-- Maths calculations to stop the player being stuck in the target
	x = x + ( ( math.cos ( math.rad ( r ) ) ) * 2 )
	y = y + ( ( math.sin ( math.rad ( r ) ) ) * 2 )

	setCameraInterior(thePlayer, interior)

	if (isPedInVehicle(thePlayer)) then
		local veh = getPedOccupiedVehicle(thePlayer)
		setElementAngularVelocity(veh, 0, 0, 0)
		setElementInterior(thePlayer, interior)
		setElementDimension(thePlayer, dimension)
		setElementInterior(veh, interior)
		setElementDimension(veh, dimension)
		setElementPosition(veh, x, y, z + 1)
		warpPedIntoVehicle ( thePlayer, veh )
		setTimer(setElementAngularVelocity, 50, 20, veh, 0, 0, 0)
	else
		setElementPosition(thePlayer, x, y, z)
		setElementInterior(thePlayer, interior)
		setElementDimension(thePlayer, dimension)
	end
	outputChatBox(" You have teleported to Fuel NPC ID#"..shopID, thePlayer)
end

function deleteFuelPed(thePlayer, commandName, id) -- maxime
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		if not (id) then
			outputChatBox("SYNTAX: /" .. commandName .. " [ID]", thePlayer, 255, 194, 14)
		else
			local counter = 0
			for k, thePed in ipairs(getElementsByType("ped", resourceRoot)) do
				local pedType = getElementData(thePed, "ped:type")
				if (pedType) then
					if (pedType=="fuel") then
						local dbid = getElementData(thePed, "dbid")
						if (tonumber(id)==dbid) then
							destroyElement(thePed)
							local adminID = getElementData(thePlayer,"account:id")
							mysql:query_free("UPDATE `fuelpeds` SET `deletedBy` = '"..tostring(adminID).."' WHERE id='" .. mysql:escape_string(dbid) .. "' LIMIT 1")
							outputChatBox("      Deleted fuel npc with ID #" .. id .. ".", thePlayer, 0, 255, 0)
							counter = counter + 1
							setElementData(thePlayer, "fuel:mostRecentDeleteFuelPed",dbid )
						end
					end
				end
			end

			if (counter==0) then
				outputChatBox("No fuel ped with such an ID exists.", thePlayer, 255, 0, 0)
				return false
			end
			return true
		end
	end
end
addCommandHandler("delfuel", deleteFuelPed, false, false)
addCommandHandler("deletefuel", deleteFuelPed, false, false)
addCommandHandler("delfuelped", deleteFuelPed, false, false)
addCommandHandler("deletefuelped", deleteFuelPed, false, false)


addCommandHandler( 'setfuelpedlink',
	function ( player, command, fuelped, shopID )
		if exports.integration:isPlayerAdmin( player ) then
			-- make sure the player actually filled in the data
			if tonumber( fuelped ) and tonumber( shopID ) then
				-- determine if the fuel ped exists.
				local findFuelPed = exports.mysql:query('SELECT `name` FROM `fuelpeds` WHERE `id` = ' .. exports.mysql:escape_string( fuelped ))
				if exports.mysql:num_rows( findFuelPed ) > 0 then
					-- determine if shop exists.
					local findShop = exports.mysql:query( 'SELECT `name` FROM `interiors` WHERE `id` = ' .. exports.mysql:escape_string( shopID ))
					if exports.mysql:num_rows( findShop ) > 0 then
						local findShopPed = exports.mysql:query( 'SELECT `id` FROM `shops` WHERE `shoptype` = 15 AND `dimension` = ' .. exports.mysql:escape_string( shopID ) )
						if exports.mysql:num_rows( findShopPed ) > 0 then
							exports.mysql:update( 'fuelpeds', { shop_link = shopID }, { id = fuelped } )

							for i, ped in pairs( getElementsByType('ped')) do
								if getElementData(ped, "ped:type" ) == "fuel" and getElementData( ped, "dbid") == tonumber( fuelped ) then
									exports.anticheat:changeProtectedElementDataEx( ped, "shop_link", tonumber( shopID ), true )
								end
							end

							outputChatBox( 'That interior has been linked to the fuel ped.', player, 155, 255, 155 )
						else
							outputChatBox( 'That interior does not have a shop type 15.', player, 255, 155, 155 )
						end
						exports.mysql:free_result( findShopPed )
					else
						outputChatBox( 'No such interior found.', player, 255, 155, 155 )
					end
					mysql:free_result( findShop )
				else
					outputChatBox( 'No such fuel ped found.', player, 255, 155, 155 )
				end
				mysql:free_result( findFuelPed )
			else
				outputChatBox( "SYNTAX: /" .. command .. " [fuel ped ID] [shop interior ID]", player, 255, 255, 255 )
			end
		end
	end
)
