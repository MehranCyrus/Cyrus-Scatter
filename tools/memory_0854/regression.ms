(
 if not matchPattern MCPFixtureDir pattern:"*/foundation-memory0854-*/" do throw "Owned memory host required"
 local phase=(dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"regression-phase.txt")
 case phase of (
  "copy": (
   CyrusPerfHeadless=false
   with undo off (
    resetMaxFile #noPrompt
    local terrain=plane name:"Owned flat receiver" length:1000 width:1000 lengthsegs:2 widthsegs:2
    local model=pyramid name:"Owned pyramid" width:1 depth:1 height:2
    MFNode=AminScatterObject name:"Owned copy memory test";MFRoot=MFNode.baseObject;MFRoot.updateMode=1
    MFRoot.newLayer();MFLayer=MFRoot.selectedLayer();MFRoot.setLayerSurfaces MFLayer #(terrain);MFLayer.sources=#(model);MFLayer.sourceWeights=#(1.0)
    MFLayer.amount=30000;MFLayer.sourceRadiiWU=#(0.0);MFLayer.procSelfOverride=true;MFLayer.procSelfEnabled=false;MFLayer.procLayerSelfEnabled=false
    MFRoot.copyLogicalLayer MFLayer variation:#new
    MFRoot.refreshAll()
   )
   MFCheck (CyrusPresetSameValues (for rows in MFRoot.groupSnapshotRows collect rows.count) #(30000,30000)) "Two 30000 layers publish 60000 placements"
   global MFCopyBefore=MFHash(),MFCopyLayers=MFRoot.layerObjects as array
   local t=timeStamp();MFRoot.copyLogicalLayer MFLayer variation:#new;MFRoot.refreshAll()
   MFState "copy-60000-to-90000";format "COPY_TIME %\n" (timeStamp()-t) to:MFLog
   MFCheck (CyrusPresetSameValues (for rows in MFRoot.groupSnapshotRows collect rows.count) #(30000,30000,30000)) "Layer Copy publishes 90000 placements with Undo intact"
   global MFCopyAfter=MFHash()
  )
  "copyUndo": (max undo)
  "checkCopyUndo": (
   MFCheck (CyrusPresetSameValues MFCopyLayers (MFRoot.layerObjects as array)) "Copy Undo restores exact ownership"
   MFRoot.refreshAll();MFCheck (MFHash()==MFCopyBefore) "Manual Update after Copy Undo restores 60000 full rows"
  )
  "copyRedo": (max redo)
  "checkCopyRedo": (
   MFRoot.refreshAll();MFCheck (MFHash()==MFCopyAfter and MFRoot.layerObjects.count==3) "Manual Update after Copy Redo restores 90000 full rows"
  )
  "radii": (
   with undo off (
    MFLayer.sourceAutoRadius=#(false)
    MFRoot.layerObjects[2].amount=500;MFRoot.layerObjects[3].amount=500;MFLayer.amount=500
    MFLayer.setSourceRadius #(1) 8.0;MFLayer.procSelfEnabled=true;MFLayer.procLayerSelfEnabled=true
    MFLayer.setSourceRadius #(1) true kind:3
    MFRoot.refreshAll()
   )
   MFCheck (MFLayer.previewError=="" and MFLayer.generatedCount>0) "Manual radius spacing and radius display publish"
   local radii=MFRoot.procPublishedRadii[1]
   MFCheck (radii.count==MFRoot.groupSnapshotRows[1].count and radii.count>0 and radii[1][1]==8.0) "Native radius count and bounded indexing work"
   MFCheck (cyrusPreviewRadiiEqual radii radii) "Native radius preview comparison works"
   MFCheck (not cyrusPreviewRadiiEqual radii #()) "Radius comparison detects different lengths"
   local validSpacing=true
   for i=1 to MFRoot.groupSnapshotRows[1].count do for j=i+1 to MFRoot.groupSnapshotRows[1].count where distance MFRoot.groupSnapshotRows[1][i][1].row4 MFRoot.groupSnapshotRows[1][j][1].row4<15.999 do validSpacing=false
   MFCheck validSpacing "Independent spacing distance oracle"
   with undo off (MFLayer.sources=#(box name:"Owned qualified Auto source" width:1 length:1 height:2);MFLayer.setSourceRadius #(1) true kind:4)
   MFRoot.refreshAll();MFCheck (MFLayer.previewError=="") "Auto radius path publishes"
   local edit=CyrusScatterEdit();addModifier MFNode edit;MFRoot.refreshAll()
   cyrusEditSelect edit #(1,2);cyrusEditCommand edit 4 (transMatrix [0,0,2]);MFRoot.refreshAll()
   MFCheck ((for row in MFRoot.groupSnapshotRows[1] where row[7] collect row).count==2) "Active Edit retains two protected transforms"
   MFLayer.procSelectedRadius 1 3.0;MFRoot.refreshAll();MFCheck (MFLayer.previewError=="") "Selected Edit radius override publishes"
   global MFSaveHash=MFHash()
   MFCheck (saveMaxFile (MCPFixtureDir+"radius-edit.max") quiet:true) "Native transient buffers excluded from valid scene save"
  )
  "reopen": (
   loadMaxFile (MCPFixtureDir+"radius-edit.max") quiet:true useFileUnits:true
   MFNode=getNodeByName "Owned copy memory test";MFRoot=MFNode.baseObject;MFLayer=MFRoot.layerObjects[1]
   MFRoot.refreshAll();MFCheck (MFHash()==MFSaveHash) "Scene reopen restores exact Edit/radius placement rows"
  )
  "release": (
   MFState "before-owned-reset"
   resetMaxFile #noPrompt
   MFRoot=undefined;MFNode=undefined;MFLayer=undefined;MFCopyLayers=undefined
   gc light:true
   local buffers=cyrusScriptBufferStats();format "RELEASE buffers=%\n" buffers to:MFLog
   MFCheck (buffers[1]==0 and buffers[3]==0) "Native schedules and radius owners release after scene/history lifecycle"
  )
  default: throw "Unknown regression phase"
 )
 flush MFLog
)
