-- Disposable integration fixture; never run in the artist process.
global CyrusV1FixtureNode
(
    local surface=plane name:"CYRUS_V1_SURFACE" width:200 length:200 lengthsegs:8 widthsegs:8
    local source=cone name:"CYRUS_V1_SOURCE" radius1:2 radius2:0 height:10 sides:8 heightsegs:1 capsegs:1 pos:[120,0,0]
    CyrusV1FixtureNode=CyrusScatterObject name:"CYRUS_V1_SCATTER"
    local root=CyrusV1FixtureNode.baseObject
    root.surfaceNodes=#(surface)
    for i=1 to 3 do (
        root.newLayer()
        local layer=root.layerObjects[i]
        layer.sources=#(source);layer.amount=i*100;layer.viewportMode=3
        root.layerNames[i]=#("Grass","Shrubs","Trees")[i]
    )
    root.activeLayer=1
    if root.layerObjects[1].layerID==root.layerObjects[2].layerID or root.layerObjects[1].layerID.count<30 do throw "Layer identities are not unique GUIDs"
    root.refreshAll()
    select CyrusV1FixtureNode
    max modify mode
    root.bindNativeUI()
    local editorHandle=root.distributionUI.hwnd
    for i=1 to 30 do (
        root.selectLayer (1+mod(i-1)3);root.bindNativeUI()
        if root.distributionUI.countSpin.value!=root.layerObjects[root.activeLayer].amount do throw "Layer binding is incorrect"
        if root.distributionUI.hwnd!=editorHandle do throw "Layer selection remounted the editor"
    )
    local before=for layer in root.layerObjects collect layer.cacheSnapshot()
    root.layerVisible[1]=false;CyrusViewportRedraw()
    if (root.viewportLayerEntries false).count!=2 do throw "Hidden viewport layer is still included"
    if (root.layerEntries()).count!=3 do throw "Viewport hiding changed render membership"
    for i=1 to 3 where (root.layerObjects[i].cacheSnapshot())[6]!=before[i][6] do throw "Visibility rebuilt placement"
    root.layerVisible[1]=true;CyrusViewportRedraw()
    root.selectLayer 1;root.bindNativeUI()
    CSPWriteText (BLDir+"native-v1-fixture.json") (CSPObject #(#("native_editor_reused",true),#("editor_hwnd",editorHandle as string),#("layer_ids",for layer in root.layerObjects collect layer.layerID),#("visibility_cached",true),#("version",root.uiVersion())))
)
