(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-surface0866-*/" do throw "Owned surface brush profile required"
 global BRoot,BLayer,BNode,BSphere,BBox,BCylinder,BArea,BDoc,BView,BHash,BUndoHash,BBytes,BBoxDoc,BCylinderDoc,BIdle,BOriginalInteractionHeld,BFixtureHeld
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"surface-phase.txt")
 local log=createFile (MCPFixtureDir+"surface-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn payload doc=((cyrusBrushRecipeExport doc)[1])
 fn refresh=(BRoot.refreshAll();BRoot.evaluateProcedural())
 fn resultHash=(cyrusRecipePublicationFingerprint BRoot.groupSnapshotRows)
 fn rows=(local block=BRoot.groupSnapshotRows[1],output=#();for offset=0 to block.count-1 by 500 do join output (cyrusPlacementPage block (cyrusPlacementToken block) offset (amin 500 (block.count-offset)));output)
 try (
  case phase of (
   "setup":(
    global BRoot,BLayer,BNode,BSphere,BBox,BCylinder,BArea,BDoc,BView,BHash,BUndoHash,BBytes,BBoxDoc,BCylinderDoc,BIdle,BOriginalInteractionHeld
    global BFixtureHeld=false
    local initialProcess=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess();format "MEASURE: initial process private bytes %\n" initialProcess.PrivateMemorySize64 to:log
    BOriginalInteractionHeld=CyrusInteractionHeld
    fn CyrusInteractionHeld=BFixtureHeld
    CyrusStopBrush();CyrusClearMeshMaskPreview undefined;CyrusPointSuspended=true;CyrusPerfHeadless=false
    with undo off (
     resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.
     viewport.setLayout #layout_1;viewport.setType #view_top
     BSphere=sphere name:"Brush_surface_sphere" radius:100 segs:32
     BBox=box name:"Brush_surface_box" width:200 length:200 height:200 pos:[300,0,0]
     BCylinder=cylinder name:"Brush_surface_cylinder" radius:100 height:200 sides:32 heightsegs:3 pos:[-300,0,0]
     local model=box name:"Brush_surface_model" width:2 length:2 height:5 pos:[1000,0,0];hide model
     BNode=AminScatterObject name:"Brush_surface_setup";BRoot=BNode.baseObject;BRoot.updateMode=1;BRoot.autoRender=false
     BRoot.newLayer();BLayer=BRoot.selectedLayer();BLayer.sources=#(model);BLayer.sourceWeights=#(1.);BLayer.sourceRadiiWU=#(0.);BLayer.amount=10000
     BLayer.procSelfOverride=true;BLayer.procSelfEnabled=false;BLayer.procLayerSelfEnabled=false
     BRoot.setLayerSurfaces BLayer #(BSphere)
     BArea=BRoot.addPaintArea BLayer target:BSphere;BDoc=BArea.paintDocument
    )
    refresh();check (BRoot.uiVersion()=="0.86.6" and cyrusBrushSurfaceVersion()==1) "Matched surface brush script/native capability loaded" log
    check (BRoot.groupSnapshotRows[1].count==0 and BLayer.previewError=="") "Empty sphere Paint Area binds and evaluates without projection error" log
    select BSphere;max zoomext sel all;select BNode;max modify mode;BRoot.bindNativeUI()
   )
   "button":(
    if not BRoot.mainUI.controlsReady do BRoot.mainUI.mountTimer.tick()
    BView=BRoot.coverageUI;BRoot.mainUI.slots[7].open=true;BRoot.mainUI.bindSection BView
    check (BView.brushUI_obj==BArea and BView.brushUI_beginButton.enabled) "Actual Painting page binds the sphere area" log
    BView.brushUI_radiusSpin.value=25;BView.brushUI_radiusSpin.changed 25
    BView.brushUI_beginButton.pressed();CyrusBrushTick undefined undefined
    check ((cyrusBrushStats BDoc)[5]==1 and CyrusBrushSessionLayer==BArea) "Actual Start Brush handler and first timer tick accept sphere" log
   )
   "manual":(
    check ((cyrusBrushStats BDoc)[5]==1) "Sphere session survives posted timer callbacks" log
    local before=BRoot.procEpoch,cache=BLayer.receiverCacheStats(),watch=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
    local path=for i=0 to 12 collect (local x=-45+i*7.5;[x,0,sqrt(10000-x*x)])
    local hits=cyrusPrivatePaintPath BDoc path false;watch.Stop()
    format "MEASURE: 13 actual Painter samples % ms\n" watch.Elapsed.TotalMilliseconds to:log
    check (hits==path.count and (cyrusBrushStats BDoc)[2]>0 and (cyrusBrushStats BDoc)[6]==0) "Actual Painter TestHit/PaintStroke/EndStroke commits a sphere stroke" log
    check (BRoot.procEpoch==before and BRoot.groupSnapshotRows[1].count==0) "Manual gesture keeps previous planting until Update" log
    refresh();check (BRoot.groupSnapshotRows[1].count>100 and BLayer.previewError=="") "Explicit Update produces sphere placements" log
    local valid=true;for row in rows() where row[1].row4.z<0 do valid=false
    check valid "Sphere stroke does not scatter through to opposite hemisphere" log
    check ((BLayer.receiverCacheStats())[1]==cache[1]) "Painting reuses prepared receiver candidates" log
    BView.brushUI_stopButton.pressed();BHash=resultHash();BBytes=payload BDoc
   )
   "erase":(
    BView.brushUI_modeRadio.state=2;BView.brushUI_modeRadio.changed 2
    BView.brushUI_radiusSpin.value=10;BView.brushUI_radiusSpin.changed 10
    BView.brushUI_beginButton.pressed();CyrusBrushTick undefined undefined
    local hits=cyrusPrivatePaintPath BDoc #([0,0,100]) false;refresh()
    BUndoHash=resultHash();check (hits==1 and BUndoHash!=BHash) "Erase callback cuts a sphere hole" log
    BView.brushUI_stopButton.pressed()
   )
   "undo":(max undo)
   "verifyUndo":(refresh();check (resultHash()==BHash and payload BDoc==BBytes) "Undo restores exact sphere coverage and placements" log)
   "redo":(max redo)
   "verifyRedo":(refresh();check (resultHash()==BUndoHash) "Redo restores erased coverage and placements" log)
   "spline":(
    local original=payload BDoc,snapshot=cyrusBrushExportSpline BDoc "Surface spline snapshot"
    check (isValidNode snapshot and numSplines snapshot>=2) "Sphere outer border and erase hole export as closed 3D splines" log
    cyrusBrushFill BDoc 0;refresh();check (BRoot.groupSnapshotRows[1].count==0) "Clear removes surface coverage" log
    check (cyrusBrushImportSpline BDoc snapshot false 0.1) "Surface spline snapshot imports after Clear" log
    refresh();check (payload BDoc==original and resultHash()==BUndoHash) "Unchanged curved spline snapshot restores exact coverage and placement" log
    local cfg=cyrusBrushFalloff BDoc;cfg[1]=5;cfg[2]=10;cfg[3]=true;cfg[4]=true;cfg[5]=0.2;cfg[6]=1.;cfg[7]=#(0,0.25,1);cfg[8]=#(0,0.6,1)
    cyrusBrushSetFalloff BDoc cfg;refresh()
    check (BLayer.previewError=="" and resultHash()!=BUndoHash) "Density and scale feather curves evaluate on curved surface" log
    cfg[1]=0;cfg[2]=0;cfg[4]=false;cyrusBrushSetFalloff BDoc cfg;refresh()
   )
   "fill":(
    cyrusBrushFill BDoc 1;refresh();check (BRoot.groupSnapshotRows[1].count==10000) "Fill covers every sphere face including back side" log
    cyrusBrushFill BDoc 0;refresh();check (BRoot.groupSnapshotRows[1].count==0) "Clear removes all full-face markers" log
    cyrusBrushSettings BDoc 30 false;cyrusBrushDab BDoc [0,0,300] [0,0,-1] true;refresh()
    check (BRoot.groupSnapshotRows[1].count>0) "Fresh painting works after Fill/Clear" log
   )
   "copy":(
    local original=payload BDoc,duplicate=copy BDoc;cyrusBrushBind duplicate
    check (payload duplicate==original) "Native document copy retains exact surface coverage" log
    cyrusBrushFill duplicate 0;check (payload BDoc==original and (cyrusBrushStats duplicate)[2]==0) "Clearing copy leaves original surface coverage independent" log
    local config=cyrusBrushRecipeExport BDoc,transferred=cyrusBrushPresetTransfer config[1] BSphere config[2] config[3] 1. 100. #(0.,0.,0.,0.)
    cyrusBrushBind transferred
    check ((cyrusBrushStats transferred)[2]==(cyrusBrushStats BDoc)[2] and abs((cyrusBrushOptions transferred)[1]-100*config[2])<0.01) "Curved preset transfer preserves indexed coverage and converts physical radius" log
    check (payload BDoc==original) "Curved preset transfer keeps source payload immutable" log
   )
   "surfaces":(
    BRoot.setLayerSurfaces BLayer #(BSphere,BBox,BCylinder)
    local area=BRoot.addPaintArea BLayer target:BBox;BBoxDoc=area.paintDocument;cyrusBrushSettings BBoxDoc 40 false
    check (cyrusBrushDab BBoxDoc [90,0,400] [0,0,-1] true) "Box top stroke is accepted" log
    check (cyrusBrushDab BBoxDoc [400,0,190] [-1,0,0] true) "Box vertical side stroke is accepted" log
    area=BRoot.addPaintArea BLayer target:BCylinder;BCylinderDoc=area.paintDocument;cyrusBrushSettings BCylinderDoc 35 false
    check (cyrusBrushDab BCylinderDoc [400,0,100] [-1,0,0] true) "Curved cylinder side stroke is accepted" log
    refresh();check (BLayer.previewError=="" and BRoot.groupSnapshotRows[1].count>0) "Multiple sphere/box/cylinder Paint Areas publish together" log
    local original=payload BBoxDoc;cyrusBrushSettings BBoxDoc 10 true;cyrusBrushDab BBoxDoc [400,0,190] [-1,0,0] false;cyrusBrushCancel BBoxDoc
    check (payload BBoxDoc==original) "Cancel retains exact committed box coverage" log
   )
   "transform":(
    BBox.scale=[2,1,3];BRoot.markInputDirty();refresh()
    cyrusBrushSettings BBoxDoc 25 false;cyrusBrushDab BBoxDoc [400,50,100] [-1,0,0] true;refresh()
    check (BLayer.previewError=="") "Paint and evaluation follow full nonuniform XYZ receiver metric" log
    BBox.scale=[-2,1,3];BBox.rotation=angleAxis 23 [0,0,1];BRoot.markInputDirty();refresh()
    check (BLayer.previewError=="") "Mirrored and rotated surface retains coverage" log
   )
   "geometry":(
    BHash=resultHash();BBytes=payload BDoc
    BSphere.segs=36;local rejected=false;try(BRoot.evaluateProcedural())catch(rejected=true)
    check (rejected and resultHash()==BHash and payload BDoc==BBytes) "Topology failure retains complete prior planting and authored paint" log
    BSphere.segs=32;refresh();check (BLayer.previewError=="" and resultHash()==BHash) "Restoring original topology recovers exact planting" log
   )
   "save":(
    BHash=resultHash();BBytes=payload BDoc
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"saved-surface-hash.txt") BHash
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"saved-surface-paint.txt") BBytes
    saveMaxFile (MCPFixtureDir+"surface-brush.max") quiet:true
   )
   "reopen":(CyrusStopBrush();loadMaxFile (MCPFixtureDir+"surface-brush.max") quiet:true useFileUnits:true)
   "verifyReopen":(
    BNode=$Brush_surface_setup;BRoot=BNode.baseObject;BLayer=BRoot.layerObjects[1];BSphere=$Brush_surface_sphere;BBox=$Brush_surface_box;BCylinder=$Brush_surface_cylinder
    BArea=(for area in BLayer.paintAreas where area.areaTarget==BSphere collect area)[1];BDoc=BArea.paintDocument
    refresh();check (resultHash()==(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"saved-surface-hash.txt")) "Scene reopen restores exact complete placements" log
    check (payload BDoc==(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"saved-surface-paint.txt")) "Scene reopen restores exact native surface coverage bytes" log
   )
   "live":(
    BHash=resultHash();BRoot.updateMode=2;CyrusPointSuspended=false
    cyrusBrushSettings BDoc 20 false;cyrusBrushDab BDoc [0,300,0] [0,-1,0] true;BArea.publishPaint()
   )
   "verifyLive":(check (BLayer.previewError=="" and resultHash()!=BHash) "Relevant Live surface stroke updates planting automatically" log)
   "idle":(BHash=resultHash();BIdle=#(BRoot.procEpoch,(cyrusBrushStats BDoc)[8],(cyrusBrushStats BDoc)[9]);redrawViews())
   "verifyIdle":(
    check (resultHash()==BHash and CyrusPresetSameValues BIdle #(BRoot.procEpoch,(cyrusBrushStats BDoc)[8],(cyrusBrushStats BDoc)[9])) "Idle/redraw reuses placements, surface snapshot and coverage field" log
    CyrusInteractionHeld=BOriginalInteractionHeld
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess();format "MEASURE: private bytes %; peak working set %\n" process.PrivateMemorySize64 process.PeakWorkingSet64 to:log
    select #(BSphere,BBox,BCylinder);viewport.setType #view_persp_user;max zoomext sel all;clearSelection();redrawViews()
    local image=gw.getViewportDib();image.filename=MCPFixtureDir+"surface-viewport.png";save image;close image
   )
   default:throw ("Unknown surface phase: "+phase)
  )
  check true "complete" log;close log
 )catch(format "FAIL: %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log;close log;CyrusStopBrush();throw())
)
