-- Navigation work counters, not a presented-FPS measurement.
(
    for n in objects do hide n
    local surface=plane name:"CYRUS_NAV_TARGET" width:2000 length:2000 widthsegs:16 lengthsegs:16
    local source=cone name:"CYRUS_NAV_SOURCE" radius1:5 radius2:0 height:25 sides:8 heightsegs:1 capsegs:1 pos:[1500,0,0]
    hide source
    local node=CyrusScatterObject name:"CYRUS_V1_NAVIGATION"
    local root=node.baseObject
    root.surfaceNodes=#(surface);root.viewportMode=3;root.viewportInstances=20000;root.autoRender=false;root.updateMode=1;root.newLayer()
    local layer=root.layerObjects[1]
    layer.sources=#(source);layer.amount=20000;layer.paintDocument=cyrusBrushCreate surface;layer.paintEnabled=true;layer.paintIdentity=true
    cyrusBrushFill layer.paintDocument 1.0
    root.refreshAll()
    hide surface
    viewport.setType #view_persp_user
    local eye=[1700,-2100,1800],look=normalize(-eye),right=normalize(cross look [0,0,1]),up=cross right look
    local viewTM=inverse(matrix3 right up (-look) eye)
    viewport.setTM viewTM
    for i=1 to 5 do completeRedraw()
    local owner=CyrusPointOwner node
    if not isValidNode owner do throw "Mesh preview has no retained owner"
    local before=cyrusRetainedStats owner,paintBefore=cyrusBrushStats layer.paintDocument,cacheBefore=layer.cacheSnapshot(),baseBefore=layer.paintCacheStats()
    local timings=#()
    for i=1 to 45 do (
        local tm=copy viewTM;tm.row4+= [sin(i*8)*40,cos(i*8)*40,0]
        local start=timeStamp()
        viewport.setTM tm;completeRedraw()
        append timings (timeStamp()-start)
    )
    local after=cyrusRetainedStats owner,paintAfter=cyrusBrushStats layer.paintDocument,cacheAfter=layer.cacheSnapshot(),baseAfter=layer.paintCacheStats()
    for index in #(3,4,5,6,7) where after[index]!=before[index] do throw "Navigation republished or uploaded retained buffers"
    for index in #(8,9,10,15) where paintAfter[index]!=paintBefore[index] do throw "Navigation recomputed Brush state"
    if cacheAfter[6]!=cacheBefore[6] or baseAfter[1]!=baseBefore[1] do throw "Navigation regenerated placements"
    if (cyrusRetainedMeshStats owner)[2]!=20000 do throw "Mesh retained preview did not display the full fixture population"
    root.layerVisible[1]=false;CyrusViewportRedraw();completeRedraw()
    if (root.viewportLayerEntries false).count!=0 do throw "Hidden navigation layer still draws"
    if (layer.cacheSnapshot())[6]!=cacheAfter[6] do throw "Hide rebuilt placements"
    root.layerVisible[1]=true;CyrusViewportRedraw();completeRedraw()
    select node;max modify mode;root.bindNativeUI()
    CSPWriteText (BLDir+"navigation-acceptance.json") (CSPObject #(#("instances",20000),#("camera_steps",45),#("step_ms",timings),#("zero_generation",true),#("zero_brush_queries",true),#("zero_retained_uploads",true),#("hide_cached",true),#("native_thread_limit",cyrusScatterCPUThreads()),#("timing_semantics","Synchronous viewport camera/redraw steps; not presented FPS")))
)
