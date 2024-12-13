local s = engineLoadCOL ( "Model.col" )
engineReplaceCOL ( s, 17573 )
local s = engineLoadTXD ( "Model.txd" )
engineImportTXD ( s, 17573 )
local s = engineLoadDFF ( "Model.dff" )
engineReplaceModel ( s, 17573, true )

local s = engineLoadCOL ( "Model.col" )
engineReplaceCOL ( s, 17885 )
local s = engineLoadTXD ( "Model.txd" )
engineImportTXD ( s, 17885 )
local s = engineLoadDFF ( "Model.dff" )
engineReplaceModel ( s, 17885, true )

removeWorldModel(1498,10,2460.24,-1692.09,12.5156)

setOcclusionsEnabled( false )
