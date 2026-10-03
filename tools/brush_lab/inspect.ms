(
local flatDoc=BLFlatLayer.CyrusBrushLabData.paintDocument
local curvedDoc=BLCurvedLayer.CyrusBrushLabData.paintDocument
CSPWriteText (BLDir+"interaction.json") (CSPObject #(#("flat",cyrusBrushStats flatDoc),#("flat_rows",(cyrusBrushRows flatDoc).count),#("curved",cyrusBrushStats curvedDoc),#("curved_rows",(cyrusBrushRows curvedDoc).count)))
BLCapture "interaction"
)
