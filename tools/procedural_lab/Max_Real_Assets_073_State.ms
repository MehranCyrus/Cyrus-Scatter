(
    if findString MCPFixtureDir "/real073-"==undefined do throw "Owned real-asset host required"
    local root=Real073Root,pages=root.mainUI.editors
    local fields=#()
    for page in pages do (
        local sizes=#()
        for control in page.controls where isProperty control #pos do append sizes #(control.name,(classof control) as string,control.pos as string,if isProperty control #width then control.width else undefined,if isProperty control #height then control.height else undefined,control.visible)
        append fields #(page.title,page.width,page.height,page.open,page.controlsReady,sizes)
    )
    CSPWriteText (MCPFixtureDir+"ui-observed-state.json") (CSPObject #(#("epoch",root.procEpoch),#("layers",for l in root.layerObjects collect #(l.paintSetName,l.generatedCount,l.requestedCount,l.procPreparedBuilds,l.previewBuildCount,l.previewError)),#("pages",fields)))
)
