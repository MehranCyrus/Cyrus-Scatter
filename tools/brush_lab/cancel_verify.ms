-- Right-click in the test viewport after cancel_begin.ms.
(
local stats=cyrusBrushLabStats (BLDocument())
BLAssert (stats[5]==0 and stats[6]==0) "Right-click did not release Painter and cancel input"
BLAssert ((cyrusEditFingerprint (cyrusBrushLabRows (BLDocument())) "brush")==BLCancelSignature) "Right-click changed committed paint"
CSPWriteText (BLDir+"cancel.json") (CSPObject #(#("real_right_click_stops_session",true),#("pending_input_canceled",true),#("committed_result_unchanged",true)))
BLPublish()
BLPanel.refresh.active=true
)
