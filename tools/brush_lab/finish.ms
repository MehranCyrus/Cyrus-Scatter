-- Leave a clean, saved demonstration and the current UI ready to use.
(
cyrusBrushStop()
BLPanel.refresh.active=false
if isValidNode BLPreviewOwner do delete BLPreviewOwner
BLPreviewOwner=undefined;BLPublished=0;BLCache=undefined
BLAssert (saveMaxFile (BLDir+"BrushLab.max") quiet:true) "Final demonstration save failed"
fileIn (BLRoot+"tools/brush_lab/BrushLab.ms")
BLUse BLFlatLayer;BLCapture "flat-painted"
BLUse BLCurvedLayer;BLCapture "curved-painted"
local flat=cyrusBrushRows BLFlatLayer.CyrusBrushLabData.paintDocument
local curved=cyrusBrushRows BLCurvedLayer.CyrusBrushLabData.paintDocument
CSPWriteText (BLDir+"final.json") (CSPObject #(#("flat_rows",flat.count),#("curved_rows",curved.count),#("flat_signature",cyrusEditFingerprint flat "brush"),#("curved_signature",cyrusEditFingerprint curved "brush"),#("curved_stats",cyrusBrushStats (BLDocument()))))
)
