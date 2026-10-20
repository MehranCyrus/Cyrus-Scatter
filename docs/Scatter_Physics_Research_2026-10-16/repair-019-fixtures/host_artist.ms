cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLArtistModels,CPLAchecks=0
fn aNeed value message=(CPLAchecks+=1;if not value do throw message)
fn aPump ms=(local until=timeStamp()+ms;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn aWrite name data=((dotNetClass "System.IO.File").WriteAllText (CPLTestDir+name) data)
(
 units.SystemType=#centimeters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane length:600 width:600 lengthsegs:4 widthsegs:4
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/artist_meshes.py"
 local ball=sphere radius:6 segments:32 name:"Artist_Sphere";hide ball
 append CPLArtistModels ball
 local results=#(),cases=0
 for original in CPLArtistModels do for quality=0 to 2 do for factor in #(.1,1.0,10.0) do
 (
  local source=copy original
  source.scale=[factor,factor,factor]
  -- Exercise transformed geometry, rather than only centred primitives.
  source.rotation=eulerAngles 0 0 17;source.pos=[-500,0,0]
  local lab=CyrusPhysicsLab name:("ArtistRegression_"+(cases as string))
  lab.setReceiver ground;lab.addSource source
  lab.brushRadius=.02;lab.birthSpacing=.2;lab.emissionHeight=.4
  lab.showCollisionShapes=true
  select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;aPump 30;lab.refreshBindings()
  cplSetSourceOptions lab.physicsDocument 1 quality (if quality==1 then 8 else 16) 1
  lab.startBrush()
  aNeed ((cplUIState lab.physicsDocument)[1]) ("Artist single source failed "+lab.uiError)
  aNeed (cplPrivatePaintPath lab.physicsDocument #([-80,0,0],[-20,0,0]) false==2) "Artist path failed"
  cplSynchronize lab.physicsDocument
  local count=(cplUIState lab.physicsDocument)[6]
  aNeed (count>1) "Artist brush stalled at one body"
  aNeed (cplPrivatePaintPath lab.physicsDocument #([20,0,0],[80,0,0]) false==2) "Artist continuous stroke failed"
  cplSynchronize lab.physicsDocument
  aNeed ((cplUIState lab.physicsDocument)[6]>count) "Artist continuous emission failed"
  count=(cplUIState lab.physicsDocument)[6]
  aNeed (cplPrivatePaintPath lab.physicsDocument #([800,800,0],[900,900,0]) false==0) "Outside stroke hit"
  cplSynchronize lab.physicsDocument;aNeed ((cplUIState lab.physicsDocument)[6]==count) "Outside stroke emitted"
  cplPause lab.physicsDocument
  local pending=cplPendingRows lab.physicsDocument
  cplUndoStroke lab.physicsDocument;cplRedoStroke lab.physicsDocument
  aNeed (cplPendingRows lab.physicsDocument==pending) "Artist full-state Undo/Redo changed poses"
  lab.startBrush();cplPause lab.physicsDocument
  cplFreeze lab.physicsDocument
  local until=timeStamp()+10000
  while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 1;aPump 10)
  aNeed (not (cplUIState lab.physicsDocument)[2]) "Artist Freeze left pending state"
  aNeed ((cplUIState lab.physicsDocument)[7]=="") ("Artist worker error "+cplStats lab.physicsDocument)
  local display=cplCollisionDisplayInfo lab.physicsDocument
  aNeed (findString display "\"error\":\"\""!=undefined) ("Artist display failed "+display)
  cplClear lab.physicsDocument
  lab.startBrush();cplPause lab.physicsDocument;cplStop lab.physicsDocument
  aNeed (not (cplUIState lab.physicsDocument)[2]) "Clear/restart left pending state"
  aWrite ("artist-case-"+(cases as string)+".json") (cplStats lab.physicsDocument)
  hide lab
  cases+=1
 )
 aWrite "assertions.txt" ("PASS "+(CPLAchecks as string)+" assertions across "+(cases as string)+" captured-source/scale/quality cases")
 aWrite "diagnostics-status.json" (cplDiagnosticInfo())
)
