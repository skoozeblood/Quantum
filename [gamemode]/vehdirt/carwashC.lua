local sx, sy = guiGetScreenSize()

local carwashMarkers = {}

local currentWashVehicle = nil

local carwashState = 1
local lastClick = 0

wGUI = {}
wW, wH = 200, 100
bH = 30

washTimer1, washTimer2 = nil, nil

function showWashGUI()
	closeWashGUI()

	wGUI.main = guiCreateWindow(0, 0, wW, wH, "Car Wash - $"..washPrice, false)
	exports.global:centerWindow(wGUI.main)

	wGUI.bCash = guiCreateButton(5, 22, wW-10, bH, "Pay (Cash)", false, wGUI.main)
	if not exports.global:hasMoney(localPlayer, washPrice) then
		guiSetEnabled(wGUI.bCash, false)
	end
	addEventHandler( "onClientGUIClick", wGUI.bCash,
	function (button)
		if button == "left" then
			destroyElement(wGUI.main)
			triggerServerEvent("vehdirt:buyCarWash", localPlayer, currentWashVehicle, false)
		end
	end, false)

	wGUI.bBank = guiCreateButton(5, 22+bH+5, wW-10, bH, "Pay (Bank)", false, wGUI.main)
	if not exports.bank:hasBankMoney(localPlayer, washPrice) then
		guiSetEnabled(wGUI.bBank, false)
	end
	addEventHandler( "onClientGUIClick", wGUI.bBank,
	function (button)
		if button == "left" then
			destroyElement(wGUI.main)
			triggerServerEvent("vehdirt:buyCarWash", localPlayer, currentWashVehicle, true)
		end
	end, false)
end

function closeWashGUI()
	if isTimer(washTimer1) then killTimer(washTimer1) end
	if isTimer(washTimer2) then killTimer(washTimer2) end
	if isElement(wGUI.main) then
		destroyElement(wGUI.main)
	end
end

function createCarwashes()
	for k, v in pairs(carwashes) do
		if v[5] then
			local carwashGarage = createObject(12943, v[1], v[2], v[3]-1, 0, 0, v[4]+90, false)
			local carwashInterior = createObject(12942, v[1], v[2], v[3]-1, 0, 0, v[4]+90, false)
			local carwashBrush = createObject(7311, v[1], v[2], v[3]+1, 0, 0, v[4]+90, false)
			setElementCollisionsEnabled(carwashBrush, false)
		end
		local marker = createMarker(v[1], v[2], v[3]-1, "cylinder", 3, 0, 180, 255, 0)
		carwashMarkers[marker] = true
		-- local carwashBlip = createBlip(v[1], v[2], v[3], 55, 1, 255, 255, 255, 255, 0, 100)
	end

	addEventHandler("onClientMarkerHit", root, triggerCarwash)
	addEventHandler("onClientMarkerLeave", root,
		function(thePlayer)

			if carwashMarkers[source] then
				if thePlayer ~= localPlayer then return end
				closeWashGUI()
			end
		end
	)
end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), createCarwashes)

function triggerCarwash(hitElement, matchingDimension)
	if carwashMarkers[source] then
		if (getElementType(hitElement) == "player") then

			if hitElement ~= localPlayer then return end

			local vehicle = getPedOccupiedVehicle(hitElement)
			if (vehicle) then
				local driver = getVehicleOccupant(vehicle)
				if driver == hitElement then
					currentWashVehicle = vehicle
					local dirtLevel = getVehicleDirtLevel(currentWashVehicle)
					if dirtLevel <= 1 then
						outputChatBox("Your vehicle is already clean!", 255,255,255)
						return
					end
					showWashGUI()
				end
			end
		end
	end
end

function sprayEffects(vehicle)
	local vehX, vehY, vehZ = getElementPosition(vehicle)
	for P=-1,1 do
		for Q=-1,1 do
			fxAddWaterHydrant(vehX+P, vehY-Q, vehZ-4)
			setTimer(function()
				setTimer(function()
					fxAddWaterSplash(vehX+P, vehY-Q, vehZ)
				end, 500, 5)
			end, 10000, 1)
		end
	end
end
addEvent("vehdirt:doSprayEffects", true)
addEventHandler("vehdirt:doSprayEffects", root, sprayEffects)


function washVehicle(vehicle)

	setElementFrozen(vehicle, true)
	setElementData(localPlayer, "spraying", true)

	washTimer1 = setTimer(function()

		if isElement(vehicle) then

			triggerServerEvent("setVehicleGrungeServer", vehicle, vehicle, 1)

			washTimer2 = setTimer(function()

				if isElement(vehicle) then
					setElementFrozen(vehicle, false)
				end
				setElementData(localPlayer, "spraying", false)
				outputChatBox("Enjoy your clean vehicle!", 0,255,0)
			end, 10000, 1)
		end
	end, 5000, 1)
end
addEvent("vehdirt:washVeh", true)
addEventHandler("vehdirt:washVeh", root, washVehicle)


--[[
local smoothMoveEXP = 0
local expWidth, expHeight = 300, 20
local expX, expY = sx/2 - expWidth/2, sy/2

addEventHandler("onClientRender", root, function()
	local actualHP = getElementHealth(localPlayer)
	local progress = ( actualHP/100 ) * expWidth

	if smoothMoveEXP > progress then
		smoothMoveEXP = smoothMoveEXP - 5
	end
	if smoothMoveEXP < progress then
		smoothMoveEXP = smoothMoveEXP + 5
	end

	dxDrawRectangle(expX, expY, expWidth, expHeight, tocolor(0, 0, 0, 255/100*65))
	if actualHP == 0 then else
		dxDrawRectangle(expX+1, expY + 1, smoothMoveEXP, 18, tocolor(214, 63, 62, 255))
		dxDrawRectangle(expX+1, expY + 1, smoothMoveEXP, 1, tocolor(214, 63, 62, 255))
	end
	dxDrawText(actualHP.." HP", expX + 1, expY +4, expWidth-2 + expX + 1, 20 + expY - 20, tocolor(255, 255, 255, 255/2), 1, "default", "center", "top", false, false, true, true)
end)
]]
