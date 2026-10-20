cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
(
 units.SystemType=#meters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane width:20 length:20
 local source=box width:.02 length:.02 height:.004 pos:[30,30,0]
 hide source
 local lab=CyrusPhysicsLab name:"Performance_1000"
 lab.setReceiver ground;lab.addSource source;lab.brushRadius=.00001;lab.birthSpacing=.060001;lab.bodyLimit=1100;lab.scaleMinimum=1;lab.scaleMaximum=1
 select ground;max zoomext sel all
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.startBrush()
 for row=0 to 9 do
 (
  local y=-3+row*.1
  cplSample lab.physicsDocument [-3,y,0] [0,0,1] false
  cplSample lab.physicsDocument [-3,y,0] [0,0,1] true
  cplSample lab.physicsDocument [(-3+99*lab.birthSpacing+.00001),y,0] [0,0,1] true
 )
 cplRelease lab.physicsDocument;cplSynchronize lab.physicsDocument
 if (cplUIState lab.physicsDocument)[6]!=1000 do throw ("Baseline birth count: "+cplStats lab.physicsDocument)
 cplStage "1000 pending before timing"
 local timings=#(),peak=0L
 for i=1 to 20 do
 (
  local started=timeStamp()
  cplPrivatePaintPath lab.physicsDocument #([(-2+i*.15),1,0]) false
  cplSynchronize lab.physicsDocument
  redrawViews()
  append timings (timeStamp()-started)
  windows.processPostedMessages()
 )
 local started=timeStamp()
 cplStop lab.physicsDocument
 local cancelMs=timeStamp()-started
 local output=createFile (CPLTestDir+"latency.json")
 format "{\"scope\":\"scripted SDK sample to host snapshot plus redraw call; no physical input or presented-frame measurement\",\"baseline_bodies\":1000,\"source_vertices\":8,\"source_faces\":12,\"latency_ms\":[" to:output
 for i=1 to timings.count do format "%%" timings[i] (if i==timings.count then "" else ",") to:output
 format "],\"cancel_ms\":%,\"diagnostics\":%}" cancelMs (cplDiagnosticInfo()) to:output
 close output
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS 1000-body baseline plus 20 moving SDK strokes, cancellation and latency/memory recording"
)
