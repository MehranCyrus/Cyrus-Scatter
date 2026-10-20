(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/" do throw "Owned reliability profile required"
 gc light:false
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"receiver-map-phase.txt")
 local log=createFile (MCPFixtureDir+"receiver-map-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn closeScalar a b=(abs(a-b)<0.00001)
 fn page=(MRoot.mainUI.editors[6])
 fn fingerprint=(cyrusRecipePublicationFingerprint MRoot.groupSnapshotRows)
 fn setChannel node channel value=(for i=1 to (meshop.getNumMapVerts node channel) do meshop.setMapVert node channel i value;update node)
 fn refresh=(MRoot.refreshAll();MRoot.evaluateProcedural())
 fn mapField=(
  cyrusDensityOverlayInfo (cyrusPrepareDensityOverlay (MLayer.validSurfaces()) (MLayer.meshMaskPayload()) (MLayer.procDensityWeights()) (MLayer.densityMappingPayload()) MLayer.densityUVChannel 2 4096 false (MLayer.surfaceFilterPayload()) false #() #(#(),#()))
 )
 try (
  case phase of (
   "setup":(
    global MRoot,MLayer,MNode,MTerrain,MOther,MModel,MVertex,MCorrection,MInner,MOuter,MChecker,MHash,MIdle
    CyrusClearMeshMaskPreview undefined;CyrusPointSuspended=true;CyrusPerfHeadless=false
    with undo off (
     resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.
     MTerrain=plane name:"Receiver map terrain" width:1000 length:1000 widthsegs:1 lengthsegs:1 mapCoords:true
     convertToMesh MTerrain;meshop.setNumMaps MTerrain 8 keep:true
     for channel in #(0,2,3,7) do (
      meshop.setMapSupport MTerrain channel true
      meshop.setNumMapVerts MTerrain channel MTerrain.numverts;meshop.setNumMapFaces MTerrain channel MTerrain.numfaces
      for i=1 to MTerrain.numfaces do meshop.setMapFace MTerrain channel i (getFace MTerrain i)
      local value=case channel of (0:[0,0,0];2:[0.25,0.5,0.75];3:[1,1,1];7:[0.25,0.25,0])
      setChannel MTerrain channel value
     )
     MModel=box name:"Receiver map model" width:8 length:8 height:20 pos:[-750,0,0];MModel.isHidden=true
     MNode=AminScatterObject name:"Receiver map scatter";MRoot=MNode.baseObject;MRoot.updateMode=1
     MRoot.newLayer();MLayer=MRoot.selectedLayer();MRoot.setLayerSurfaces MLayer #(MTerrain)
     MLayer.sources=#(MModel);MLayer.sourceWeights=#(1.);MLayer.sourceRadiiWU=#(0.);MLayer.amount=1000
     MLayer.procSelfOverride=true;MLayer.procSelfEnabled=false;MLayer.procLayerSelfEnabled=false
     MVertex=Vertex_Color map:3;MCorrection=ColorCorrection map:MVertex;MInner=Output map1:MCorrection;MOuter=Output map1:MInner
     MChecker=Checker color1:black color2:white
    )
    select MNode;max modify mode;MRoot.bindNativeUI()
   )
   "white":(
    MRoot.mainUI.slots[6].open=true;MRoot.mainUI.bindSection (page())
    (page()).distributionUI_densityButton.picked MOuter;refresh()
    check (MLayer.densityCoordinateMode==3) "Map picker selects receiver-aware coordinates" log
    check (closeScalar (cyrusReceiverMapSample MTerrain MOuter 1 [0.2,0.3,0.5]) 1) "Vertex Color / Color Correction / Output chain reads white channel 3" log
    check (MRoot.groupSnapshotRows[1].count==1000 and MLayer.previewError=="") "White graph admits every candidate" log
    local info=mapField();check (closeScalar info[2] 1 and closeScalar info[3] 1) "White graph preview agrees with placements" log
    MHash=fingerprint();setChannel MTerrain 3 [0,0,0];refresh()
    check (MRoot.groupSnapshotRows[1].count==0 and MLayer.previewError=="") "Editing receiver channel to black removes every candidate" log
    info=mapField();check (info[2]==0 and info[3]==0) "Black graph preview agrees with placements" log
    setChannel MTerrain 3 [1,1,1];refresh();check (fingerprint()==MHash) "Restoring channel data restores exact identities/transforms" log
   )
   "channels":(
    MVertex.map=2;refresh()
    local expected=0.25*0.2126+0.5*0.7152+0.75*0.0722
    check (closeScalar (cyrusReceiverMapSample MTerrain MVertex 1 [0.2,0.3,0.5]) expected) "Arbitrary numeric channel RGB is interpolated before luminance" log
    local info=mapField();check (closeScalar info[2] expected and closeScalar info[3] expected) "Nested graph preview uses the same scalar response" log
    MVertex.map=0;refresh();check (MRoot.groupSnapshotRows[1].count==0) "Vertex Color can use black channel 0" log
    MVertex.map=8;local previous=fingerprint(),failed=false
    try(MRoot.evaluateProcedural())catch(failed=true;format "EXPECTED: %\n" (getCurrentException()) to:log)
    check (failed and fingerprint()==previous) "Missing map channel retains the complete previous result" log
    MVertex.map=3;refresh();check (fingerprint()==MHash) "Repairing the map channel recovers the exact white result" log
   )
   "checker":(
    (page()).distributionUI_densityButton.picked MChecker;refresh()
    check (MRoot.groupSnapshotRows[1].count>0 and MRoot.groupSnapshotRows[1].count<1000) "Checker uses receiver UV1" log
    MHash=fingerprint();MChecker.coords.mapChannel=7;refresh()
    local value=cyrusReceiverMapSample MTerrain MChecker 1 [0.2,0.3,0.5],info=mapField()
    check ((value==0 or value==1) and info[2]==value and info[3]==value) "Checker's own UV7 is a constant field on this receiver" log
    check (MRoot.groupSnapshotRows[1].count==(value*1000) and fingerprint()!=MHash) "Changing the map's own UV channel changes placement eligibility" log
    MChecker.coords.mapChannel=1;refresh();check (fingerprint()==MHash) "Returning map UV1 restores the exact Checker result" log
    (page()).distributionUI_meshChannelSpin.changed 2;(page()).distributionUI_meshCheck.changed true;refresh()
    (page()).distributionUI_densityButton.picked undefined;refresh()
    check (MLayer.densityMap==undefined and MLayer.distributionMode==1 and MLayer.meshMaskEnabled) "Clear removes map while preserving the independent mesh mask" log
    (page()).distributionUI_meshCheck.changed false
    CyrusSetDensityImage MLayer (MCPFixtureDir+"scripts/Patterns/wide-bands.png") pattern:"wide-bands" revision:"receiver-map-test";refresh()
    check (MLayer.densityCoordinateMode==1 and MRoot.groupSnapshotRows[1].count>0) "Pattern selection restores projected image coordinates" log
    (page()).distributionUI_densityButton.picked MOuter;refresh()
    check (MLayer.densityCoordinateMode==3 and MRoot.groupSnapshotRows[1].count==1000) "Returning to a map restores receiver context after pattern and mesh-mask changes" log
   )
   "receivers":(
    MOther=copy MTerrain;MOther.name="Second map receiver";MOther.pos=[2000,0,300]
    setChannel MOther 3 [0,0,0];MRoot.setLayerSurfaces MLayer #(MTerrain,MOther);refresh()
    check (MRoot.groupSnapshotRows[1].count==500) "Two equal receivers evaluate their own white/black channel data" log
    local info=mapField();check (info[2]==0 and info[3]==1) "Multiple-receiver preview contains both independent fields" log
    setChannel MOther 3 [1,1,1];refresh();check (MRoot.groupSnapshotRows[1].count==1000) "Changing only the second receiver refreshes its eligibility" log
    MOther.scale=[-2,1,0.5];MOther.rotation=eulerAngles 20 15 35;refresh()
    check (MRoot.groupSnapshotRows[1].count==1000 and closeScalar (cyrusReceiverMapSample MOther MOuter 1 [0.2,0.3,0.5]) 1) "Mirrored, scaled and rotated receiver preserves its constant channel" log
    MRoot.setLayerSurfaces MLayer #(MTerrain);refresh()
   )
   "live":(
    MRoot.updateMode=2;CyrusPointSuspended=false;MVertex.map=0
   )
   "verifyLive":(
    check (MRoot.groupSnapshotRows[1].count==0 and MLayer.previewError=="") "Nested map edit updates Live placements without Update" log
    MVertex.map=3
   )
   "idle":(
    check (MRoot.groupSnapshotRows[1].count==1000) "Nested map recovery updates Live placements" log
    MIdle=#(cyrusReceiverMapStats(),MRoot.procEpoch)
   )
   "verifyIdle":(
    check (CyrusPresetSameValues MIdle[1] (cyrusReceiverMapStats()) and MIdle[2]==MRoot.procEpoch) "Idle performs no map evaluation or scatter solve" log
    check (saveMaxFile (MCPFixtureDir+"receiver-map-roundtrip.max") quiet:true) "Receiver map graph saves" log
   )
   "reopen":(
    loadMaxFile (MCPFixtureDir+"receiver-map-roundtrip.max") quiet:true
    MNode=getNodeByName "Receiver map scatter";MRoot=MNode.baseObject;MLayer=MRoot.layerObjects[1];MTerrain=getNodeByName "Receiver map terrain"
   )
   "verifyReopen":(
    refresh();check (MLayer.densityCoordinateMode==3 and MRoot.groupSnapshotRows[1].count==1000 and MLayer.previewError=="") "Scene reopen restores graph and receiver coordinates" log
   )
   "animationSetup":(
    MRoot.updateMode=1;CyrusPointSuspended=true
    with animate on (
     at time 0 (MChecker.color1=black;MChecker.color2=black)
     at time 10 (MChecker.color1=white;MChecker.color2=white)
    )
    sliderTime=0;(page()).distributionUI_densityButton.picked MChecker;refresh()
    check (MRoot.groupSnapshotRows[1].count==0) "Animated map starts with a black field" log
    MHash=fingerprint();CyrusPointSuspended=false;sliderTime=10
   )
   "animationManual":(
    check (fingerprint()==MHash) "Manual map animation retains publication until Update" log
    local info=mapField();check (abs(info[2]-1)<0.00001 and abs(info[3]-1)<0.00001) "Current animated mask can preview while Manual plants remain pending" log
    refresh();check (MRoot.groupSnapshotRows[1].count==1000) "Explicit Update evaluates animated map at current time" log
    MRoot.updateMode=2;sliderTime=0
   )
   "animationLive":(
    check (MRoot.groupSnapshotRows[1].count==0 and MLayer.previewError=="") "Live follows the relevant animated map to black" log
    sliderTime=10
   )
   "animationRecover":(
    check (MRoot.groupSnapshotRows[1].count==1000 and MLayer.previewError=="") "Live follows the relevant animated map back to white" log
    (page()).distributionUI_densityButton.picked MOuter;refresh();sliderTime=0
    global MUnrelated
    MUnrelated=box name:"Unrelated animated object" pos:[3000,0,0]
    with animate on (at time 0 MUnrelated.pos=[3000,0,0];at time 10 MUnrelated.pos=[3500,0,0])
   )
   "unrelatedStart":(MIdle=#(cyrusReceiverMapStats(),MRoot.procEpoch);sliderTime=10)
   "unrelatedVerify":(
    check (CyrusPresetSameValues MIdle[1] (cyrusReceiverMapStats()) and MIdle[2]==MRoot.procEpoch) "Unrelated animation does not sample the static map or solve Scatter" log
   )
   "scaleBounds":(
    MRoot.updateMode=1;CyrusPointSuspended=true
    for factor in #(0.00001,100000.) do (
     MTerrain.scale=[factor,factor,factor];refresh()
     check (MRoot.groupSnapshotRows[1].count==1000 and MLayer.previewError=="" and closeScalar (cyrusReceiverMapSample MTerrain MOuter 1 [.2,.3,.5]) 1) "Very small and large uniform receiver scales keep the constant field valid" log
    )
    MHash=fingerprint();MTerrain.scale=[0,1,1];local failed=false
    try(MRoot.evaluateProcedural())catch(failed=true;format "EXPECTED: %\n" (getCurrentException()) to:log)
    check (failed and fingerprint()==MHash) "Singular receiver retains complete previous publication" log
    MTerrain.scale=[1,1,1];refresh()
    check (MRoot.groupSnapshotRows[1].count==1000 and MLayer.previewError=="") "Repairing receiver scale recovers normal map evaluation" log
   )
   "unsupported":(
    MRoot.updateMode=1;CyrusPointSuspended=true;MHash=fingerprint()
    local unsupported=Falloff(),failed=false
    format "HOLD before unsupported assignment: %\n" (theHold.Holding()) to:log
    (page()).distributionUI_densityButton.picked unsupported
    format "HOLD after unsupported assignment: %\n" (theHold.Holding()) to:log
    try(MRoot.evaluateProcedural())catch(failed=true;format "EXPECTED: %\n" (getCurrentException()) to:log)
    check (failed and fingerprint()==MHash) "Unsupported view-dependent graph retains the complete previous result" log
    format "HOLD after unsupported calculation: %\n" (theHold.Holding()) to:log
    local deep=Vertex_Color map:3
    for i=1 to 34 do deep=Output map1:deep
    format "HOLD after deep graph creation: %\n" (theHold.Holding()) to:log
    (page()).distributionUI_densityButton.picked deep;failed=false
    try(MRoot.evaluateProcedural())catch(failed=true;format "EXPECTED: %\n" (getCurrentException()) to:log)
    check (failed and fingerprint()==MHash) "Excessive nested graph rejects within its traversal bound" log
    format "HOLD after deep graph rejection: %\n" (theHold.Holding()) to:log
    (page()).distributionUI_densityButton.picked MOuter;refresh();check (fingerprint()==MHash) "Supported replacement graph recovers exact publication" log
   )
   default:throw "Unknown receiver-map phase"
  )
  format "HOLD: %\n" (theHold.Holding()) to:log
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
