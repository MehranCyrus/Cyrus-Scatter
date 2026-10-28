-- Read-only redraw observations. No forced redraw, scene sync or geometry edits.
global ADDrawSample,ADDrawSamples,ADDrawLast
if not matchPattern GardenRun pattern:"*/build/adaptation08754-20261028-01/host-*/" do throw "Owned adaptation host required."
if CVProfileCase=="drag-native-start" then (
    if ADDrawSample!=undefined do unregisterRedrawViewsCallback ADDrawSample
    ADDrawSamples=#();ADDrawLast=undefined
    fn ADDrawSample = (
        if ADDrawSamples.count<256 and isValidNode ADWall do (
            local position=ADWall.pos,stats=WFRoot.interactionsStatistics(),key=position as string
            if key!=ADDrawLast do (
                ADDrawLast=key
                append ADDrawSamples #(#("position",position),#("held",CyrusInteractionHeld()),#("statistics",stats),#("epoch",WFRoot.procEpoch),#("group_builds",WFRoot.groupBuilds))
            )
        )
    )
    registerRedrawViewsCallback ADDrawSample
) else if CVProfileCase=="drag-native-stop" then (
    unregisterRedrawViewsCallback ADDrawSample
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"actual-drag-redraw.json") (ADNativeJSON (for sample in ADDrawSamples collect ADNativeObject sample))
) else throw "Unknown read-only drag observation phase."
