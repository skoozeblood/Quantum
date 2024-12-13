local s = engineLoadCOL ( "Model.col" )
engineReplaceCOL ( s, 10378 )
local s = engineLoadTXD ( "Model.txd" )
engineImportTXD ( s, 10378 )
local s = engineLoadDFF ( "Model.dff" )
engineReplaceModel ( s, 10378, true )

setOcclusionsEnabled( false )

