cplResetScene()
fn gripLifeRequire value message = if not value do throw message
fn gripLifeFreeze lab = (cplFreeze lab.physicsDocument;for i=1 to 200 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;sleep .01);gripLifeRequire (not (cplUIState lab.physicsDocument)[2]) (cplStats lab.physicsDocument))
(
 units.SystemType=#centimeters;units.SystemScale=1
 local ground=plane name:"Grip_cm_slope" width:600 length:600 widthsegs:16 lengthsegs:16
 rotate ground (angleaxis 30 [0,1,0]);rotate ground (angleaxis 27 [0,0,1]);ground.pos=[120,-80,40]
 local model=box name:"Grip_cm_model" width:7 length:5 height:1 pos:[900,900,0]
 local lab=CyrusPhysicsLab name:"Grip_cm_lab"
 lab.setReceiver ground;lab.addSource model;lab.stickiness=65;lab.brushRadius=.001;lab.emissionHeight=.2
 local normal=normalize ground.transform.row3,centre=ground.pos
 lab.startBrush();cplSample lab.physicsDocument centre normal true;cplRelease lab.physicsDocument;cplSynchronize lab.physicsDocument;cplPause lab.physicsDocument
 local blocked=false;try(cplSetGrip lab.physicsDocument .9)catch(blocked=true)
 gripLifeRequire blocked "Native grip mutation accepted during pending work"
 local clone=copy lab;clone.name="Grip_cm_clone"
 gripLifeRequire (clone.stickiness==65 and (cplUIState clone.physicsDocument)[6]==1) "Clone lost grip or pending preview"
 clone.startBrush();cplPause clone.physicsDocument;gripLifeFreeze clone
 gripLifeRequire ((cplUIState lab.physicsDocument)[5]==0) "Clone shared mutable publication"
 cplFinish lab.physicsDocument
 for i=1 to 1800 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;sleep .01)
 gripLifeRequire ((cplUIState lab.physicsDocument)[5]==1 and not (cplUIState lab.physicsDocument)[2]) ("Slope Finish failed: "+cplStats lab.physicsDocument)
 cplExportFile lab.physicsDocument (CPLTestDir+"grip-cm-result.json")
 local saved=cplRows lab.physicsDocument
 local imported=CyrusPhysicsLab name:"Grip_imported"
 cplImportFile (imported.ensureDocument()) (CPLTestDir+"grip-cm-result.json")
 gripLifeRequire (cplRows imported.physicsDocument==saved) "Result JSON changed grip poses"
 saveNodes #(lab,ground,model) (CPLTestDir+"grip-merge.max") quiet:true
 delete lab
 gripLifeRequire (mergeMaxFile (CPLTestDir+"grip-merge.max") #select #autoRenameDups #useMergedMtlDups quiet:true) "Grip merge failed"
 lab=getNodeByName "Grip_cm_lab"
 gripLifeRequire (isValidNode lab and lab.stickiness==65 and cplRows lab.physicsDocument==saved) "Merge changed grip or cached result"
 lab.bodyLimit=100;lab.areaCount=12;lab.settleArea()
 for i=1 to 5000 while (cplUIState lab.physicsDocument)[2] do cplTick lab.physicsDocument 8
 gripLifeRequire ((cplUIState lab.physicsDocument)[5]==12 and not (cplUIState lab.physicsDocument)[2]) ("Grip Area failed: "+cplStats lab.physicsDocument)
 local area=cplRows lab.physicsDocument
 cplRebuild lab.physicsDocument lab
 for i=1 to 5000 while (cplUIState lab.physicsDocument)[2] do cplTick lab.physicsDocument 8
 gripLifeRequire ((cplUIState lab.physicsDocument)[5]==12) "Grip Rebuild lost count"
 max undo
 gripLifeRequire (cplRows lab.physicsDocument==area) "Grip Rebuild Undo changed result"
 cplClear lab.physicsDocument
 lab.startBrush();cplSample lab.physicsDocument centre normal true;cplRelease lab.physicsDocument;cplSynchronize lab.physicsDocument
 -- Merge creates independent bound nodes; mutate the merged source, not the old one.
 model=lab.sourceNodes[1];model.width=8;cplTick lab.physicsDocument 1
 local rejected=false;try(cplFinish lab.physicsDocument)catch(rejected=true)
 gripLifeRequire rejected "Source change accepted Finish with old grip capture"
 gripLifeFreeze lab
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS grip setting lock, centimetre rotated/translated slope, clone, Finish, JSON, merge, Area/Rebuild Undo and source invalidation Freeze"
)
