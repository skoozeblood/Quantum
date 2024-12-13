--Vehicle textures
--Script that handles texture replacements for vehicles
--Created by Exciter, 01.01.2015 (DD.MM.YYYY).

local vehicle = nil
local isAdmin = false
local busy = false

	local sw, sh = guiGetScreenSize()
	local width = 600
	local height = 400
	local x = ( sw - width ) / 2
	local y = ( sh - height ) / 2

timer = nil
function initiateAntiAboose()
	local x,y,z = getElementPosition(localPlayer)
	if not isTimer(timer) then
		timer = setTimer(function()
			local nx,ny,nz = getElementPosition(localPlayer)
			if getDistanceBetweenPoints3D(x,y,z,nx,ny,nz) > 50 then
				vehTex_hideGui()
				killTimer(timer)
		timer = nil
			end
		end, 1000,0)
	end
end

hiddenTexNames = {
	["plateback1"] = true,
	["plateback2"] = true,
	["plateback3"] = true,
}

local gui = {}
function vehTex_showGui(editVehicle, admin, bypass)

	if busy and not bypass then return end
	busy = true

	initiateAntiAboose()

	if admin then isAdmin = true else
		isAdmin = false
	end

	vehicle = editVehicle
	if not vehicle then
		return false
	end

	if isAdmin then triggerEvent("f_toggleCursor", localPlayer, true)
	end


	local vehID = getElementData(vehicle, "dbid")

	local windowTitle = "Texture list for vehicle ID #"..tostring(vehID)
	gui.window = guiCreateWindow ( x, y, width, height, windowTitle, false )
	gui.list = guiCreateGridList ( 10, 25, width - 20, height - 120, false, gui.window )
	gui.remove = guiCreateButton ( 10, height - 90, width - 20, 25, "Remove selected texture", false, gui.window )
	gui.add = guiCreateButton ( 10, height - 60, width - 20, 25, "Add new texture", false, gui.window )
	gui.cancel = guiCreateButton ( 10, height - 30, width - 20, 25, "Close", false, gui.window )

	if isAdmin then
		guiGridListAddColumn ( gui.list, "Texture", 0.2 )
		guiGridListAddColumn ( gui.list, "URL", 0.8 )
	else
		guiGridListAddColumn ( gui.list, "Texture", 1 )
	end

	guiWindowSetSizable ( gui.window, false )
	guiSetEnabled ( gui.remove, false )


	local currentTextures = getElementData(vehicle, "textures")
	for k,v in ipairs(currentTextures) do
		if v[1] and v[2] then
			if not hiddenTexNames[v[1]] then
				local row = guiGridListAddRow ( gui.list )
				guiGridListSetItemText ( gui.list, row, 1, v[1], false, false )
				if isAdmin then
					guiGridListSetItemText ( gui.list, row, 2, v[2], false, false )
				end
			end
		end
	end

	if isAdmin then
		addEventHandler ( "onClientGUIClick", gui.window, vehTex_WindowClick )
		addEventHandler("onClientGUIDoubleClick", gui.window, vehTex_copyToClipboard)
	else
		addEventHandler ( "onClientGUIClick", gui.window, vehTex_WindowClick )
	end
end
addEvent("item-texture:vehtex")
addEventHandler("item-texture:vehtex", getRootElement(), vehTex_showGui)

function vehTex_WindowClick ( button, state )
	if button == "left" and state == "up" then
		if source == gui.cancel then
			vehTex_hideGui ( )
			if not isAdmin then
				triggerEvent("garageSys:openUpgradesMenu",localPlayer)
			end
		elseif source == gui.list then
			local texID = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 1 )

			if texID ~= "" then
				guiSetEnabled ( gui.remove, true )
			else
				guiSetEnabled ( gui.remove, false )
			end
		elseif source == gui.add then
			vehTex_addGui()
		elseif source == gui.remove then
			local row, column = guiGridListGetSelectedItem(gui.list)
			local texname = guiGridListGetItemText ( gui.list, row, 1 )
			if texname ~= "" then
				if isAdmin then
					guiGridListRemoveRow(gui.list, row)
					triggerServerEvent("vehtex:removeTexture", getLocalPlayer(), vehicle, texname)
				else
					triggerEvent("garage:addTextureToBasket",localPlayer, vehicle,texname,texurl, true)
					vehTex_hideGui()
					triggerEvent("garageSys:openUpgradesMenu",localPlayer)
				end
			end
		end
	end
end

function vehTex_copyToClipboard()
    if source == gui.list then
        local url = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 2 )
        if url then
            outputChatBox("URL copied to clipboard.")
            setClipboard(url)
        end
    end
end

function vehTex_hideGui()
	if gui.window then
		if gui.window2 then
			destroyElement ( gui.window2 )
			gui.window2 = nil
		end
		if gui.window3 then
			destroyElement ( gui.window3 )
			gui.window3 = nil
		end
		if gui.window4 then
			destroyElement ( gui.window4 )
			gui.window4 = nil
		end
		destroyElement ( gui.window )
		gui.window = nil
		vehicle = nil

		busy = false


		if isAdmin then triggerEvent("f_toggleCursor", localPlayer, false) end

	end
end

function vehTex_hideGui_2()
	if gui.window then
		if gui.window2 then
			destroyElement ( gui.window2 )
			gui.window2 = nil
		end
		if gui.window3 then
			destroyElement ( gui.window3 )
			gui.window3 = nil
		end
		destroyElement ( gui.window )
		gui.window = nil
	end

end

function vehTex_previewBox(texname, texurl)

	local sw, sh = guiGetScreenSize()
	local width = 400
	local height = 80
	local x = ( sw - width ) / 2
	local y = ( sh - height ) / 2

	gui.window4 = guiCreateWindow(15, y, width, height, "Texture Preview", false)
	guiWindowSetSizable(gui.window4, false)

	gui.prevLabel = guiCreateLabel(10, height/4, width-20, height-40, tostring(texname), false, gui.window4)
		guiLabelSetHorizontalAlign(gui.prevLabel, "center", true)
		-- guiLabelSetVerticalAlign(gui.prevLabel, "center")
	gui.prevBtn = guiCreateButton(10, height-35, width-20, 30, "End Preview", false, gui.window4)
	addEventHandler ( "onClientGUIClick", gui.prevBtn, function ()
		vehTex_previewBox_hide(texname, texurl)
	end, false )
end
function vehTex_previewBox_hide(texname, texurl)
	if gui.window4 then
		destroyElement ( gui.window4 )
		gui.window4 = nil
	end
	triggerServerEvent("vehtex:removeTexture", getLocalPlayer(), vehicle, texname, true, localPlayer)
	setTimer(function()
		vehTex_addGui(texname, texurl)
	end, 1000, 1)
end

function vehTex_addGui(tn, tu)


	if isAdmin then
		triggerEvent("displayMesaage", localPlayer, "License plate textures can be changed with /setplatetexture or mechanic garage menu", "info")
	end

	vehTex_hideGui_2()
	if isAdmin then
		gui.window2 = guiCreateWindow(x, y, width, height-50, "Add New Vehicle Texture", false)
	else
		gui.window2 = guiCreateWindow(x, y, width, height-50, "Preview Texture", false)
	end
	guiWindowSetSizable(gui.window2, false)


	gui.addLabel2 = guiCreateLabel(15, 58, 50, 18, "Texture:", false, gui.window2)
	gui.addCombo = guiCreateComboBox(74, 64, width-100, height-250, "", false, gui.window2)

	gui.addLabel1 = guiCreateLabel(36, 32, 30, 17, "URL:", false, gui.window2)
	gui.addUrl = guiCreateEdit(76, 29, width-100, 25, "", false, gui.window2)


	gui.addCancel = guiCreateButton(width-215, height-65-50, 200, 40, "Cancel", false, gui.window2)
	addEventHandler ( "onClientGUIClick", gui.addCancel, function()
		vehTex_addGui_hide()
		vehTex_showGui(vehicle, isAdmin, true)
		end, false )

	gui.addApply = guiCreateButton(15, height-65-50, 200, 40, "Apply", false, gui.window2)
	addEventHandler ( "onClientGUIClick", gui.addApply, vehTex_addGui_apply, false )
	guiSetProperty ( gui.addApply, "NormalTextColour", "FF00FF00")

	gui.pBtn = guiCreateButton(15, height-65-50-50, 200, 40, "Preview", false, gui.window2)
	addEventHandler ( "onClientGUIClick", gui.pBtn, vehTex_addGui_preview, false )
	guiSetProperty ( gui.pBtn, "NormalTextColour", "FFFFEF00")

	guiSetInputEnabled(true)


	local alreadyAdded = {}
	local currentTextures = getElementData(vehicle, "textures")
	for k,v in ipairs(currentTextures) do
		if v[1] then
			alreadyAdded[v[1]] = true
		end
	end
	local model = exports.global:getVehicleModelNew(vehicle)
	local texnames = engineGetModelTextureNames(tostring(model))
	if extraVehTexNames[model] then
		for k,v in ipairs(extraVehTexNames[model]) do
			table.insert(texnames, v)
		end
	end


	if globalVehTexNames then
		for k,v in ipairs(globalVehTexNames) do
			table.insert(texnames, v)
		end
	end

	local ind = 0
	local c = 0
	for k,v in ipairs(texnames) do
		if not alreadyAdded[tostring(v)] then
			guiComboBoxAddItem(gui.addCombo, tostring(v))
			if tn == tostring(v) then
				ind = c
			end
			c = c + 1
		end
	end

	if tn and tu then
		guiComboBoxSetSelected(gui.addCombo, ind)
		guiSetText(gui.addUrl, tu)
	end
end

function vehTex_addGui_hide(finalClose)
	if gui.window2 then
		destroyElement ( gui.window2 )
		gui.window2 = nil
		if gui.window3 then
			destroyElement ( gui.window3 )
			gui.window3 = nil
		end
	end
	guiSetInputEnabled(false)

	if finalClose then
		busy = false
		if isAdmin then triggerEvent("f_toggleCursor", localPlayer, false) end
	end

end

function vehTex_error(msg)
	if gui.window3 then
		vehTex_error_hide()
	end
	if isElement(gui.window2) then
		guiSetEnabled(gui.window2, false)
	end

	local sw, sh = guiGetScreenSize()
	local width = 400
	local height = 150
	local x = ( sw - width ) / 2
	local y = ( sh - height ) / 2

	gui.window3 = guiCreateWindow(x, y, width, height, "Error", false)
	guiWindowSetSizable(gui.window3, false)

	gui.errorLabel = guiCreateLabel(10, 20, width-20, height-40, tostring(msg), false, gui.window3)
		guiLabelSetHorizontalAlign(gui.errorLabel, "center", true)
		guiLabelSetVerticalAlign(gui.errorLabel, "center")
	gui.errorBtn = guiCreateButton(10, height-35, width-20, 30, "OK", false, gui.window3)
	addEventHandler ( "onClientGUIClick", gui.errorBtn, vehTex_error_hide, false )
end
function vehTex_error_hide()
	if isElement(gui.window2) then
		guiSetEnabled(gui.window2, true)
	end
	if gui.window3 then
		destroyElement ( gui.window3 )
		gui.window3 = nil
	end
	if gui.addApply then
		guiSetEnabled(gui.addApply, true)
		guiSetText(gui.addApply, "Apply")
	end
	if gui.pBtn then
		guiSetEnabled(gui.pBtn, true)
		guiSetText(gui.pBtn, "Preview")
	end
end


function vehTex_addGui_apply()
	guiSetEnabled(gui.addApply, false)
	guiSetText(gui.addApply, "Please wait...")
	local texurl = guiGetText(gui.addUrl)
	local texname = tostring(guiComboBoxGetItemText(gui.addCombo, guiComboBoxGetSelected(gui.addCombo)))
	if (not texname or texname == "" or texname == " ") then
		vehTex_error("You did not select what texture you want to replace.")
		return false
	end
	if (not texurl or texurl == "" or texurl == " ") then
		vehTex_error("You did not enter an URL.")
		return
	end

	local valid, err = isImageURLValid(texurl)
	if not valid then
		vehTex_error(err)
		return false
	end

	--validate file
	local path = getPath(texurl)
	if fileExists(path) then --file already exists, so we dont need to validate
		if isAdmin then
			vehTex_apply(texname, texurl)
		else
			vehTex_sendMech(texname, texurl)
		end
	else
		--we need to download :(
		triggerServerEvent("vehtex:validateFile", resourceRoot, vehicle, texname, texurl, false)
		guiSetText(gui.addApply, "Please wait. Downloading...")
	end
end

function vehTex_addGui_preview()
	guiSetEnabled(gui.pBtn, false)
	guiSetText(gui.pBtn, "Please wait...")
	local texurl = guiGetText(gui.addUrl)
	local texname = tostring(guiComboBoxGetItemText(gui.addCombo, guiComboBoxGetSelected(gui.addCombo)))
	if (not texname or texname == "" or texname == " ") then
		vehTex_error("You did not select what texture you want to replace.")
		return false
	end
	if (not texurl or texurl == "" or texurl == " ") then
		vehTex_error("You did not enter an URL.")
		return
	end
	if (string.len(texurl)>36) then
		vehTex_error("URL too long. Try uploading to Imgur.")
		return
	end

	triggerServerEvent("vehtex:validateFile", resourceRoot, vehicle, texname, texurl, true)
end

-- receive answer from server:
function vehTex_fileValidationResult(editVehicle, texname, texurl, approved, msg)
	if not editVehicle or not vehicle then return false end
	if editVehicle ~= vehicle then return false end
	if approved then
		vehTex_apply(texname, texurl)
		return true
	else
		vehTex_error("File validation failed! \n"..tostring(msg))
		return false
	end
end
addEvent("vehtex:fileValidationResult", true)
addEventHandler("vehtex:fileValidationResult", resourceRoot, vehTex_fileValidationResult)

-- receive answer from server:
function P_vehTex_fileValidationResult(editVehicle, texname, texurl, approved, msg)
	if not editVehicle or not vehicle then return false end
	if editVehicle ~= vehicle then return false end
	if approved then
		vehTex_addGui_hide()
		triggerServerEvent("vehtex:addTexture", getLocalPlayer(), vehicle, texname, texurl, true, localPlayer)
		vehTex_previewBox(texname,texurl)
		return true
	else
		vehTex_error("File validation failed! \n"..tostring(msg))
		return false
	end
end
addEvent("vehtex:fileValidationResult:PREVIEW", true)
addEventHandler("vehtex:fileValidationResult:PREVIEW", resourceRoot, P_vehTex_fileValidationResult)

function vehTex_sendMech(texname, texurl)
	triggerEvent("garage:addTextureToBasket",localPlayer, vehicle,texname,texurl)
	vehTex_addGui_hide(true)
	triggerEvent("garageSys:openUpgradesMenu",localPlayer)
end

function vehTex_apply(texname, texurl)
	triggerServerEvent("vehtex:addTexture", getLocalPlayer(), vehicle, texname, texurl)
	vehTex_addGui_hide(true)
end