-- Fresh owned Max 2027 scenes only. Requests are serialized by the host driver.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/" do throw "Owned reliability profile required"
 local phase=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"reliability-phase.txt")
 local log=createFile (MCPFixtureDir+"lifecycle-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  case phase of (
   "setup":(
    global RNode,RRoot,RLayer,RTerrain,RModel,RHash,RWindow,RSize,RPosition
    CyrusClearMeshMaskPreview undefined;CyrusPerfHeadless=false;CyrusPointSuspended=true
    with undo off (
     resetMaxFile #noPrompt
     RTerrain=plane name:"Reliability receiver" width:1000 length:1000 widthsegs:1 lengthsegs:1
     RModel=pyramid name:"Reliability model" width:10 depth:10 height:30 pos:[-600,0,0];RModel.isHidden=true
     RNode=AminScatterObject name:"Reliability lifecycle";RRoot=RNode.baseObject;RRoot.updateMode=1
     RRoot.newLayer();RLayer=RRoot.selectedLayer();RRoot.setLayerSurfaces RLayer #(RTerrain)
     RLayer.sources=#(RModel);RLayer.sourceWeights=#(1.);RLayer.sourceRadiiWU=#(0.);RLayer.amount=200
     RLayer.procSelfOverride=true;RLayer.procSelfEnabled=false;RLayer.procLayerSelfEnabled=false
    )
    select RNode;max modify mode;RRoot.bindNativeUI()
   )
   "mount":(
    RRoot.mainUI.slots[3].open=true;RRoot.mainUI.bindSection RRoot.mainUI.editors[3]
    RRoot.refreshAll();RHash=cyrusRecipePublicationFingerprint RRoot.groupSnapshotRows
    check (RRoot.groupSnapshotRows[1].count==200 and RLayer.previewError=="") "Model starts with 200 valid placements" log
   )
   "remove":(
    local page=RRoot.mainUI.editors[3]
    check (page.sourceUI_obj==RLayer) "Actual Models page owns the target layer" log
    page.sourceUI_plantList.selection=#{1};page.sourceUI_removePlant.pressed()
    check (RLayer.sources.count==0 and RRoot.groupSnapshotRows[1].count==200) "Manual removal retains publication pending Update" log
    RRoot.refreshAll();RRoot.evaluateProcedural()
    check (RRoot.groupSnapshotRows[1].count==0 and RLayer.cachedPointCount==0 and RLayer.previewError=="") "Removing last model publishes empty placements/display without source index error" log
    with undo off RLayer.amount=5000
    RRoot.refreshAll();RRoot.evaluateProcedural()
    check (RRoot.groupSnapshotRows[1].count==0 and RLayer.previewError=="") "Changing Amount with no sources remains valid and empty" log
   )
   "undo":(max undo)
   "verifyUndo":(
    check (RLayer.sources.count==1 and RLayer.sources[1]==RModel) "Undo restores removed source" log
    with undo off RLayer.amount=200
    RRoot.refreshAll();check (cyrusRecipePublicationFingerprint RRoot.groupSnapshotRows==RHash) "Undo restores exact original placements" log
   )
   "redo":(max redo)
   "verifyRedo":(
    RRoot.refreshAll();check (RLayer.sources.count==0 and RRoot.groupSnapshotRows[1].count==0 and RLayer.previewError=="") "Redo clears placements and display again" log
   )
   "point":(
    RRoot.mainUI.editors[3].sourceUI_addPoint.pressed();RRoot.refreshAll()
    check ((RLayer.validSources()).count==1 and RRoot.groupSnapshotRows[1].count==200 and RLayer.previewError=="") "Explicit Point source still produces placements" log
   )
   "replace":(
    with undo off (RLayer.sources=#(RModel);RLayer.sourcePoint=#(false);RLayer.sourceEmpty=#(false))
    RLayer.markInputDirty();RRoot.refreshAll()
    check (RRoot.groupSnapshotRows[1].count==200 and RLayer.previewError=="") "Replacement model restores valid geometry" log
    RRoot.updateMode=2;CyrusPointSuspended=false
    delete RModel
   )
   "verifyDelete":(
    check ((RLayer.validSources()).count==0 and RRoot.groupSnapshotRows[1].count==0 and RLayer.previewError=="") "Deleting the actual model node clears Live placements" log
   )
   "emptyEdges":(
    RRoot.updateMode=1;CyrusPointSuspended=true
    RLayer.meshMaskEnabled=true;RLayer.meshMaskSource=1;RLayer.meshMaskChannel=99
    RLayer.placementMode=2;RLayer.gridColumnWU=0.0001;RLayer.gridRowWU=0.0001
    RLayer.containerMode=4;RLayer.containerNodes=#()
    RRoot.refreshAll();RRoot.evaluateProcedural()
    check (RRoot.groupSnapshotRows[1].count==0 and RLayer.cachedPointCount==0 and RLayer.previewError=="") "Empty source pool ignores missing channel and oversized grid without retaining instances" log
    RLayer.containerMode=1;RModel=box name:"Restored source" width:10 length:10 height:30 pos:[-600,0,0];RModel.isHidden=true
    RLayer.sources=#(RModel);local failed=false
    try(RRoot.evaluateProcedural())catch(failed=true)
    check (failed and RRoot.groupSnapshotRows[1].count==0) "Replacement source validates retained incompatible inputs before publication" log
    RLayer.meshMaskEnabled=false;RLayer.placementMode=1;RRoot.refreshAll();RRoot.evaluateProcedural()
    check (RRoot.groupSnapshotRows[1].count==200 and RLayer.previewError=="") "Repairing inputs restores the replacement model" log
   )
   "libraryOpen":(
    CyrusOpenRecipeLibrary RRoot
   )
   "libraryMinimize":(
    RWindow=CyrusRecipeBrowser.hwnd;RSize=getDialogSize CyrusRecipeBrowser;RPosition=getDialogPos CyrusRecipeBrowser
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"library-window.txt") (RWindow as string)
    check (RSize.x>=900 and RSize.y>=600) "Library opens at usable normal size" log
    windows.sendMessage RWindow 0x112 0xF020 0
   )
   "libraryRestore":(
    CyrusOpenRecipeLibrary RRoot
    check (CyrusRecipeBrowser.hwnd==RWindow) "Recipes reuses the existing minimized window" log
    check ((getDialogSize CyrusRecipeBrowser)==RSize and (getDialogPos CyrusRecipeBrowser)==RPosition) "Recipes restores the normal window size and position" log
    CyrusOpenRecipeLibrary RRoot
    check (CyrusRecipeBrowser.hwnd==RWindow) "Repeated Recipes focuses the same open window" log
   )
   "libraryContext":(
    local previous=CyrusRecipeBrowser.sessionID,other=plane name:"Second Library destination" width:500 length:700
    local otherNode=AminScatterObject name:"Second Library owner",otherRoot=otherNode.baseObject
    otherRoot.newLayer();otherRoot.setLayerSurfaces (otherRoot.selectedLayer()) #(other)
    windows.sendMessage RWindow 0x112 0xF020 0
    CyrusOpenRecipeLibrary otherRoot surface:other
    check (CyrusRecipeBrowser.hwnd==RWindow and CyrusRecipeBrowser.root==otherRoot and CyrusRecipeBrowser.surface==other) "Restored Library binds the newly requested owner and terrain" log
    check (CyrusRecipeBrowser.sessionID!=previous) "Changed destination invalidates the preceding Library callback context" log
    destroyDialog CyrusRecipeBrowser
   )
   "libraryReopen":(CyrusOpenRecipeLibrary RRoot)
   "libraryVerifyReopen":(
    local size=getDialogSize CyrusRecipeBrowser
    check (size.x>=900 and size.y>=600) "Closed Library reopens at usable size" log
    destroyDialog CyrusRecipeBrowser
   )
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
