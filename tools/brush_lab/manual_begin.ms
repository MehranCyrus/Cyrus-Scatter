-- Run after verify.ms. Prepare a REAL erase gesture in Manual mode.
(
global BLManualRows,BLManualCounters,BLManualRevision,BLManualHistory,BLManualStats
fileIn (BLRoot+"tools/brush_lab/BrushLab.ms")
BLUse BLCurvedLayer
BLManualRows=cyrusBrushLabRows (BLDocument())
BLManualHistory=(cyrusBrushLabStats (BLDocument()))[2]
BLPanel.live.checked=false
BLPanel.mode.state=2
BLApplySettings()
completeRedraw()
BLManualCounters=cyrusRetainedStats BLPreviewOwner
BLManualRevision=BLPublished
BLManualStats=cyrusBrushLabStats (BLDocument())
)
