-- One real low-resolution Scanline render in the clean, synthetic demo.
(
    local node=getNodeByName "Cyrus_Scatter_1_Demo",root=node.baseObject
    root.layerVisible[1]=false;CyrusViewportRedraw()
    local expected=0
    for entry in root.layerEntries() do expected+=(entry[2].placements (entry[2].validSources())).count
    local prior=renderers.current
    renderers.current=Default_Scanline_Renderer()
    local camera=targetCamera name:"Cyrus_Trial_Camera" pos:[170,-220,190] target:(targetObject pos:[0,0,0])
    local image=undefined,rendered=0,failure=undefined,target=camera.target
    try (
        image=render camera:camera outputwidth:128 outputheight:128 vfb:false
        if image==undefined do throw "Scanline returned no render"
        if image.width!=128 or image.height!=128 do throw "Wrong render dimensions"
        for data in CyrusPFData do rendered+=data.count
        if rendered!=expected do throw "Rendered population did not match final placements"
        image.filename=BLDir+"render.png";save image;close image;image=undefined
    ) catch (failure=getCurrentException())
    if image!=undefined do close image
    CyrusPFClear()
    if isValidNode camera do delete camera
    if isValidNode target do delete target
    renderers.current=prior
    root.layerVisible[1]=true;CyrusViewportRedraw()
    if failure!=undefined do throw failure
    CSPWriteText (BLDir+"render-acceptance.json") (CSPObject #(#("renderer","Default Scanline"),#("size",128),#("instances",rendered),#("hidden_layer_rendered",true),#("transient_cleanup",true)))
)
