-- Exercise native rollout lifetime without changing authoring or rebuilding placements.
(
    P07Case="native rollout lifetime"
    P07New count:300
    P07Root.setGroupDisplay 3;select P07Node;max modify mode;modPanel.setCurrentObject P07Root
    P07Root.bindNativeUI()
    for r in P07Root.nativeEditors() do r.open=false
    local panel=P07Root.layerPanels[1]
    panel.open=true;panel.mount()
    for r in panel.editors do r.open=false
    panel.editors[10].open=true
    P07Root.mainUI.layoutPanels();P07Root.refreshAll();CyrusViewportRedraw()
    for i=1 to 3 do (completeRedraw();windows.processPostedMessages())
    local allPanels=P07Root.nativeEditors()+#(panel)+panel.editors
    local handles=for r in allPanels collect r.hwnd
    local builds=(P07Layer.procStatistics())[3],epoch=(P07Root.procStatistics())[5],display=(P07Layer.cacheSnapshot())[6]
    for i=1 to 20 do (
        panel.open=false;P07Root.mainUI.layoutPanels();windows.processPostedMessages()
        panel.open=true;P07Root.mainUI.layoutPanels();windows.processPostedMessages()
        panel.editors[10].open=false;P07Root.mainUI.layoutPanels()
        panel.editors[10].open=true;P07Root.mainUI.layoutPanels()
    )
    for i=1 to allPanels.count do P07Assert (allPanels[i].hwnd==handles[i]) "Opening recreated native controls"
    P07Assert ((P07Layer.procStatistics())[3]==builds and (P07Root.procStatistics())[5]==epoch and (P07Layer.cacheSnapshot())[6]==display) "Opening rebuilt placements or display"
    CSPWriteText (MCPFixtureDir+"ui-lifetime.json") (CSPObject #(#("cycles",20),#("handles_retained",true),#("zero_generation",true),#("zero_display_rebuild",true),#("ui_version",P07Root.uiVersion())))
)
