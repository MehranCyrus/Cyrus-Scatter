(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
global BRoot,BLayer,BNode,BPlane,BArea,BD,BView
CyrusStopBrush();resetMaxFile #noPrompt
viewport.setLayout #layout_1;viewport.setType #view_top
BPlane=plane name:"Button_receiver" width:200 length:200 widthsegs:4 lengthsegs:4
BNode=AminScatterObject name:"Button_scatter";BRoot=BNode.baseObject
BRoot.setLayerTransfer true;BRoot.updateMode=1;BRoot.autoRender=false;BRoot.newLayer()
BLayer=BRoot.selectedLayer();BRoot.setLayerTransfer false;BRoot.setLayerSurfaces BLayer #(BPlane)
BArea=BRoot.addPaintArea BLayer target:BPlane;BD=BArea.paintDocument
select BPlane;max zoomext sel all
select BNode;max modify mode;modPanel.setCurrentObject BRoot
if not BRoot.mainUI.controlsReady do BRoot.mainUI.mountTimer.tick()
BView=BRoot.coverageUI;BView.open=true;BRoot.mainUI.bindSection BView
local log=createFile (MCPFixtureDir+"button-diagnostic.txt")
format "Before: % | % | % | %\n" BView.controlsReady BView.brushUI_controlsReady BView.brushUI_obj BView.brushUI_beginButton.enabled to:log
try(BView.refreshBrushStatus();format "Direct status passed\n" to:log)catch(format "Direct status ERROR: %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
BView.brushUI_beginButton.pressed()
format "After button: % | session %\n" (cyrusBrushStats BD) CyrusBrushSessionLayer to:log
try(CyrusBrushTick undefined undefined)catch(format "Tick ERROR: %\n" (getCurrentException()) to:log)
format "After tick: % | session %\n" (cyrusBrushStats BD) CyrusBrushSessionLayer to:log
close log
)
