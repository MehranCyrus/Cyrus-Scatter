(
global BLFlatLayer,BLCurvedLayer,BLSource,BLFlat,BLCurved,BLAssert,BLCapture
global BLCreate,BLUse,BLDocument
fn BLAssert value message = (if not value do throw message)
fn BLCapture name = (
    completeRedraw();windows.processPostedMessages()
    local bmp=gw.getViewportDib();bmp.filename=BLDir+name+".png";save bmp;close bmp
)
BLAssert (objects.count==0) "Brush lab needs its own fresh Max scene"
BLFlat=plane name:"Brush_Flat" width:400 length:400 widthsegs:1 lengthsegs:1 pos:[-250,0,0]
BLCurved=sphere name:"Brush_Curved" radius:160 segs:48 pos:[250,0,0]
BLFlat.wirecolor=color 150 155 165;BLCurved.wirecolor=BLFlat.wirecolor
BLSource=cone name:"Brush_Source" radius1:2 radius2:0 height:10 sides:6 heightsegs:1 capsegs:1 pos:[-1000,0,0]
hide BLSource
fileIn (BLRoot+"tools/brush_lab/BrushLab.ms")
BLFlatLayer=BLCreate BLFlat BLSource
BLCurvedLayer=BLCreate BLCurved BLSource
BLUse BLFlatLayer
viewport.setLayout #layout_1
viewport.setType #view_persp_user
local cam=targetCamera pos:[0,-950,820] target:(targetObject pos:[0,0,0])
local viewTM=inverse cam.transform
local target=cam.target;delete cam;if isValidNode target do delete target
viewport.setType #view_persp_user;viewport.setTM viewTM
viewport.setRenderLevel #smoothhighlights
local viewSettings=NitrousGraphicsManager.GetActiveViewportSetting()
viewSettings.AdaptiveDegradeNeverDegradeGeometry=true
completeRedraw()
local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
local modules=#()
for index=0 to process.Modules.Count-1 do (
    local loaded=process.Modules.Item[index]
    if matchPattern loaded.ModuleName pattern:"*Cyrus*" or matchPattern loaded.ModuleName pattern:"AminScatter*" do append modules #(loaded.ModuleName,loaded.FileName)
)
CSPWriteText (BLDir+"ready.json") (CSPObject #(#("pid",process.Id),#("host",maxVersion()),#("modules",modules),#("stats",cyrusBrushStats (BLDocument()))))
BLCapture "initial"
)
