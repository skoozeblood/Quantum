-- Fernando: 18/05/2021
-- support for infinite objects
-- major artifacts revamp

local allocatedArtifacts = {} --[[ [artifact name] = fakeID  ]]
local loadedArtifacts = {}
local artifacts_Client = {} -- artifacts synced by the server

function artifactIDs()
	outputChatBox("Loaded artifact IDs:", 255,194,14)
	for artifact, fakeID in pairs(allocatedArtifacts) do
		outputChatBox("  - "..artifact.." allocated to ID #"..fakeID,255,126,0)
	end
end
addCommandHandler("artifacts", artifactIDs, false)

function syncWearingArtifacts(player, artifacts)
	artifacts_Client[player] = artifacts
end
addEvent("syncWearingArtifacts", true)
addEventHandler("syncWearingArtifacts", root, syncWearingArtifacts)

function isPlayerWearingArtifact(player, artifact)
	--returns boolean wether player is wearing the specified artifact or not

	if artifacts_Client[player] and artifacts_Client[player][artifact]
	and isElement(artifacts_Client[player][artifact].obj) then
		-- print(getPlayerName(player).." wearing "..artifact)
		return true
	end
	-- print(getPlayerName(player).." NOT wearing "..artifact)
	return false
end

function loadArtifactObject()
	if loadedArtifacts[source] then
		return
	end
	local int,dim = getElementInterior(localPlayer), getElementDimension(localPlayer)
	if getElementDimension(source)~=dim or getElementInterior(source)~=int then return end

	local artifactName = getElementData(source, "sarp_items:artifact")
	if not artifactName then return end

	local data = g_artifacts[artifactName]
	if not data then return end
	artifactName = data.customDffName or artifactName

	local gtaModel = data.gtaModel
	local newID
	if not gtaModel then

		local fakeID = allocatedArtifacts[artifactName]
		if not tonumber(fakeID) then return end
		newID = tonumber(fakeID)

	else
		newID = tonumber(gtaModel)
	end

	loadedArtifacts[source] = artifactName
	setElementModel(source, newID)

	if not data.colEnabled then
		setElementCollisionsEnabled(source, false)
	else
		setElementCollisionsEnabled(source, true)
	end

	setElementDoubleSided(source, data.ds)

	local x,y,z = getElementPosition(source)
	-- outputChatBox("Loaded artifact '"..artifactName.."' at "..x..", "..y..", "..z, 25,255,25)
end
addEvent("loadArtifactObject", true)
addEventHandler("loadArtifactObject", root, loadArtifactObject)

addEventHandler( "onClientElementStreamIn", root, 
function () 
	if getElementType(source) ~= "object" then return end
	triggerEvent("loadArtifactObject", source)
end)

addEventHandler( "onClientElementStreamOut", root, 
function () 
	if getElementType(source) ~= "object" then return end
	local l = loadedArtifacts[source]
	if l then
		-- outputChatBox("Unloaded artifact '"..l.."'.", 255,255,25)
		loadedArtifacts[source] = nil
	end
end)
addEventHandler( "onClientElementDestroy", root, 
function () 
	if getElementType(source) ~= "object" then return end
	local l = loadedArtifacts[source]
	if l then
		-- outputChatBox("Unloaded artifact '"..l.."'.", 255,255,25)
		loadedArtifacts[source] = nil
	end
end)

local path = "models/"
local exts = {
	dff = ".dff",
	txd = ".txd",
	col = ".col",
}
local loadedTxds = {}
local loadedDffs = {}
local loadedCols = {} -- not all need custom collision

function loadArtifactObjects()

	for artifact, _ in pairs(g_artifacts) do
		
		local isGtaModel = _.gtaModel
		if not isGtaModel then
			local newID = engineRequestModel("object", 1856) -- casino chip collision-less
			if not newID then
				outputDebugString("FAILED to get new object ID upon loading artifacts", 1)
				return
			end
			local lCount = 0

			local name = _.customDffName or artifact
			local txdname = _.customTxdName or name

			local txd = path..txdname..exts.txd
			if fileExists(txd) then
				if loadedTxds[txdname] then
					engineImportTXD(loadedTxds[txdname], newID)
					lCount = lCount + 1
				else
					local txdModel = engineLoadTXD(txd)
					if txdModel then
						loadedTxds[txdname] = txdModel
						engineImportTXD(txdModel, newID)
						lCount =  lCount + 1
					end
				end
			end

			local dff = path..name..exts.dff
			if fileExists(dff) then
				if loadedDffs[name] then
					engineReplaceModel(loadedDffs[name], newID)
					lCount = lCount + 1
				else
					local dffModel = engineLoadDFF(dff, newID)
					if dffModel then
						loadedDffs[name] = dffModel
						engineReplaceModel(dffModel, newID)
						lCount =  lCount + 1
					end
				end
			end

			local lNeed = 2

			if _.colEnabled then
				lNeed = 3

				local col = path..name..exts.col
				if fileExists(col) then
					if loadedCols[name] then
						engineReplaceCOL(loadedCols[name], newID)
						lCount = lCount + 1
					else
						local colStuff = engineLoadCOL(col)
						if colStuff then
							loadedCols[name] = colStuff
							engineReplaceCOL(colStuff, newID)
							lCount =  lCount + 1
						end
					end
				end
			end

			if lCount == lNeed then
				allocatedArtifacts[name] = newID
				-- print("Loaded artifact: "..name)
			else
				outputDebugString("Didn't load artifact properly: "..name, 1)
			end
		end
	end

	triggerServerEvent("item-system:addPlayerArtifacts", localPlayer)
	
	for k, object in ipairs(getElementsByType("object"), getRootElement(), true) do
		triggerEvent("loadArtifactObject", object)
	end
end


-- Fernando: 21/05/2021
-- ability to adjust position/rotation/scale of artifacts
local xmlPath = "wearable_positions.xml"
attTable = {}

function updateWearablesTable(artifact, pos)

	local skinID = getElementData(localPlayer, "skinID") or getElementModel(localPlayer)
	if not attTable[skinID] then
		attTable[skinID] = {}
	end

	attTable[skinID][artifact] = {
		pos[1], pos[2], pos[3], pos[4], pos[5], pos[6], pos[7]
	}


	if exports.global:isScripterOnDuty(localPlayer) then
		local text = pos[1]..", "..pos[2]..", "..pos[3]..",   "..pos[4]..", "..pos[5]..", "..pos[6].."},scale="..pos[7]
		if setClipboard(text) then
			outputChatBox(text.." #ffffffcopied to clipboard & not saving locally", 255,194,0,true)
			attTable[skinID][artifact] = nil
			return
		end
	end
	if saveWearablesTable() then
		outputChatBox("Saved '"..artifact.."' position for skin #"..skinID..".", 20,255,20)
		syncPositions()
	end
end

function resetPositionFor(artifact, skinID)
	if not attTable[skinID] then
		attTable[skinID] = {}
	end

	local xml = xmlCreateFile(xmlPath, "attachments")

	for i, skinNode in pairs(xmlNodeGetChildren(xml)) do
		local skinID_ = tonumber(xmlNodeGetAttribute(skinNode, "skinid"))
		if skinID_ == skinID then
			for j, artifactNode in pairs(xmlNodeGetChildren(skinNode)) do

				local artifact_  = tostring(xmlNodeGetAttribute(artifactNode, "artifact"))
				if artifact_ == artifact then
					xmlDestroyNode(artifactNode)
					break
				end
			end
		end
	end

	xmlSaveFile(xml)
	xmlUnloadFile(xml)

	attTable[skinID][artifact] = nil
	syncPositions()

	outputChatBox("Reset '"..artifact.."' position for skin #"..skinID..".", 20,255,20)
	return true
end

function resetAllPositions()
	local count = 0
	local xml = xmlCreateFile(xmlPath, "attachments")
	for i, skinNode in pairs(xmlNodeGetChildren(xml)) do
		for j, artifactNode in pairs(xmlNodeGetChildren(skinNode)) do
			xmlDestroyNode(artifactNode)
			count = count +1
		end
	end

	xmlSaveFile(xml)
	xmlUnloadFile(xml)

	attTable = {}
	syncPositions()

	outputChatBox("Deleted "..count.." saved wearable positions.", 50,255,50)
	return true
end

function togArtifactShowing(artifact, skinID, toHide)
	if not attTable[skinID] then
		attTable[skinID] = {}
	end

	if not attTable[skinID][artifact] then
		local data = g_artifacts[artifact]
		local pos = data.pos
  		local scale = data.scale
  		-- loading defaults as player is trying to hide an artifact that is not saved yet
		attTable[skinID][artifact] = {
		pos[1],
		  pos[2],
		  pos[3],
		  pos[4],
		  pos[5],
		  pos[6],
		  scale
		}
	end
	
	attTable[skinID][artifact][8] = toHide and "true" or nil

	if saveWearablesTable() then
		syncPositions()

		if toHide then
			outputChatBox("Wearable '"..artifact.."' will no longer be visible for skin #"..skinID..".", 5,255,5)
		else
			outputChatBox("Wearable '"..artifact.."' will now appear for skin #"..skinID..".", 5,255,5)
		end
	end
	return true
end

-- Save table to xml file
function saveWearablesTable()
	local result = false
	local xml = xmlCreateFile(xmlPath, "attachments")

	for skinID, attachments in pairs(attTable) do
		local skinNode = xmlCreateChild(xml, "skin")

		xmlNodeSetAttribute(skinNode, "skinid", skinID)
		result = true

		for artifactName, p in pairs(attachments) do
			local artifactNode = xmlCreateChild(skinNode, "wearable")

			xmlNodeSetAttribute(artifactNode, "artifact", artifactName)
			xmlNodeSetAttribute(artifactNode, "x", p[1])
			xmlNodeSetAttribute(artifactNode, "y", p[2])
			xmlNodeSetAttribute(artifactNode, "z", p[3])
			xmlNodeSetAttribute(artifactNode, "rx", p[4])
			xmlNodeSetAttribute(artifactNode, "ry", p[5])
			xmlNodeSetAttribute(artifactNode, "rz", p[6])
			xmlNodeSetAttribute(artifactNode, "scale", p[7])
			if p[8] then
				xmlNodeSetAttribute(artifactNode, "hidden", "true")
			else
				xmlNodeSetAttribute(artifactNode, "hidden", nil)
			end
		end
	end

	xmlSaveFile(xml)
	xmlUnloadFile(xml)
	return result
end

-- Load xml file to table
function loadWearablesTable()
	local xml = xmlLoadFile(xmlPath)

	if xml then
		for i, skinNode in pairs(xmlNodeGetChildren(xml)) do
			local skinID = tonumber(xmlNodeGetAttribute(skinNode, "skinid"))
			attTable[skinID] = {}

			for j, artifactNode in pairs(xmlNodeGetChildren(skinNode)) do
				local artifact   = tostring(xmlNodeGetAttribute(artifactNode, "artifact"))
				local x    = tonumber(xmlNodeGetAttribute(artifactNode, "x"))
				local y    = tonumber(xmlNodeGetAttribute(artifactNode, "y"))
				local z    = tonumber(xmlNodeGetAttribute(artifactNode, "z"))
				local rx   = tonumber(xmlNodeGetAttribute(artifactNode, "rx"))
				local ry   = tonumber(xmlNodeGetAttribute(artifactNode, "ry"))
				local rz   = tonumber(xmlNodeGetAttribute(artifactNode, "rz"))
				local scale= tonumber(xmlNodeGetAttribute(artifactNode, "scale"))
				local hidden=  xmlNodeGetAttribute(artifactNode, "hidden") and "true" or nil

				-- Validate the values before loading them into the table
				if math.abs(x) <= 0.5 and math.abs(y) <= 0.5 and math.abs(z) <= 0.5 then
					attTable[skinID][artifact] = {x, y, z, rx, ry, rz, scale, hidden}
				end
			end
		end

		xmlUnloadFile(xml)
	end
	return true
end

-- Send table to server
function syncPositions()
	triggerServerEvent("artifacts:syncPositions", localPlayer, localPlayer, attTable)
end


local startTimer
addEventHandler("onClientResourceStart", resourceRoot, function()

	setElementData(localPlayer, "artifacts-loading", true)
	loadArtifactObjects()
	if loadWearablesTable() then
		syncPositions()
	end
end)

addEventHandler( "onClientResourceStop", resourceRoot, function () 
	for _, realid in pairs(allocatedArtifacts) do
        engineFreeModel(tonumber(realid))
    end
end)
