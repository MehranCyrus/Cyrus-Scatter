(
global BLCancelSignature
BLPanel.refresh.active=false
cyrusBrushStop()
BLCancelSignature=cyrusEditFingerprint (cyrusBrushRows (BLDocument())) "brush"
cyrusBrushBegin (BLDocument())
cyrusBrushDab (BLDocument()) [0,-400,0] [0,1,0] false
BLAssert ((cyrusBrushStats (BLDocument()))[6]==1) "No pending input for cancel test"
)
