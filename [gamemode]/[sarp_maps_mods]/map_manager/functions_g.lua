-- Fernando for SARP
-- November 2020

settings = {
	client_file = 'map.xml',
	map_content_max_length = 1000000,
	external_map_max_objects = 300,
	interior_map_max_objects = 250,

	external_map_max_concurrent_requests = 4,
}

req_questions = {
	["exterior"] = {
		[1] = "Short and descriptive name:",
		[2] = "What will the map be used for?",
		[3] = "Who will be affected by the map? Is it suitable for public usage?",
		[4] = "Link(s) to screenshot(s) of the map:",
		[5] = "Who made the map? List the username(s) of the author(s):"
	},
	["interior"] = {
		[1] = "Short and descriptive name:",
		[2] = "Interior ID (the property where your custom map will go):",
		[3] = "Why should this map be added? What is its purpose? What does it improve?",
		[4] = "Link(s) to screenshot(s) of the map:",
		[5] = "Who made the map? List the username(s) of the author(s):"
	},
}

warnings = {

	["exterior"] = [[
	** MAP CODE GOES HERE - READ ME FIRST **

	Ensure your exterior map meets the following requirements:

	  -  Map must have less than ]]..settings.external_map_max_objects..[[ objects.
	  -  Map must be visually appealing and must be fit for the GTA:SA atmosphere.
	  -  Please try not to have too many exterior objects in one place.
	]],

	["interior"] = [[
	** MAP CODE GOES HERE - READ ME FIRST **

	Ensure your interior map meets the following requirements:

	  -  Interior size must be a maximum of 1.35 times the size of the building (exterior).
	  -  Map can be mapped in any dimension as it will be overriden/ignored by the property's current dimension.
	  -  Map must have a maximum of ]]..settings.interior_map_max_objects..[[ objects. For larger maps contact MT.
	  -  Map must be visually appealing and must be fit for the GTA:SA atmosphere
	  -  Map must not remove any world objects (removeWorldObject).
	]]
}


function getReqStatus( v, playerView )
	if v.approved == 0 then
		return (playerView and 'Pending' or 'Pen.'), 255, 255, 255, 200
	elseif v.approved == 2 then
		return (playerView and 'Declined' or 'Dec.'), 255, 0, 0, 255
	else
		if v.enabled == 1 then
			return (playerView and 'Implemented' or 'Imp.'), 0, 255, 0, 255
		else
			return (playerView and 'Disabled' or 'Dis.'), 255, 50, 0, 200
		end
	end
end

function getCurrentTimeString()
	local time = getRealTime()
	return "["..time.monthday.."/"..(time.month+1).."/"..(time.year+1900).."]"
end

function canAdminMaps( player )
	return exports.integration:isPlayerScripter( player )
	or exports.integration:isPlayerMTMember( player )
	or exports.integration:isPlayerHeadAdmin( player )
end

function canAccessMgmtTab( player )
	return exports.integration:isPlayerTrialAdmin( player )
	or exports.integration:isPlayerScripter( player )
	or exports.integration:isPlayerMTMember( player )
end

function canEditMap( player, map, tab_id )
	local isReqEditable = not exports.map_load:isMapLoaded( map.id ) and map.approved == 0
	if tab_id == 1 then
		return isReqEditable
	else
		return isReqEditable and canAdminMaps( player )
	end
end

function canDeleteMap( player, map, tab_id )
	if tab_id == 1 then
		return map.approved == 0 and map.enabled == 0 and not exports.map_load:isMapLoaded( map.id )
	else
		return (not exports.map_load:isMapLoaded( map.id ) and map.enabled == 0) and canAdminMaps( player )
	end
	return false
end

function canAcceptMap( player, map )
	return ( map.approved ~= 1 and map.enabled == 0 ) and canAdminMaps( player )
end

function canDeclineMap( player, map )
	return ( map.approved ~= 2 and map.enabled == 0 ) and canAdminMaps( player )
end

function canImplementMap( player, map )
	return 
	(
	(map.enabled == 1 and canDisableMap( player, map ))
	or
	(map.approved == 1 and map.enabled ~= 1 and canAdminMaps( player ))
	)
end

function canDisableMap( player, map )
	return map.approved == 1 and map.enabled == 1 and canAdminMaps( player )
end

local trashobjects

local forbiddenObjects = {
	-- objects one should not use in their maps
	[726] = true, -- laggy tree that was replaced in _sarpjoin
}

--Fernando
function processMapContent( content, max_objects, content_is_filepath, map_type, prop_dim )

	if not trashobjects then
		trashobjects = exports["job-system"]:getTrashObjects()
	end

	local map = fileCreate( settings.client_file )                -- attempt to create a new file
	result, message = false, 'Errors occurred while processing map content. Code 341'
	if map then
		if not content_is_filepath then
	    	fileWrite(map, content)
	    	fileClose(map)
	    end
	    local root = xmlLoadFile ( content_is_filepath and content or settings.client_file )
	    if root then
	    	local objects = xmlNodeGetChildren( root )
	    	if objects then
	    		if #objects < 1 or #objects > max_objects then
	    			result, message = false, "Your map ("..#objects.." objs) must contain at least one object and at most "..max_objects.." objects (including world object removals)."
	    		else
	    			local submit_objects = {}
	    			local int, dim

		    		for index, object in ipairs( objects ) do

		    			local nodename = xmlNodeGetName(object)
		    			if not (nodename == "object" or nodename == "removeWorldObject") then
		    				xmlUnloadFile( root )
							if not content_is_filepath then
								fileDelete( settings.client_file )
							end
		    				return false, "Your map contains an unknown object/removeWorldObject line named '"..nodename.."'"
		    			end

		    			local submit_one_object = {}

		    			for name, value in pairs ( xmlNodeGetAttributes ( object ) ) do

							-- validating by Fernando
							if map_type == "interior" and name=="radius" then
								xmlUnloadFile( root )
								if not content_is_filepath then
									fileDelete( settings.client_file )
								end
								return false, 'Interior maps cannot have any removeWorldObject.'
							end

							if name == "model" then
								if not tonumber(value) then
									xmlUnloadFile( root )
									if not content_is_filepath then
										fileDelete( settings.client_file )
									end
									return false, "Incorrect model ID for at least one object"
								end

								if forbiddenObjects[tonumber(value)] then
									xmlUnloadFile( root )
									if not content_is_filepath then
										fileDelete( settings.client_file )
									end
									return false, "Object model "..tonumber(value).." cannot be used: please remove it from the map file"
								end
							end

							if name == 'interior' and value then
								if map_type == "exterior" and tonumber(value) and tonumber(value)~=0 then
									xmlUnloadFile( root )
									if not content_is_filepath then
										fileDelete( settings.client_file )
									end
									return false, 'All objects within an exterior map must be in interior world 0.'
								end
								
								if map_type == "interior" and tonumber(value) and tonumber(value)==0 then
									xmlUnloadFile( root )
									if not content_is_filepath then
										fileDelete( settings.client_file )
									end
									return false, 'All objects within an interior map must be in interior world > 0. Search GTA SA Interior IDs list.'
								end

					        	if not int then
					        		int = value
					        	else
					        		if int ~= value then
					        			xmlUnloadFile( root )
					        			if not content_is_filepath then
		    								fileDelete( settings.client_file )
		    							end
		    							return false, 'All objects within one mapping must be in the same interior.'
		    						end
		    					end
							elseif name == 'dimension' and value then
								if map_type == "exterior" and tonumber(value) and tonumber(value)~=0 then
									xmlUnloadFile( root )
									if not content_is_filepath then
										fileDelete( settings.client_file )
									end
									return false, 'All objects within an exterior map must be in dimension world 0.'
								end

		    					if not dim then
		    						dim = value
		    					else
		    						if dim ~= value then
		    							xmlUnloadFile( root )
		    							if not content_is_filepath then
		    								fileDelete( settings.client_file )
		    							end
		    							return false, 'All objects within one mapping must be in the same dimension.'
		    						end
								end

								if map_type == "interior" and prop_dim and tonumber(value) then
									-- Set the dimension to the property's
									value = prop_dim
								end
							end

							local tab1
							if name == "textures" then
								
								local str = value

								local textures = split(str, ",")
								if not textures then
									xmlUnloadFile( root )
									if not content_is_filepath then
										fileDelete( settings.client_file )
									end
									return false, "Object "..index.." in your map has invalid textures (see examples in the map upload forms)"
								end

								for j,w in pairs(textures) do
									local tab = split(w,":")
									if not tab then
		    							xmlUnloadFile( root )
		    							if not content_is_filepath then
		    								fileDelete( settings.client_file )
		    							end
										return false, "Object "..index.." in your map has invalid textures (see examples in the map upload forms)"
									end
							        local texname = tab[1]
							        local other = tab[2]
							        if not texname or not other then
		    							xmlUnloadFile( root )
		    							if not content_is_filepath then
		    								fileDelete( settings.client_file )
		    							end
										return false, "Object "..index.." in your map has invalid textures (see examples in the map upload forms)"
							        end
							        local rstuff = split(tab[2],"-")
							        if not rstuff then
		    							xmlUnloadFile( root )
		    							if not content_is_filepath then
		    								fileDelete( settings.client_file )
		    							end
										return false, "Object "..index.." in your map has invalid textures (see examples in the map upload forms)"
							        end
							        local rmodel = rstuff[1]
							        local rname = rstuff[2]
							        if not rmodel or not rname then
		    							xmlUnloadFile( root )
		    							if not content_is_filepath then
		    								fileDelete( settings.client_file )
		    							end
										return false, "Object "..index.." in your map has invalid textures (see examples in the map upload forms)"
							        end
							        if not tab1 then tab1 = {} end
							        table.insert(tab1, {texname, rmodel,rname})
								end
							end


							if name == "textures" then
								if tab1 then
									submit_one_object[ name ] = toJSON(tab1)
								end
							else
								submit_one_object[ name ] = tonumber(value) or value
						        if submit_one_object[ name ] == 'true' then
						        	submit_one_object[ name ] = 1
						        elseif submit_one_object[ name ] == 'false' then
						        	submit_one_object[ name ] = 0
								end
							end
					    end

					    -- Default values
					    if not submit_one_object.id then
					    	submit_one_object.id = "Unnamed"
					    end
					    if not submit_one_object.frozen then
					    	submit_one_object.frozen = 0
					    end
					    if not submit_one_object.breakable then
					    	submit_one_object.breakable = 0
					    end
					    if not submit_one_object.doublesided then
					    	submit_one_object.doublesided = 0
					    end
					    if not submit_one_object.collisions then
					    	submit_one_object.collisions = 0
					    end
					    if not submit_one_object.distance then
					    	submit_one_object.distance = 0
					    end
					    if not submit_one_object.textures then
					    	submit_one_object.textures = ""
					    end
					    if not submit_one_object.w_textures then
					    	submit_one_object.w_textures = ""
					    end

				    	-- VALIDATE ALL OBJECT ATTRIBUTES BEFORE SENDING TO SERVER (DB) - Fernando
				    	local required = {
				    		["removal"] = {
				    			["radius"] = "number",
				    			["interior"] = "number",
				    			["model"] = "number",
				    			["lodModel"] = "number",
				    			["posX"] = "number",
				    			["posY"] = "number",
				    			["posZ"] = "number",
				    			["rotX"] = "number",
				    			["rotY"] = "number",
				    			["rotZ"] = "number",
				    		},
				    		["object"] = {
				    			["interior"] = "number",
				    			["dimension"] = "number",
				    			["alpha"] = "number",
				    			["model"] = "number",
				    			["scale"] = "number",
				    			["posX"] = "number",
				    			["posY"] = "number",
				    			["posZ"] = "number",
				    			["rotX"] = "number",
				    			["rotY"] = "number",
				    			["rotZ"] = "number",
				    		}
				    	}
				    	local found = {}

		    			local isRemove = nodename == "removeWorldObject"

				    	local req = isRemove and required["removal"] or required["object"]

				    	for name, value in pairs(submit_one_object) do

				    		local reqtype = req[name]
				    		if reqtype then
				    			if type(value) == reqtype then
				    				found[name] = true
				    			else
				    				found[name] = "wrong"
				    			end
				    		end
				    	end

				    	for name, reqtype in pairs(req) do
				    		if not found[name] then
				    			found[name] = "missing"
				    		end
				    	end

				    	for name, v in pairs(found) do
				    		if v == "missing" then
    							xmlUnloadFile( root )
    							if not content_is_filepath then
    								fileDelete( settings.client_file )
    							end
				    			return false, "A '"..nodename.."' in your map is missing the attribute '"..name.."'."
				    		elseif v == "wrong" then
				    			xmlUnloadFile( root )
    							if not content_is_filepath then
    								fileDelete( settings.client_file )
    							end
				    			return false, "A '"..nodename.."' in your map has an invalid value for '"..name.."'."
				    		end
				    	end

				    	-- Get rid of trash objects in map (if any)
				    	local ignorethis = nil
				    	if not isRemove then
				    		local model = submit_one_object.model
				    		if model and trashobjects[model] then
				    			ignorethis = model
				    		end
				    	end

				    	if not ignorethis then
				    		table.insert( submit_objects, submit_one_object )
				    	else
				    		-- print("Ignoring trash object model #"..ignorethis)
				    	end
		    		end
					xmlUnloadFile( root )
					if not content_is_filepath then
						fileDelete( settings.client_file )
					end
					return submit_objects
		    	end
	    	else
	    		result, message = false, 'Error occurred while processing map content. Code 136.'
	    	end
	    	xmlUnloadFile( root )
	    else
	    	result, message = false, 'Error occurred while processing map content. Code 133.'
	    end
	    if not content_is_filepath then
	    	fileDelete( settings.client_file )
	    end
	end
	return result, message
end
