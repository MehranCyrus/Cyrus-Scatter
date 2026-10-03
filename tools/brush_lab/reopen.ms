(
BLPanel.refresh.active=false
cyrusBrushLabStop()
BLAssert (loadMaxFile BLReopenScene quiet:true) "Brush fixture failed to load"
BLFlat=getNodeByName "Brush_Flat";BLCurved=getNodeByName "Brush_Curved";BLSource=getNodeByName "Brush_Source"
BLFlatLayer=getNodeByName "Brush_Lab_Layer001";BLCurvedLayer=getNodeByName "Brush_Lab_Layer002"
cyrusBrushLabBind BLFlatLayer.CyrusBrushLabData.paintDocument
cyrusBrushLabBind BLCurvedLayer.CyrusBrushLabData.paintDocument
local flatRows=cyrusBrushLabRows BLFlatLayer.CyrusBrushLabData.paintDocument
local curvedRows=cyrusBrushLabRows BLCurvedLayer.CyrusBrushLabData.paintDocument
BLAssert (flatRows.count>0 and curvedRows.count>0) "Saved paint did not reconstruct"
BLPreviewOwner=undefined;BLPublished=0;BLUse BLCurvedLayer
BLPanel.refresh.active=true
CSPWriteText (BLDir+"reopen.json") (CSPObject #(#("scene",BLReopenScene),#("flat_rows",flatRows.count),#("curved_rows",curvedRows.count),#("flat_signature",cyrusEditFingerprint flatRows "brush"),#("curved_signature",cyrusEditFingerprint curvedRows "brush"),#("curved_stats",cyrusBrushLabStats (BLDocument()))))
)
