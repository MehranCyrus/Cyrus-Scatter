(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
global BRoot,BLayer,BNode,BPlane,BSecond,BArea,BD,BView,BChecks=#(),BAssert,BPump
-- Hidden hosts can inherit the desktop's held-button state. Drive the existing
-- interaction provider explicitly and test both states; never send OS input.
local originalInteractionHeld=CyrusInteractionHeld
global BFixtureHeld=false
fn CyrusInteractionHeld = BFixtureHeld
try (
fn BAssert value message = (
 if not value do throw ("Button workflow: "+message)
 append BChecks message
 local log=createFile (MCPFixtureDir+"button-checks.txt")
 for line in BChecks do format "%\n" line to:log
 close log;true
)
fn BPump duration = (local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep 0.01))
CyrusStopBrush();resetMaxFile #noPrompt
viewport.setLayout #layout_1;viewport.setType #view_top
BPlane=plane name:"Button_receiver" width:200 length:200 widthsegs:4 lengthsegs:4
BSecond=plane name:"Button_second" width:200 length:200 widthsegs:4 lengthsegs:4 pos:[300,0,0]
local model=box name:"Button_model" width:1 length:1 height:3 pos:[1000,0,0];hide model
BNode=AminScatterObject name:"Button_scatter";BRoot=BNode.baseObject
BRoot.setLayerTransfer true;BRoot.updateMode=1;BRoot.autoRender=false;BRoot.newLayer()
BLayer=BRoot.selectedLayer();BLayer.sources=#(model);BLayer.sourceWeights=#(1.0);BLayer.amount=5000
BRoot.setLayerTransfer false;BRoot.setLayerSurfaces BLayer #(BPlane,BSecond)
BArea=BRoot.addPaintArea BLayer target:BPlane;BD=BArea.paintDocument;BRoot.refreshAll()
select BPlane;max zoomext sel all
select BNode;max modify mode;modPanel.setCurrentObject BRoot
if not BRoot.mainUI.controlsReady do BRoot.mainUI.mountTimer.tick()
BView=BRoot.coverageUI;BView.open=true;BRoot.mainUI.bindSection BView
BAssert (BRoot.uiVersion()=="0.78.3") "Patched script version loaded"
BAssert (BView.controlsReady and BView.brushUI_controlsReady and BView.brushUI_obj==BArea and BView.brushUI_beginButton.enabled) "Main Start Brush bound to selected area"
BView.refreshBrushStatus();BAssert true "Status delegate resolves its rollout function"
BView.brushUI_radiusSpin.value=12;BView.brushUI_radiusSpin.changed 12
BView.brushUI_beginButton.pressed()
BAssert ((cyrusBrushStats BD)[5]==1 and CyrusBrushSessionLayer==BArea) "Main button starts native and scripted sessions"
BPump 1200
BAssert ((cyrusBrushStats BD)[5]==1 and CyrusBrushSessionLayer==BArea and CyrusBrushSessionRevision==(cyrusBrushStats BD)[1]) "Session survives real timer callbacks after Start"
BAssert (BView.brushUI_brushState.text=="Brush active") "Main status reports active brush"
local beforeEpoch=BRoot.procEpoch,beforeBuilds=BLayer.receiverCacheStats(),path=for i=0 to 30 collect [-60+i*4,35*sin(i*12),0]
local hits=cyrusPrivatePaintPath BD path false
BAssert (hits==path.count and (cyrusBrushStats BD)[7]==path.count) "Actual Painter TestHit and PaintStroke callbacks accept the entire path"
BPump 300
BAssert ((cyrusBrushStats BD)[2]>0 and (cyrusBrushStats BD)[6]==0 and (cyrusBrushStats BD)[5]==1) "Callback EndStroke commits contours and keeps brush active"
BAssert (BRoot.procEpoch==beforeEpoch and BRoot.groupSnapshotRows[1].count==0) "Manual drawing preserves the completed population until Update"
BRoot.refreshAll();BAssert (BRoot.groupSnapshotRows[1].count>0 and BLayer.previewError=="") "Explicit Update publishes painted plants"
BAssert ((BLayer.receiverCacheStats())[1]==beforeBuilds[1]) "Painting reuses receiver candidate caches"
local painted=cyrusEditFingerprint BRoot.groupSnapshotRows[1] "button"
BView.brushUI_modeRadio.state=2;BView.brushUI_modeRadio.changed 2
BAssert ((cyrusBrushOptions BD)[2]) "Erase radio updates native settings"
hits=cyrusPrivatePaintPath BD #([0,0,0],[0,20,0]) false;BPump 200;BRoot.refreshAll()
local erased=cyrusEditFingerprint BRoot.groupSnapshotRows[1] "button"
BAssert (hits==2 and erased!=painted) "Erase callbacks cut the committed vector region"
max undo;BRoot.refreshAll();BAssert ((cyrusEditFingerprint BRoot.groupSnapshotRows[1] "button")==painted) "Callback Undo restores exact placements"
max redo;BRoot.refreshAll();BAssert ((cyrusEditFingerprint BRoot.groupSnapshotRows[1] "button")==erased) "Callback Redo restores erase"
hits=cyrusPrivatePaintPath BD #([-45,0,0],[45,0,0]) true;BPump 200;BRoot.refreshAll()
BAssert ((cyrusEditFingerprint BRoot.groupSnapshotRows[1] "button")==erased) "Callback cancellation preserves committed region"
BView.brushUI_stopButton.pressed();BPump 100
BAssert ((cyrusBrushStats BD)[5]==0 and CyrusBrushSessionLayer==undefined and not CyrusBrushTimer.Enabled) "Stop button ends session and timer"
-- The floating editor uses its own generated rollout instances.
CyrusOpenLayerEditor BRoot BLayer;CyrusLayerEditor.showTopic 3 rebind:true
BView=(for r in CyrusLayerEditor.activeEditors() where isProperty r #brushUI_obj collect r)[1]
BAssert (BView.brushUI_obj==BArea) "Floating editor selects the same native area"
BView.brushUI_modeRadio.state=1;BView.brushUI_modeRadio.changed 1
BView.brushUI_beginButton.pressed();BPump 1200
BAssert ((cyrusBrushStats BD)[5]==1 and CyrusBrushSessionLayer==BArea) "Floating Start Brush survives timer and UI refresh"
BRoot.updateMode=2;BRoot.markInputDirty();BPump 300
local oldCount=BRoot.groupSnapshotRows[1].count
BFixtureHeld=true
hits=cyrusPrivatePaintPath BD #([-65,-60,0],[0,-60,0],[65,-60,0]) false;BPump 300
BAssert (BRoot.groupSnapshotRows[1].count==oldCount) "Live population publication waits while interaction is held"
BFixtureHeld=false;BPump 1800
BAssert (hits==3 and BRoot.groupSnapshotRows[1].count>oldCount and BLayer.previewError=="") "Live callback painting publishes new plants automatically"
BAssert ((cyrusBrushStats BD)[5]==1) "Live publication preserves active brush"
BView.brushUI_stopButton.pressed();CyrusCloseLayerEditor()
BRoot.updateMode=1;BRoot.markInputDirty()
-- Switching paint areas must switch target ownership without losing contours.
local other=BRoot.addPaintArea BLayer target:BSecond
select BSecond;max zoomext sel all;select BNode;max modify mode;modPanel.setCurrentObject BRoot
if not BRoot.mainUI.controlsReady do BRoot.mainUI.mountTimer.tick()
BView=BRoot.coverageUI;BView.open=true;BRoot.mainUI.bindSection BView
BAssert (BView.brushUI_obj==other) "New receiver area binds to the main brush"
BView.brushUI_beginButton.pressed();BPump 400
hits=cyrusPrivatePaintPath other.paintDocument #([270,0,0],[330,0,0]) false;BPump 200
BAssert (hits==2 and (cyrusBrushStats other.paintDocument)[2]>0 and (cyrusBrushStats BD)[2]>0) "Second receiver paints independently and retains the first"
BView.brushUI_stopButton.pressed()
saveMaxFile (MCPFixtureDir+"button-workflow.max") quiet:true
BAssert true "Button workflow saved"
)catch(CyrusInteractionHeld=originalInteractionHeld;throw())
CyrusInteractionHeld=originalInteractionHeld
)
