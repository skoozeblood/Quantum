-- Fernando: 21/05/2021
-- ability to adjust position/rotation/scale of artifacts
-- based on a community resource

local SCREENSIZE_X, SCREENSIZE_Y = guiGetScreenSize()
local RESOLUTION_OFFSET_RIGHT = 0.715
local RESOLUTION_OFFSET_BOTTOM = 0.997
local NUM_CUBOIDS = 6
local IMAGE_PREFIX = "images/"
local MOUSE_LEFT_DOWN = false
local FOR_LOOP_CALLBACK = {}
local CURSOR_CACHE = {}
local ARTIFACT_NAME, POSITION_OBJECT, CACHE_CHECK, CURR_CHECK
local WAS_WEARING
local POSITION_LOCALISATION = {}
local HOVER_ELEMENT
local OBJECT_X, OBJECT_Y, OBJECT_Z = 0.001, 0.001, 0.001
local OBJECT_RX, OBJECT_RY, OBJECT_RZ = 1, 1, 1
local OBJECT_SCALE = 0.01
local POSITION_BONE = 1
local POSITION_TABLE = {
  0,
  0,
  0,
  0,
  0,
  0,
  1
}
local CUBOID_PARAMETERS = {
  0,
  0,
  0,
  0.1,
  0.1,
  0.1
}
local LINE_PARAMETERS = {
  [2] = {
    0,
    255,
    0,
    230,
    0.5
  },
  [4] = {
    255,
    0,
    0,
    230,
    0.5
  },
  [6] = {
    181,
    34,
    203,
    230,
    0.5
  }
}
local POSITION_DATA = {
  CUBOIDS = {},
  CUB_IMAGES = {
    -- ["saveicon.png"] = {
    --   true,
    --   -145,
    --   40,
    --   1,
    --   {
    --     0,
    --     0,
    --     0,
    --     0
    --   },
    --   false
    -- },

    -- ["h_saveicon.png"] = {
    --   false,
    --   -145,
    --   40,
    --   1,
    --   {
    --     0,
    --     0,
    --     0,
    --     0
    --   },
    --   false
    -- },
    -- ["cancelicon.png"] = {
    --   true,
    --   -200,
    --   40,
    --   1,
    --   {
    --     0,
    --     0,
    --     0,
    --     0
    --   },
    --   false
    -- },
    -- ["h_cancelicon.png"] = {
    --   false,
    --   -200,
    --   40,
    --   1,
    --   {
    --     0,
    --     0,
    --     0,
    --     0
    --   },
    --   false
    -- },
    ["arrowicon.png"] = {
      false,
      20,
      40,
      1,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["rotation.png"] = {
      true,
      -35,
      40,
      1,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["resizeicon.png"] = {
      true,
      -90,
      40,
      1,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["arrowiconx.png"] = {
      true,
      20,
      40,
      6,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["arrowicony.png"] = {
      true,
      20,
      40,
      3,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["arrowiconz.png"] = {
      true,
      20,
      40,
      2,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["resizeiconx.png"] = {
      false,
      20,
      40,
      6,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["resizeicony.png"] = {
      false,
      20,
      40,
      3,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["resizeiconz.png"] = {
      false,
      20,
      40,
      2,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["rotationx.png"] = {
      false,
      20,
      40,
      6,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["rotationy.png"] = {
      false,
      20,
      40,
      3,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["rotationz.png"] = {
      false,
      20,
      40,
      2,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_arrowicon.png"] = {
      true,
      20,
      40,
      1,
      {
        0,
        0,
        0,
        0
      },
      true
    },
    ["h_arrowiconx.png"] = {
      false,
      20,
      40,
      6,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_arrowicony.png"] = {
      false,
      20,
      40,
      3,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_arrowiconz.png"] = {
      false,
      20,
      40,
      2,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_rotation.png"] = {
      false,
      -35,
      40,
      1,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_rotationx.png"] = {
      false,
      20,
      40,
      6,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_rotationy.png"] = {
      false,
      20,
      40,
      3,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_rotationz.png"] = {
      false,
      20,
      40,
      2,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_resizeicon.png"] = {
      false,
      -90,
      40,
      1,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_resizeiconx.png"] = {
      false,
      20,
      40,
      6,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_resizeicony.png"] = {
      false,
      20,
      40,
      3,
      {
        0,
        0,
        0,
        0
      },
      false
    },
    ["h_resizeiconz.png"] = {
      false,
      20,
      40,
      2,
      {
        0,
        0,
        0,
        0
      },
      false
    },
  }
}
local ATTACH_OFFSETS = {
  [1] = {
    0.5,
    0,
    0.6
  },
  [2] = {
    -0.5,
    0,
    0.6
  },
  [3] = {
    0,
    0.5,
    0.6
  },
  [4] = {
    0,
    -0.5,
    0.6
  },
  [5] = {
    0,
    0,
    0.1
  },
  [6] = {
    0,
    0,
    1
  }
}
function wearable_initialize_lines()
  wearable_create_lines()
  wearable_icon_handler()
  wearable_draw_icons()
end
function wearable_is_main_icon(IMAGE_NAME)
  local MAIN_ICON_TABLE = {
    ["h_arrowicon.png"] = true,
    ["h_rotation.png"] = true,
    ["h_resizeicon.png"] = true
  }
  if MAIN_ICON_TABLE[IMAGE_NAME] and POSITION_DATA.CUB_IMAGES[IMAGE_NAME][6] then
    return true
  end
end

function wearable_update_position(POSITION_STATE)
  if POSITION_STATE == true then
    OBJECT_X, OBJECT_Y, OBJECT_Z = 0.004, 0.004, -0.004
    OBJECT_RX, OBJECT_RY, OBJECT_RZ = 1, 1, 1
    OBJECT_SCALE = 0.01
  elseif POSITION_STATE == false then
    OBJECT_X, OBJECT_Y, OBJECT_Z = -0.003, -0.003, 0.003
    OBJECT_RX, OBJECT_RY, OBJECT_RZ = -1, -1, -1
    OBJECT_SCALE = -0.01
  end
end

function wearable_hover_image_check(CURSOR_X, CURSOR_Y, X, Y, W, H)
  local X_CHECK = X < CURSOR_X and CURSOR_X < X + W
  local Y_CHECK = Y < CURSOR_Y and CURSOR_Y < Y + H
  return X_CHECK and Y_CHECK
end

function wearable_save()
  local currentPos = {
      POSITION_TABLE[1],
      POSITION_TABLE[2],
      POSITION_TABLE[3],
      POSITION_TABLE[4],
      POSITION_TABLE[5],
      POSITION_TABLE[6],
      POSITION_TABLE[7]
    }

    updateWearablesTable(ARTIFACT_NAME, currentPos)
    wearable_hide()
end

function wearable_icon_action(ICON_ACTION)
  local TOGGLE_ICONS = {}
  if wearable_is_main_icon(ICON_ACTION) then
    return
  end
  -- if ICON_ACTION == "h_saveicon.png" then
  --   do
  --     wearable_save()
  --   end
  -- elseif ICON_ACTION == "h_cancelicon.png" then
  --   do
  --     wearable_hide()
  --   end
  -- elseif ICON_ACTION == "h_arrowicon.png" then
  if ICON_ACTION == "h_arrowicon.png" then
    TOGGLE_ICONS = {
      "arrow",
      "rotation",
      "h_arrowicon.png",
      "rotation.png"
    }
  elseif ICON_ACTION == "h_rotation.png" then
    TOGGLE_ICONS = {
      "rotation",
      "arrow",
      "h_rotation.png",
      "arrowicon.png"
    }
  end
  if next(TOGGLE_ICONS) then
    local ENABLE_ICON, DISABLE_ICON, MAIN_ICON, PREV_MAIN_ICON = unpack(TOGGLE_ICONS)
    for IMAGE_NAME, IMAGE_DATA in pairs(POSITION_DATA.CUB_IMAGES) do
      if IMAGE_NAME == MAIN_ICON then
        POSITION_DATA.CUB_IMAGES[IMAGE_NAME][1] = true
        POSITION_DATA.CUB_IMAGES[IMAGE_NAME][6] = true
      elseif string.find(IMAGE_NAME, DISABLE_ICON) then
        POSITION_DATA.CUB_IMAGES[IMAGE_NAME][1] = false
        POSITION_DATA.CUB_IMAGES[IMAGE_NAME][6] = false
        if IMAGE_NAME == PREV_MAIN_ICON then
          POSITION_DATA.CUB_IMAGES[IMAGE_NAME][1] = true
        end
      elseif string.find(IMAGE_NAME, ENABLE_ICON) and not string.find(IMAGE_NAME, "h_") then
        POSITION_DATA.CUB_IMAGES[IMAGE_NAME][1] = true
        POSITION_DATA.CUB_IMAGES[IMAGE_NAME][6] = false
      end
    end
  end
end
function wearable_on_click_handler(button, state)
  if HOVER_ELEMENT then
    if button == "left" and state == "down" then
      MOUSE_LEFT_DOWN = true
      if HOVER_ELEMENT == "h_saveicon.png" or HOVER_ELEMENT == "h_cancelicon.png" then
        wearable_icon_action(HOVER_ELEMENT)
      elseif HOVER_ELEMENT == "h_arrowicon.png" then
        wearable_icon_action(HOVER_ELEMENT)
      elseif HOVER_ELEMENT == "h_rotation.png" then
        wearable_icon_action(HOVER_ELEMENT)
      end
      return
    else
      MOUSE_LEFT_DOWN = false
    end
  elseif MOUSE_LEFT_DOWN then
    MOUSE_LEFT_DOWN = false
  end
  CURSOR_CACHE = {}
end
function wearable_mouse_move_handler(_, _, C_X, C_Y, W_X, W_Y, W_Z)
  if HOVER_ELEMENT and MOUSE_LEFT_DOWN then
    if not next(CURSOR_CACHE) then
      CURSOR_CACHE = {
        C_X,
        C_Y,
        W_X,
        W_Y,
        W_Z
      }
    end
    local CURSOR_X, CURSOR_Y, CURSOR_WX, CURSOR_WY, CURSOR_WZ = unpack(CURSOR_CACHE)
    POSITION_LOCALISATION = {
      X = {CURSOR_WX, W_X},
      Y = {CURSOR_WY, W_Y},
      Z = {CURSOR_WZ, W_Z}
    }
    if string.find(HOVER_ELEMENT, "x") then
      CACHE_CHECK, CURR_CHECK = unpack(POSITION_LOCALISATION.X)
    elseif string.find(HOVER_ELEMENT, "y") then
      CACHE_CHECK, CURR_CHECK = unpack(POSITION_LOCALISATION.Y)
    elseif string.find(HOVER_ELEMENT, "rotationz") then
      CACHE_CHECK, CURR_CHECK = unpack(POSITION_LOCALISATION.Y)
    elseif string.find(HOVER_ELEMENT, "z") then
      CACHE_CHECK, CURR_CHECK = unpack(POSITION_LOCALISATION.Z)
    else
      return
    end
    if CURR_CHECK < CACHE_CHECK then
      wearable_update_position(true)
    elseif CURR_CHECK > CACHE_CHECK then
      wearable_update_position(false)
    end
    if HOVER_ELEMENT == "h_arrowiconx.png" then
      wearable_move_object("X")
    elseif HOVER_ELEMENT == "h_arrowicony.png" then
      wearable_move_object("Y")
    elseif HOVER_ELEMENT == "h_arrowiconz.png" then
      wearable_move_object("Z")
    elseif HOVER_ELEMENT == "h_rotationx.png" then
      wearable_move_object("RX")
    elseif HOVER_ELEMENT == "h_rotationy.png" then
      wearable_move_object("RY")
    elseif HOVER_ELEMENT == "h_rotationz.png" then
      wearable_move_object("RZ")
    elseif string.find(HOVER_ELEMENT, "resizeicon") then
      wearable_move_object("OC")
    end
    setCursorPosition(CURSOR_X, CURSOR_Y)
  end
end

function wearable_initialize_system(artifactName, savedPos)
  POSITION_OBJECT = createObject(default_obj, 0, 0, 0)
  setElementData(POSITION_OBJECT, "sarp_items:artifact", artifactName)

  ARTIFACT_NAME = artifactName
  local data = g_artifacts[artifactName]
  local bone = data.bone

  local pos = data.pos
  local scale = data.scale

  if savedPos then --x,y,z, rx,ry,rz, scale
  	-- load saved client position
  	pos = savedPos
  	scale = savedPos[7]
  	triggerEvent("displayMesaage", localPlayer, "Loaded saved position for '"..artifactName.."'.", "success")
  else
  	triggerEvent("displayMesaage", localPlayer, "Loaded default position for '"..artifactName.."'.", "info")
  end

  POSITION_BONE = bone
	--x,y,z,rx,ry,rz,scale    
	POSITION_TABLE = {
	  pos[1],
	  pos[2],
	  pos[3],
	  pos[4],
	  pos[5],
	  pos[6],
	  scale
	}

	exports.pAttach:attach(POSITION_OBJECT, localPlayer, POSITION_BONE,
		pos[1],
		pos[2],
		pos[3],
		pos[4],
		pos[5],
		pos[6]
	  )

	setObjectScale(POSITION_OBJECT, scale)

  for OFFSET_ADDRESS = 1, NUM_CUBOIDS do
    local CUB_X, CUB_Y, CUB_Z, CUB_WIDTH, CUB_DEPTH, CUB_HEIGHT = unpack(CUBOID_PARAMETERS)
    local X_OFF, Y_OFF, Z_OFF = unpack(ATTACH_OFFSETS[OFFSET_ADDRESS])
    local CUB_ELEMENT_TEMP = createColCuboid(CUB_X, CUB_Y, CUB_Z, CUB_WIDTH, CUB_DEPTH, CUB_HEIGHT)
    setElementDimension(CUB_ELEMENT_TEMP, getElementDimension(localPlayer))
    setElementInterior(CUB_ELEMENT_TEMP, getElementInterior(localPlayer))
    attachElements(CUB_ELEMENT_TEMP, POSITION_OBJECT, X_OFF, Y_OFF, Z_OFF, RX_ATTACH, RY_ATTACH, RZ_ATTACH)
    POSITION_DATA.CUBOIDS[OFFSET_ADDRESS] = CUB_ELEMENT_TEMP
  end

  addEventHandler("onClientPreRender", getRootElement(), wearable_initialize_lines)
end

function wearable_create_lines()
  local COUNT = 0
  for OFFSET_ADDRESS = 1, NUM_CUBOIDS do
    COUNT = COUNT + 1
    local CUB_ELEMENT = POSITION_DATA.CUBOIDS[OFFSET_ADDRESS]
    if COUNT == 2 then
      COUNT = 0
      local X_R, Y_R, Z_R = getElementPosition(CUB_ELEMENT)
      local X_L, Y_L, Z_L = getElementPosition(POSITION_DATA.CUBOIDS[OFFSET_ADDRESS - 1])
      local R, G, B, A, LINE_THICK = unpack(LINE_PARAMETERS[OFFSET_ADDRESS])
      dxDrawLine3D(X_L, Y_L, Z_L, X_R, Y_R, Z_R, tocolor(R, G, B, A), LINE_THICK)
    end
  end
end

function wearable_icon_handler()
  local CURSOR_X, CURSOR_Y
  local IMAGE_OVERLAY = false
  if not MOUSE_LEFT_DOWN and HOVER_ELEMENT then
    HOVER_ELEMENT = nil
  end
  if not isCursorShowing() then
    CURSOR_X, CURSOR_Y = 0, 0
  else
    CURSOR_X, CURSOR_Y = getCursorPosition()
  end
  CURSOR_X, CURSOR_Y = CURSOR_X * SCREENSIZE_X, CURSOR_Y * SCREENSIZE_Y
  for IMAGE_NAME, IMAGE_DATA in pairs(POSITION_DATA.CUB_IMAGES) do
    local IMAGE_SHOW, _, _, _, DX_TABLE = unpack(IMAGE_DATA)
    local DX_DRAW_IMAGE_X, DX_DRAW_IMAGE_Y, DX_DRAW_IMAGE_WIDTH, DX_DRAW_IMAGE_HEIGHT = unpack(DX_TABLE)
    local IMG_HIGHLIGHTED = string.find(IMAGE_NAME, "h_")
    local IMG_PREFIX_H = "h_" .. IMAGE_NAME
    local IMG_PREFIX = string.sub(IMAGE_NAME, 3)
    if IMAGE_SHOW then
      if not FOR_LOOP_CALLBACK[IMAGE_NAME] then
        break
      else
        FOR_LOOP_CALLBACK[IMAGE_NAME] = false
      end
      if not IMG_HIGHLIGHTED and wearable_is_main_icon(IMG_PREFIX_H) then
        POSITION_DATA.CUB_IMAGES[IMAGE_NAME][1] = false
        POSITION_DATA.CUB_IMAGES[IMG_PREFIX_H][1] = true
      end
      if DX_DRAW_IMAGE_X ~= 0 or DX_DRAW_IMAGE_Y ~= 0 then
        if wearable_hover_image_check(CURSOR_X, CURSOR_Y, DX_DRAW_IMAGE_X, DX_DRAW_IMAGE_Y, DX_DRAW_IMAGE_WIDTH, DX_DRAW_IMAGE_HEIGHT) then
          if MOUSE_LEFT_DOWN then
            if IMAGE_NAME ~= HOVER_ELEMENT then
              IMAGE_OVERLAY = true
            else
              IMAGE_OVERLAY = false
            end
          end
          if not IMG_HIGHLIGHTED and not IMAGE_OVERLAY then
            POSITION_DATA.CUB_IMAGES[IMAGE_NAME][1] = false
            POSITION_DATA.CUB_IMAGES[IMG_PREFIX_H][1] = true
          end
          if not IMAGE_OVERLAY then
            HOVER_ELEMENT = IMAGE_NAME
          end
        elseif IMG_HIGHLIGHTED and not MOUSE_LEFT_DOWN and not wearable_is_main_icon(IMAGE_NAME) then
          POSITION_DATA.CUB_IMAGES[IMAGE_NAME][1] = false
          POSITION_DATA.CUB_IMAGES[IMG_PREFIX][1] = true
        end
      end
    end
  end
end

function wearable_draw_icons()
  for IMAGE_NAME, IMAGE_DATA in pairs(POSITION_DATA.CUB_IMAGES) do
    local IMAGE_SHOW, IMAGE_X, IMAGE_Y, CUB_ADDRESS = unpack(IMAGE_DATA)
    local CUB_ELEMENT = POSITION_DATA.CUBOIDS[CUB_ADDRESS]
    local CUB_X, CUB_Y, CUB_Z = getElementPosition(CUB_ELEMENT)
    local FIN_IMAGE_NAME = IMAGE_PREFIX .. IMAGE_NAME
    if IMAGE_SHOW then
      local SCREEN_X, SCREEN_Y = getScreenFromWorldPosition(CUB_X, CUB_Y, CUB_Z, 0, false)
      if SCREEN_X or SCREEN_Y then
        local CAMERA_X, CAMERA_Y, CAMERA_Z, _, _, _, _, CAMERA_FOV = getCameraMatrix()
        local CUB_CAM_DIST = getDistanceBetweenPoints3D(CUB_X, CUB_Y, CUB_Z + 0.06, CAMERA_X, CAMERA_Y, CAMERA_Z)
        local U_SCREENSIZE_X = SCREENSIZE_X + RESOLUTION_OFFSET_RIGHT
        local U_SCREENSIZE_Y = SCREENSIZE_Y + RESOLUTION_OFFSET_BOTTOM
        local DX_DRAW_IMAGE_X = SCREEN_X - IMAGE_X / CUB_CAM_DIST * SCREENSIZE_X / 800 / 70 * CAMERA_FOV
        local DX_DRAW_IMAGE_Y = SCREEN_Y - IMAGE_Y / CUB_CAM_DIST * SCREENSIZE_Y / 600 / 70 * CAMERA_FOV
        local DX_DRAW_IMAGE_WIDTH = 50 / CUB_CAM_DIST * U_SCREENSIZE_X / 800 / 70 * CAMERA_FOV
        local DX_DRAW_IMAGE_HEIGHT = 50 / CUB_CAM_DIST * U_SCREENSIZE_Y / 600 / 70 * CAMERA_FOV
        POSITION_DATA.CUB_IMAGES[IMAGE_NAME][5] = {
          DX_DRAW_IMAGE_X,
          DX_DRAW_IMAGE_Y,
          DX_DRAW_IMAGE_WIDTH,
          DX_DRAW_IMAGE_HEIGHT
        }
        dxDrawImage(DX_DRAW_IMAGE_X, DX_DRAW_IMAGE_Y, DX_DRAW_IMAGE_WIDTH, DX_DRAW_IMAGE_HEIGHT, FIN_IMAGE_NAME)
        FOR_LOOP_CALLBACK[IMAGE_NAME] = true
      end
    end
  end
end

function wearable_move_object(POSITION_VALUE)
  -- exports.pAttach:detach(POSITION_OBJECT)
  if POSITION_VALUE == "X" then
    do
      local CURR_OBJECT_X = POSITION_TABLE[1]
      POSITION_TABLE[1] = CURR_OBJECT_X + OBJECT_X
    end
  elseif POSITION_VALUE == "Y" then
    do
      local CURR_OBJECT_Y = POSITION_TABLE[2]
      POSITION_TABLE[2] = CURR_OBJECT_Y + OBJECT_Y
    end
  elseif POSITION_VALUE == "Z" then
    do
      local CURR_OBJECT_Z = POSITION_TABLE[3]
      POSITION_TABLE[3] = CURR_OBJECT_Z + OBJECT_Z
    end
  elseif POSITION_VALUE == "RX" then
    do
      local CURR_OBJECT_RX = POSITION_TABLE[4]
      POSITION_TABLE[4] = CURR_OBJECT_RX + OBJECT_RX
    end
  elseif POSITION_VALUE == "RY" then
    do
      local CURR_OBJECT_RY = POSITION_TABLE[5]
      POSITION_TABLE[5] = CURR_OBJECT_RY + OBJECT_RY
    end
  elseif POSITION_VALUE == "RZ" then
    do
      local CURR_OBJECT_RZ = POSITION_TABLE[6]
      POSITION_TABLE[6] = CURR_OBJECT_RZ + OBJECT_RZ
    end
  elseif POSITION_VALUE == "OC" then
    local CURR_OBJECT_SCALE = POSITION_TABLE[7]
    POSITION_TABLE[7] = CURR_OBJECT_SCALE + OBJECT_SCALE
  end
  local POSITION_ROWS = table.getn(POSITION_TABLE)
  for POSITION_OFFSET = 1, POSITION_ROWS do
    if POSITION_OFFSET > 0 and POSITION_OFFSET <= 3 then
      if POSITION_TABLE[POSITION_OFFSET] > 2 or POSITION_TABLE[POSITION_OFFSET] < -2 then
        POSITION_TABLE[POSITION_OFFSET] = 0
      end
    elseif POSITION_OFFSET > 3 and POSITION_OFFSET <= 6 and (POSITION_TABLE[POSITION_OFFSET] > 360 or POSITION_TABLE[POSITION_OFFSET] < -360) then
      POSITION_TABLE[POSITION_OFFSET] = 0
    end
  end
  if getObjectScale(POSITION_OBJECT) > 1.5 or getObjectScale(POSITION_OBJECT) < 0.5 then
    POSITION_TABLE[7] = 1
  end
  setObjectScale(POSITION_OBJECT, POSITION_TABLE[7])

  exports.pAttach:setPositionOffset(POSITION_OBJECT, POSITION_TABLE[1], POSITION_TABLE[2], POSITION_TABLE[3])
  exports.pAttach:setRotationOffset(POSITION_OBJECT, POSITION_TABLE[4], POSITION_TABLE[5], POSITION_TABLE[6])
  -- exports.pAttach:attach(POSITION_OBJECT,
  --   POSITION_TABLE[1], POSITION_TABLE[2], POSITION_TABLE[3],
  --   POSITION_TABLE[4], POSITION_TABLE[5], POSITION_TABLE[6]
  -- )
end

addEventHandler("onClientClick", getRootElement(), wearable_on_click_handler)
addEventHandler("onClientCursorMove", getRootElement(), wearable_mouse_move_handler)

local saveButton
local cancelButton
local resetPosButton
local resetAllPosButton
local hideArtifactButton

local uSure = false
local uSureTimer

function wearable_hide(DontReadd)

  wearable_icon_action("h_arrowicon.png")
  if isElement(POSITION_OBJECT) then
    for OFFSET_ADDRESS = 1, NUM_CUBOIDS do
      local CUB_ELEMENT_TEMP = POSITION_DATA.CUBOIDS[OFFSET_ADDRESS]
      destroyElement(CUB_ELEMENT_TEMP)
    end
    exports.pAttach:detach(POSITION_OBJECT)
    destroyElement(POSITION_OBJECT)
    POSITION_TABLE = {
      0,
      0,
      0,
      0,
      0,
      0,
      1
    }
  end
  MOUSE_LEFT_DOWN = false
  HOVER_ELEMENT = nil
  removeEventHandler("onClientPreRender", getRootElement(), wearable_initialize_lines)

  if WAS_WEARING and not DontReadd then
  	triggerServerEvent("artifacts:showOnPlayer", localPlayer, localPlayer, WAS_WEARING)
  end

  if isElement(saveButton) then destroyElement(saveButton) end
  if isElement(cancelButton) then destroyElement(cancelButton) end
  if isElement(resetPosButton) then destroyElement(resetPosButton) end
  if isElement(resetAllPosButton) then destroyElement(resetAllPosButton) end
  if isElement(hideArtifactButton) then destroyElement(hideArtifactButton) end

  uSure = false
  if isTimer(uSureTimer) then killTimer(uSureTimer) end

  triggerEvent("f_toggleCursor", localPlayer, false)
  setElementData(localPlayer, "exclusiveGUI", false, false)
  return true
end
addEventHandler("onClientChangeChar", getRootElement(), wearable_hide)


function adjustWearables(cmd,artifact)
	if getElementData(localPlayer, "loggedin") ~= 1 then return end

	if isElement(POSITION_OBJECT) then
		wearable_hide()
		return
	end

  setTimer(function() triggerEvent("f_toggleCursor", localPlayer, true) end, 500, 1)
  setElementData(localPlayer, "exclusiveGUI", true, false)

	WAS_WEARING = false
	if isPlayerWearingArtifact(localPlayer, artifact) then
		-- hide it serverside so they dont overlap :)
		triggerServerEvent("artifacts:hideOnPlayer", localPlayer, localPlayer, artifact)
		WAS_WEARING = artifact
	end

	local skinID = getElementData(localPlayer, "skinID") or getElementModel(localPlayer)
	local savedPos
	local saves = attTable[skinID]
	if saves then
		savedPos = saves[artifact] or nil --x,y,z, rx,ry,rz, scale
	end

	wearable_initialize_system(artifact, savedPos)

  local isVisible = (not (type(savedPos)=="table")) or (not (savedPos[8]))

  cancelButton = guiCreateButton(SCREENSIZE_X - 110, SCREENSIZE_Y - 65 - 40, 95, 30, "Cancel", false)
  guiSetProperty(cancelButton, "NormalTextColour", "ffffffff")
  addEventHandler( "onClientGUIClick", cancelButton, 
  function (button) 
    if button == "left" then
      wearable_hide()
    end
  end, false)

  saveButton = guiCreateButton(SCREENSIZE_X - 210, SCREENSIZE_Y - 65 - 40, 95, 30, "Save", false)
  guiSetProperty(saveButton, "NormalTextColour", "ff70ff77")
  addEventHandler( "onClientGUIClick", saveButton, 
  function (button) 
    if button == "left" then
      wearable_save()
    end
  end, false)

  hideArtifactButton = guiCreateButton(SCREENSIZE_X - 110, SCREENSIZE_Y - 65, 95, 30, "Hide", false)
  guiSetProperty(hideArtifactButton, "NormalTextColour", "ffff6666")
  addEventHandler( "onClientGUIClick", hideArtifactButton, 
  function (button) 
    if button == "left" then
      if togArtifactShowing(ARTIFACT_NAME, getElementData(localPlayer, "skinID"), isVisible and true or false) then
        if wearable_hide(true) then
          adjustWearables(cmd,ARTIFACT_NAME)
        end
      end
    end
  end, false)

  resetPosButton = guiCreateButton(SCREENSIZE_X - 210, SCREENSIZE_Y - 65, 95, 30, "Reset", false)
  guiSetProperty(resetPosButton, "NormalTextColour", "FFFFFF00")

  addEventHandler( "onClientGUIClick", resetPosButton, 
  function (button) 
    if button == "left" then
      if resetPositionFor(ARTIFACT_NAME, getElementData(localPlayer, "skinID")) then
        if wearable_hide(true) then
          adjustWearables(cmd,ARTIFACT_NAME)
        end
      end
    end
  end, false)
  

  local resetAllText = "Reset All"
  resetAllPosButton = guiCreateButton(SCREENSIZE_X - 310, SCREENSIZE_Y - 65, 95, 30, resetAllText, false)
  guiSetProperty(resetAllPosButton, "NormalTextColour", "ffff8e24")

  addEventHandler( "onClientGUIClick", resetAllPosButton, 
  function (button) 
    if button == "left" then
      if not uSure then
        outputChatBox("Are you sure you want to delete all saved wearable positions? Click again to proceed.", 255,100,100)
        guiSetEnabled(source, false)
        guiSetText(resetAllPosButton, resetAllText.." (Wait)")
        uSure = true

        uSureTimer = setTimer(function() 
          guiSetText(resetAllPosButton, resetAllText)
          guiSetEnabled(resetAllPosButton, true)
        end, 5000, 1)
      else
        if resetAllPositions() then
          if wearable_hide(true) then
            adjustWearables(cmd,ARTIFACT_NAME)
          end
        end
      end
    end
  end, false)
end
addCommandHandler("wearables", adjustWearables, false)
