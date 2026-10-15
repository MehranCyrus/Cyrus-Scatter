-- Wait outside Max between views so asynchronous drawing can finish.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-feature-demo0824-*/" do throw "Owned feature-demo host required."
    global DemoShotIndex,DemoShotTimer,DemoShotTicks,DemoShotTick
    if DemoShotIndex==undefined or DemoShotIndex>=5 do DemoShotIndex=0
    fn DemoShotTick sender args = (
        DemoShotTicks+=1
        if DemoShotTicks>=15 do (
            DemoShotTimer.Stop()
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"demo-shot-ready.txt") "ready"
        )
    )
    local views=#(#("CAM 01 | Overview","Preview - Overview.png"),#("CAM 02 | Plane - density Paint Bands","Preview - Plane.png"),#("CAM 03 | Mountain - normals and filters","Preview - Mountain.png"),#("CAM 04 | Top plan","Preview - Top.png"))
    local log=if DemoShotIndex==0 then createFile (MCPFixtureDir+"demo-staged-capture.txt") else openFile (MCPFixtureDir+"demo-staged-capture.txt") mode:"a"
    if DemoShotIndex>0 do (
        local expected=getNodeByName views[DemoShotIndex][1],actual=viewport.getCamera()
        format "Capture % | expected % | actual %\n" DemoShotIndex expected actual to:log;flush log
        if actual!=expected do (close log;throw "Owned viewport changed before capture; inspect before retrying.")
        local image=viewport.getViewportDib index:viewport.activeViewport;image.filename=MCPFixtureDir+views[DemoShotIndex][2];save image;close image
    )
    DemoShotIndex+=1
    if DemoShotIndex<=4 then (
        (LayerManager.getLayerFromName "DEMO | Cameras").isHidden=false
        local cam=getNodeByName views[DemoShotIndex][1]
        for other in cameras do if other!=cam then hide other else unhide other
        local result=viewport.setCamera cam
        format "Set % | result % | camera %\n" DemoShotIndex result (viewport.getCamera()) to:log;flush log
        completeRedraw()
        deleteFile (MCPFixtureDir+"demo-shot-ready.txt")
        try(DemoShotTimer.Stop();DemoShotTimer.Dispose())catch()
        DemoShotTicks=0;DemoShotTimer=dotNetObject "System.Windows.Forms.Timer";DemoShotTimer.Interval=100
        dotNet.addEventHandler DemoShotTimer "Tick" DemoShotTick;DemoShotTimer.Start()
    ) else (
        DemoShotTimer.Dispose();format "COMPLETE\n" to:log
    )
    close log
)
