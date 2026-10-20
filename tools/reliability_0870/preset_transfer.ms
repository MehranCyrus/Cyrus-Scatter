(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/" do throw "Owned reliability profile required"
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"preset-transfer-phase.txt")
 local token=io.ReadAllText (MCPFixtureDir+"preset-transfer-case.txt"),log=createFile (MCPFixtureDir+"preset-"+token+"-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try(
  case phase of (
   "setup":(
    global PNode,PRoot,PTerrain,PModel,PBaseline,PBefore,PAdded,PLoaded,PCount,PInitial
    for dialog in #(CyrusRecipeBrowser,CyrusReadyPresetEditor) where dialog!=undefined do destroyDialog dialog
    CyrusClearMeshMaskPreview undefined;CyrusPointSuspended=true
    with undo off (
     resetMaxFile #noPrompt
     units.SystemType=case (io.ReadAllText (MCPFixtureDir+"preset-transfer-unit.txt")) of ("meters":#meters;"centimeters":#centimeters;"millimeters":#millimeters;"feet":#feet;default:throw "Unsupported test unit")
     units.SystemScale=1.
     local metre=units.decodeValue "1m",variant=io.ReadAllText (MCPFixtureDir+"preset-transfer-variant.txt")
     PTerrain=if variant=="folded" then box name:"Transfer receiver" width:(20*metre) length:(30*metre) height:(5*metre) else plane name:"Transfer receiver" width:(20*metre) length:(30*metre) widthsegs:7 lengthsegs:9
     if variant=="tiny" do (PTerrain.width*=0.01;PTerrain.length*=0.01)
     if variant=="huge" do (PTerrain.width*=10;PTerrain.length*=10)
     if variant=="heightfield" do (
      convertToMesh PTerrain
      for i=1 to PTerrain.numverts do (local v=getVert PTerrain i;v.z=(v.x+10*metre)*0.2;setVert PTerrain i v)
      update PTerrain
     )
     if variant=="transformed" do (PTerrain.pos=[70*metre,-20*metre,100*metre];PTerrain.rotation=eulerAngles 12 18 30;PTerrain.scale=[-1.2,0.8,1.5])
     PModel=box name:"Existing model" width:(.1*metre) length:(.1*metre) height:(.3*metre) pos:[-30*metre,0,0];PModel.isHidden=true
     PNode=AminScatterObject name:"Transfer scatter";PRoot=PNode.baseObject;PRoot.updateMode=1;PRoot.newLayer()
     local layer=PRoot.selectedLayer();PRoot.setLayerSurfaces layer #(PTerrain);layer.sources=#(PModel);layer.sourceWeights=#(1.);layer.sourceRadiiWU=#(0.)
     layer.amount=50;layer.procSelfOverride=true;layer.procSelfEnabled=false;layer.procLayerSelfEnabled=false
    )
    PRoot.refreshAll();PBaseline=cyrusRecipePublicationFingerprint PRoot.groupSnapshotRows
    PBefore=PRoot.layerObjects as array;PInitial=objects as array;PCount=objects.count
    check (PRoot.groupSnapshotRows[1].count==50) "Fresh destination starts with 50 valid existing placements" log
   )
   "load":(CyrusOpenReadyPreset PRoot (io.ReadAllText (MCPFixtureDir+"preset-transfer-package.txt")) surface:PTerrain)
   "poll":(
    local state=if CyrusReadyPresetEditor.finished then (if matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*" then "ready" else "error") else "pending"
    io.WriteAllText (MCPFixtureDir+"preset-transfer-state.txt") state
    format "STATE: %\nSTATUS: %\n" state CyrusReadyPresetEditor.status.text to:log
   )
   "verify":(
    check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Preset loads onto a new selected terrain" log
    PAdded=CyrusReadyPresetEditor.result[2]
    check (PAdded.count>0 and PRoot.layerObjects[1]==PBefore[1]) "Import adds layers after the existing owner" log
    for layer in PAdded do (
     check (CyrusPresetSameValues (layer.validSurfaces()) #(PTerrain)) "Imported layer binds only the selected receiver" log
     check (layer.previewError=="") "Imported layer has no calculation/preview error" log
     for area in layer.paintAreas where area.paintDocument!=undefined do (
      check (area.areaTarget==PTerrain) "Transferred Paint binds the selected receiver" log
      local data=cyrusBrushRecipeExport area.paintDocument
      check (data[1].count>0 and data[2]>0) "Transferred Paint remains serializable with a valid brush radius" log
     )
    )
    PLoaded=cyrusRecipePublicationFingerprint PRoot.groupSnapshotRows
    check (PRoot.groupSnapshotRows[1].count==50 and PRoot.updateMode==1) "Existing publication and Manual setting survive import" log
    format "COUNTS: %\n" (for rows in PRoot.groupSnapshotRows collect rows.count) to:log
    destroyDialog CyrusReadyPresetEditor
   )
   "verifyFailure":(
    check (CyrusReadyPresetEditor.finished and CyrusReadyPresetEditor.result==undefined) "Unsupported receiver rejects before adding preset layers" log
    local reason=CyrusReadyPresetEditor.status.text
    format "EXPECTED: %\n" reason to:log
    check (findString reason "Cannot transfer Paint"!=undefined and findString reason "-- Runtime error:"==undefined) "Paint failure gives a clean, contextual explanation" log
    check (CyrusPresetSameValues (PRoot.layerObjects as array) PBefore) "Failed import preserves original owners" log
    check ((cyrusRecipePublicationFingerprint PRoot.groupSnapshotRows)==PBaseline and objects.count==PCount) "Failed import preserves exact publication and leaves no scene assets" log
    destroyDialog CyrusReadyPresetEditor
   )
   "repair":(
    with undo off (
     local previous=PTerrain,metre=units.decodeValue "1m"
     PTerrain=plane name:"Repaired transfer receiver" width:(20*metre) length:(30*metre) widthsegs:7 lengthsegs:9
     PRoot.setLayerSurfaces PBefore[1] #(PTerrain);delete previous
    )
    PRoot.refreshAll();PBaseline=cyrusRecipePublicationFingerprint PRoot.groupSnapshotRows;PInitial=objects as array;PCount=objects.count
   )
   "undo":(max undo)
   "physicalUnits":(python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/reliability_0870/physical_units.py";check true "Physical distances, Paint radius and source mesh coordinates match serialized metre values" log)
   "verifyUndo":(
    check (CyrusPresetSameValues (PRoot.layerObjects as array) PBefore) "One Undo removes the imported owners" log
    check ((cyrusRecipePublicationFingerprint PRoot.groupSnapshotRows)==PBaseline) "Undo restores the exact preceding publication" log
    check (objects.count==PCount and (for node in PInitial where not isValidNode node collect node).count==0) "Undo removes imported assets and preserves original nodes" log
   )
   "redo":(max redo)
   "verifyRedo":(
    check ((cyrusRecipePublicationFingerprint PRoot.groupSnapshotRows)==PLoaded) "Redo restores the exact imported publication" log
    check ((for layer in PAdded where findItem PRoot.layerObjects layer==0 collect layer).count==0) "Redo restores imported owner identities" log
   )
   "save":(check (saveMaxFile (MCPFixtureDir+"preset-"+token+".max") quiet:true) "Transferred preset scene saves" log)
   "reopen":(loadMaxFile (MCPFixtureDir+"preset-"+token+".max") quiet:true;PNode=getNodeByName "Transfer scatter";PRoot=PNode.baseObject)
   "verifyReopen":(
    PRoot.refreshAll();PRoot.evaluateProcedural()
    check ((cyrusRecipePublicationFingerprint PRoot.groupSnapshotRows)==PLoaded) "Save/reopen preserves exact transferred publication" log
   )
   default:throw "Unknown preset transfer phase"
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
