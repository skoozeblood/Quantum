-------------------------------- Fernando --------------------------------

 --[[		Find textures in server

SELECT id,textures FROM `vehicles` WHERE `textures` LIKE '%.png?%';
SELECT id,metadata FROM `worlditems` WHERE `metadata` LIKE '%.png?%';
SELECT `index`,`type`,`owner`,`metadata` FROM `items` WHERE `metadata` LIKE '%.png?%';

--]]


cacheFolder = "sarp_cache"

cacheFileNameServer = cacheFolder.."/%s"
cacheFileName = "@"..cacheFolder.."/%s"

listFilePath = "@"..cacheFolder.."/".."file_list.xml"
rootNodeName, entryNodeName = "list", "file"


function GetFileExtension(url)
  return url:match("^.+(%..+)$")
end

function removeExtension(ext, s)
    return string.gsub(s, "%"..ext, "")
end

function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end

-- Only allow .png
function isFileExtensionValid(fn)

	if GetFileExtension(fn) == ".png" then
		return true
	end
	return false
end

function isImageURLValid ( url )
	local url = url:lower()

	if not isURL( url ) then
		return false, "Invalid URL!"
	end

	if not isHostAllowed(url) then
		return false, "Image must be hosted on imgur.com."
	end

	if isFileExtensionValid(url) then
		return true
	end

	return false, "Only .png files are allowed."
end


maxFileSize = 400000 -- bytes
maxFileSizeTxt = (maxFileSize/1000).." kb"
maxHeight, maxWidth = 1024, 1024

allowedImageHosts = {
	["imgur.com"] = true,
}


plateTextures = {

	[1]={"Black w/ yellow text", "https://i.imgur.com/XKL3pMT.png"},
	[2]={"Blue w/ yellow text", "https://i.imgur.com/arCaWvh.png"},
	[3]={"White w/ black text", "https://i.imgur.com/rUKtRiJ.png"},
	[4]={"White w/ red text", "https://i.imgur.com/FYAq40w.png"},
	[5]={"White w/ red & yellow text", "https://i.imgur.com/RGRSKNY.png"},
	[6]={"White w/ Las Venturas", "https://i.imgur.com/8zC1xFp.png"},

	-- Restriced; Don't show up in mechanic menu
	[100]={"SA Exempt", "https://i.imgur.com/AtjTrHt.png"},
	[101]={"Vice City", "https://i.imgur.com/iYqeXUf.png"},
}

extraVehTexNames = {
	[596] = {"vehiclepoldecals128","vehiclepoldecals128lod"}, --police LS
	[597] = {"vehiclepoldecals128","vehiclepoldecals128lod"}, --police SF
	[598] = {"vehiclepoldecals128","vehiclepoldecals128lod"}, --police LV
	[599] = {"vehiclepoldecals128","vehiclepoldecals128lod"}, --police ranger
	[427] = {"vehiclepoldecals128","vehiclepoldecals128lod"}, --enforcer
	[497] = {"vehiclepoldecals128","vehiclepoldecals128lod"}, --police maverick
	[523] = {"vehiclepoldecals128","vehiclepoldecals128lod"}, --copbike /Fernando
}

globalVehTexNames = {
	"vehiclegrunge256", --overrides shader_car_paint and dirt levels
	"platecharset", --license plate letters & numbers in vehicle.txd
}

function isURLPlateTextre(url)
	for k, v in pairs(plateTextures) do
		if v[2] == url then
			return true
		end
	end
	return false
end


function getPlateTextures()
	return plateTextures
end

function isURL(url)
	if url and (string.find(url, "http://", 1, true) or string.find(url, "https://", 1, true)) then
		return true
	else
		return false
	end
end
function isHostAllowed(url)
	if string.find(url, "http://", 1, true) or string.find(url, "https://", 1, true) then
		local domain = url:match("[%w%.]*%.(%w+%.%w+)") or url:match("^%w+://([^/]+)")
		if allowedImageHosts[domain] then
			return true
		end
	end
	return false
end
function getHost(url)
	if string.find(url, "http://", 1, true) or string.find(url, "https://", 1, true) then
		local domain = url:match("[%w%.]*%.(%w+%.%w+)") or url:match("^%w+://([^/]+)")
		if allowedImageHosts[domain] then
			return domain
		end
	end
	return false
end

-- print(isImageURLValid("https://i.imgur.com/MGNgeIT.png?1")) -- testing
