-- Fernando
-- 2021 SARP

local GUIEditor = {
    edit = {},
    button = {},
    window = {},
    label = {},
    combobox = {}
}

local pedName
local cost = 50

local progressTimer = nil

function createGUI(pedName_)
	pedName = pedName_

	closeDuplicateWindow()

	GUIEditor.window[1] = guiCreateWindow(0, 0, 272, 180, "Locksmith", false)
	guiWindowSetSizable(GUIEditor.window[1], false)
	exports.global:centerWindow(GUIEditor.window[1])

	GUIEditor.label[1] = guiCreateLabel(0.03, 0.12, 0.93, 0.09, "What key would you like to duplicate?", true, GUIEditor.window[1])


	GUIEditor.combobox[1] = guiCreateComboBox(0.03, 0.27, 0.97, 0.53, "Select a key", true, GUIEditor.window[1])

	local validKeys = {
		[4] = true,
		[5] = true,
		[73] = true,
		[3] = true,
		[98] = true,
		[151] = true,
	}

	for k, item in ipairs(exports["item-system"]:getItems(localPlayer)) do
		if validKeys[tonumber(item[1])] then

			local name, desc = exports["item-system"]:getItemName(tonumber(item[1]), tonumber(item[2]), item[5])
			if desc then
				desc = "(#"..item[2]..") "..desc
				-- outputChatBox(item[1].." - "..item[2].." : "..desc)
				guiComboBoxAddItem(GUIEditor.combobox[1], desc)
			end
		end
	end


	GUIEditor.label[3] = guiCreateProgressBar(0.03, 0.80, 0.42, 0.10, true, GUIEditor.window[1])

	GUIEditor.button[1] = guiCreateButton(0.53, 0.75, 0.23, 0.18, "Duplicate", true, GUIEditor.window[1])
	addEventHandler("onClientGUIClick", GUIEditor.button[1], function ()
			if not inprocess then
				local selitem = guiComboBoxGetSelected( GUIEditor.combobox[1] )
				if selitem ~= -1 then
					local selectedName = guiComboBoxGetItemText( GUIEditor.combobox[1], selitem )
					if selectedName then

						local foundKeyID, foundKeyValue

						for k, item in ipairs(exports["item-system"]:getItems(localPlayer)) do
							if validKeys[tonumber(item[1])] then
								local name, desc  = exports["item-system"]:getItemName(tonumber(item[1]), tonumber(item[2]), item[5])
								if desc then
									desc = "(#"..item[2]..") "..desc
									if desc == selectedName then
										foundKeyID = tonumber(item[1])
										foundKeyValue = tonumber(item[2])
										break
									end
								end
							end
						end

						if foundKeyID and foundKeyValue then
							duplicateKey(foundKeyID, foundKeyValue)
						end
					end
				end
			end
		end, false)

	GUIEditor.button[2] = guiCreateButton(0.76, 0.75, 0.19, 0.18, "Close", true, GUIEditor.window[1])
	addEventHandler("onClientGUIClick", GUIEditor.button[2], function ()
			closeDuplicateWindow()
		end, false)

	triggerEvent("f_toggleCursor", localPlayer, true)
	guiSetInputEnabled(true)
end
addEvent("locksmithGUI", true)
addEventHandler("locksmithGUI", localPlayer, createGUI)

function closeDuplicateWindow()
	if isElement(GUIEditor.window[1]) then
		destroyElement(GUIEditor.window[1])
	end
	guiSetInputEnabled(false)
	inprocess = false
	if isTimer(progressTimer) then
		outputChatBox("Copying cancelled!", 255,0,0)
		killTimer(progressTimer)
	end
end

function duplicateKey(keyid, keyvalue)

	-- local keytypes = {}

	-- if type == "Main Door Key" then keytypes = {4, 5} end
	-- if type == "Door Key" then keytypes = {73} end
	-- if type == "Vehicle Key" then keytypes = {3} end
	-- if type == "Garage Remote" then keytypes = {98} end
	-- if type == "Ramp Remote" then keytypes = {151} end


	-- doublecheck
	if not exports.global:hasItem( getLocalPlayer(), tonumber(keyid), tonumber(keyvalue) ) then
		guiSetText( GUIEditor.label[1], "You do not possess this key." )
		guiLabelSetColor( GUIEditor.label[1], 255, 0, 0 )
		progressTimer = setTimer(function ()
				if isElement(GUIEditor.label[1]) then
					guiSetText(GUIEditor.label[1], "What key would you like to duplicate?")
					guiLabelSetColor(GUIEditor.label[1], 255, 255, 255)
				end
			end, 2000, 1)
		return
	end

	if not exports.global:hasMoney(getLocalPlayer(), cost) then -- checks if the player has enough money to get it duplicated
		guiSetText( GUIEditor.label[1], "You need $"..cost.." to duplicate a key." )
		guiLabelSetColor( GUIEditor.label[1], 255, 0, 0 )
		progressTimer = setTimer(function ()
				if isElement(GUIEditor.label[1]) then
					guiSetText(GUIEditor.label[1], "What key would you like to duplicate?")
					guiLabelSetColor(GUIEditor.label[1], 255, 255, 255)
				end
			end, 2000, 1)
		return
	end

	guiSetText(GUIEditor.label[1], "Duplicating...")
	guiLabelSetColor(GUIEditor.label[1], 0, 255, 0)

	guiProgressBarSetProgress(GUIEditor.label[3], 0)
	inprocess = true

	setTimer( function()
		if isElement(GUIEditor.label[3]) and isTimer(progressTimer) then
			guiProgressBarSetProgress (GUIEditor.label[3], guiProgressBarGetProgress(GUIEditor.label[3]) + 5 )
		end
	end, 500, 20)

	progressTimer = setTimer(function ()
		if isElement(GUIEditor.window[1]) then
			guiSetText(GUIEditor.label[1], "Duplicated!")
			inprocess = false

			triggerServerEvent("locksmithNPC:givekey", resourceRoot, getLocalPlayer(), keyid, keyvalue, cost, pedName)
		end
	end, 10000, 1)
end


-- createGUI("Jasper Brooks") --testing
