-- Additional adversarial witnesses, only in the owned reliability profile.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/" do throw "Owned reliability profile required"
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"edge-phase.txt")
 local log=createFile (MCPFixtureDir+"edge-"+phase+".txt")
 fn check ok message log=(format "%: %\n" (if ok then "PASS" else "FAIL") message to:log;flush log;if not ok do throw message)
 fn fingerprint=(cyrusRecipePublicationFingerprint ERoot.groupSnapshotRows)
 try(case phase of (
  "setup":(
   global ENode,ERoot,ELayer,ETerrain,EA,EB,EHash,ECount,EOwners,ENodes
   CyrusClearMeshMaskPreview undefined;CyrusPointSuspended=true;CyrusPerfHeadless=false
   with undo off (
    resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.
    ETerrain=plane name:"Edge receiver" width:2000 length:3000 widthsegs:7 lengthsegs:9
    EA=box name:"First source" width:10 length:10 height:20;EB=sphere name:"Second source" radius:10
    EA.isHidden=true;EB.isHidden=true
    ENode=AminScatterObject name:"Edge scatter";ERoot=ENode.baseObject;ERoot.updateMode=1;ERoot.newLayer()
    ELayer=ERoot.selectedLayer();ERoot.setLayerSurfaces ELayer #(ETerrain)
    ELayer.sources=#(EA,EB);ELayer.sourceWeights=#(1.,1.);ELayer.sourceRadiiWU=#(0.,0.);ELayer.amount=1000
    ELayer.procSelfOverride=true;ELayer.procSelfEnabled=false;ELayer.procLayerSelfEnabled=false
   )
   select ENode;max modify mode;ERoot.bindNativeUI();ERoot.refreshAll()
   check (ERoot.groupSnapshotRows[1].count==1000) "Two source pool starts valid" log
  )
  "mount":(ERoot.mainUI.slots[3].open=true;ERoot.mainUI.bindSection ERoot.mainUI.editors[3])
  "leadingSource":(
   local page=ERoot.mainUI.editors[3];page.sourceUI_plantList.selection=#{1};page.sourceUI_removePlant.pressed()
   ERoot.refreshAll();ERoot.evaluateProcedural()
   check (ELayer.sources.count==1 and ELayer.sources[1]==EB and ERoot.groupSnapshotRows[1].count==1000 and ELayer.previewError=="") "Removing the leading source reindexes remaining placements and display" log
   page=ERoot.mainUI.editors[3];page.sourceUI_plantList.selection=#{1};page.sourceUI_removePlant.pressed();ERoot.refreshAll()
   check (ELayer.sources.count==0 and ERoot.groupSnapshotRows[1].count==0 and ELayer.cachedPointCount==0) "Removing remaining source clears display" log
   check (saveMaxFile (MCPFixtureDir+"edge-empty.max") quiet:true) "Empty source scene saves" log
  )
  "emptyReopen":(loadMaxFile (MCPFixtureDir+"edge-empty.max") quiet:true;ENode=getNodeByName "Edge scatter";ERoot=ENode.baseObject;ELayer=ERoot.layerObjects[1];ETerrain=getNodeByName "Edge receiver")
  "gap":(
   ERoot.refreshAll();ERoot.evaluateProcedural()
   check (ELayer.sources.count==0 and ERoot.groupSnapshotRows[1].count==0 and ELayer.previewError=="") "Empty publication survives save/reopen" log
   ELayer.sources=#(undefined);ELayer.sourcePoint=#(false);ELayer.sourceEmpty=#(true);ELayer.sourceWeights=#(1.);ELayer.sourceRadiiWU=#(0.)
   ELayer.markInputDirty();ERoot.refreshAll();ERoot.evaluateProcedural()
   check ((ELayer.validSources()).count==1 and ERoot.groupSnapshotRows[1].count==0 and ELayer.previewError=="") "Explicit Empty gap remains an authored source role with no visible plants" log
   ELayer.sourcePoint=#(true);ELayer.markInputDirty();ERoot.refreshAll()
   check (ERoot.groupSnapshotRows[1].count==1000 and ELayer.previewError=="") "Converting the gap to Point restores visible placements" log
  )
  "mapBudget":(
   local terrain=plane name:"Budget receiver" width:100 length:100 widthsegs:1 lengthsegs:1
   convertToMesh terrain;meshop.setNumMaps terrain 26 keep:true
   for channel=2 to 25 do (meshop.setMapSupport terrain channel true;meshop.setNumMapVerts terrain channel 1000000 keep:false)
   local failed=false,reason="",map=Checker()
   try(cyrusReceiverMapKey terrain map)catch(failed=true;reason=getCurrentException())
   format "EXPECTED: %\n" reason to:log
   check (failed and findString reason "256 MiB"!=undefined) "Unused channel arrays count toward bounded receiver-map memory" log
   delete terrain;gc light:false
   check ((cyrusReceiverMapSample ETerrain (Checker color1:white color2:white) 1 [.2,.3,.5])==1) "A supported replacement receiver works after resource rejection" log
  )
  "load":(
   EHash=fingerprint();ECount=objects.count;EOwners=ERoot.layerObjects as array;ENodes=objects as array
   CyrusOpenReadyPreset ERoot (io.ReadAllText (MCPFixtureDir+"edge-package.txt")) surface:ETerrain
  )
  "poll":(
   local state=if CyrusReadyPresetEditor.finished then (if matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*" then "ready" else "error") else "pending"
   io.WriteAllText (MCPFixtureDir+"edge-state.txt") state
   format "STATE: %\nSTATUS: %\n" state CyrusReadyPresetEditor.status.text to:log
  )
  "failure":(
   local reason=CyrusReadyPresetEditor.status.text
   check (CyrusReadyPresetEditor.finished and CyrusReadyPresetEditor.result==undefined and findString reason "-- Runtime error:"==undefined) "Rejected import gives a clean explanation" log
   format "EXPECTED: %\n" reason to:log
   check (fingerprint()==EHash and objects.count==ECount and CyrusPresetSameValues (ERoot.layerObjects as array) EOwners) "Rejected import retains exact publication, owners and node count" log
   check ((for node in ENodes where not isValidNode node collect node).count==0) "Rejected import preserves all preceding nodes" log
   destroyDialog CyrusReadyPresetEditor
  )
  "success":(
   check (CyrusReadyPresetEditor.result!=undefined and ERoot.layerObjects.count>EOwners.count) "Repeated import adds new independent owners" log
   check (ELayer==ERoot.layerObjects[1] and ERoot.groupSnapshotRows[1].count==1000 and ELayer.previewError=="") "Repeated import retains the preceding layer" log
   destroyDialog CyrusReadyPresetEditor
  )
  default:throw "Unknown edge phase"
 );format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
