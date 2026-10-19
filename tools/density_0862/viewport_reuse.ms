(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"viewport-phase.txt"),log=createFile (MCPFixtureDir+"viewport-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  case phase of (
   "before":(
    CyrusPerfHeadless=false;CyrusPointSuspended=false;CyrusPointSync();completeRedraw()
    global QOwner=CyrusPointOwner DNode,QBefore=undefined
    global QNameBefore=DRoot.layerNames[DRoot.activeLayer]
    check (isValidNode QOwner) "Actual retained viewport owner exists" log
    local stats=cyrusRetainedStats QOwner
    check (stats[12]==1) "Native viewport buffers are ready" log
    QBefore=#(DRoot.procEpoch,DRoot.groupBuilds,DLayer.densityCacheStats(),cyrusPlacementTransportStats(),stats[3],stats[6])
   )
   "after":(
    local stats=cyrusRetainedStats QOwner,after=#(DRoot.procEpoch,DRoot.groupBuilds,DLayer.densityCacheStats(),cyrusPlacementTransportStats(),stats[3],stats[6])
    format "BEFORE=%\nAFTER=%\n" QBefore after to:log
    check (CyrusPresetSameValues QBefore after) "Physical panel navigation/idle reuses solves, sampled image, native placements and uploaded buffers" log
   )
   "redraw":(
    CyrusMaskView=1;CyrusMaskDetail=2;CyrusShowMeshMaskPreview DLayer;completeRedraw()
    local before=cyrusDensityOverlayStats(),stats=cyrusRetainedStats QOwner,epoch=DRoot.procEpoch,start=timeStamp()
    for i=1 to 30 do completeRedraw()
    local elapsed=timeStamp()-start,after=cyrusDensityOverlayStats(),next=cyrusRetainedStats QOwner
    format "30 complete redraw requests=% ms; field counters % -> %\n" elapsed before after to:log
    check (before[1]==after[1] and before[2]==after[2]) "Redraw uses cached field vertices without preparation" log
    check (stats[3]==next[3] and stats[6]==next[6] and DRoot.procEpoch==epoch) "Mask drawing does not republish or re-upload Scatter instances" log
    CyrusClearMeshMaskPreview undefined
   )
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
