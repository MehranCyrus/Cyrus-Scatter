-- Original scene is read-only on disk; changes remain in this private process.
(
    local nodes=for n in objects where classof n.baseObject==CyrusScatterObject collect n
    if nodes.count==0 do throw "Legacy scene has no Cyrus controller"
    local records=#()
    for node in nodes do (
        local root=node.baseObject
        root.syncLayerIdentity();root.viewportMode=3;root.autoRender=false;root.refreshAll()
        select node;max modify mode;root.bindNativeUI()
        if root.uiVersion()!="1.0.0" do throw "Legacy scene retained the old script definition"
        for entry in root.layerEntries() do (
            local layer=entry[2],state=layer.cacheSnapshot()
            if layer.paintIdentity do throw "Legacy scene was silently converted to Brush identities"
            if state[4]!="" do throw ("Legacy preview error: "+state[4])
            append records #(node.name,root.layerNames[entry[1]],state[5],state[2],layer.layerID)
        )
    )
    CSPWriteText (BLDir+"legacy-acceptance.json") (CSPObject #(#("original_scene",maxFilePath+maxFileName),#("controllers",nodes.count),#("layers",records),#("native_ui",true),#("legacy_generation_preserved",true),#("saved_original",false)))
)
