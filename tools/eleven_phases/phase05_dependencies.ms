-- Real deleted-handle callbacks. Each stage has a quiet host-event boundary.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
 global P05DRoot,P05DLeaf,P05DOther,P05DParent,P05DSource,P05DReceiver,P05DRevision,P05DOtherRevision,P05DEpoch,P05DRows,P05DOtherRows
 -- Keep a resumable stage marker; the runner archives it before a fresh run.
 local marker=MCPFixtureDir+"phase05-dependencies-stage.txt",stage=1
 if doesFileExist marker do stage=(((dotNetClass "System.IO.File").ReadAllText marker) as integer)+1
 local log=if stage==1 then createFile (MCPFixtureDir+"phase05-dependencies.txt") else openFile (MCPFixtureDir+"phase05-dependencies.txt") mode:"a"
 fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn p05DKey root i = (with printAllElements on (root.groupSnapshotRows[i] as string))
 fn p05DSave = (
  P05DRevision=P05DLeaf.procGeometryRevision;P05DOtherRevision=P05DOther.procGeometryRevision;P05DEpoch=P05DRoot.procEpoch
  P05DRows=p05DKey P05DRoot 1;P05DOtherRows=p05DKey P05DRoot 2
 )
 try (
  case stage of (
   1: (
    CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
    local node=AminScatterObject name:"P05 dependency deletion";P05DRoot=node.baseObject
    P05DRoot.updateMode=1;P05DRoot.autoRender=false
    P05DReceiver=plane length:40 width:40 lengthsegs:1 widthsegs:1
    P05DParent=dummy();P05DSource=box length:1 width:1 height:2 pos:[100,0,0];P05DSource.parent=P05DParent
    P05DRoot.newLayer();P05DLeaf=P05DRoot.selectedLayer();P05DRoot.setLayerSurfaces P05DLeaf #(P05DReceiver)
    P05DLeaf.sources=#(P05DSource);P05DLeaf.amount=80;P05DLeaf.procSelfOverride=true;P05DLeaf.procSelfEnabled=false
    P05DRoot.newLayer();P05DOther=P05DRoot.selectedLayer();P05DRoot.setLayerSurfaces P05DOther #(plane length:40 width:40 lengthsegs:1 widthsegs:1 pos:[0,100,0])
    P05DOther.addPointSource();P05DOther.amount=40;P05DOther.procSelfOverride=true;P05DOther.procSelfEnabled=false
    P05DRoot.refreshAll();CyrusPointSync()
    verify (findItem P05DLeaf.procDependencyHandles (getHandleByAnim P05DParent)>0) "Published dependency handles include ancestors" log
    CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject P05DRoot
    if not P05DRoot.mainUI.controlsReady do P05DRoot.mainUI.mountTimer.tick()
    P05DRoot.updateMode=2;P05Root=P05DRoot;P05Arm()
   )
   2: (p05DSave();delete P05DParent;P05Arm())
   3: (
    verify (P05DLeaf.procGeometryRevision>P05DRevision and P05DRoot.procEpoch>P05DEpoch) "Deleting a real dependency parent triggers Live successor" log
    verify (P05DOther.procGeometryRevision==P05DOtherRevision and (p05DKey P05DRoot 2)==P05DOtherRows) "Parent deletion does not invalidate unrelated layer geometry" log
    verify (isValidNode P05DSource) "Parent deletion leaves source available" log
    p05DSave();clearUndoBuffer();undo "P05 delete actual source" on delete P05DSource;P05Arm()
   )
   4: (
    verify (P05DLeaf.procGeometryRevision>P05DRevision and P05DRoot.procEpoch==P05DEpoch and P05DLeaf.previewError!="" and (p05DKey P05DRoot 1)==P05DRows) "Deleting the only source attempts Live update and retains complete result on failure" log
    verify (P05DLeaf.procDependencyHandles.count>0) "Failed successor retains dependency handles" log
    verify (P05DOther.procGeometryRevision==P05DOtherRevision and (p05DKey P05DRoot 2)==P05DOtherRows) "Source deletion preserves unrelated geometry revision and rows" log
    max undo;P05Arm()
   )
   5: (
    verify (isValidNode P05DLeaf.sources[1] and (p05DKey P05DRoot 1)==P05DRows) "Undo restores deleted source and complete placement rows" log
    P05DRoot.updateMode=1;p05DSave();delete P05DReceiver;P05Arm()
   )
   6: (
    verify (P05DLeaf.procGeometryRevision>P05DRevision and P05DRoot.procEpoch==P05DEpoch and (p05DKey P05DRoot 1)==P05DRows) "Manual receiver deletion invalidates input but retains published rows" log
    verify (P05DOther.procGeometryRevision==P05DOtherRevision and (p05DKey P05DRoot 2)==P05DOtherRows) "Receiver deletion preserves unrelated layer" log
    verify (not theHold.Holding()) "Dependency lifecycle leaves no stranded hold" log
    format "COMPLETE\n" to:log
   )
  )
  (dotNetClass "System.IO.File").WriteAllText marker (stage as string);close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
