(
BLPanel.refresh.active=false
cyrusBrushStop()
cyrusBrushSettings BLFlatLayer.CyrusBrushLabData.paintDocument 35 1 .5 false 1
cyrusBrushDab BLFlatLayer.CyrusBrushLabData.paintDocument [0,0,100] [0,0,-1] true
cyrusBrushSettings BLCurvedLayer.CyrusBrushLabData.paintDocument 35 1 .5 false 1
cyrusBrushDab BLCurvedLayer.CyrusBrushLabData.paintDocument [0,-400,200] [0,1,-.5] true
global BLSmokeExpected=#((cyrusBrushRows BLFlatLayer.CyrusBrushLabData.paintDocument).count,(cyrusBrushRows BLCurvedLayer.CyrusBrushLabData.paintDocument).count)
if isValidNode BLPreviewOwner do delete BLPreviewOwner
BLPreviewOwner=undefined;BLCache=undefined
local saved=saveMaxFile (BLDir+"storage-smoke.max") quiet:true
local loaded=loadMaxFile (BLDir+"storage-smoke.max") quiet:true
CSPWriteText (BLDir+"storage-smoke.txt") ((saved as string)+" "+(loaded as string)+" nodes:"+(objects.count as string))
CSPWriteText (BLDir+"storage.log") (cyrusBrushStorageLog())
)
