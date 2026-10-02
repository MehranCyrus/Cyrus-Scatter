-- Run after visibly maximizing the private Max window. All three arms share it.
(
    RIAssert (gw.getWinSizeX()>1000 and gw.getWinSizeY()>650) "Maximize the viewport window first"
    viewport.setRenderLevel #smoothhighlights
    completeRedraw();windows.processPostedMessages()
    RIBenchmark "artist-maximized"
)
