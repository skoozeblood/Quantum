-- Fernando / SARP 2021

-- Fernando
-- 2021 SARP

local bc = {}

local GUIEditor = {
    memos = {},
    button = {},
    window = {},
    label = {},
    combobox = {}
}

local pedName
local minCharText = 16
local cost = 20

local question = "Design your own customized business card!"
local placeholder = "John Doe - Lead Sales Executive\nPH 123456\nwww.example.com"

function createBcardsGUI(pedName_)
	pedName = pedName_

	closeBcardsWindow()

	bc.window = guiCreateWindow(0, 0, 272, 210, "Business Cards", false)
	guiWindowSetSizable(bc.window, false)
	exports.global:centerWindow(bc.window)

	GUIEditor.label[1] = guiCreateLabel(0.03, 0.12, 0.93, 0.09, question, true, bc.window)
	GUIEditor.combobox[1] = guiCreateComboBox(0.03, 0.27, 0.47, 0.69, "Amount", true, bc.window)
	guiComboBoxAddItem(GUIEditor.combobox[1], "1")
	guiComboBoxAddItem(GUIEditor.combobox[1], "5")
	guiComboBoxAddItem(GUIEditor.combobox[1], "10")
	guiComboBoxAddItem(GUIEditor.combobox[1], "15")
	guiComboBoxAddItem(GUIEditor.combobox[1], "20")


	GUIEditor.memos[1] = guiCreateMemo(0.03, 0.41, 0.93, 0.3, placeholder, true, bc.window)
	addEventHandler( "onClientGUIClick", GUIEditor.memos[1],
	function (button, state, absoluteX, absoluteY)
		local text = guiGetText(source)
		if text == placeholder then
			guiSetText(source, "")
		end
	end, false)


	GUIEditor.label[2] = guiCreateLabel(0.53, 0.29, 0.40, 0.12, "($"..cost.." each)", true, bc.window)

	GUIEditor.button[1] = guiCreateButton(0.51, 0.75, 0.23, 0.15, "Purchase", true, bc.window)
	addEventHandler("onClientGUIClick", GUIEditor.button[1], function ()

			local amount = guiGetText(GUIEditor.combobox[1])
			if not amount or not tonumber(amount) then
				return triggerEvent("displayMesaage", localPlayer, "You need to select an amount!", 'error')
			end
			local text = guiGetText(GUIEditor.memos[1])
			if not text or text == "" then
				return triggerEvent("displayMesaage", localPlayer, "You need to enter text to display on the business card.", 'error')
			end

			if string.len(text) < minCharText then
				return triggerEvent("displayMesaage", localPlayer, "You need to enter at least "..minCharText.." characters.", 'error')
			end

			makeBusinessCard(amount, text)
			closeBcardsWindow()

		end, false)

	GUIEditor.button[2] = guiCreateButton(0.76, 0.75, 0.23, 0.15, "Close", true, bc.window)
	addEventHandler("onClientGUIClick", GUIEditor.button[2], function ()
			closeBcardsWindow()
		end, false)

	triggerEvent("f_toggleCursor", localPlayer, true)
	guiSetInputEnabled(true)
end
addEvent("bcardsGUI", true)
addEventHandler("bcardsGUI", localPlayer, createBcardsGUI)

function closeBcardsWindow()
	if isElement(bc.window) then
		destroyElement(bc.window)
	end
	triggerEvent("f_toggleCursor", localPlayer, false)
	guiSetInputEnabled(false)
end

function makeBusinessCard(amount, text)
	local keytype = nil

	amount = tonumber(amount)
	local cost1 = amount * cost

	if not exports.global:hasMoney(getLocalPlayer(), cost1) then

		guiSetText( GUIEditor.label[1], "You need $"..cost1.."in cash." )
		guiLabelSetColor( GUIEditor.label[1], 255, 0, 0 )
		setTimer(function ()
			if isElement(GUIEditor.label[1]) then
				guiSetText(GUIEditor.label[1], question)
				guiLabelSetColor(GUIEditor.label[1], 255, 255, 255)
			end
		end, 2000, 1)
		return
	end

	triggerServerEvent("bcardsNPC:make", root, localPlayer, amount, text, cost)
end
