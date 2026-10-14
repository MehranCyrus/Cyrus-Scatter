(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p02-*/" do throw "Owned P02 host required"
    local log=createFile (MCPFixtureDir+"phase02-lifecycle-final.txt")
    fn verify value label log = (
        format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log
        if not value do throw label
    )
    fn presetSnapshot root leaf = (
        for category in #("population","transforms","spacing") collect
            cyrusPresetEncode category "lifecycle" (CyrusPresetCapture (CyrusPresetMakeBinding root leaf category))
    )
    try (
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node=AminScatterObject name:"P02 persisted presets",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane name:"P02 persisted receiver" length:30 width:30 lengthsegs:1 widthsegs:1
        root.newLayer();local leaf=root.selectedLayer()
        root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=40
        local target=CyrusPresetMakeBinding root leaf "population",values=CyrusPresetCapture target
        values[1]=55;values[4]=8765;CyrusPresetApply target #("population","Population",values)
        target=CyrusPresetMakeBinding root leaf "transforms";values=CyrusPresetCapture target
        values[16]=0.2;values[17]=0.4;values[22]=0.8;values[23]=1.4
        CyrusPresetApply target #("transforms","Transforms",values)
        CyrusPresetApply (CyrusPresetMakeBinding root leaf "spacing") #("spacing","Spacing",#(false,1.7,0.25,true))
        local expected=presetSnapshot root leaf,sourceID=leaf.layerID
        local duplicate=root.copyLogicalLayer leaf
        verify ((presetSnapshot root duplicate) as string==expected as string and duplicate.layerID!=sourceID) "Layer copy retains applied settings with an independent identity" log
        duplicate.movXMinWU=0.1
        verify (abs(leaf.movXMinWU-0.2*(units.decodeValue "1m"))<0.0001) "Changing copied transforms leaves original values unchanged" log
        local scene=MCPFixtureDir+"P02_persisted_settings.max"
        saveMaxFile scene quiet:true
        local stale=CyrusPresetMakeBinding root leaf "population"
        loadMaxFile scene quiet:true useFileUnits:true
        node=getNodeByName "P02 persisted presets";root=node.baseObject;leaf=root.layerObjects[1]
        verify ((presetSnapshot root leaf) as string==expected as string) "All setting categories survive current-schema reopen" log
        local rejected=false
        try(CyrusPresetApply stale #("population","Stale",#(80,1,100,42,1,8,8,false)))catch(rejected=true)
        verify rejected "A binding captured before scene reopen is rejected" log
        root.refreshAll()
        verify (leaf.generatedCount==55 and leaf.previewError=="") "Reopened preset settings produce the intended result" log
        resetMaxFile #noPrompt
        mergeMAXFile scene #select #autoRenameDups quiet:true
        node=getNodeByName "P02 persisted presets";root=node.baseObject;leaf=root.layerObjects[1]
        verify ((presetSnapshot root leaf) as string==expected as string) "All setting categories survive merge" log
        root.refreshAll()
        verify (leaf.generatedCount==55 and leaf.previewError=="") "Merged receiver and source references remain usable" log
        verify (not theHold.Holding()) "Lifecycle test leaves no native transaction open" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
