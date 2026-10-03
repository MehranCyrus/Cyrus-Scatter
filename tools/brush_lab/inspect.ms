(
local flatDoc=BLFlatLayer.CyrusBrushLabData.paintDocument
local curvedDoc=BLCurvedLayer.CyrusBrushLabData.paintDocument
CSPWriteText (BLDir+"interaction.json") (CSPObject #(#("flat",cyrusBrushLabStats flatDoc),#("flat_rows",(cyrusBrushLabRows flatDoc).count),#("curved",cyrusBrushLabStats curvedDoc),#("curved_rows",(cyrusBrushLabRows curvedDoc).count)))
BLCapture "interaction"
)
