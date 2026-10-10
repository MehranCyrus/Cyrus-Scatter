(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
CyrusStopBrush();resetMaxFile #noPrompt
viewport.setLayout #layout_1;viewport.setType #view_top
local receiver=plane name:"Speed_receiver" width:200 length:200 widthsegs:32 lengthsegs:32
local model=box width:1 length:1 height:3 pos:[1000,0,0];hide model
local node=AminScatterObject name:"Speed_scatter",root=node.baseObject
root.setLayerTransfer true;root.updateMode=1;root.autoRender=false;root.newLayer()
local layer=root.selectedLayer();layer.sources=#(model);layer.sourceWeights=#(1.0);layer.amount=5000
root.setLayerTransfer false;root.setLayerSurfaces layer #(receiver)
local area=root.addPaintArea layer target:receiver,doc=area.paintDocument
root.refreshAll();select receiver;max zoomext sel all;select node;max modify mode;modPanel.setCurrentObject root
if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
local view=root.coverageUI;view.open=true;root.mainUI.bindSection view
view.brushUI_radiusSpin.value=3;view.brushUI_radiusSpin.changed 3;view.brushUI_beginButton.pressed()
CyrusBrushTimer.Stop()
local patched=(root.uiVersion()=="0.78.2")
view.refreshBrushStatus()
if patched and view.brushUI_refreshBrushStatus()!=false do throw "Unchanged status must not trigger panel layout"
local watch=dotNetObject "System.Diagnostics.Stopwatch",out=createFile (MCPFixtureDir+"drawing-timings.csv")
format "point,author_ms,border_ms,editors_ms,redraw_ms,vertices,segments\n" to:out
local epoch=root.procEpoch,cache=layer.receiverCacheStats()
for i=0 to 299 do (
 local p=[-80+160.0*i/299,65*sin(i*9),200]
 watch.Restart();cyrusBrushDab doc p [0,0,-1] false;watch.Stop();local author=watch.Elapsed.TotalMilliseconds
 watch.Restart();cyrusBrushRefreshMask doc;watch.Stop();local border=watch.Elapsed.TotalMilliseconds
 watch.Restart();root.refreshBrushEditors();watch.Stop();local editors=watch.Elapsed.TotalMilliseconds
 watch.Restart();redrawViews();watch.Stop();local draw=watch.Elapsed.TotalMilliseconds
 local state=cyrusBrushStats doc
 format "%,%,%,%,%,%,%\n" i author border editors draw state[3] state[19] to:out
)
close out
if root.procEpoch!=epoch or (layer.receiverCacheStats())[1]!=cache[1] do throw "Drawing rebuilt the population"
cyrusBrushCancel doc;cyrusBrushRefreshMask doc
-- No message pumping: measure whether production SDK callbacks keep borders
-- current themselves, even while low-priority WinForms timers cannot execute.
local path=for i=0 to 999 collect [-80+160.0*i/999,65*sin(i*2.7),0]
watch.Restart();local hits=cyrusPrivatePaintContinue doc path;watch.Stop()
out=createFile (MCPFixtureDir+"callback-speed.txt")
format "hits=% elapsed_ms=% mid_stroke_stats=%\n" hits watch.Elapsed.TotalMilliseconds (cyrusBrushStats doc) to:out
close out
if hits!=path.count do throw "Callback path missed receiver"
if patched do (
 local state=cyrusBrushStats doc
 if state[19]==0 or state[6]!=1 do throw "Continuous callbacks did not prepare intermediate borders"
)
cyrusPrivatePaintPath doc #(path[path.count]) false
if patched do (
 if cyrusBrushRefreshMask doc!=false do throw "EndStroke did not flush final feedback"
 if root.procEpoch!=epoch or (layer.receiverCacheStats())[1]!=cache[1] do throw "Continuous callbacks rebuilt the population"
 root.refreshAll();local fingerprint=cyrusEditFingerprint root.groupSnapshotRows[1] "speed"
 cyrusBrushSettings doc 8 true
 cyrusPrivatePaintPath doc path true
 CyrusBrushTick undefined undefined;CyrusBrushTimer.Stop();root.refreshAll()
 if (cyrusEditFingerprint root.groupSnapshotRows[1] "speed")!=fingerprint do throw "Continuous erase cancellation changed coverage"
 local result=createFile (MCPFixtureDir+"responsiveness-checks.txt")
 format "PASS unchanged status does not layout\nPASS all 1000 callbacks hit\nPASS intermediate borders prepared without timer delivery\nPASS final feedback flushed\nPASS no duplicate feedback preparation\nPASS Manual population and receiver caches unchanged\nPASS continuous erase cancellation preserves placements\n" to:result;close result
)
view.brushUI_stopButton.pressed()
)
