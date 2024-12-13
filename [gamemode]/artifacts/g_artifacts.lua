-- Fernando: 18/05/2021
-- support for infinite objects
-- major artifacts revamp

default_obj = 1856 -- casino chip // don't change

BONE_HEAD = "head"

local tf = ":artifacts/textures/"

local bandmask_pos = {-0.198, -0.643, -0.043,   0, 252, -4}
local bandmask_scale = 1.03

g_artifacts = {
	--[ID] = {
	-- bone, pos(x,y,z,rx,ry,rz), scale, doublesided(ds),
	-- OPTIONAL: (texture), (customDffName), (customColName), (customTxdName), (colEnabled), (gtaModel)
	--},

	["hockeymask"]		= {bone=BONE_HEAD,pos={0.017, 0.598, 0.253,   -265, 116, 87},scale=1.06,ds=true,texname="MaskV_Cyb3rMotion"}, --texture name is so preview textures detects which to apply
	["balaclava"]		= {bone=BONE_HEAD,pos={-0.001, -0.07, -0.021,   107, 106, 193},scale=1.173,ds=true,texname="Balaclava1"},
	["gasmask"]			= {bone=BONE_HEAD,pos={0.002, -0.038, 0.076,   97, 113, 90},scale=0.8725,ds=true},
	["helmet"]			= {bone=BONE_HEAD,pos={-0.014, -0.072, -0.029,   103.5, 115, 191},scale=0.82,ds=false,texname="helmet"},
	["bikerhelmet"]		= {bone=BONE_HEAD,pos={-0.006, -0.086, -0.024,   96.5, 98, 180},scale=0.87,ds=false,texname="helmet_b"},
	["fullfacehelmet"]	= {bone=BONE_HEAD,pos={0, -0.027, -0.021,   113.5, -241, 198},scale=0.95,ds=false,texname="helmet_f"},
	["christmashat"]	= {bone=BONE_HEAD,pos={0, -0.117, -0.042,   94, 82, 89},scale=1,ds=false,texname="helmet_f"},
	["swathelmet"]		= {bone=BONE_HEAD,pos={-0.008, -0.115, -0.031,   180, -180, 80},scale=1.15,ds=false,texname="helmet_f"},
	["earmuffs-final"]	= {bone=BONE_HEAD,pos={-0.008, -0.115, -0.031,   270, -180, 80},scale=1,ds=false,texname="earmuffs_diffuse"},--Portside
	["sunglasses"]		= {bone=BONE_HEAD,pos={-0.008, 0.4, -0.1,   90, 90, 80},scale=1,ds=false,texname="glasses04"},--Portside
	["snapback"]		= {bone=BONE_HEAD,pos={-0.008, 0.4, -0.1,   90, 90, 80},scale=1,ds=false,texname="capbklback"},--Portside
	["cowboyhat"]		= {bone=BONE_HEAD,pos={-0.008, 0.4, 0.3,   0, 180, 120},scale=1,ds=false,texname="body"},--Portside
	["drdre"]			= {bone=BONE_HEAD,pos={-0.008, -0.115, -0.031,   270, -180, 0},scale=1,ds=false,texname="headphones04"},--Portside
	["firehelmet"]		= {bone=BONE_HEAD,pos={-0.008, -0.1, 0,   180, 180, 70},scale=1,ds=false,texname="lafda0"},--Portside

	["backpack"]		= {bone="backpack",pos={0, 0.032, -0.072,   -6, -12, -20},scale=1,ds=true,texname="textures"},
	["dufflebag"]		= {bone="backpack",pos={0.039, -0.194, 0.166,   98, 0, 0},scale=0.83,ds=true, texname="hoodyabase5"},
	["medicbag"]		= {bone="backpack",pos={0.039, -0.194, 0.166,   98, 0, 0},scale=0.83,ds=true, texname="hoodyabase5", texture = tf.."medicbag.png", customDffName = "dufflebag", customTxdName = "dufflebag"},
	["briefcase"]		= {bone="right-hand",pos={0, -0.115, -0.054,   0, 260, 88},scale=1,ds=false,gtaModel=1210, texname="briefcase"},
	["briefcase2"]		= {bone="right-hand",pos={0.017, 0.012, 0,   3, 273, 88},scale=1,ds=false, texname="CJ_CASE_BROWN"},
	["holstgun"]		= {bone="left-hip",pos={0.017, 0.312, 0,   3, 273, 88},scale=1,ds=false,texname="gun"},--Portside
	["holstgunr"]		= {bone="right-hip",pos={0.017, 0.312, 0,   3, 273, 88},scale=1,ds=false,texname="gun"},--Portside
	["huntingknifeholstered"]		= {bone="pelvis",pos={0.4, 0.312, 0,   90, 0, 60},scale=1,ds=false,texname="backpack_dif"},--Portside
	["axonbodycam"]		= {bone="spine",pos={-0.05, 0.312, 0,   90, 0, 180},scale=1,ds=true,texname="axon"},--Portside

	["trafficvest"]		= {bone="backpack",pos={0, 0.047, 0.043,   87, 2, -182},scale=1.095,ds=true,texname="BMYAP"},
	["kevlar1"]			= {bone="backpack",pos={0, 0.052, 0.04,   0, 349, 0},scale=1.125,ds=true,texname="colete"},
	["kevlar2"]			= {bone="backpack",pos={0, 0.04, 0.063,   0, 0, 0},scale=1.15,ds=true},
	["kevlar3"]			= {bone="backpack",pos={0, 0.025, 0.092,   0, 0, 0},scale=1.05,ds=true},
	["chestrig"]		= {bone="backpack",pos={0, 0.025, -0.2,   90, 0, 180},scale=1,ds=true,texname="backpack_dif"},--Portside
	["chestrig-stripped"]	= {bone="backpack",pos={0, 0.025, -0.2,   90, 0, 180},scale=1,ds=true,texname="backpack_dif"}, --Portside

	["shield"]			= {bone="backpack",pos={0, 0.331, -0.248,   88, -1, -2},scale=1,ds=false,colEnabled=false, texname="riot_shield"},
	["rod"]				= {bone="right-hand",pos={0, -0.003, 0.003,   0, 141, 0},scale=1,ds=false},

	-- Bandanas:
	--[[
		Item IDs: 122,123,124,125,135,136,158,168,237,238,239 (not this order)
	]]
	["bandmask_lightblue"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandlightblue.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_red"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandred.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_yellow"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandyellow.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_purple"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandpurple.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_blue"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandblue.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_brown"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandbrown.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_green"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandgreen.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_orange"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandorange.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_black"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandblack.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_grey"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandgrey.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},
	
	["bandmask_white"]		= {bone=BONE_HEAD,pos=bandmask_pos,scale=bandmask_scale,ds=true,
		texture = tf.."bandwhite.png", texname="bandknot", customDffName="bandmask", customTxdName="banddefault"},

}

local texnames = {}
for artifact, _ in pairs(g_artifacts) do
	local tname = _.texname
	if tname then
		texnames[artifact] = tname
	end
end

-- used in item-system g_item_functions getItemTexture
function getTextureNames()
	return texnames
end

-- Used in item-world for dropping down an artifact
function getArtifactScale(artifact)
	local data = g_artifacts[artifact]
	if data then
		return data.scale
	end
	return 1
end

-- Used in item-texture s_itemtexture
function getArtifacts()
	return g_artifacts
end


function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end