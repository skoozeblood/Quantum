txd = engineLoadTXD ("models/ammu_nation_ls.txd", 4552)
engineImportTXD(txd, 4552)
dff = engineLoadDFF ("models/ammu_nation_ls.dff", 4552)
engineReplaceModel(dff, 4552, true)
col = engineLoadCOL("models/ammu_nation_ls.col")
engineReplaceCOL(col, 4552)


setOcclusionsEnabled ( false )