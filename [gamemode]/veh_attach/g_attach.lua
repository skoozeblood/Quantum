-- Fernando: 27/05/2021
-- new attachments system for vehicles

-- default_obj = 1856 -- casino chip // don't change

g_artifacts = {
	--[ID] = {
	-- bone, pos(x,y,z,rx,ry,rz), scale, doublesided(ds),
	-- OPTIONAL: (texture), (customDffName), (customColName), (customTxdName), (colEnabled), (gtaModel)
	--},

	["hockeymask"]		= {bone=BONE_HEAD,pos={0.017, 0.598, 0.253,   -265, 116, 87},scale=1.06,ds=true,texname="MaskV_Cyb3rMotion"},
}

-- local texnames = {}
-- for artifact, _ in pairs(g_artifacts) do
-- 	local tname = _.texname
-- 	if tname then
-- 		texnames[artifact] = tname
-- 	end
-- end

-- used in item-system g_item_functions getItemTexture
-- function getTextureNames()
-- 	return texnames
-- end


-- Used in item-texture s_itemtexture
-- function getArtifacts()
-- 	return g_artifacts
-- end


function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end