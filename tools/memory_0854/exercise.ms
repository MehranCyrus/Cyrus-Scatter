(
if not matchPattern MCPFixtureDir pattern:"*/foundation-memory0854-*/" do throw "Owned memory host required"
local io=dotNetClass "System.IO.File",phase=io.ReadAllText(MCPFixtureDir+"phase.txt")
case phase of (
 "undo": (max undo)
 "checkUndo": (
  MFState "after-undo";MFCheck (MFLayer.amount==5000 and MFHash()==MFBefore) "Undo restores settings and exact complete rows"
  MFCheck ((theHold.GetRedoNames()).count>0) "Redo available"
 )
 "redo": (max redo)
 "checkRedo": (
  MFState "after-redo";MFCheck (MFLayer.amount==50000 and MFHash()=="35c2706213cb957417417b6f1338fd0c9d3b02011ccfbff33b8bb630855c9c89") "Redo restores exact 50000 publication"
 )
 "counts": (
  MFHashes=#()
  for amount in #(30000,90000,200000,5000,50000,90000,200000,5000) do (
   MFCount amount
   local prior=for pair in MFHashes where pair[1]==amount collect pair[2]
   if prior.count>0 then MFCheck (MFHash()==prior[1]) "Repeated Count exact rows" else append MFHashes #(amount,MFHash())
  )
 )
 "manual": (
  MFRoot.mainUI.updateRadio.state=1;MFRoot.mainUI.updateRadio.changed 1
  global MFManualRows=MFHash(),MFManualEpoch=MFRoot.procEpoch
  MFRoot.populationUI.distributionUI_countSpin.value=50000;MFRoot.populationUI.distributionUI_countSpin.changed 50000
  MFCheck (MFRoot.procEpoch==MFManualEpoch and MFHash()==MFManualRows and MFLayer.requestedCount==5000) "Manual edit keeps old output without calculation"
  MFRoot.mainUI.updateNow.pressed()
  MFState "manual-update";MFCheck (MFLayer.previewError=="" and MFHash()=="35c2706213cb957417417b6f1338fd0c9d3b02011ccfbff33b8bb630855c9c89") "Explicit Update publishes complete requested result"
 )
 "failure": (
  MFRoot.mainUI.updateRadio.state=2;MFRoot.mainUI.updateRadio.changed 2
  global MFReserveOriginal=CyrusReserveScriptWorkspace,MFFailedRows=MFHash(),MFFailedEpoch=MFRoot.procEpoch,MFUndoCount=(theHold.GetUndoNames()).count
  fn CyrusReserveScriptWorkspace required=(throw "Owned injected reservation failure")
  MFRoot.populationUI.distributionUI_countSpin.value=90000;MFRoot.populationUI.distributionUI_countSpin.changed 90000
  CyrusReserveScriptWorkspace=MFReserveOriginal
  MFState "reservation-failure"
  MFCheck (MFHash()==MFFailedRows and MFRoot.procEpoch==MFFailedEpoch) "Failed successor retains full previous publication"
  MFCheck ((theHold.GetUndoNames()).count>=MFUndoCount and matchPattern MFLayer.previewError pattern:"*Owned injected*") "Reservation failure retains Undo and explains error"
 )
 "recover": (
  MFCheck (MFLayer.amount==50000 and MFHash()==MFFailedRows and MFLayer.previewError=="") "Undo of failed edit restores complete valid state"
  MFCount 90000
 )
 "stagedFailure": (
  global MFStagedRows=MFHash(),MFStagedEpoch=MFRoot.procEpoch,MFStagedUndo=(theHold.GetUndoNames()).count,MFStagedRadius=MFLayer.procRadiusIDs as array
  with undo off MFLayer.procRadiusIDs=#("owned-invalid-radius-metadata")
  MFRoot.populationUI.distributionUI_countSpin.value=50000;MFRoot.populationUI.distributionUI_countSpin.changed 50000
  with undo off MFLayer.procRadiusIDs=MFStagedRadius
  MFState "after-candidate-preparation-failure"
  MFCheck (MFLayer.previewError!="" and MFHash()==MFStagedRows and MFRoot.procEpoch==MFStagedEpoch and (theHold.GetUndoNames()).count>=MFStagedUndo) "Invalid radius metadata after preparation retains prior full publication and Undo"
 )
 "stagedRecovery": (
  MFCheck (MFLayer.amount==90000 and MFHash()==MFStagedRows and MFLayer.previewError=="") "Undo recovers staged failure"
 )
 "passive": (
  global MFPassiveStats=#(MFRoot.procEpoch,MFRoot.groupBuilds,for leaf in MFRoot.layerObjects collect #(leaf.procPreparedBuilds,leaf.procReceiverBuilds,leaf.previewBuildCount),cyrusRetainedStats (CyrusPointOwner MFNode)),MFPassiveHash=MFHash(),MFPassiveReserved=CyrusScriptWorkspaceReserved
  local times=#()
  for cycle=1 to 3 do for slot in MFRoot.mainUI.slots do (
   local t=timeStamp();slot.open=true;slot.rolledUp false;slot.open=false;slot.rolledUp true;append times (timeStamp()-t)
  )
  format "PANEL_HANDLER_MS %\n" times to:MFLog
  MFCheck (MFRoot.procEpoch==MFPassiveStats[1] and MFRoot.groupBuilds==MFPassiveStats[2] and MFHash()==MFPassiveHash and CyrusScriptWorkspaceReserved==MFPassiveReserved) "Panel opening keeps placement and workspace unchanged"
  MFCheck (CyrusPresetSameValues MFPassiveStats[3] (for leaf in MFRoot.layerObjects collect #(leaf.procPreparedBuilds,leaf.procReceiverBuilds,leaf.previewBuildCount))) "Panel opening performs no receiver, preparation or preview builds"
 )
 "idleStart": (
  global MFIdleEpoch=MFRoot.procEpoch,MFIdleBuilds=MFRoot.groupBuilds,MFIdleRows=MFHash(),MFIdleStart=timeStamp(),MFIdleDisplay=cyrusRetainedStats (CyrusPointOwner MFNode),MFIdlePrepare=for leaf in MFRoot.layerObjects collect #(leaf.procPreparedBuilds,leaf.procReceiverBuilds,leaf.previewBuildCount)
  MFState "idle-start"
 )
 "idleEnd": (
  MFState "idle-end"
  format "IDLE_ELAPSED_MS %\n" (timeStamp()-MFIdleStart) to:MFLog
  MFCheck ((timeStamp()-MFIdleStart)>=60000) "At least 60 seconds idle observed"
  MFCheck (MFRoot.procEpoch==MFIdleEpoch and MFRoot.groupBuilds==MFIdleBuilds and MFHash()==MFIdleRows) "Idle has zero publication or placement builds"
  MFCheck (CyrusPresetSameValues MFIdlePrepare (for leaf in MFRoot.layerObjects collect #(leaf.procPreparedBuilds,leaf.procReceiverBuilds,leaf.previewBuildCount))) "Idle has zero preparation, receiver or preview builds"
  local display=cyrusRetainedStats (CyrusPointOwner MFNode)
  MFCheck (display[4]==MFIdleDisplay[4] and display[6]==MFIdleDisplay[6]) "Idle retained geometry/upload counters unchanged"
 )
 default: throw "Unknown phase"
)
flush MFLog
)
