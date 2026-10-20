-- Actual rollout buttons/timers plus public SDK Painter callbacks; no OS input.
setSilentMode true
setQuietMode true
resetMaxFile #noPrompt
cplStage "scene reset"
setSilentMode false
setQuietMode false
global CPLUIChecks=0
fn uiRequire value message = (CPLUIChecks+=1;if not value do throw message)
fn uiPump duration = (local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep 0.01))
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
(
 units.SystemType=#meters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane name:"Brush_receiver" width:5 length:5 widthsegs:4 lengthsegs:4
 local source=pyramid name:"Brush_source" width:.1 depth:.1 height:.15 pos:[8,8,0]
 hide source
 local lab=CyrusPhysicsLab name:"PhysicsLab_ButtonTest"
 lab.showViewportIcon=false;lab.applyViewportIcon()
 lab.brushRadius=.025;lab.birthSpacing=.08
 select ground;max zoomext sel all
 cplStage "before Modify panel"
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true;lab.brushUI.open=true
 cplStage "after Modify panel"
 uiPump 300
 uiRequire lab.brushHeader.isDisplayed "Brush header must be open for the real-button test."
 uiRequire lab.brushHeader.controlsReady ("Main panel did not bind: "+lab.brushHeader.statusLabel.text)
 uiRequire (not lab.brushHeader.startButton.enabled) "Start enabled without input objects."
 lab.objectsUI.receiverPick.picked ground
 uiRequire (not lab.brushHeader.startButton.enabled) "Start enabled without models."
 lab.objectsUI.sourcePick.picked source
 uiPump 200
 uiRequire (lab.receiverNode==ground and lab.sourceNodes.count==1 and lab.brushHeader.startButton.enabled) ("Pick handlers did not bind objects: "+lab.brushHeader.statusLabel.text)
 cplStage "before actual Start button"
 lab.brushHeader.startButton.pressed()
 cplStage "after actual Start button"
 uiPump 1200
 uiRequire (findString (cplStats lab.physicsDocument) "\"painting\":true"!=undefined) ("Button/timer stopped painting: "+cplStats lab.physicsDocument)
 cplStage "before SDK TestHit path"
 local hits=cplPrivatePaintPath lab.physicsDocument #([-.4,0,0],[0,0,0],[.4,0,0]) false
 uiRequire (hits==3) "Painter did not hit the receiver at all three points."
 cplStage "after SDK path"
 uiPump 3000
 local done=false
 for i=1 to 1000 while not done do (done=cplTick lab.physicsDocument 8;windows.processPostedMessages())
 uiRequire done "Stroke did not finish."
 local count=(cplUIState lab.physicsDocument)[5]
 uiRequire (count>=10 and count<=11) "Viewport-quantized path emission count outside expected range."
 uiRequire (findString (cplStats lab.physicsDocument) "\"settled\":true"!=undefined) "Result was accepted unfinished."
 local geometry=snapshotAsMesh lab
 for i=1 to geometry.numverts do uiRequire ((getVert geometry i).z>-.001) "Pyramid penetrated/fell below the receiver."
 local saved=cplRows lab.physicsDocument
 uiRequire (cplPrivatePaintPath lab.physicsDocument #([1,0,0]) true==1) "Cancel path did not hit the receiver."
 uiPump 200
 uiRequire (cplRows lab.physicsDocument==saved) "Cancel changed the saved result."
 uiRequire (cplPrivatePaintPath lab.physicsDocument #([1,0,0],[1.2,0,0]) false==2) "Append path missed receiver."
 done=false
 for i=1 to 1000 while not done do (done=cplTick lab.physicsDocument 8;windows.processPostedMessages())
 uiRequire done "Append did not finish."
 uiRequire (findString (cplRows lab.physicsDocument) (substring saved 1 (saved.count-1))==1) "Append moved saved bodies."
 max undo
 uiRequire (cplRows lab.physicsDocument==saved) "Append Undo did not restore exact saved transforms."
 uiRequire (findString (cplStats lab.physicsDocument) "\"painting\":true"!=undefined) "Settling or redraw ended brush mode."
 lab.brushHeader.stopButton.pressed()
 uiRequire (findString (cplStats lab.physicsDocument) "\"painting\":false"!=undefined) "Stop button did not end brush mode."
 local report=createFile (CPLTestDir+"assertions.txt")
 format "PASS % actual-button/timer/SDK-hit checks\n%\n" CPLUIChecks (cplStats lab.physicsDocument) to:report
 close report
)
