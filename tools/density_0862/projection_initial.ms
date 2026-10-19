-- Disposable owned Max 2027 fixture. Never execute in an artist process.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned density profile required"
    global DNode,DRoot,DLayer,DTerrain,DModel,DLog,DCheck,DInitialHash,DInitialEpoch
    DLog=createFile (MCPFixtureDir+"initial.txt")
    fn DCheck yes message = (format "%: %\n" (if yes then "PASS" else "FAIL") message to:DLog;flush DLog;if not yes do throw message)
    try (
        CyrusPerfHeadless=true;CyrusPointSuspended=true
        with undo off (
            resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.0
            DTerrain=plane name:"Density low-poly plane" width:1000 length:1000 widthsegs:1 lengthsegs:1 mapCoords:false
            DModel=pyramid name:"Density model" width:8 depth:8 height:24 pos:[-750,0,0];DModel.isHidden=true
            DNode=AminScatterObject name:"Density 0.86.2 witness";DRoot=DNode.baseObject;DRoot.updateMode=1
            DRoot.newLayer();DLayer=DRoot.selectedLayer();DRoot.setLayerSurfaces DLayer #(DTerrain)
            DLayer.sources=#(DModel);DLayer.sourceWeights=#(1.0);DLayer.amount=20000;DLayer.sourceRadiiWU=#(0.)
            DLayer.procSelfOverride=true;DLayer.procSelfEnabled=false;DLayer.procLayerSelfEnabled=false
        )
        DCheck (cyrusRecipeVersion()==6 and cyrusDensityImageVersion()==1) "Matched new native contracts"
        CyrusSetDensityImage DLayer (MCPFixtureDir+"scripts/Patterns/uniform.png") pattern:"uniform" revision:"fixture"
        DCheck (DLayer.densityCoordinateMode==1 and DLayer.densityWrapMode==1) "Pattern action selects physical projection and repeat"
        DRoot.evaluateProcedural()
        DCheck (DRoot.groupSnapshotRows[1].count==20000) "White projected image works without terrain UVs"
        DInitialHash=cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows;DInitialEpoch=DRoot.procEpoch
        close DLog
    )catch(if DLog!=undefined do (format "ERROR %\n" (getCurrentException()) to:DLog;close DLog);throw())
)
