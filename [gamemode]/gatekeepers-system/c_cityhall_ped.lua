-- Fernando

local vmOptionMenu = nil

local pname = nil

function popupJesPedMenu(pedname)
	pname = pedname
	if getElementData(getLocalPlayer(), "exclusiveGUI") then
		return
	end
	closevmPedMenu()
	local width, height = 200, 300
	local scrWidth, scrHeight = guiGetScreenSize()
	local x = scrWidth/2 - (width/2)
	local y = scrHeight/2 - (height/2)

	vmOptionMenu = guiCreateStaticImage(x, y, width, height, ":resources/window_body.png", false)

	local l1 = guiCreateLabel(0, 0.06, 1, 0.25, "What can I help you with?", true, vmOptionMenu)
	guiLabelSetHorizontalAlign(l1, "center")

	local bheight = 26
	local bx = 6
	local bys = bheight + 6

	local by = 48

	local bJob = guiCreateButton(bx, by, width-bx*2, bheight, "Apply for Job", false, vmOptionMenu)
	addEventHandler("onClientGUIClick", bJob, bJobF, false)
	guiSetProperty ( bJob, "NormalTextColour", "FFFFFFFF")

	by = by + bys

	local bBiz = guiCreateButton(bx, by, width-bx*2, bheight, "Register Business", false, vmOptionMenu)
	addEventHandler("onClientGUIClick", bBiz, regBiz, false)
	guiSetProperty ( bBiz, "NormalTextColour", "FFFFFFFF")

	by = by + bys

	-- local bFine = guiCreateButton(bx, by, width-bx*2, bheight, "Parking Tickets", false, vmOptionMenu)
	-- addEventHandler("onClientGUIClick", bFine, payFines, false)
	-- guiSetProperty ( bFine, "NormalTextColour", "FFFFFFFF")

	-- by = by + bys

	local bID = guiCreateButton(bx, by, width-bx*2, bheight, "New ID Card ($5)", false, vmOptionMenu)
	addEventHandler("onClientGUIClick", bID, newIDCard, false)
	guiSetProperty ( bID, "NormalTextColour", "FFFFFFFF")

	by = by + bys

	local bLocksmith = guiCreateButton(bx, by, width-bx*2, bheight, "Copy Keys (Locksmith)", false, vmOptionMenu)
	addEventHandler("onClientGUIClick", bLocksmith, locksmith, false)
	guiSetProperty ( bLocksmith, "NormalTextColour", "FFFFFFFF")

	by = by + bys

	-- local bCards = guiCreateButton(bx, by, width-bx*2, bheight, "Custom Business Cards", false, vmOptionMenu)
	-- addEventHandler("onClientGUIClick", bCards, bizcards, false)
	-- guiSetProperty ( bCards, "NormalTextColour", "FFFFFFFF")

	-- by = by + bys

	local bSomethingElse = guiCreateButton(bx, by, width-bx*2, bheight, "Nevermind", false, vmOptionMenu)
	addEventHandler("onClientGUIClick", bSomethingElse, closevmPedMenu, false)

	-- triggerEvent("f_toggleCursor", localPlayer, true)
end
addEvent("cityhall:jesped", true)
addEventHandler("cityhall:jesped", getRootElement(), popupJesPedMenu)

function closevmPedMenu()
	if vmOptionMenu and isElement(vmOptionMenu) then
		destroyElement(vmOptionMenu)
		vmOptionMenu = nil
	end
	-- triggerEvent("f_toggleCursor", localPlayer, false)
end

function bizcards()
	closevmPedMenu()
	triggerEvent("bcardsGUI", localPlayer, pname)
end

function locksmith()
	closevmPedMenu()
	triggerEvent("locksmithGUI", localPlayer, pname)
end

function bJobF()
	closevmPedMenu()
	triggerEvent("onEmployment", getLocalPlayer(), pname)
end

function newIDCard()
	closevmPedMenu()
	triggerServerEvent("cityhall:makeIdCard", getLocalPlayer())
end

function regBiz()
	closevmPedMenu()
	triggerEvent("factions:onRegistryPed", getLocalPlayer())
end

-- function payFines()
-- 	closevmPedMenu()
-- 	triggerServerEvent("openPayParkingTicketsNPC", getLocalPlayer(), pname)
-- end
