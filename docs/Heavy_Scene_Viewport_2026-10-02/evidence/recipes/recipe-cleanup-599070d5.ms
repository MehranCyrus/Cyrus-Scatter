-- Destructive only to the disposable fixture launched by launch.py.
(
    if HVPDir==undefined or HVPNode==undefined or HVPCommandTimer==undefined do throw "Private fixture is not active"
    if not matchPattern HVPDir pattern:"*/build/heavy-viewport-2026-10-02/" do throw "Unexpected experiment directory"
    local before=HVPStats()
    HVPArm="off"
    unregisterRedrawViewsCallback HVPDraw
    HVPCaches=#()
    HVPExactRows=undefined
    resetMaxFile #noPrompt
    HVPNode=undefined
    gc()
    completeRedraw(); windows.processPostedMessages()
    local witness=CyrusRetainedPointProbe name:"Empty reset witness"
    local after=cyrusPointProbeStats witness
    if after[1]!=0 or after[10]!=0 do throw "Reset retained preview points or live render items"
    if after[9]!=0 do throw "A GPU realization failure was recorded"
    delete witness
    completeRedraw(); windows.processPostedMessages()
    if objects.count!=0 do throw "Cleanup left scene objects"
    CSPWriteText (HVPDir+"cleanup.json") (CSPObject #(#("status","SUCCESS"),#("before_reset",before),#("after_reset",after),#("objects_after_cleanup",objects.count),#("redraw_callback_unregistered",true)))
)
