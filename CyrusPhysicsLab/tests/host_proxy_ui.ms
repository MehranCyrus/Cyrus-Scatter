-- Real Sphere32, full render mesh, custom/automatic UI and SDK Painter callbacks.
cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLProxyChecks=0
fn proxyRequire value message = (CPLProxyChecks+=1;if not value do throw message)
fn proxyPump milliseconds = (local end=timeStamp()+milliseconds;while timeStamp()<end do (windows.processPostedMessages();sleep .01))
fn proxyFinish lab = (local done=false;for i=1 to 1000 while not done do (done=cplTick lab.physicsDocument 8;windows.processPostedMessages());proxyRequire done ("Sphere brush did not finish: "+cplStats lab.physicsDocument);proxyRequire (findString (cplStats lab.physicsDocument) "\"settled\":true"!=undefined) "Unfinished sphere result";lab.syncUI())
(
 units.SystemType=#millimeters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane name:"Proxy_receiver" width:5000 length:5000 widthsegs:4 lengthsegs:4
 local source=sphere name:"Sphere32_source" radius:32.788 segments:32 pos:[8000,8000,1000]
 local low=sphere name:"Sphere8_custom" radius:32.788 segments:8 pos:[8000,8000,1000]
 local extra=box name:"Extra_scene_collider" width:100 length:400 height:100 pos:[1500,0,0]
 hide source;hide low
 local original=snapshotAsMesh source
 proxyRequire (original.numverts>128) "Fixture does not exercise detailed source geometry"
 local lab=CyrusPhysicsLab name:"PhysicsLab_Sphere32"
 lab.showViewportIcon=false;lab.applyViewportIcon()
 lab.brushRadius=.01;lab.birthSpacing=.2;lab.emissionHeight=.1
 select ground;max zoomext sel all
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true;lab.brushUI.open=true;lab.collisionUI.open=true
 proxyPump 250
 lab.objectsUI.receiverPick.picked ground;lab.objectsUI.sourcePick.picked source;lab.objectsUI.colliderPick.picked extra
 proxyPump 200
 proxyRequire lab.brushHeader.startButton.enabled "Normal sphere/plane did not enable Start"
 proxyRequire (not cplCustomProxy lab.physicsDocument 1) "Default sphere unexpectedly requires a custom proxy"
 proxyRequire (findString (toLower lab.collisionUI.proxyLabel.text) "automatic"!=undefined) "Automatic mode not shown"
 cplStage "Sphere32 Start"
 local started=timeStamp()
 lab.brushHeader.startButton.pressed()
 local startMs=timeStamp()-started
 proxyPump 200
 proxyRequire ((cplUIState lab.physicsDocument)[1]) ("Sphere32 Start failed: "+lab.uiError)
 proxyRequire (cplPrivatePaintPath lab.physicsDocument #([0,0,0],[400,0,0],[800,0,0]) false==3) "Sphere brush missed the receiver"
 proxyFinish lab
 local count=(cplUIState lab.physicsDocument)[5] as integer
 proxyRequire (count>=4 and count<=5) "Unexpected viewport-quantized sphere birth count"
 local output=snapshotAsMesh lab
 proxyRequire (output.numverts==count*original.numverts and output.numfaces==count*original.numfaces) "Detailed sphere render geometry was reduced"
 for i=1 to output.numverts do proxyRequire ((getVert output i).z>-.5) "Sphere fell through the Plane"
 local saved=cplRows lab.physicsDocument
 cplExportFile lab.physicsDocument (CPLTestDir+"sphere-auto.json")
 proxyRequire (cplPrivatePaintPath lab.physicsDocument #([-800,0,0],[-400,0,0]) false==2) "Sphere append missed receiver"
 proxyFinish lab
 proxyRequire (findString (cplRows lab.physicsDocument) (substring saved 1 (saved.count-1))==1) "Append moved existing spheres"
 max undo
 proxyRequire (cplRows lab.physicsDocument==saved) "Sphere append Undo changed existing poses"
 lab.brushHeader.stopButton.pressed()
 lab.collisionUI.proxyPick.picked source
 proxyRequire (findString lab.uiError "128"!=undefined) "Oversized explicit proxy was not rejected when picked"
 proxyRequire (not cplCustomProxy lab.physicsDocument 1 and cplRows lab.physicsDocument==saved) "Failed custom binding changed the model or result"
 lab.collisionUI.proxyPick.picked low
 proxyRequire (cplCustomProxy lab.physicsDocument 1 and lab.collisionUI.autoProxyButton.enabled) "Small custom proxy did not bind"
 proxyRequire (findString lab.collisionUI.proxyLabel.tooltip "Sphere8_custom"!=undefined) "Custom proxy identity not shown"
 lab.brushHeader.startButton.pressed()
 proxyRequire (findString lab.uiError "Rebuild"!=undefined) "Changing a collision shape should require explicit Rebuild for saved results"
 proxyRequire (cplRows lab.physicsDocument==saved) "Proxy change replayed saved poses"
 lab.collisionUI.autoProxyButton.pressed()
 proxyRequire (not cplCustomProxy lab.physicsDocument 1) "Use auto did not remove the override"
 proxyRequire (findString (toLower lab.collisionUI.proxyLabel.text) "automatic"!=undefined) "Use auto did not refresh mode"
 lab.brushHeader.startButton.pressed()
 proxyRequire ((cplUIState lab.physicsDocument)[1]) ("Restoring automatic mode did not restore authoring: "+lab.uiError)
 lab.brushHeader.stopButton.pressed()
 proxyRequire (cplRows lab.physicsDocument==saved) "Use auto changed the retained result"
 local custom=CyrusPhysicsLab name:"PhysicsLab_Sphere32_Custom"
 custom.showViewportIcon=false;custom.applyViewportIcon()
 custom.setReceiver ground;custom.addSource source proxy:low;custom.brushRadius=.01;custom.emissionHeight=.1
 select custom;modPanel.setCurrentObject custom.baseObject
 custom.brushHeader.open=true;custom.collisionUI.open=true;custom.refreshBindings()
 custom.brushHeader.startButton.pressed()
 proxyRequire (cplPrivatePaintPath custom.physicsDocument #([0,800,0]) false==1) "Custom proxy brush missed receiver"
 proxyFinish custom
 proxyRequire ((snapshotAsMesh custom).numverts==original.numverts) "Custom collision mesh replaced detailed render geometry"
 custom.brushHeader.stopButton.pressed()
 local customRows=cplRows custom.physicsDocument
 cplExportFile custom.physicsDocument (CPLTestDir+"sphere-custom.json")
 saveMaxFile (CPLTestDir+"Sphere32_Auto_Custom.max") quiet:true
 loadMaxFile (CPLTestDir+"Sphere32_Auto_Custom.max") quiet:true
 lab=getNodeByName "PhysicsLab_Sphere32";custom=getNodeByName "PhysicsLab_Sphere32_Custom"
 proxyRequire (cplRows lab.physicsDocument==saved and cplRows custom.physicsDocument==customRows) "Scene reopen changed sphere results"
 proxyRequire (not cplCustomProxy lab.physicsDocument 1 and cplCustomProxy custom.physicsDocument 1) "Scene reopen changed proxy ownership"
 proxyRequire ((snapshotAsMesh lab).numverts==count*original.numverts) "Reopened detailed sphere mesh changed"
 local report=createFile (CPLTestDir+"assertions.txt")
 format "PASS % Sphere32/plane/button/Painter/proxy/Undo/roundtrip checks; source % vertices / % faces\n" CPLProxyChecks original.numverts original.numfaces to:report
 format "Sphere32 Start handler % ms (whole handler, not solver-only or presented FPS)\n" startMs to:report
 close report
)
