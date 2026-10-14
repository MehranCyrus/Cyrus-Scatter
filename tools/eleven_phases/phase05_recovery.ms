(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p05-*/" do throw "Owned P05 host required"
 global P05RStage,P05RRoot,P05RLeaf,P05RBad,P05RGood,P05REpoch,P05RRows
 if P05RStage==undefined do P05RStage=0
 local stage=P05RStage+1,log=if stage==1 then createFile (MCPFixtureDir+"phase05-recovery.txt") else openFile (MCPFixtureDir+"phase05-recovery.txt") mode:"a"
 fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 try (
  case stage of (
   1: (
    CyrusPerfHeadless=true;resetMaxFile #noPrompt
    local node=AminScatterObject name:"P05 dependency recovery";P05RRoot=node.baseObject;P05RRoot.updateMode=1;P05RRoot.autoRender=false
    P05RRoot.newLayer();P05RLeaf=P05RRoot.selectedLayer();P05RGood=plane length:30 width:30
    P05RRoot.setLayerSurfaces P05RLeaf #(P05RGood);P05RLeaf.addPointSource();P05RLeaf.amount=80
    P05RLeaf.procSelfOverride=true;P05RLeaf.procSelfEnabled=false;P05RLeaf.distributionMode=3;P05RLeaf.densityMap=checker color1:white color2:white
    P05RRoot.refreshAll();CyrusPointSync();P05REpoch=P05RRoot.procEpoch;P05RRows=with printAllElements on (P05RRoot.groupSnapshotRows as string)
    P05RBad=plane length:30 width:30 pos:[50,0,0];convertToMesh P05RBad;meshop.setMapSupport P05RBad 1 false;update P05RBad
    P05RRoot.setLayerSurfaces P05RLeaf #(P05RGood,P05RBad)
    local failure="";try(P05RRoot.refreshAll())catch(failure=getCurrentException())
    verify (P05RRoot.procEpoch==P05REpoch and (failure!="" or P05RLeaf.previewError!="")) "New receiver fails UV validation before publication" log
    CyrusPerfHeadless=false;select node;max modify mode;modPanel.setCurrentObject P05RRoot
    if not P05RRoot.mainUI.controlsReady do P05RRoot.mainUI.mountTimer.tick()
    P05RRoot.updateMode=2;P05Root=P05RRoot;P05Arm()
   )
   2: (delete P05RBad;P05Arm())
   3: (
    verify (P05RRoot.procEpoch>P05REpoch and P05RLeaf.previewError=="" and P05RLeaf.generatedCount==80) "Deleting a never-published failed dependency automatically recovers Live" log
    verify ((with printAllElements on (P05RRoot.groupSnapshotRows as string))==P05RRows) "Recovery restores complete original placement rows" log
    format "COMPLETE\n" to:log
   )
  )
  P05RStage=stage;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
