(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-meshmask-*/" do throw "Owned mask host required"
    local node=getNodeByName "Cyrus Scatter001",root=node.baseObject
    select node;max modify mode
    if modPanel.getCurrentObject()!=root do modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.populationUI.open=true;root.mainUI.bindSection root.populationUI
    if CyrusFalloffGraph==undefined then (
        root.populationUI.distributionUI_meshCurveButton.pressed()
        if CyrusFalloffGraph.obj!=root.layerObjects[1] or CyrusFalloffGraph.title!="Mesh Channel Density - Layer_01" do throw "Wrong mesh graph owner/title"
    ) else CyrusFalloffGraph.doneButton.pressed()
)
