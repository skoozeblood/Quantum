function setLODsClient(lodTbl)
	-- autism from RPP 5150
	-- for i, model in ipairs(lodTbl) do
	-- 	engineSetModelLODDistance(model, 300)
	-- end

	-- this is bad idea - disabled // Fernando
	-- for i = 1, 10000 do -- put all objects between 1 t/m 10000 in a loop
	-- 	engineSetModelLODDistance ( i, 300 ) --force them to load.
	-- end
end
addEvent("setLODsClient", true)
addEventHandler("setLODsClient", resourceRoot, setLODsClient)

-- Fernando
function removeCertainObjects()

	triggerServerEvent("requestLODsClient", resourceRoot)

end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), removeCertainObjects)
