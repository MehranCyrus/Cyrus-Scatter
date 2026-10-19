-- Failure, persistence and heavy-placement witnesses in this task's owned process.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"extended-phase.txt"),log=createFile (MCPFixtureDir+"extended-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try(
  case phase of (
   "maskRefresh":(
    check (CyrusMeshMaskPreviewTarget==DLayer) "Invert leaves mask visibility intent enabled" log
    check ((cyrusDensityOverlayInfo CyrusMeshMaskPreviewRows)[3]==0) "Coalesced preview refresh shows inverted white as zero" log
    check (DRoot.procEpoch==DInitialEpoch) "Preview refresh preserves Manual publication" log
    max undo
    check (CyrusMeshMaskPreviewTarget==DLayer) "Undo retains visible mask intent" log
   )
   "maskUndo":(
    check ((cyrusDensityOverlayInfo CyrusMeshMaskPreviewRows)[2]==1) "Undo refreshes the still-visible mask" log
    max redo
    check (CyrusMeshMaskPreviewTarget==DLayer) "Redo retains visible mask intent" log
   )
   "maskRedo":(
    check ((cyrusDensityOverlayInfo CyrusMeshMaskPreviewRows)[3]==0) "Redo refreshes visible field" log
    CyrusClearMeshMaskPreview undefined
    global DHidden=cyrusDensityOverlayStats(),DIdle=cyrusPlacementTransportStats(),DEpoch=DRoot.procEpoch
    with undo off (DLayer.invertDensity=false;DLayer.densityHeading=25)
   )
   "hiddenIdle":(
    check (CyrusPresetSameValues DHidden (cyrusDensityOverlayStats())) "Hidden mask edits and idle do not sample or draw fields" log
    check (DRoot.procEpoch==DEpoch and CyrusPresetSameValues DIdle (cyrusPlacementTransportStats())) "Manual idle does not calculate or upload placements" log
   )
   "lateFailure":(
    CyrusPointSuspended=true
    with undo off (DLayer.invertDensity=false;DLayer.densityHeading=0;DRoot.updateMode=1)
    DRoot.evaluateProcedural()
    local before=DRoot.layerObjects as array,objectsBefore=objects as array,hash=cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows,bindings=#()
    local document=CyrusRecipeCapture DRoot #(DLayer) "Late failure fixture" bindingResult:bindings,settings=CyrusRecipeGet (CyrusRecipeGet document "layers")[1] "settings"
    CyrusRecipePut settings "placementMode" 2;CyrusRecipePut settings "gridColumnWU" 0.001;CyrusRecipePut settings "gridRowWU" 0.001
    undo "Prior artist transform witness" on DModel.pos.x-=10
    local position=DModel.pos,rejected=false,reason=""
    global DStageSeen=false
    fn stageFailureWitness unused bindings=(DStageSeen=true;box name:"Owned late-failure asset" width:1 length:1 height:1;bindings)
    try(CyrusRecipeImport DRoot document bindings variation:#same prepareAssets:#(stageFailureWitness,undefined) packagedPaintReceivers:#() calculate:true)catch(rejected=true;reason=getCurrentException())
    format "REJECTION: %\n" reason to:log;flush log
    check (rejected and DStageSeen and matchPattern (toLower reason) pattern:"*grid*") "First native grid calculation fails after asset/layer staging, not recipe validation" log
    check (CyrusPresetSameValues before (DRoot.layerObjects as array) and CyrusPresetSameValues objectsBefore (objects as array)) "Late failure rolls back staged owners and nodes" log
    check ((cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows)==hash) "Late failure retains previous complete native publication" log
    max undo
    check (DModel.pos.x==position.x+10) "Failed import does not consume or clear preceding Undo history" log
    max redo
    check (DModel.pos==position) "Preceding history still supports Redo" log
    CyrusPointSuspended=false
   )
   "heavy":(
    CyrusPerfHeadless=false;CyrusPointSuspended=true
    cyrusPlacementTransportStats true
    with undo off (DRoot.updateMode=1;DLayer.meshMaskEnabled=false;DLayer.invertDensity=false;DLayer.densityCoordinateMode=1;DLayer.densityHeading=0;DLayer.amount=200000)
    local start=timeStamp(),maps=DLayer.densityCacheStats()
    DRoot.refreshAll();local elapsed=timeStamp()-start
    format "HEAVY 200000 candidates: % ms, accepted=% maps=% transport=%\n" elapsed DRoot.groupSnapshotRows[1].count (DLayer.densityCacheStats()) (cyrusPlacementTransportStats()) to:log;flush log
    check (DLayer.previewError=="" and DRoot.groupSnapshotRows[1].count==200000) "Large white-mask Count publishes native placements" log
    global HHash=cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows,HMaps=DLayer.densityCacheStats(),HSolves=DRoot.groupBuilds
    undo "Large Count change" on DLayer.amount=250000
    start=timeStamp();DRoot.refreshAll();format "HEAVY 250000 candidates: % ms\n" (timeStamp()-start) to:log
    check (DLayer.previewError=="" and DRoot.groupSnapshotRows[1].count==250000) "Large count change succeeds without MAXScript placement arrays" log
    max undo;DRoot.refreshAll()
    check ((cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows)==HHash) "Large Count Undo reproduces exact preceding placements" log
    max redo;DRoot.refreshAll()
    check (DRoot.groupSnapshotRows[1].count==250000) "Large Count Redo succeeds" log
    check ((DLayer.densityCacheStats())[1]==HMaps[1]) "Count-only edits reuse the unchanged sampled image" log
    CyrusPointSuspended=false
    CyrusPointSync();completeRedraw()
    global HIdle=#(DRoot.procEpoch,DRoot.groupBuilds,cyrusPlacementTransportStats(),DLayer.densityCacheStats(),cyrusDensityOverlayStats())
   )
   "heavyIdle":(
    check (CyrusPresetSameValues HIdle #(DRoot.procEpoch,DRoot.groupBuilds,cyrusPlacementTransportStats(),DLayer.densityCacheStats(),cyrusDensityOverlayStats())) "Heavy scene idle does not solve, rebake or upload" log
   )
   "noise":(
    with undo off (DLayer.amount=4000;DLayer.densityMap=Noise size:25;DLayer.invertDensity=false;DLayer.densityHeading=0)
    DRoot.refreshAll()
    check (DLayer.previewError=="" and DRoot.groupSnapshotRows[1].count>0) "Built-in Noise evaluates as a live bounded 2D density tile" log
    global NBefore=DLayer.procDensityWeights(),NMap=DLayer.densityMap,NHash=cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows
    CyrusBakeDensityImage DLayer directory:(MCPFixtureDir+"baked-maps")
    check (classof DLayer.densityMap==Bitmaptexture and matchPattern DLayer.densityMapProvenance pattern:"baked 2D tile*") "Bake authors an explicit portable snapshot with provenance" log
    DRoot.refreshAll()
    local image=DLayer.procDensityWeights(),mapping=DLayer.densityMappingPayload(),cfg=#(false,2,1,0.,1.,false,#(0.,1.)),filters=#(false,0.,180.,0.,0.,false,0.,1000.,0.,0.)
    local a=cyrusPrepareDensityOverlay #(DTerrain) cfg NBefore mapping 1 0 4096 false filters false #() #(#(),#())
    local b=cyrusPrepareDensityOverlay #(DTerrain) cfg image mapping 1 0 4096 false filters false #() #(#(),#()),error=0.
    for i=1 to (cyrusDensityOverlayInfo a)[1] by 17 do for j=1 to 3 do error=amax error (abs((cyrusDensityOverlayVertex a i j)[2]-(cyrusDensityOverlayVertex b i j)[2]))
    format "BAKE maximum scalar error=%\n" error to:log;flush log
    check (error<0.0001) "Baked image preserves the live scalar tile within PNG quantization/filter tolerance" log
    max undo
    check (DLayer.densityMap==NMap) "One Undo restores the original editable procedural map" log
   )
   default:throw "Unknown extended phase"
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
