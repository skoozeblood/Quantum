
local editing, editingObject
local wInfo, eInfo, bReset, bClose, bProtect = nil, {}
local screenX, screenY = guiGetScreenSize( )
local ignoreGUIInput, ignoreKeyInput = false, false
exteriorMoving=nil -- Forthwind

local moveSpam
local moveSpamDelay = 2000


-- testing
local testingID

function moveTestObj(cmd, id)
  id = tonumber(id)
  if not id then
    return outputChatBox("SYNTAX: /"..cmd.." [testObj ID]", 255,194,14)
  end
  local object = getElementData(root, "testObj_"..id)
  if not isElement(object) then
    return outputChatBox("No test object found with ID "..id, 255,0,0)
  end
  testingID = id
  makeWindow(object)
  outputChatBox("Moving test object #"..id, 0,255,0)
end
addCommandHandler("mto", moveTestObj, false)

function getInFrontOf( x, y, rot, dist )
  return x + (dist or 1) * math.sin( math.rad( -rot ) ), y + (dist or 1) * math.cos( math.rad( -rot ) )
end


-- Fernando
playerMoveBannedItems = {

  [2] = true,
  [3] = true,
  [4] = true,
  [5] = true,
  [6] = true,
  [27] = true,
  [29] = true,
  [30] = true,
  [31] = true,
  [32] = true,
  [33] = true,
  [34] = true,
  [35] = true,
  [36] = true,
  [37] = true,
  [38] = true,
  [39] = true,
  [40] = true,
  [41] = true,
  [42] = true,
  [43] = true,
  [44] = true,
  [45] = true,
  [47] = true,
  [50] = true,
  [85] = true,
  [98] = true,
  [115] = true,
  [116] = true,
  [126] = true,
  [133] = true,
  [137] = true,
  [148] = true,
  [149] = true,
  [150] = true,
  [151] = true,
  [152] = true,
  [153] = true,
  [154] = true,
  [155] = true,
  [169] = true,
  [170] = true,
  [181] = true,
  [182] = true,
  [214] = true,
  [219] = true,
  [220] = true,
  [221] = true,
  [224] = true,
  [225] = true,
  [226] = true,
  [227] = true,
  [228] = true,
  [261] = true,
  [269] = true,
  [267] = true,
  [300] = true,
}

function canPlayerMoveItem(thePlayer, itemID, itemValue, metadata, object)
  itemID = tonumber(itemID)
  local isAdm = exports.global:isAdminOnDuty(thePlayer)
  if playerMoveBannedItems[itemID] and not isAdm then
    return false, "You cannot move this item."
  end

  if exports["item-system"]:isBadge(itemID) and not isAdm then
    return false, "You cannot move badges."
  end

  if exports["sittablechairs"]:isSittableChair(object) then
    if exports["sittablechairs"]:isChairUsed(object) and not isAdm then
      return false, "This object cannot be moved as it's being used."
    end
  end

  return true
end


-- exported
function isEditing()
  return isElement(editingObject)
end

function getObjectName( object )
  if isElement(object) then
    local specialObject = getElementData(object, "sarp_items:artifact")
    if specialObject then
      return tostring(specialObject).." (CUSTOM)"
    end

    local model = getElementModel(object)
    if tonumber(model) then

      if testingID and getElementData(root, "testObj_"..testingID) then
        return "TObj #"..model
      else
        local name = engineGetModelNameFromID( model )
        if name then
          return name .. ' [' .. model .. ']'
        end
      end
    end
  end
  return tostring(model)
end

local function getFancyRotation( rx, ry, rz )
  if rx < 0 then
    rx = 360-rx
  end
  if ry < 0 then
    ry = 360-ry
  end
  if rz < 0 then
    rz = 360-rz
  end
  return rx,ry,rz
end

local function canEditObject( object )
  return exports.integration:isStaffOnDuty(localPlayer) or exports.integration:isPlayerScripter(localPlayer)
end

-- Forthwind
function checkIfCloseBy()
	if exteriorMoving ~= nil then
		local x, y, z = getElementPosition(editingObject)
		local hX, hY, hZ = getElementPosition(exteriorMoving)
		if getDistanceBetweenPoints3D(x, y, z, hX, hY, hZ) > 10 then
			return outputChatBox("Object is too far from interior entrance, move it closer to save!", client, 255)
		else
			return false
		end
	end
end

function makeWindow(object)
  editing = object and getElementDimension(object) or nil
  guiSetInputMode("no_binds_when_editing")--Fernando
  
  if isElement(wInfo) then
    reset( )

    destroyElement( wInfo )
    wInfo = nil

    removeEventHandler( 'onClientElementDestroy', root, destroyed )
    removeEventHandler( 'onClientRender', root, render )
    removeEventHandler( 'onClientKey', root, captureKeys )
    resetController( )
    setElementFrozen( localPlayer, false )
    setObject( )
  end
  if editing and object then
    -- the info panel for the object attributes
    wInfo = guiCreateWindow( screenX - 250 -35, screenY - 265, 250+35, 265, '', false)
    guiWindowSetMovable( wInfo, false )

    for k, name in ipairs({'Model', 'PosX', 'PosY', 'PosZ', 'RotX', 'RotY', 'RotZ'}) do
      local y = k * 25
      guiCreateLabel( 15, y + 2, 35, 20, name .. ':', false, wInfo )
      eInfo[k] = guiCreateEdit( 55, y, 200, 20, '', false, wInfo )

      addEventHandler( 'onClientGUIFocus', eInfo[k], function( ) ignoreKeyInput = true end, false )
      addEventHandler( 'onClientGUIBlur', eInfo[k], function( ) ignoreKeyInput = false end, false )
      addEventHandler( 'onClientGUIChanged', eInfo[k],
        function( )
          if not ignoreGUIInput then
            local x, y, z = tonumber(guiGetText(eInfo[2])), tonumber(guiGetText(eInfo[3])), tonumber(guiGetText(eInfo[4]))
            local rx, ry, rz = tonumber(guiGetText(eInfo[5])), tonumber(guiGetText(eInfo[6])), tonumber(guiGetText(eInfo[7]))
            if x and y and z and rx and ry and rz then
              setElementPosition( editingObject, x, y, z )
              setElementRotation( editingObject, rx, ry, rz )
            end
          end
        end, false)
    end
    guiEditSetReadOnly( eInfo[1], true )

    bProtect = guiCreateButton( 5, 200, 65, 20, 'Protect', false, wInfo )
    addEventHandler( 'onClientGUIClick', bProtect,
      function( button, state )
        if button == 'left' and state == 'up' then

    if exteriorMoving ~= nil then
      local closeEnough = checkIfCloseBy()
      if closeEnough ~= false then return end
    end

          triggerEvent("item:move:protect", editingObject)
        end
      end, false
    )

    bReset = guiCreateButton( 75, 200, 65, 20, 'Reset', false, wInfo )
    addEventHandler( 'onClientGUIClick', bReset,
      function( button, state )
        if button == 'left' and state == 'up' then

          if moveSpam then
            return outputChatBox("Please wait before trying to move an item again.", 187, 187, 187)
          end
          moveSpam = setTimer(function() moveSpam = nil end, moveSpamDelay, 1)

          reset( true )
          updateInfoPanel( )
        end
      end, false
    )

    bSave = guiCreateButton( 145, 200, 65, 20, 'Save', false, wInfo )
    addEventHandler( 'onClientGUIClick', bSave,
      function( button, state )
        if button == 'left' and state == 'up' then

          if moveSpam then
            return outputChatBox("Please wait before trying to move an item again.", 187, 187, 187)
          end
          moveSpam = setTimer(function() moveSpam = nil end, moveSpamDelay, 1)

          save( )
          updateInfoPanel( )
        end
      end, false
    )

    bClose = guiCreateButton( 215, 200, 30, 20, 'Close', false, wInfo )
    addEventHandler( 'onClientGUIClick', bClose,
      function( button, state )
        if button == 'left' and state == 'up' then
          close( )
        end
      end, false
    )

    local bCopy = guiCreateButton( 215+32, 200, 30, 20, 'Copy', false, wInfo )
    guiSetProperty(bCopy, "NormalTextColour", "FF00FF00")
    addEventHandler( 'onClientGUIClick', bCopy,
      function( button, state )
        if button == 'left' and state == 'up' then
          if isElement(editingObject) then
            local x,y,z = getElementPosition(editingObject)
            local rx,ry,rz = getElementRotation(editingObject)
            local text = x..", "..y..", "..z..",  "..rx..", "..ry..", "..rz
            if setClipboard(text) then
              outputChatBox("Copied to clipboard: "..text, 255,194,14)
            end
          end
        end
      end, false
    )

    local controls = guiCreateLabel( 15, 225, 240, 40, "Moving: WASD, Arrow Up/Down\nRotating: Arrow Left/Right, Mouse", false, wInfo )

    setObject( object )
    updateInfoPanel( )

    --

    addEventHandler( 'onClientElementDestroy', root, destroyed )
    addEventHandler( 'onClientRender', root, render )
    addEventHandler( 'onClientKey', root, captureKeys )
  end
end

addEvent('item:move', true)
addEventHandler('item:move', root,
  function(object, int)
    if not object then return end
    local itemID = getElementData(object, "itemID")
    local itemValue = getElementData(object, "itemValue")
    local metadata = getElementData(object, "metadata")

    -- Fernando
    local can, reason = canPlayerMoveItem(localPlayer,itemID,itemValue,metadata,object)
    if not can then
      outputChatBox(reason, 255,0,0)
      return
    end

	if int ~= nil then exteriorMoving = int end
    makeWindow(object)
  end, false
)

function destroyed( )
  if source == editingObject then
    setObject( )
    updateInfoPanel( )

    triggerEvent('item:move', root)
  end
end

function roundNumber(num)
  return num
end

function updateInfoPanel( )
  if editingObject then
    ignoreGUIInput = true


    guiSetSize( wInfo, 250+35, 265, false )
    guiSetPosition( wInfo, screenX - 250-35, screenY - 265, false )
    guiSetText( wInfo, 'Object' )

    -- new & shiny coords
    guiSetText( eInfo[1], getObjectName( editingObject ) )
    for k, v in ipairs({getElementPosition(editingObject)}) do
      guiSetText( eInfo[k+1], roundNumber(v) )
    end
    local rx, ry, rz = getFancyRotation(getElementRotation(editingObject))
    guiSetText( eInfo[5], roundNumber(rx) )
    guiSetText( eInfo[6], roundNumber(ry) )
    guiSetText( eInfo[7], roundNumber(rz) )

    ignoreGUIInput = false

    guiSetVisible( wInfo, true )
    --guiSetText( bClose, isChanged() and 'Save' or 'Close' )
  elseif isElement( wInfo ) then
    guiSetVisible( wInfo, false )
  end
end

function isChanged( )
  if editingObject then
    local difference = 0
    local x, y, z = getElementPosition(editingObject)
    local rx, ry, rz = getFancyRotation(getElementRotation(editingObject))
    local new = {{x, y, z}, {rx, ry, rz}}
    local keys = { 'pos', 'rot' }

    local hasChanged = true
    return hasChanged, new, x, y, z, rx, ry, rz
  end

  return false
end

function save( )
  if editingObject then
    -- did anyone even touch this?

	if exteriorMoving ~= nil then
		local closeEnough = checkIfCloseBy()
		if closeEnough ~= false then return end
	end
    local changed, new, x, y, z, rx, ry, rz = isChanged()
    if changed then
      setElementRotation(editingObject, rx, ry, rz)
      if setElementCollisionsEnabled(editingObject, true) then
        -- print("save col enabled")
      end

      if not isElementLocal(editingObject) then
        triggerServerEvent( 'item:move:save', editingObject, x, y, z, rx, ry, rz )
      end
    else
      setObject( )
      triggerEvent('item:move', root)
    end
  end
end

function close( )
  reset( )
  setObject( )

  if wInfo then


    destroyElement( wInfo )
    guiSetInputMode("allow_binds")--Fernando
    wInfo = nil

    removeEventHandler( 'onClientElementDestroy', root, destroyed )
    removeEventHandler( 'onClientRender', root, render )
    removeEventHandler( 'onClientKey', root, captureKeys )
    resetController( )
    setElementFrozen( localPlayer, false )
    setObject( )
  end
  exteriorMoving = nil
end
addEvent("menu:close", true)
addEventHandler("menu:close", root, close)

function reset( remainEditing )
  if editingObject then
    if not isElementLocal(editingObject) then
      triggerServerEvent("item:move:resetpos", editingObject)
    end
    if remainEditing then
      if setElementCollisionsEnabled(editingObject, false) then
        -- print("reset remainEditing col disabled")
      end
    else
      if setElementCollisionsEnabled(editingObject, true) then
        -- print("reset col enabled")
      end
    end
  end
end

--
-- mostly just for keeping data up to date

function getObject( )
  return editingObject
end

function setObject( obj )
  editingObject = obj
  if obj then

    if setElementCollisionsEnabled(obj, false) then
      -- print("setObject col disabled")
    end

    if isElement(wInfo) then
      guiSetEnabled(bProtect, not isElementLocal(editingObject))
      guiSetEnabled(bReset, not isElementLocal(editingObject))
      guiSetEnabled(bSave, not isElementLocal(editingObject))
    end
  end
  updateCamera( )
end

function updateCamera( )
  if editingObject and isCursorShowing( ) and not isMTAWindowActive( ) then
    --setCameraMatrix( getCameraMatrix( ) )
    if getElementAlpha( localPlayer ) == 255 then
      setElementAlpha( localPlayer, 63 )
    end
  else
    if getCameraTarget( ) ~= localPlayer then
      --setCameraTarget( localPlayer )
    end
    if getElementAlpha( localPlayer ) == 63 then
      setElementAlpha( localPlayer, 255 )
    end
  end
end

--
-- fancy key actions

function render( )
  if editing ~= getElementDimension( localPlayer ) then
    triggerEvent('item:move', root)
  else
    setElementFrozen( localPlayer, isCursorShowing( ) )
    local x, y, z, rx, ry, rz, deselect, reset_, next, prev = updateKeys( editingObject )
    updateCamera( )
    if not isMTAWindowActive( ) and not ignoreKeyInput then
      if editingObject then
        renderLines( editingObject )
      end
      if not isCursorShowing( ) then return end

      if editingObject then
        if reset_ then
          reset( true )
        elseif x then
          setElementPosition( editingObject, x, y, z )
          setElementRotation( editingObject, rx, ry, rz )
        end
      end

      if not reset_ and (next or prev or deselect) then
        save( )

        if deselect then
          guiGridListSetSelectedItem( gExisting, 0, 0 )
        else
          local row = guiGridListGetSelectedItem( gExisting )
          local max = guiGridListGetRowCount( gExisting ) - 1
          if prev then
            row = row - 1
            if row < -1 then
              row = max
            end
          elseif next then
            row = row + 1
            if row > max then
              row = -1
            end
          end
          guiGridListSetSelectedItem( gExisting, row, 1 )
        end
        triggerEvent( 'onClientGUIClick', gExisting, 'left', 'up' )
      end

      updateInfoPanel( )
    end
  end
end

addEventHandler( 'onClientResourceStop', resourceRoot,
  function( )
    if editing then
      setElementFrozen( localPlayer, false )
      if getElementAlpha( localPlayer ) == 63 then
        setElementAlpha( localPlayer, 255 )
      end
    end
  end
)

--

function isMouseOverGUI( cx, cy )
  if not cx then
    cx, cy = getCursorPosition( )
    cx, cy = cx * screenX, cy * screenY
  end
  for k, v in ipairs( getElementsByType( 'gui-window' ) ) do
    if guiGetVisible( v ) then
      local ax, ay = guiGetPosition( v, false )
      local bx, by = guiGetSize( v, false )
      bx, by = bx + ax, by + ay
      if cx >= ax and cx <= bx and cy >= ay and cy <= by then
        return true
      end
    end
  end
end

addEventHandler( 'onClientElementDataChange', resourceRoot,
  function( name )
    if name == 'moving' and source == editingObject then
      setObject( )
    end
  end
)
