local sw, sh = guiGetScreenSize ( )
local gui = { }

-- Fernando: texlist highlighting the selected texture
hl, hlTexname, hlTexID = nil, nil, nil
hlReplacement = dxCreateShader ( "shaders/replacement2.fx" )

function highlightTexture(texName, texID)
	texID = tonumber(texID)

	local dim = getElementDimension(localPlayer)

	if hlTexname and texName and hlTexname == texName then return end

	if hl and hlTexname then
		-- delete
		engineRemoveShaderFromWorldTexture(hlReplacement, hlTexname)
		if isElement(hl) then destroyElement(hl) end
		addTexture(hlTexID)

		hl = nil
		hlTexname = nil
		hlTexID = nil
	end

	if texName then

		triggerEvent("frames:removeOne", resourceRoot, dim, texID, texName)
	end
end

function highlightTexture_2(texName, texID)
	texID = tonumber(texID)

	local dim = getElementDimension(localPlayer)

	if hlTexname and texName and hlTexname == texName then return end

	if hl and hlTexname then
		-- delete
		engineRemoveShaderFromWorldTexture(hlReplacement, hlTexname)
		if isElement(hl) then destroyElement(hl) end
		addTexture(hlTexID)

		hl = nil
		hlTexname = nil
		hlTexID = nil
	end

	if texName then

		triggerEvent("frames:removeOne", resourceRoot, dim, texID, texName)
	end
end

local worldObject
function showJustTexturesList(worldObject_, model, textures)
	if not gui.window then
		worldObject = worldObject_
		triggerEvent("displayMesaage", localPlayer, "Clearing textures to allow preview..", "info")

		-- clear all item textures first
		triggerEvent("item-texture:removeOne", localPlayer, worldObject)
		-- clear all texture system textures too
		for k, texname2 in pairs(textures) do -- they're not applied to objects, but to everything
											  -- when the player is inside the dimension
			for id, _ in pairs(loaded) do
				if loaded.texname == texname2 then
					destroyElement(loaded.texture)
					destroyElement(loaded.shader)
				end
			end
		end


		local width = 250
		local height = 300
		local x = sw - width - 30
		local y = ( sh - height ) / 2

		local windowTitle = (engineGetModelNameFromID(model) or "Unknown").." #" .. model

		gui.window = guiCreateWindow ( x, y, width, height, windowTitle, false )
		gui.list = guiCreateGridList ( 10, 25, width - 20, height-60, false, gui.window )

		gui.cancel = guiCreateButton ( 10, height - 30, width - 20, 25, "Close", false, gui.window )

		guiGridListAddColumn ( gui.list, " ", 0.15 )
		guiGridListAddColumn ( gui.list, "Texture Name (click me to preview)", 0.73 )

		guiWindowSetSizable ( gui.window, false )
		triggerEvent("f_toggleCursor", localPlayer, true)

		frames_fillTexList_2( textures or {} )

		addEventHandler ( "onClientGUIClick", gui.window, frames_texWindowClick_2 )
		addEventHandler("onClientGUIDoubleClick", gui.window, frames_texWindowDoubleClick_2)
	end
end
addEvent("showJustTexturesList", true)
addEventHandler("showJustTexturesList", root, showJustTexturesList)

function frames_showTexGUI ( )
	local interiorID = getElementDimension ( localPlayer )
	local interiorWorld = getElementInterior( localPlayer )

	local admEditPerm = hasWorldEditPerm(localPlayer)
	local iOwnerPerm = legitimateOwner(localPlayer, interiorID)

	if interiorID == 0 and interiorWorld == 0 and not admEditPerm then
		outputChatBox("You do not have permission to edit the exterior world.", 187, 187, 187)
		if exports.integration:isPlayerTrialAdmin(localPlayer) then
			outputChatBox("You need to be on admin duty to gain access.", 222, 187, 222)
		end
		return
	end

	if interiorID > 0 then
		if not iOwnerPerm and not admEditPerm then
			outputChatBox("You do not have permission to edit textures in this interior.", 187, 187, 187)
			if exports.integration:isPlayerTrialAdmin(localPlayer) then
				outputChatBox("You need to be on admin duty to gain access.", 222, 187, 222)
			end
			return
		end
	end

	if not gui.window then
		local width = 600
		local height = 430+30
		local x = ( sw - width ) / 2
		local y = ( sh - height ) / 2

		local windowTitle = "Texture list for interior ID #" .. interiorID
		if(interiorID > 20000) then
			windowTitle = "Texture list for interior of vehicle #" .. interiorID - 20000
			if(not exports.global:hasItem(localPlayer, 3, interiorID-20000)) then
				windowTitle = "Texture list for interior of vehicle #" .. interiorID - 20000 .. " (Admin access)"
			end
		elseif(interiorWorld == 0) then
			windowTitle = "Texture list for exterior region #" .. interiorID .. " (Admin access)"
		else
			if(not exports.global:hasItem(localPlayer, 4, interiorID) and not exports.global:hasItem(localPlayer, 5, interiorID)) then
				windowTitle = "Texture list for interior ID #"..interiorID.." (Admin access)"
			end
		end
		gui.window = guiCreateWindow ( x, y, width, height, windowTitle, false )
		gui.list = guiCreateGridList ( 10, 25, width - 20, height - 150, false, gui.window )


		gui.rotate = guiCreateButton ( 10, height - 120, width - 20, 25, "Rotate selected texture by 90°", false, gui.window )
		guiSetProperty(gui.rotate, "NormalTextColour", "ff00e1ff")

		gui.remove = guiCreateButton ( 10, height - 90, width - 20, 25, "Remove selected texture", false, gui.window )
		guiSetProperty(gui.remove, "NormalTextColour", "ffff6200")

		gui.removeall = guiCreateButton ( 10, height - 60, width - 20, 25, "Remove all textures", false, gui.window )
		guiSetProperty(gui.removeall, "NormalTextColour", "ffff0000")

		gui.cancel = guiCreateButton ( 10, height - 30, width - 20, 25, "Cancel", false, gui.window )

		guiGridListAddColumn ( gui.list, "ID", 0.1 )
		guiGridListAddColumn ( gui.list, "Texture", 0.2 )
		guiGridListAddColumn ( gui.list, "URL", 0.8 )

		guiWindowSetSizable ( gui.window, false )
		guiSetEnabled ( gui.remove, false )
		guiSetEnabled ( gui.rotate, false )
		triggerEvent("f_toggleCursor", localPlayer, true)

		frames_fillTexList( savedTextures[getElementDimension(localPlayer)] or {})

		addEventHandler ( "onClientGUIClick", gui.window, frames_texWindowClick )
		addEventHandler("onClientGUIDoubleClick", gui.window, frames_texWindowDoubleClick)
	else
		frames_hideTexGUI ( )
	end
end
addCommandHandler ( "texlist", frames_showTexGUI )

local uSure--?

function frames_texWindowClick ( button, state )
	if button == "left" and state == "up" then
		if source == gui.cancel then
			frames_hideTexGUI ( )

		elseif source == gui.list then
			local texID = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 1 )
			local texName = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 2 )

			if texID ~= "" then
				guiSetEnabled ( gui.remove, true )
				guiSetEnabled ( gui.rotate, true )

				-- Fernando: Highlight texture
				highlightTexture(texName, texID)
			else
				guiSetEnabled ( gui.remove, false )
				guiSetEnabled ( gui.rotate, false )

				-- Fernando: Highlight texture STOP
				highlightTexture()
			end
		elseif source == gui.remove then
			local texID = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 1 )

			if texID ~= "" then
				frames_hideTexGUI ( )
				triggerServerEvent ( "frames:delete", resourceRoot, tonumber( texID ) )
			end
		elseif source == gui.removeall then

			if not uSure then

				triggerEvent("displayMesaage", localPlayer, "Click again if you want to remove all textures in this interior.", "info")
				uSure = setTimer(function()
					uSure = nil
				end, 5000, 1)
				return
			else
				frames_hideTexGUI ( )
				triggerServerEvent ( "frames:deleteall", resourceRoot)
				uSure = nil
			end
		elseif source == gui.rotate then
			local texID = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 1 )

			if texID ~= "" then
				triggerServerEvent ( "frames:updateRotation", resourceRoot, tonumber( texID ) )
			end
		end
	end
end


function frames_texWindowClick_2 ( button, state )
	if button == "left" and state == "up" then
		if source == gui.cancel then
			frames_hideTexGUI ( )

			if isElement(worldObject) then

				triggerEvent("displayMesaage", localPlayer, "Resetting textures back to normal..", "info")
				triggerServerEvent("item-world:reloadOneItem", localPlayer, getElementData(worldObject, "id"))
			end

		elseif source == gui.list then
			local texID = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 1 )
			local texName = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 2 )

			if texID ~= "" then

				-- Fernando: Highlight texture
				highlightTexture_2(texName, texID)
			else

				-- Fernando: Highlight texture STOP
				highlightTexture_2()
			end
		elseif source == gui.remove then
			local texID = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 1 )

			if texID ~= "" then
				frames_hideTexGUI ( )
				triggerServerEvent ( "frames:delete", resourceRoot, tonumber( texID ) )
			end
		elseif source == gui.removeall then

			if not uSure then

				triggerEvent("displayMesaage", localPlayer, "Click again if you want to remove all textures in this interior.", "info")
				uSure = setTimer(function()
					uSure = nil
				end, 5000, 1)
				return
			else
				frames_hideTexGUI ( )
				triggerServerEvent ( "frames:deleteall", resourceRoot)
				uSure = nil
			end
		elseif source == gui.rotate then
			local texID = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 1 )

			if texID ~= "" then
				triggerServerEvent ( "frames:updateRotation", resourceRoot, tonumber( texID ) )
			end
		end
	end
end

function frames_texWindowDoubleClick()
    if source == gui.list then
        local url = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 3 )
        if url then
            outputChatBox("URL copied to clipboard.")
            setClipboard(url)
        end
    end
end

function frames_texWindowDoubleClick_2()
    if source == gui.list then
        local name = guiGridListGetItemText ( gui.list, guiGridListGetSelectedItem ( gui.list ), 2 )
        if name then
            outputChatBox(name.." copied to clipboard.")
            setClipboard(name)
        end
    end
end

function frames_hideTexGUI ( )
	if gui.window then
		destroyElement ( gui.window )
		gui.window = nil

		triggerEvent("f_toggleCursor", localPlayer, false)

		-- Fernando: Highlight texture STOP
		highlightTexture()
		highlightTexture_2()
	end
end

function frames_fillTexList ( texList )
	if gui.list then
		guiGridListClear ( gui.list )
	end

	local any = false
	for _, tex in pairs ( texList ) do
		any = true
		local row = guiGridListAddRow ( gui.list )

		guiGridListSetItemText ( gui.list, row, 1, tex.id, false, false )
		guiGridListSetItemText ( gui.list, row, 2, tex.texture, false, false )
		guiGridListSetItemText ( gui.list, row, 3, tex.url, false, false )
	end

	if not any then
		guiGridListSetItemText ( gui.list, guiGridListAddRow ( gui.list ), 1, "None", true, false )
		return
	end
end

function frames_fillTexList_2 ( texList )
	if gui.list then
		guiGridListClear ( gui.list )
	end

	local any = false

	local id = 1

	for _, name in pairs ( texList ) do
		any = true
		local row = guiGridListAddRow ( gui.list )

		guiGridListSetItemText ( gui.list, row, 1, id, false, false )
		guiGridListSetItemText ( gui.list, row, 2, name, false, false )

		id = id + 1
	end

	if not any then
		guiGridListSetItemText ( gui.list, guiGridListAddRow ( gui.list ), 1, "None", true, false )
		return
	end
end

