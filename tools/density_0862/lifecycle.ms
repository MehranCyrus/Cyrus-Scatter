(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"lifecycle-phase.txt"),log=createFile (MCPFixtureDir+"lifecycle-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  case phase of (
   "liveStart":(
    CyrusClearMeshMaskPreview undefined
    with undo off (
     CyrusSetDensityImage DLayer (MCPFixtureDir+"scripts/Patterns/uniform.png") pattern:"uniform" revision:"QA"
     DLayer.invertDensity=false;DLayer.meshMaskEnabled=false;DLayer.amount=4000;DRoot.updateMode=2
    )
    DRoot.refreshAll()
    check (DRoot.groupSnapshotRows[1].count==4000) "Live fixture begins with white image" log
    global LiveBefore=DRoot.procEpoch
    undo "Live map output" on DLayer.densityMap.output.RGB_Level=0.
   )
   "liveVerify":(
    check (DRoot.groupSnapshotRows[1].count==0 and DRoot.procEpoch>LiveBefore) "Editing a referenced texture output updates Live placements" log
    global LiveIdle=#(DRoot.procEpoch,DRoot.groupBuilds,DLayer.densityCacheStats())
   )
   "liveIdle":(
    check (CyrusPresetSameValues LiveIdle #(DRoot.procEpoch,DRoot.groupBuilds,DLayer.densityCacheStats())) "Live idle does not solve or rebake" log
    with undo off (
     global Unrelated=box name:"Owned unrelated animation witness" width:1 length:1 height:1
     with animate on (at time 0 Unrelated.pos=[1000,0,0];at time 10 Unrelated.pos=[1100,0,0])
    )
    sliderTime=5
   )
   "unrelatedTime":(
    check (CyrusPresetSameValues LiveIdle #(DRoot.procEpoch,DRoot.groupBuilds,DLayer.densityCacheStats())) "Unrelated animation does not recalculate static density placements" log
    with undo off (delete Unrelated;sliderTime=0;DRoot.updateMode=1;DLayer.densityMap.output.RGB_Level=1.)
    DRoot.refreshAll();CyrusMaskView=3;CyrusShowMeshMaskPreview DLayer
    global MaskComplete=CyrusMeshMaskPreviewRows
    with undo off (DLayer.meshMaskEnabled=true;DLayer.meshMaskChannel=7)
   )
   "staleField":(
    check (CyrusMeshMaskPreviewTarget==DLayer and CyrusMeshMaskPreviewRows==MaskComplete and CyrusMeshMaskPreviewError!="") "Failed same-owner mask refresh retains visible intent and marks previous field stale" log
    local other=DRoot.newLayer();other=DRoot.selectedLayer();DRoot.setLayerSurfaces other #(DTerrain)
    with undo off (other.meshMaskEnabled=true;other.meshMaskChannel=7)
    local rejected=false;try(CyrusShowMeshMaskPreview other)catch(rejected=true)
    check (rejected and CyrusMeshMaskPreviewTarget==other and CyrusMeshMaskPreviewRows==undefined and CyrusMeshMaskPreviewError!="") "Failed owner switch cannot display another layer's mask" log
    CyrusClearMeshMaskPreview undefined
   )
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
