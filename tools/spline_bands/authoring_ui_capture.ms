-- Owned window snapshots inspect layout; they do not qualify physical pointer input.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
resetMaxFile #noPrompt
global BandCaptureNode=AminScatterObject name:"Spline Band authoring"
global BandCaptureRoot=BandCaptureNode.baseObject
BandCaptureRoot.updateMode=1;BandCaptureRoot.autoRender=false;BandCaptureRoot.newLayer()
global BandCaptureLeaf=BandCaptureRoot.selectedLayer()
local surface=plane width:500 length:500,asset=box name:"Meadow flowers" pos:[700,0,0]
BandCaptureRoot.setLayerSurfaces BandCaptureLeaf #(surface)
BandCaptureLeaf.sources=#(asset);BandCaptureLeaf.diversityMode=3;BandCaptureLeaf.amount=300
for i=1 to 3 do (
    local path=rectangle name:("Garden path "+(i as string)) width:100 length:100 pos:[i*100,0,0]
    BandCaptureLeaf.addStroke path
    if i==1 do (BandCaptureLeaf.setStrokeSelection 1 2 #(asset);BandCaptureLeaf.addStroke path side:2)
)
BandCaptureLeaf.patternWidths=#(10.,40.,20.,30.)
BandCaptureRoot.evaluateProcedural()
select BandCaptureNode;max modify mode
if not BandCaptureRoot.mainUI.controlsReady do BandCaptureRoot.mainUI.mountTimer.tick()
BandCaptureRoot.layoutUI.open=true;BandCaptureRoot.mainUI.bindSection BandCaptureRoot.layoutUI
global BandCapturePage=BandCaptureRoot.layoutUI
BandCapturePage.diversityUI_selectedPathID=BandCaptureLeaf.strokePathIDs[1]
BandCapturePage.diversityUI_selectedBandID=BandCaptureLeaf.strokeIDs[1]
BandCapturePage.diversityUI_updatePattern();BandCapturePage.layout()
local image=windows.snapshot BandCapturePage.hwnd gammaCorrect:false captureScreenPixels:false
image.filename=MCPFixtureDir+"band-authoring-modify.png";save image;close image
local y=BandCapturePage.diversityUI_addOutside.pos.y
if y!=BandCapturePage.diversityUI_addInside.pos.y or y!=BandCapturePage.diversityUI_removeStrokeButton.pos.y do throw "Band actions are not on one row"
if BandCapturePage.diversityUI_pickPath.pos.y!=BandCapturePage.diversityUI_removePath.pos.y do throw "Path actions are not adjacent"
if BandCapturePage.diversityUI_pathsList.items.count!=3 do throw "Path list did not retain all three entries"
)
