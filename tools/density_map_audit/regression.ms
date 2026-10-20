-- Serialized Max 2027 regression. Only the run.py-owned profile may execute it.
(
 if not (matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-map-audit-*/" or matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/") do throw "Owned map audit/reliability profile required"
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"audit-phase.txt")
 local log=createFile (MCPFixtureDir+"regression-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn fingerprint = cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows
 fn amountPage = (local p=DRoot.mainUI.editors[6];if p==undefined or p.distributionUI_obj!=DLayer do throw "Amount owner not mounted";p)
 fn scalarField = (
  local image=if DLayer.distributionMode==3 then DLayer.procDensityWeights() else undefined
  cyrusDensityOverlayInfo (cyrusPrepareDensityOverlay #(DTerrain) (DLayer.meshMaskPayload()) image (DLayer.densityMappingPayload()) DLayer.densityUVChannel 2 4096 false (DLayer.surfaceFilterPayload()) false #() #(#(),#()))
 )
 try (
  case phase of (
   "setup":(
    global DNode,DRoot,DLayer,DTerrain,DModel,AuditChecker,AuditCheckerHash,AuditCombinedHash,AuditClearHash,AuditIdle
    CyrusClearMeshMaskPreview undefined;CyrusPerfHeadless=false;CyrusPointSuspended=true
    with undo off (
     resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.
     DTerrain=plane name:"Map audit terrain" width:1000 length:1000 widthsegs:1 lengthsegs:1 mapCoords:true
     convertToMesh DTerrain;meshop.setNumMaps DTerrain 8 keep:true
     for channel in #(0,2,3,7) do (
      meshop.setMapSupport DTerrain channel true
      meshop.setNumMapVerts DTerrain channel DTerrain.numverts;meshop.setNumMapFaces DTerrain channel DTerrain.numfaces
      local value=case channel of (0:[0,0,0];2:[0.25,0.5,0.75];3:[1,1,1];7:[0.25,0.25,0])
      for i=1 to DTerrain.numverts do meshop.setMapVert DTerrain channel i value
      for i=1 to DTerrain.numfaces do meshop.setMapFace DTerrain channel i (getFace DTerrain i)
     )
     update DTerrain
     DModel=pyramid name:"Map audit model" width:8 depth:8 height:24 pos:[-750,0,0];DModel.isHidden=true
     DNode=AminScatterObject name:"Map audit scatter";DRoot=DNode.baseObject;DRoot.updateMode=1
     DRoot.newLayer();DLayer=DRoot.selectedLayer();DRoot.setLayerSurfaces DLayer #(DTerrain)
     DLayer.sources=#(DModel);DLayer.sourceWeights=#(1.);DLayer.sourceRadiiWU=#(0.);DLayer.amount=1000
     DLayer.procSelfOverride=true;DLayer.procSelfEnabled=false;DLayer.procLayerSelfEnabled=false
     AuditChecker=Checker color1:black color2:white;DLayer.densityCoordinateMode=0
    )
    select DNode;max modify mode;DRoot.bindNativeUI()
   )
   "mount":(DRoot.mainUI.slots[6].open=true;DRoot.mainUI.bindSection DRoot.mainUI.editors[6];check ((amountPage()).isDisplayed) "Actual Amount page bound" log)
   "manualClear":(
    local p=amountPage()
    p.distributionUI_densityButton.picked AuditChecker;DRoot.refreshAll()
    AuditCheckerHash=fingerprint();local beforeCount=DRoot.groupSnapshotRows[1].count,epoch=DRoot.procEpoch
    check (beforeCount>0 and beforeCount<1000) "Checker has a non-uniform starting publication" log
    p.distributionUI_densityButton.picked undefined
    check (DLayer.densityMap==undefined and DLayer.distributionMode==1) "Clear removes the map and disables image density" log
    check (DRoot.procEpoch==epoch and fingerprint()==AuditCheckerHash) "Manual Clear retains plants until Update" log
    DRoot.refreshAll();DRoot.evaluateProcedural();AuditClearHash=fingerprint()
    check (DRoot.groupSnapshotRows[1].count==1000 and AuditClearHash!=AuditCheckerHash) "Update after Clear publishes unmasked plants without an error" log
    local field=scalarField();check (field[2]==1 and field[3]==1) "Clear also removes image influence from the density field" log
   )
   "undo":(max undo)
   "verifyUndo":(
    check (DLayer.densityMap==AuditChecker and DLayer.distributionMode==3) "Undo restores both the map and image enable state" log
    DRoot.refreshAll();check (fingerprint()==AuditCheckerHash) "Undo reproduces the exact Checker publication" log
   )
   "redo":(max redo)
   "verifyRedo":(
    check (DLayer.densityMap==undefined and DLayer.distributionMode==1) "Redo restores the complete Clear state" log
    DRoot.refreshAll();check (fingerprint()==AuditClearHash) "Redo reproduces the exact cleared publication" log
   )
   "meshClear":(
    local p=amountPage()
    p.distributionUI_densityButton.picked AuditChecker
    p.distributionUI_meshChannelSpin.changed 2;p.distributionUI_setMeshMask #meshMaskComponent 1;p.distributionUI_meshCheck.changed true
    DRoot.refreshAll();AuditCombinedHash=fingerprint()
    p.distributionUI_densityButton.picked undefined;DRoot.refreshAll();DRoot.evaluateProcedural()
    check (DLayer.meshMaskEnabled and DLayer.meshMaskChannel==2 and DLayer.meshMaskComponent==1) "Clear preserves the independent numeric mesh rule" log
    local field=scalarField();check (field[2]==0.25 and field[3]==0.25) "Mesh-only field remains 0.25 after image Clear" log
    check (DRoot.groupSnapshotRows[1].count>0 and DRoot.groupSnapshotRows[1].count<1000 and fingerprint()!=AuditCombinedHash) "Mesh-only planting replaces the combined result" log
   )
   "verifyMeshUndo":(
    check (DLayer.densityMap==AuditChecker and DLayer.distributionMode==3 and DLayer.meshMaskEnabled) "Undo Clear preserves enabled mesh density" log
    DRoot.refreshAll();check (fingerprint()==AuditCombinedHash) "Undo restores exact combined image/mesh planting" log
   )
   "switch":(
    local p=amountPage()
    p.distributionUI_meshCheck.changed false
    for pattern in #("uniform","wide-bands","soft-patches") do (
     CyrusSetDensityImage DLayer (MCPFixtureDir+"scripts/Patterns/"+pattern+".png") pattern:pattern revision:"audit"
     DRoot.refreshAll();DRoot.evaluateProcedural()
     check (DRoot.groupSnapshotRows[1].count>0) ("Pattern evaluates: "+pattern) log
    )
    p.distributionUI_densityButton.picked AuditChecker;p.distributionUI_setImage #densityCoordinateMode 0
    DRoot.refreshAll();AuditCheckerHash=fingerprint()
    for channel in #(2,3,0,7) do (
     p.distributionUI_meshChannelSpin.changed channel;p.distributionUI_meshCheck.changed true
     DRoot.refreshAll();DRoot.evaluateProcedural();p.distributionUI_meshCheck.changed false;DRoot.refreshAll()
     check (fingerprint()==AuditCheckerHash) ("Disabling channel "+channel as string+" restores exact Checker result") log
    )
    p.distributionUI_meshChannelSpin.changed 8;p.distributionUI_meshCheck.changed true
    local failed=false;try(DRoot.evaluateProcedural())catch(failed=true)
    check (failed and fingerprint()==AuditCheckerHash) "Missing enabled mesh channel retains prior publication" log
    p.distributionUI_meshCheck.changed false;DRoot.refreshAll()
    check (fingerprint()==AuditCheckerHash) "Disabling the invalid mesh channel recovers" log
    p.distributionUI_uvChannelSpin.changed 7;DRoot.refreshAll();check (DRoot.groupSnapshotRows[1].count==1000) "Explicit constant receiver UV7 is sampled" log
    p.distributionUI_uvChannelSpin.changed 1;DRoot.refreshAll();check (fingerprint()==AuditCheckerHash) "Returning to receiver UV1 restores exact Checker result" log
    p.distributionUI_imageCheck.changed false;DRoot.refreshAll()
    check (DLayer.densityMap==AuditChecker and DRoot.groupSnapshotRows[1].count==1000) "Disable retains the map but removes its influence" log
    p.distributionUI_imageCheck.changed true;DRoot.refreshAll()
    check (fingerprint()==AuditCheckerHash) "Re-enable restores the assigned map" log
   )
   "patternClear":(
    local p=amountPage()
    for pattern in #("uniform","wide-bands","soft-patches") do (
     CyrusSetDensityImage DLayer (MCPFixtureDir+"scripts/Patterns/"+pattern+".png") pattern:pattern revision:"audit"
     DRoot.refreshAll()
     p.distributionUI_densityButton.picked undefined;DRoot.refreshAll();DRoot.evaluateProcedural()
     check (DLayer.densityMap==undefined and DLayer.distributionMode==1 and DRoot.groupSnapshotRows[1].count==1000) ("Clear removes pattern influence: "+pattern) log
     check (DLayer.densityPatternID=="" and DLayer.densityPatternRevision=="" and DLayer.densityMapProvenance=="") ("Clear removes pattern metadata: "+pattern) log
    )
   )
   "liveClear":(
    DRoot.updateMode=2;CyrusPointSuspended=false
    local p=amountPage();p.distributionUI_densityButton.picked AuditChecker;DRoot.refreshAll()
    check (DRoot.groupSnapshotRows[1].count>0 and DRoot.groupSnapshotRows[1].count<1000) "Live starts with the Checker result" log
    p.distributionUI_densityButton.picked undefined
   )
   "verifyLive":(
    check (DLayer.densityMap==undefined and DLayer.distributionMode==1 and DRoot.groupSnapshotRows[1].count==1000) "Live Clear publishes unmasked plants through callbacks without explicit Update" log
    AuditIdle=#(DRoot.procEpoch,DRoot.groupBuilds,DLayer.densityCacheStats())
   )
   "idle":(check (CyrusPresetSameValues AuditIdle #(DRoot.procEpoch,DRoot.groupBuilds,DLayer.densityCacheStats())) "Quiet Live does not solve or rebake" log)
   "liveMeshClear":(
    global AuditMeshOnlyHash
    local p=amountPage()
    p.distributionUI_meshChannelSpin.changed 2;p.distributionUI_setMeshMask #meshMaskComponent 1;p.distributionUI_meshCheck.changed true
    DRoot.refreshAll();AuditMeshOnlyHash=fingerprint()
    p.distributionUI_densityButton.picked AuditChecker;DRoot.refreshAll()
    CyrusMaskView=3;CyrusMaskDetail=1;CyrusShowMeshMaskPreview DLayer
    p.distributionUI_densityButton.picked undefined
   )
   "verifyLiveMesh":(
    check (DLayer.meshMaskEnabled and fingerprint()==AuditMeshOnlyHash) "Live Clear restores exact mesh-only planting without explicit Update" log
    local info=cyrusDensityOverlayInfo CyrusMeshMaskPreviewRows
    check (CyrusMeshMaskPreviewError=="" and info[2]==0.25 and info[3]==0.25) "Visible combined mask refreshes to mesh-only density after Clear" log
    CyrusClearMeshMaskPreview undefined
    (amountPage()).distributionUI_meshCheck.changed false
   )
   "save":(check (saveMaxFile (MCPFixtureDir+"clear-roundtrip.max") quiet:true) "Cleared scene saves" log)
   "reopen":(
    loadMaxFile (MCPFixtureDir+"clear-roundtrip.max") quiet:true
    DNode=getNodeByName "Map audit scatter";DRoot=DNode.baseObject;DLayer=DRoot.layerObjects[1];DTerrain=getNodeByName "Map audit terrain"
   )
   "verifyReopen":(
    check (DLayer.densityMap==undefined and DLayer.distributionMode==1) "Scene reopen preserves the disabled, empty map state" log
    DRoot.refreshAll();DRoot.evaluateProcedural()
    check (DRoot.groupSnapshotRows[1].count==1000) "Reopened cleared scene evaluates without missing-map failure" log
   )
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR %\n" (getCurrentException()) to:log;close log;throw())
)
