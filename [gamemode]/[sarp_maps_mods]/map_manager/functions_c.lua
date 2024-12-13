local GUIEditor = {
    button = {},
    window = {},
    label = {},
    memo = {}
}

-- Fernando (fixes)
local function generateMapContent( objects )
	local buffer = '<map edf:definitions="editor_main">'
	for i, obj in ipairs( objects ) do
        local objname = (engineGetModelNameFromID(obj.model) or "unknown").." ("..obj.model..") "..i
        if obj.radius and tonumber(obj.radius)~=0 then
	        buffer = buffer..'\n    '..'<removeWorldObject id="object '..objname..'" radius="'..obj.radius..'" interior="'..obj.interior..'" model="'..obj.model..'" lodModel="'..obj.lodModel..'" posX="'..obj.posX..'" posY="'..obj.posY..'" posZ="'..obj.posZ..'" rotX="'..obj.rotX..'" rotY="'..obj.rotY..'" rotZ="'..obj.rotZ..'"></removeWorldObject>'
	    else
            local extra = ""
            local count = 0
            if obj.textures and obj.textures ~= "" then
                local textures = ""
                for k,v in pairs(fromJSON(obj.textures)) do
                    if type(v)=="table" then
                        local texname, rmodel,rname = unpack(v)
                        rmodel = tonumber(rmodel)
                        if type(texname) == "string" and type(rmodel) == "number" and type(rname) == "string" then
                            
                            if count == 0 then
                                textures = texname..":"..rmodel.."-"..rname
                            else
                                textures = textures..","..texname..":"..rmodel.."-"..rname
                            end
                            count = count + 1
                        end
                    end
                end

                extra = 'textures="'..tostring(textures)..'"'
            end
            buffer = buffer..'\n    '..'<object id="object '..objname..'" breakable="'..( tonumber(obj.breakable) == 0 and 'false' or 'true' )..'" frozen="'..( tonumber(obj.frozen) == 0 and 'false' or 'true' )..'" interior="'..obj.interior..'" alpha="'..( obj.alpha and obj.alpha or "255" )..'" model="'..obj.model..'" doublesided="'..( tonumber(obj.doublesided) == 0 and 'false' or 'true' )..'" scale="'..( obj.scale and obj.scale or '1.0000000' )..'" dimension="'..obj.dimension..'" posX="'..obj.posX..'" posY="'..obj.posY..'" posZ="'..obj.posZ..'" rotX="'..obj.rotX..'" rotY="'..obj.rotY..'" rotZ="'..obj.rotZ..'"'..extra..'></object>'
        end
    end
	buffer = buffer..'\n</map>'
	return buffer
end

-- Fernando
local function generateMapContentLua( objects )
    local buffer = ''
    for i, obj in ipairs( objects ) do
        if obj.radius and tonumber(obj.radius)~=0 then
            buffer = buffer..'\nremoveWorldModel('..obj.model..', '..obj.radius..', '..obj.posX..', '..obj.posY..', '..obj.posZ..', '..obj.interior..') --'..tostring(obj.id)
            if tonumber(obj.lodModel) ~= 0 then
                buffer = buffer..'\nremoveWorldModel('..obj.lodModel..', '..obj.radius..', '..obj.posX..', '..obj.posY..', '..obj.posZ..', '..obj.interior..') -- corresponding LOD'
            end
        else
            local objname = " -- "..(engineGetModelNameFromID(obj.model) or "unknown").." ("..obj.model..")"
            buffer = buffer..'\nlocal obj = createObject('..obj.model..', '..obj.posX..', '..obj.posY..', '..obj.posZ..', '..obj.rotX..', '..obj.rotY..', '..obj.rotZ..')'..objname

            if tonumber(obj.breakable) ~= 0 then
                buffer = buffer..'\nsetObjectBreakable(obj, true)'
            end
            if tonumber(obj.doublesided) ~= 0 then
                buffer = buffer..'\nsetElementDoubleSided(obj, true)'
            end
            if tonumber(obj.frozen) ~= 0 then
                buffer = buffer..'\nsetElementFrozen(obj, true)'
            end
            if obj.dimension and tonumber(obj.dimension) ~= 0 then
                buffer = buffer..'\nsetElementDimension(obj, '..obj.dimension..')'
            end
            if obj.interior and tonumber(obj.interior) ~= 0 then
                buffer = buffer..'\nsetElementInterior(obj, '..obj.interior..')'
            end
            if obj.alpha and tonumber(obj.alpha) ~= 255 then
                buffer = buffer..'\nsetElementAlpha(obj, '..obj.alpha..')'
            end
            if obj.scale and tonumber(obj.scale) ~= 1 then
                buffer = buffer..'\nsetObjectScale(obj, '..obj.scale..')'
            end
            local textures = obj.textures
            if textures and textures ~= "" then
                textures = fromJSON(textures)
                buffer = buffer .."\nlocal textures = "..tostring(inspect(textures)).." -- textures for object above"
            end
        end
    end
    buffer = buffer..'\n'
    return buffer
end


addEvent( 'map:exportmap', true )
addEventHandler( 'map:exportmap', resourceRoot, function ( objects, export_type )
    closeExporter()
    GUIEditor.window[1] = guiCreateWindow(562, 184, 800, 600, "Map Objects Exporter - Map ID #"..objects[1].map_id, false)
    guiWindowSetSizable(GUIEditor.window[1], false)
    exports.global:centerWindow( GUIEditor.window[1] )

    local content = (export_type == "map" and generateMapContent( objects ) or generateMapContentLua( objects ))

    GUIEditor.memo[1] = guiCreateMemo(9, 22, 781, 525, content or "Error..", false, GUIEditor.window[1])
    GUIEditor.button[1] = guiCreateButton(679, 557, 111, 29, "Close", false, GUIEditor.window[1])
    GUIEditor.button[2] = guiCreateButton(558, 557, 111, 29, "Save to file", false, GUIEditor.window[1])
    GUIEditor.button[3] = guiCreateButton(437, 557, 111, 29, "Copy to clipboard", false, GUIEditor.window[1])
    GUIEditor.label[1] = guiCreateLabel(13, 556, 401, 30, "Description: "..( objects[1].comment and objects[1].comment or "N/A" ), false, GUIEditor.window[1])
    guiLabelSetVerticalAlign(GUIEditor.label[1], "center")

    addEventHandler( 'onClientGUIClick', GUIEditor.window[1], function ()
        if source == GUIEditor.button[1] then
            closeExporter()
        elseif source == GUIEditor.button[2] then
            local file = fileCreate( 'exported/MAP['..objects[1].map_id..'].'..export_type )
            if file then
                fileWrite( file, content )
                fileClose( file )
                exports.global:playSoundSuccess()
                outputChatBox( "Done! File is located in your MTA folder at '/mods/deathmatch/resources/map_manager/exported-"..objects[1].map_id.."."..export_type )
            else
                exports.global:playSoundError()
                outputChatBox( "Errors occurred while writing data to file." )
            end
        elseif source == GUIEditor.button[3] then
            if setClipboard ( content ) then
                exports.global:playSoundSuccess()
                outputChatBox( "Copied" )
            end
        end
    end )

    addEventHandler( 'onClientChangeChar', root, closeExporter )
end )

function closeExporter()
	if GUIEditor.window[1] and isElement( GUIEditor.window[1] ) then
		destroyElement( GUIEditor.window[1] )
		GUIEditor.window[1] = nil
		removeEventHandler( 'onClientChangeChar', root, closeExporter )
	end
end

