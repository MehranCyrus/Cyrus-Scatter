-- Read/selection diagnostics in the explicitly owned host; no save to artist input.
(
    if findString MCPFixtureDir "/real073-"==undefined do throw "Owned real-asset host required"
    global Real073Node,Real073Root,Real073Plants
    local controllers=for n in objects where classof n.baseObject==AminScatterObject collect n
    local roots=#(),proxies=#()
    for n in controllers do (
        local root=n.baseObject,sets=#()
        for leaf in root.layerObjects do append sets #(leaf.layerID,leaf.logicalParentID,leaf.paintSetName,leaf.amount,leaf.generatedCount,leaf.paintEnabled,leaf.paintDocument!=undefined,for s in leaf.sources where isValidNode s collect s.name,leaf.containerMode,for c in leaf.containerNodes where isValidNode c collect #((classof c.baseObject) as string,c.name),leaf.previewError)
        append roots #(n.name,root.version,root.updateMode,root.procEpoch,sets,root.layerNames as array)
    )
    for n in objects where (classof n.baseObject)==CProxy do append proxies #(n.name,n.filename,doesFileExist n.filename,n.previzType)
    CSPWriteText (MCPFixtureDir+"scatter-asset-inventory.json") (CSPObject #(#("controllers",roots),#("proxies",proxies),#("loaded_payload",CyrusLoadedScriptFingerprint)))
    if controllers.count==1 do (
        Real073Node=controllers[1];Real073Root=Real073Node.baseObject
        select Real073Node;max modify mode;modPanel.setCurrentObject Real073Root
    )
)
