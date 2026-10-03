(
global BLCancelSignature
BLPanel.refresh.active=false
cyrusBrushLabStop()
BLCancelSignature=cyrusEditFingerprint (cyrusBrushLabRows (BLDocument())) "brush"
cyrusBrushLabBegin (BLDocument())
cyrusBrushLabDab (BLDocument()) [0,-400,0] [0,1,0] false
BLAssert ((cyrusBrushLabStats (BLDocument()))[6]==1) "No pending input for cancel test"
)
