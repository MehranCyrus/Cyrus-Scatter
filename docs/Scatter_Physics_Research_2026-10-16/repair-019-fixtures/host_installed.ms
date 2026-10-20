fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/host_continuous.ms"
copyFile (CPLTestDir+"assertions.txt") (CPLTestDir+"continuous-assertions.txt")
global CPLInstallChecks=0,CPLUILab
fn iNeed value message=(CPLInstallChecks+=1;if not value do throw message)
for factor in #(1.0,1.5) do
(
 CustomControlsOptions.UIUserScaleFactor=factor
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/host_popup.ms"
 copyFile (CPLTestDir+"popup-layout.json") (CPLTestDir+"popup-"+(factor as string)+".json")
 local lab=CPLUILab,source=lab.sourceNodes[1],replacement=box length:2 width:3 height:4
 local node=refs.dependentNodes lab firstOnly:true
 select node;max modify mode;modPanel.setCurrentObject lab
 lab.objectsUI.open=true;lab.collisionUI.open=true;windows.processPostedMessages();lab.refreshBindings()
 cplSetSourceOptions lab.physicsDocument 1 2 16 1
 lab.objectsUI.sourceList.SelectedIndex=0;lab.objectsUI.removeSourceButton.pressed()
 iNeed (lab.sourceNodes.count==0 and not lab.brushHeader.startButton.enabled) "Installed Remove failed"
 iNeed (lab.collisionUI.qualityInfo.text=="Add a model in Objects") "Empty palette retains stale shape information"
 max undo;iNeed (lab.sourceNodes.count==1 and (cplSourceOptions lab.physicsDocument 1)[2]==2) "Installed Remove Undo lost quality"
 max redo;iNeed (lab.sourceNodes.count==0) "Installed Remove Redo failed"
 lab.objectsUI.sourcePick.picked source
 iNeed (lab.sourceNodes.count==1 and cplSourceIndex lab.physicsDocument 1==1) "Installed Add glyph handler failed"
 lab.objectsUI.replaceSourcePick.picked replacement
 iNeed (lab.sourceNodes[1]==replacement) "Installed Replace handler failed"
 max undo;iNeed (lab.sourceNodes[1]==source) "Installed Replace Undo failed"
)
-- Expected authored-change/invalid-input failures must preserve complete output.
(
 units.SystemType=#centimeters;units.SystemScale=1
 local ground=plane length:2000 width:2000,source=teapot name:"Guard_Teapot_019" radius:5 segments:8 pos:[1000,1000,0]
 local lab=CyrusPhysicsLab name:"Guard_Lab_019"
 lab.setReceiver ground;lab.addSource source;lab.brushRadius=.02;lab.birthSpacing=.15;lab.emissionHeight=.1
 viewport.setLayout #layout_1;viewport.setType #view_top;select ground;max zoomext sel all
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;windows.processPostedMessages();lab.refreshBindings()
 lab.startBrush()
 iNeed (cplPrivatePaintPath lab.physicsDocument #([-40,0,0],[40,0,0]) false==2) "Installed guard stroke missed"
 cplSynchronize lab.physicsDocument;cplPause lab.physicsDocument;cplFreeze lab.physicsDocument
 local until=timeStamp()+10000
 while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 1;windows.processPostedMessages();sleep .01)
 local saved=cplRows lab.physicsDocument
 iNeed ((cplUIState lab.physicsDocument)[5]>0) "Guard test has no completed output"
 cplSetSourceOptions lab.physicsDocument 1 2 16 1;lab.refreshBindings();lab.brushHeader.startButton.pressed()
 iNeed (findString lab.uiError "collision or geometry changed"!=undefined) "Changed-quality action was not explained"
 iNeed (findString lab.uiError "Guard_Teapot_019"!=undefined and findString lab.uiError "-- Runtime error"==undefined) "Status did not name model cleanly"
 iNeed (not (cplUIState lab.physicsDocument)[2] and cplRows lab.physicsDocument==saved) "Changed geometry damaged saved output"
 source.scale=[1,1,0];lab.brushHeader.startButton.pressed()
 iNeed (findString lab.uiError "Guard_Teapot_019"!=undefined) "Invalid preflight did not identify model"
 iNeed (not (cplUIState lab.physicsDocument)[2] and cplRows lab.physicsDocument==saved) "Invalid preflight started a worker or lost output"
 source.scale=[1,1,1];cplClear lab.physicsDocument;lab.uiError="";lab.startBrush()
 iNeed ((cplUIState lab.physicsDocument)[1]) "Clear and corrected geometry did not recover"
 cplStop lab.physicsDocument
)
(dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"installed-assertions.txt") ("PASS "+(CPLInstallChecks as string)+" installed toolbar/empty-state/history checks; popup at 100% and 150%")
