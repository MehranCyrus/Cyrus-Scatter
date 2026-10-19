(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/library-surface0861-*/" do throw "Owned profile required"
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"extra-phase.txt"),log=createFile (MCPFixtureDir+"extra-"+phase+".txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 fn counters root node=(local retained=cyrusRetainedStats (CyrusPointOwner node);#(root.procEpoch,root.groupBuilds,(for leaf in root.layerObjects collect #(leaf.procPreparedBuilds,leaf.procReceiverBuilds,leaf.previewBuildCount)),#(retained[4],retained[5],retained[6],retained[7]),cyrusPlacementTransportStats()))
 try(
  case phase of (
   "rollback":(
    for d in #(CyrusRecipeBrowser,CyrusReadyPresetEditor,CyrusRecipeSaveEditor,CyrusPresetSaveEditor) where d!=undefined do destroyDialog d
    local package=cyrusAssetPackageRead SPackage,document=cyrusRecipeRead (pathConfig.appendPath SPackage "entry.csrecipe.json"),plan=(CyrusPresetPlan undefined SPackage package document surface:STerrain)[1]
    local before=objects as array,beforeLayers=SRoot.layerObjects as array,beforeHash=cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows,rejected=false
    global LOriginalApply=CyrusRecipeApplySettings,LApplyCalls=0
    fn LFailApply owner settings bindings variation:#new = (
      LApplyCalls+=1
      if LApplyCalls==3 do throw "Owned failure after setup and first layer creation"
      LOriginalApply owner settings bindings variation:variation
    )
    CyrusRecipeApplySettings=LFailApply
    try(CyrusAssetImport plan)catch(rejected=matchPattern (getCurrentException()) pattern:"*Owned failure*")
    CyrusRecipeApplySettings=LOriginalApply
    check (rejected and LApplyCalls==3) "Late failure reaches new setup and first layer creation" log
    check (CyrusPresetSameValues before (objects as array)) "Late rollback removes all created setup/source/path nodes" log
    check (CyrusPresetSameValues beforeLayers (SRoot.layerObjects as array) and (cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows)==beforeHash) "Late rollback preserves preceding layers/publication" log
    check (not theHold.Holding()) "Late failure leaves no stranded Undo hold" log
    local stage=CyrusAssetOwnStage(),material=standardMaterial diffuse:(color 72 150 44) specularLevel:12
    try(
      local context=CyrusAssetCaptureContext directory:stage[1]
      check ((CyrusAssetMaterial context material)!=undefined) "Canonical Standard colors/specular settings save despite host aliases" log
      material.shaderType=5;rejected=false
      try(CyrusAssetMaterial (CyrusAssetCaptureContext directory:stage[1]) material)catch(rejected=true)
      check rejected "Unsupported shader remains rejected after alias correction" log
      CyrusAssetRemoveStage stage
    )catch(CyrusAssetRemoveStage stage;throw())
   )
   "deleted":(
    global LDeletedBefore=objects as array,LTemporary=plane name:"Temporary receiver" width:1000 length:1000 widthsegs:12 lengthsegs:12
    CyrusOpenReadyPreset undefined SPackage surface:LTemporary
    with undo off delete LTemporary
   )
   "verifyDeleted":(
    check (CyrusReadyPresetEditor.finished and not matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Deleting captured target rejects pending import" log
    check (CyrusPresetSameValues LDeletedBefore (objects as array)) "Deleted-target failure creates no Scatter/assets" log
    destroyDialog CyrusReadyPresetEditor
   )
   "browserRace":(
    global LRaceA=plane name:"First captured receiver" width:1000 length:1000 widthsegs:12 lengthsegs:12
    global LRaceB=plane name:"Reopened receiver" width:1000 length:1000 widthsegs:12 lengthsegs:12 pos:[3000,0,0]
    CyrusOpenRecipeLibrary undefined surface:LRaceA
    CyrusOpenReadyPreset undefined (io.ReadAllText (MCPFixtureDir+"meadow-package.txt")) surface:LRaceA
    CyrusOpenRecipeLibrary undefined surface:LRaceB
   )
   "verifyBrowserRace":(
    check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "First captured operation finishes after browser reopening" log
    check (CyrusRecipeBrowser.surface==LRaceB and CyrusRecipeBrowser.root==undefined) "Late callback cannot bind the newly opened browser to the preceding setup" log
    for owner in CyrusReadyPresetEditor.root.layerObjects do check (CyrusPresetSameValues (owner.validSurfaces()) #(LRaceA)) "First operation retains its own captured terrain" log
    destroyDialog CyrusReadyPresetEditor
    CyrusOpenReadyPreset undefined (io.ReadAllText (MCPFixtureDir+"meadow-package.txt")) surface:LRaceB
   )
   "verifyReopenedLoad":(
    check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "New browser's own load succeeds" log
    check (CyrusRecipeBrowser.root==CyrusReadyPresetEditor.root and CyrusRecipeBrowser.surface==LRaceB) "Only the matching browser binds its newly created owner" log
    for owner in CyrusRecipeBrowser.root.layerObjects do check (CyrusPresetSameValues (owner.validSurfaces()) #(LRaceB)) "Reopened browser loads onto its own terrain" log
    destroyDialog CyrusReadyPresetEditor
   )
   "macro":(
    select STerrain
    fileIn (io.ReadAllText (MCPFixtureDir+"macro-path.txt"))
    macros.run "Cyrus" "CyrusScatterLibrary"
    check (CyrusRecipeBrowser!=undefined and CyrusRecipeBrowser.surface==STerrain and CyrusRecipeBrowser.root==SRoot) "Actual Cyrus Library action binds the selected terrain's owner" log
   )
   "idleStart":(global LFullIdle=counters SRoot SNode)
   "idleEnd":(check (CyrusPresetSameValues LFullIdle (counters SRoot SNode)) "Passive gallery has zero solves, receiver/preparation rebuilds, buffer uploads or bulk script materialization" log)
  )
  format "PASS: complete\n" to:log;close log
 )catch(
  if phase=="rollback" and LOriginalApply!=undefined do CyrusRecipeApplySettings=LOriginalApply
  format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
 )
)
