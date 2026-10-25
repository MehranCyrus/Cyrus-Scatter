loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-stem-inspect-20261024-02/" "CyrusStemInspect.dlx"
(
    cvlStage "load lavender source"
    loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library/Models/Shrubs/A084 - Lavender - 05/model.max" quiet:true useFileUnits:true
    cvlStage "export topology"
    cvsInspect (getNodeByName "CyrusModel_A084") (CVLTestDir+"lavender")
    cvlStage "done"
)
