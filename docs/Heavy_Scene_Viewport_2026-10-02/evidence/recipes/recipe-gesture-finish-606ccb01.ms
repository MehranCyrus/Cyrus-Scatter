(
    local after=HVPStats()
    CSPWriteText (HVPDir+"gesture.json") (CSPObject #(#("before",HVPBeforeGesture),#("after",after),#("view",(viewport.getTM()) as string)))
    if after[6]!=HVPBeforeGesture[6] or after[11]!=HVPBeforeGesture[11] do throw "Gesture changed or uploaded point data"
    max select
    viewport.setTM HVPBaseTM
    completeRedraw()
)
