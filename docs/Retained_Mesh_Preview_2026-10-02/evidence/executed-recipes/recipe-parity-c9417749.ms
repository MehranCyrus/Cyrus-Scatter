(
    RIAssert (matchPattern RIDir pattern:"*mesh-integration-2026-10-02/run*/") "Not a private test process"
    global MIParityCache,MIParityLegacy=false,MIParityDraw
    try(unregisterRedrawViewsCallback MIParityDraw)catch()
    resetMaxFile #noprompt;CyrusPFTimer.Stop();CyrusReleaseTimer.Stop()
    RINode=AminScatterObject name:"MI_Parity_Controller";RINode.showPoints=false
    local source=mesh name:"MI_Parity_Source" vertices:#([-30,-25,0],[35,-25,0],[20,40,0],[0,0,80],[0,0,0]) faces:#([1,3,2],[1,2,4],[2,3,4],[3,1,4],[5,5,5])
    source.pos=[-10000,0,0];source.objectOffsetPos=[3,-5,2];hide source
    local rows=#()
    append rows #((matrix3 [1,0,0] [0,1,0] [0,0,1] [-150,0,0]),1)
    append rows #((matrix3 [-1.4,0,0] [0,.6,0] [0,0,1.8] [-50,0,0]),1)
    append rows #((matrix3 [1,.4,.2] [.2,1,0] [0,.3,1.1] [70,0,0]),1)
    append rows #((matrix3 [1,0,0] [0,1,0] [0,0,0] [160,0,20]),1)
    append rows #((transMatrix [0,70,120]),2)
    MIParityCache=cyrusBuildGeometryPreview rows #(source,-1) #(green,red) 4 100 100000
    local owner=cyrusRetainedCreate()
    RIAssert (cyrusRetainedPublish owner RINode #(MIParityCache) #(#(false,white))) "Parity publication failed"
    fn MIParityDraw = (if MIParityLegacy do aminScatterDrawPreview MIParityCache false white)
    registerRedrawViewsCallback MIParityDraw
    local occluder=box name:"MI_Occluder" width:55 length:30 height:105 pos:[65,-30,0] wireColor:blue
    viewport.setLayout #layout_1;viewport.setType #view_persp_user
    local camera=targetCamera pos:[260,-650,400] target:(targetObject pos:[0,0,35])
    local cameraTarget=camera.target,baseTM=inverse camera.transform
    delete camera;if isValidNode cameraTarget do delete cameraTarget;viewport.setTM baseTM
    local report=#()
    try (
        for style in #(#smoothhighlights,#wireframe) do (
            viewport.setRenderLevel style
            MIParityLegacy=false;cyrusRetainedPublish owner RINode #(MIParityCache) #(#(false,white))
            completeRedraw();completeRedraw()
            local before=cyrusRetainedStats owner
            RICapture ("parity-"+(style as string)+"-retained")
            RIAssert ((cyrusRetainedStats owner)[12]==1) "Parity native resources failed"
            MIParityLegacy=true;cyrusRetainedPublish owner RINode #() #()
            RICapture ("parity-"+(style as string)+"-gw")
            append report #(style as string,for index=1 to 12 collect (before[index] as integer))
        )
        MIParityLegacy=false;cyrusRetainedPublish owner RINode #(MIParityCache) #(#(false,white));completeRedraw()
        local cachedHash=(cyrusRetainedStats owner)[13]
        viewport.setTM ((transMatrix [50000,0,0])*baseTM);completeRedraw();completeRedraw()
        RIAssert (cyrusRetainedMatches owner #(MIParityCache) #(#(false,white))) "Offscreen item triggered legacy fallback"
        viewport.setTM baseTM;completeRedraw();completeRedraw()
        RIAssert ((cyrusRetainedStats owner)[13]==cachedHash) "Offscreen return changed snapshot"
        CSPWriteText (RIDir+"mesh-parity.json") (CSPObject #(#("cases",report),#("faces",cyrusPreviewFaces MIParityCache),#("instances_and_marker",aminScatterPreviewCount MIParityCache),#("transforms","identity, mirrored nonuniform, shear, singular; source pivot offset; degenerate triangle; placeholder; occluder"),#("offscreen_return",true)))
    )catch(unregisterRedrawViewsCallback MIParityDraw;CyrusPointDelete #(owner);throw())
    unregisterRedrawViewsCallback MIParityDraw;CyrusPointDelete #(owner);MIParityCache=undefined
    CyrusReleaseTimer.Start()
)
