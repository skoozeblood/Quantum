local s = engineLoadCOL ( "Model.col" )
engineReplaceCOL ( s, 16201 )
local s = engineLoadTXD ( "Model.txd" )
engineImportTXD ( s, 16201 )
local s = engineLoadDFF ( "Model.dff" )
engineReplaceModel ( s, 16201, true )

setOcclusionsEnabled( false )
