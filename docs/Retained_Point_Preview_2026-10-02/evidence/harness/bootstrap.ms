(
global RINode,RISource,RISurface,RIBaseTM,RIClock,RIFrequency
global RIAssert,RIStats,RICapture,RIStamp
-- MAXScript binds names when this block compiles, before fileIn creates them.
global CyrusPFTimer,CyrusPointSync,CyrusPointOwner,CyrusPointLastError,AminScatterObject
fn RIAssert value message = (if not value do throw message)
fn RIStats node = (
    local owner=CyrusPointOwner node
    RIAssert (isValidNode owner) "Missing retained owner"
    local raw=cyrusRetainedStats owner
    local result=for i=1 to 12 collect (raw[i] as integer)
    append result raw[13];result
)
fn RICapture name = (
    completeRedraw();windows.processPostedMessages()
    local bitmap=gw.getViewportDib();bitmap.filename=RIDir+name+".png";save bitmap;close bitmap
)
RIClock=dotNetClass "System.Diagnostics.Stopwatch"
RIFrequency=RIClock.Frequency as double
fn RIStamp = ((RIClock.GetTimestamp() as double)*1000.0/RIFrequency)
fileIn (RIDir+"AminScatterObject.ms")
fileIn (RIRoot+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
CyrusPFTimer.Stop()
RIAssert (objects.count==0) "Fixture requires a freshly launched empty scene"
RISurface=plane name:"RI_Surface" width:8000 length:8000 widthsegs:1 lengthsegs:1
RISource=cone name:"RI_Source" radius1:42 radius2:0 height:180 sides:16 heightsegs:1 capsegs:1 pos:[-10000,0,0]
RINode=AminScatterObject name:"RI_Controller"
RINode.surfaceNodes=#(RISurface);RINode.newLayer()
RINode.layerObjects[1].sources=#(RISource);RINode.layerObjects[1].amount=5000
RINode.pointsPerPlant=100;RINode.previewBudget=500000;RINode.autoRender=false
RINode.refreshAll()
viewport.setLayout #layout_1
viewport.setType #view_persp_user
local camera=targetCamera pos:[7000,-8500,9200] target:(targetObject pos:[0,0,0])
RIBaseTM=inverse camera.transform
local target=camera.target;delete camera;if isValidNode target do delete target
viewport.setType #view_persp_user;viewport.setTM RIBaseTM
viewport.setRenderLevel #smoothhighlights
local viewportSettings=NitrousGraphicsManager.GetActiveViewportSetting()
viewportSettings.AdaptiveDegradeNeverDegradeGeometry=true
CyrusPointSync();completeRedraw();windows.processPostedMessages();completeRedraw()
local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
local modules=#()
for index=0 to process.Modules.Count-1 do (
    local loaded=process.Modules.Item[index]
    if matchPattern loaded.ModuleName pattern:"*Cyrus*" or matchPattern loaded.ModuleName pattern:"AminScatter*" do append modules #(loaded.ModuleName,loaded.FileName)
)
CSPWriteText (RIDir+"ready.json") (CSPObject #(#("pid",process.Id),#("host",maxVersion()),#("modules",modules),#("stats",RIStats RINode),#("error",CyrusPointLastError),#("layer_status",RINode.layerObjects[1].statusText())))
RICapture "initial-retained"
)
