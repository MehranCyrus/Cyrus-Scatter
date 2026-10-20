cplResetScene()
fn lifeRequire value message = if not value do throw message
fn lifeFlush lab = cplSynchronize lab.physicsDocument
fn lifeFreeze lab = (cplFreeze lab.physicsDocument;for i=1 to 100 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;sleep .01);lifeRequire (not (cplUIState lab.physicsDocument)[2]) ("Freeze failed: "+cplStats lab.physicsDocument))
(
 units.SystemType=#centimeters;units.SystemScale=1
 local ground=plane name:"Lifecycle_ground" width:500 length:500
 local source=box name:"Lifecycle_source" width:10 length:5 height:.4 pos:[800,800,0]
 local lab=CyrusPhysicsLab name:"Lifecycle_lab"
 lab.setReceiver ground;lab.addSource source;lab.brushRadius=.001
 for i=1 to 12 do
 (
  lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument;lifeFlush lab;cplPause lab.physicsDocument
  lab.startBrush();cplSample lab.physicsDocument [20,0,0] [0,0,1] true;cplRelease lab.physicsDocument;lifeFlush lab;cplStop lab.physicsDocument
  lifeRequire ((cplUIState lab.physicsDocument)[5]==0 and not (cplUIState lab.physicsDocument)[2]) "Repeated cancel leaked pending state"
 )
 cplStage "global Undo with live session"
 lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument;lifeFlush lab
 undo "Unrelated fixture object" on (box name:"Unrelated_undo" pos:[900,900,0])
 max undo
 lifeRequire ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[8] and (cplUIState lab.physicsDocument)[6]==1) "Unrelated global Undo destroyed live work"
 cplStage "paused clone and merge"
 local duplicate=copy lab
 duplicate.name="Lifecycle_clone"
 lifeRequire ((cplUIState duplicate.physicsDocument)[2] and (cplUIState duplicate.physicsDocument)[6]==1) "Clone lost paused preview"
 duplicate.startBrush();cplPause duplicate.physicsDocument
 lifeFreeze duplicate
 lifeRequire ((cplUIState duplicate.physicsDocument)[5]==1 and (cplUIState lab.physicsDocument)[5]==0) "Clone shared mutable session state"
 saveNodes #(duplicate,ground,source) (CPLTestDir+"clone-merge.max") quiet:true
 delete duplicate
 lifeRequire (mergeMaxFile (CPLTestDir+"clone-merge.max") #select #autoRenameDups #useMergedMtlDups quiet:true) "Merge failed"
 lifeRequire (isValidNode (getNodeByName "Lifecycle_clone")) "Merged clone missing"
 cplStage "source invalidation"
 lab.startBrush();source.width=12
 sleep .05;cplTick lab.physicsDocument 1
 lifeRequire ((cplUIState lab.physicsDocument)[2]) "Source invalidation discarded preview"
 local rejected=false
 try(cplFinish lab.physicsDocument)catch(rejected=true)
 lifeRequire rejected "Changed input accepted Finish"
 lifeFreeze lab
 lifeRequire ((cplUIState lab.physicsDocument)[5]==1) "Changed input could not Freeze captured preview"
 cplClear lab.physicsDocument
 cplStage "frame and units"
 lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument;lifeFlush lab;cplPause lab.physicsDocument
 lab.position=[10,0,0];cplTick lab.physicsDocument 1
 lifeFreeze lab
 lifeRequire ((cplUIState lab.physicsDocument)[5]==1) "Moved owner could not Freeze captured preview"
 cplClear lab.physicsDocument;lab.position=[0,0,0]
 lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument;lifeFlush lab
 units.SystemType=#meters;cplPause lab.physicsDocument
 lifeFreeze lab
 lifeRequire ((cplUIState lab.physicsDocument)[5]==1) "Unit change could not Freeze captured preview"
 cplClear lab.physicsDocument;units.SystemType=#centimeters
 cplStage "owner deletion and reset"
 lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true
 delete lab
 cplResetScene()
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS repeated live start/pause/resume/cancel, unrelated global Undo, clone/merge isolation, source/frame/unit invalidation, owner deletion and reset"
)
