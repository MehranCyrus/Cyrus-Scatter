-- Frozen 0.73 camera/redraw/retained-cache regression.
-- Synchronous camera+completeRedraw latency, NOT presented frame rate.
global P07Navigation
fn P07Navigation label population procedural:true frames:90 modes:#(0,1,2,3,4) containers:false = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private profile required"
    resetMaxFile #noPrompt
    units.SystemType=#Centimeters;units.SystemScale=1
    local surface=plane name:"NAV_Surface" width:2000 length:2000 widthsegs:16 lengthsegs:16
    local source=cone name:"NAV_Asset" radius1:5 radius2:0 height:25 sides:8 heightsegs:1 capsegs:1 pos:[1500,0,0]
    hide source
    local node=AminScatterObject name:"NAV_Controller",root=node.baseObject
    root.surfaceNodes=#(surface);root.viewportMode=3;root.viewportInstances=population;root.viewportFaces=10000000
    root.previewBudget=500000;root.pointsPerPlant=5;root.autoRender=false;root.updateMode=1
    root.newLayer()
    local leaf=root.layerObjects[1]
    leaf.sources=#(source);leaf.amount=population;leaf.randomSeed=42
    if not procedural do throw "Only the unified model is supported"
    (
        leaf.paintDocument=cyrusBrushCreate surface;leaf.paintEnabled=true
        cyrusBrushFill leaf.paintDocument 1.0
        if containers do (
            leaf.containerMode=4
            leaf.containerNodes=#(CyrusSourceContainer name:"NAV_Source_Container" width:300 length:200 pos:source.pos)
        )
    )
    local timer=dotNetObject "System.Diagnostics.Stopwatch"
    timer.Start();root.refreshAll();local buildMs=timer.Elapsed.TotalMilliseconds
    if (leaf.cacheSnapshot())[5]!=population do throw "Population was not fully generated"
    hide surface;clearSelection();max create mode
    viewport.setLayout #layout_1;viewport.setType #view_persp_user;viewport.setRenderLevel #smoothhighlights
    local eye=[1700,-2100,1800],look=normalize(-eye),right=normalize(cross look [0,0,1]),up=cross right look
    local baseTM=inverse(matrix3 right up (-look) eye),trials=#()
    viewport.setTM baseTM
    for mode in modes do (
        root.showPoints=(mode!=0)
        if mode!=0 do (
            root.setGroupDisplay mode
        )
        for warm=1 to 8 do (completeRedraw();windows.processPostedMessages())
        local before=leaf.cacheSnapshot(),owner=CyrusPointOwner node
        local retained=if isValidNode owner then cyrusRetainedStats owner else undefined
        local prepared=if procedural then leaf.procStatistics() else undefined
        local rootStats=if procedural then root.procStatistics() else undefined
        local brush=if procedural then cyrusBrushStats leaf.paintDocument else undefined
        local membership=if containers then #(leaf.containerScans,leaf.containerTests,leaf.containerMembershipBuilds) else undefined
        local meshStats=if isValidNode owner then cyrusRetainedMeshStats owner else undefined
        local timings=#()
        for frame=1 to frames do (
            local started=timer.Elapsed.TotalMilliseconds
            viewport.setTM ((rotateZMatrix (4.0*sin(frame*7.0)))*baseTM)
            completeRedraw();windows.processPostedMessages()
            append timings (timer.Elapsed.TotalMilliseconds-started)
        )
        local after=leaf.cacheSnapshot(),now=if isValidNode owner then cyrusRetainedStats owner else undefined
        if after[6]!=before[6] do throw "Navigation rebuilt display cache"
        if retained!=undefined do for k in #(3,4,5,6,7,9) where retained[k]!=now[k] do throw "Navigation rebuilt/uploaded retained buffers"
        if procedural do (
            if (leaf.procStatistics())[3]!=prepared[3] or (root.procStatistics())[5]!=rootStats[5] do throw "Navigation recalculated placement"
            local brushNow=cyrusBrushStats leaf.paintDocument
            for k in #(8,9,10,15) where brush[k]!=brushNow[k] do throw "Navigation queried Brush"
            if containers and #(leaf.containerScans,leaf.containerTests,leaf.containerMembershipBuilds) as string!=membership as string do throw "Navigation recomputed source-container membership"
        )
        if mode==3 and (meshStats==undefined or meshStats[2]!=population) do throw "Mesh instance display budget hid plants"
        append trials #(#("mode",mode),#("step_ms",timings),#("generated",after[5]),#("shown",after[2]),#("retained_before",retained),#("retained_after",now),#("mesh",meshStats),#("zero_rebuilds",true),#("zero_brush_work",procedural))
    )
    timer.Stop()
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    process.Refresh()
    local data=#(#("label",label),#("population",population),#("procedural",procedural),#("initial_update_ms",buildMs),#("viewport",#(gw.getWinSizeX(),gw.getWinSizeY())),#("render_level",viewport.getRenderLevel() as string),#("source_faces",(snapshotAsMesh source).numfaces),#("working_set_bytes",process.WorkingSet64),#("peak_working_set_bytes",process.PeakWorkingSet64),#("trials",trials),#("metric","synchronous camera plus completeRedraw and posted messages, not presented FPS"))
    CSPWriteText (MCPFixtureDir+label+"-navigation.json") (CSPObject data)
    true
)
