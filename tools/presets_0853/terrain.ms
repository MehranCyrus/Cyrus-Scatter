(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-presets0853-recipient-*/" do throw "Owned recipient required"
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"terrain-phase.txt"),log=createFile (MCPFixtureDir+"terrain-"+phase+".txt")
 fn check ok text log=(format "%: %\n" (if ok then "PASS" else "FAIL") text to:log;flush log;if not ok do throw text)
 try (
  if phase=="missing" then (
   if CyrusRecipeBrowser!=undefined do destroyDialog CyrusRecipeBrowser
   with undo off (
    global TerrainTestNode=AminScatterObject name:"Owned missing-channel destination",TerrainTestRoot=TerrainTestNode.baseObject
    TerrainTestRoot.updateMode=1;TerrainTestRoot.newLayer();local leaf=TerrainTestRoot.selectedLayer()
    global TerrainTestGround=plane name:"Existing terrain without channel 2" width:1500 length:1500 widthsegs:2 lengthsegs:2
    local source=pyramid width:10 depth:10 height:20 pos:[3000,0,0]
    TerrainTestRoot.setLayerSurfaces leaf #(TerrainTestGround);leaf.sources=#(source);leaf.ensureSourceRows();leaf.amount=60;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
    TerrainTestRoot.refreshAll()
   )
   global TerrainBeforeRow=cyrusRecipePublicationFingerprint TerrainTestRoot.groupSnapshotRows
   CyrusOpenReadyPreset TerrainTestRoot (io.ReadAllText (MCPFixtureDir+"preset-path.txt"))
  ) else if phase=="checkMissing" then (
   check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Required-channel preset loads successfully on a setup without channel 2" log
   check (findString CyrusReadyPresetEditor.status.text "Included terrain: saved Paint or mesh-channel data"!=undefined) "Missing channel chooses and reports included terrain" log
   check (TerrainTestRoot.layerObjects.count==4 and TerrainTestRoot.layerObjects[1].surfaceNodes[1]==TerrainTestGround) "Existing terrain/layer remains owned and unchanged" log
   check (TerrainBeforeRow==(cyrusRecipePublicationFingerprint #(TerrainTestRoot.groupSnapshotRows[1]))) "Existing full rows remain identical" log
   global TerrainAfterSettings=for leaf in TerrainTestRoot.layerObjects collect CyrusStyleSnapshot leaf
   format "DIRTY immediate: %\n" (for leaf in TerrainTestRoot.layerObjects collect leaf.dirty) to:log
   destroyDialog CyrusReadyPresetEditor
  ) else if phase=="settled" then (
   format "DIRTY settled: %\n" (for leaf in TerrainTestRoot.layerObjects collect leaf.dirty) to:log
   check ((for leaf in TerrainTestRoot.layerObjects where leaf.dirty collect leaf).count==0) "Delayed node notifications do not leave the loaded preset pending" log
   for i=1 to TerrainTestRoot.layerObjects.count do check (CyrusPresetSameValues TerrainAfterSettings[i] (CyrusStyleSnapshot TerrainTestRoot.layerObjects[i])) "Authored values stay stable after the load tick" log
  ) else if phase=="valid" then (
   global TerrainValidBefore=PresetTestRoot.layerObjects.count
   PresetTestRoot.refreshAll();CyrusOpenReadyPreset PresetTestRoot (io.ReadAllText (MCPFixtureDir+"preset-path.txt"))
  ) else if phase=="checkValid" then (
   check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Required-channel preset loads onto a compatible existing receiver" log
   check (findString CyrusReadyPresetEditor.status.text "Current terrain:"!=undefined and PresetTestRoot.layerObjects.count==TerrainValidBefore+3) "Compatible channel 2 reuses terrain and adds three layers" log
   destroyDialog CyrusReadyPresetEditor
  ) else if phase=="liveCount" then (
   with undo off (global TerrainLiveNode=AminScatterObject name:"Owned single Live solve",TerrainLiveRoot=TerrainLiveNode.baseObject)
   global TerrainLiveBefore=TerrainLiveRoot.groupBuilds
   CyrusOpenReadyPreset TerrainLiveRoot (io.ReadAllText (MCPFixtureDir+"preset-path.txt"))
  ) else if phase=="checkLiveCount" then (
   check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Live Load + Update succeeds" log
   check (TerrainLiveRoot.groupBuilds==TerrainLiveBefore+1) "Live preset load performs one placement solve" log
   check ((for leaf in TerrainLiveRoot.layerObjects where leaf.dirty collect leaf).count==0 and not CyrusPointSuspended) "Live preset is current and display suspension is released" log
   format "BUILDS: % -> %\n" TerrainLiveBefore TerrainLiveRoot.groupBuilds to:log
   destroyDialog CyrusReadyPresetEditor
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
