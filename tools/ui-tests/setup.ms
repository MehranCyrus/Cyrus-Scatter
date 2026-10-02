-- Run only in the private retained_integration fixture; never in artist startup.
(
    RIAssert (matchPattern RIDir pattern:"*ui-layer-status-*/") "Wrong fixture directory"
    global UILayerNode=RINode,UIAssert,UIChecks=#()
    fn UIAssert value message = (if not value then throw message else append UIChecks message)
    UILayerNode.name="Cyrus_UI_Test"
    UILayerNode.updateMode=1;UILayerNode.viewportMode=1;UILayerNode.pointsPerPlant=12;UILayerNode.previewBudget=10000
    while UILayerNode.layerObjects.count<10 do UILayerNode.newLayer()
    local names=#("Grass","Leaves","clover","BushesCenter","Bourder","Street_Plant","Layer_07","Layer_08","Layer_09","Layer_10")
    for i=1 to 10 do (
        UILayerNode.layerNames[i]=names[i]
        UILayerNode.layerObjects[i].sources=#(RISource)
        UILayerNode.layerObjects[i].amount=i*100
    )
    UILayerNode.refreshAll()
    select UILayerNode
    setCommandPanelTaskMode #modify
    modPanel.setCurrentObject UILayerNode.baseObject
    windows.processPostedMessages()
    UIAssert UILayerNode.mainUI.controlsReady "Modify panel opened"
    UILayerNode.mainUI.open=true
    UIAssert (UILayerNode.uiVersion()=="2026-10-02.5") "Correct UI revision loaded"
    UIAssert (UILayerNode.mainUI.layerPanels.count==10) "Ten layer headers mounted"
    UIAssert ((for p in UILayerNode.mainUI.layerPanels where p.children.count!=0 collect p).count==0) "Closed layers remain lazy"
    UILayerNode.mainUI.roots[4].open=true
    UILayerNode.mainUI.layoutPanels()
    CSPWriteText (RIDir+"ui-setup.json") (CSPObject #(#("checks",UIChecks),#("summary",UILayerNode.mainUI.roots[4].statsTotal.text),#("detail",UILayerNode.mainUI.roots[4].statsDetail.text)))
)
