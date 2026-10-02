HVPMode "retained"
local before=HVPStats(), original=viewport.getTM(), applied=#(), started=HVPStamp()
for i=1 to 30 do (
    append applied (viewport.setTM ((rotateZMatrix (6.0*sin(i*12.0)))*HVPBaseTM))
    completeRedraw()
    windows.processPostedMessages()
)
CSPWriteText (HVPDir+"redraw-check.json") (CSPObject #(#("before",before),#("after",HVPStats()),#("applied",applied),#("type",viewport.getType()),#("before_tm",original as string),#("after_tm",(viewport.getTM()) as string),#("elapsed_ms",HVPStamp()-started)))
HVPCapture "redraw-retained"
