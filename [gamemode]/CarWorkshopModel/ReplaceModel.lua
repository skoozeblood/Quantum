local s = engineLoadCOL ( "Model.col" )
engineReplaceCOL ( s, 4848 )
local s = engineLoadTXD ( "Model.txd" )
engineImportTXD ( s, 4848 )
local s = engineLoadDFF ( "Model.dff" )
engineReplaceModel ( s, 4848, true )

setOcclusionsEnabled( false )

