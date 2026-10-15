-- Native MAXScript entry avoids Python ExecuteFile's surrounding hold while
-- invoking Max Undo. Only the owned qualification profile is permitted.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-panel0826-*/" do throw "Owned I02 host required"
    if theHold.Holding() do throw "Release the test transport hold before native Undo"
    PanelRoot.mainUI.updateRadio.changed 1
    PanelRoot.mainUI.slots[1].open=true;PanelRoot.mainUI.slots[1].rolledUp false
    local count=PanelRoot.layerObjects.count,ids=for leaf in PanelRoot.layerObjects collect leaf.layerID
    clearUndoBuffer()
    PanelRoot.managerUI.flow_layersUI_removeButton.pressed()
    if PanelRoot.layerObjects.count!=count-1 do throw "Remove handler failed"
    max undo
    if PanelRoot.layerObjects.count!=count do throw "Undo did not restore layer count"
    for i=1 to count where PanelRoot.layerObjects[i].layerID!=ids[i] do throw "Undo changed stable layer identity"
    PanelRoot.refreshAll()
    local report=createFile (MCPFixtureDir+"native-undo.txt")
    format "PASS actual Remove handler; native Undo; % layer identities restored\n" count to:report
    close report
)
