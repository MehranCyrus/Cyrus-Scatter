if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-*/" do throw "Owned 0.85.4 memory host required."
global MFRoot,MFNode,MFLayer,MFFilters,MFLog,MFBefore,MFHashes=#(),MFStart
fn MFCheck yes message=(format "%: %\n" (if yes then "PASS" else "FAIL") message to:MFLog;flush MFLog;if not yes do throw message)
fn MFHash=(cyrusRecipePublicationFingerprint MFRoot.groupSnapshotRows)
fn MFState label = (
 local before=heapFree,p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess();p.Refresh()
 format "STATE % heap=% free=% private=% undo=% redo=% epoch=% builds=% hash=% buffers=% reserved=%\n" label heapSize before p.PrivateMemorySize64 (theHold.GetUndoNames()) (theHold.GetRedoNames()) MFRoot.procEpoch MFRoot.groupBuilds (MFHash()) (cyrusScriptBufferStats()) CyrusScriptWorkspaceReserved to:MFLog
 for leaf in MFRoot.layerObjects do format "LAYER count=% request=% accepted=% prepared=% prepareBuilds=% receiverBuilds=% error=%\n" leaf.amount leaf.requestedCount leaf.generatedCount leaf.procPreparedRows.count leaf.procPreparedBuilds leaf.procReceiverBuilds leaf.previewError to:MFLog
 flush MFLog
)
fn MFFilterCheck=(for i=1 to MFRoot.layerObjects.count do MFCheck (CyrusPresetSameValues MFFilters[i] (MFRoot.layerObjects[i].surfaceFilterPayload())) "Filter values unchanged")
fn MFCount amount = (
 local before=(theHold.GetUndoNames()).count,t=timeStamp()
 MFRoot.populationUI.distributionUI_countSpin.value=amount;MFRoot.populationUI.distributionUI_countSpin.changed amount
 MFState ("count-"+(amount as string));format "COUNT_TIME % %\n" amount (timeStamp()-t) to:MFLog;flush MFLog
 MFCheck (MFLayer.amount==amount and MFLayer.requestedCount==amount and MFLayer.previewError=="") "Actual Count control calculates requested value"
 MFCheck ((theHold.GetUndoNames()).count>=before) "Count edit retains prior Undo history"
 MFFilterCheck()
)
MFLog=createFile (MCPFixtureDir+"memory-fix.txt")
try (
 CyrusPerfHeadless=false
 CyrusPointSuspended=true
 loadMaxFile "F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/foundation-presets0853-memory-20261017-01/count50000-pending.max" quiet:true useFileUnits:true
 MFNode=getNodeByName "Owned Count memory investigation";MFRoot=MFNode.baseObject;MFLayer=MFRoot.layerObjects[1]
 MFFilters=for leaf in MFRoot.layerObjects collect leaf.surfaceFilterPayload()
 with undo off (MFLayer.amount=5000;MFRoot.updateMode=1)
 MFRoot.refreshAll();CyrusPointSuspended=false
 select MFNode;max modify mode;modPanel.setCurrentObject MFNode
 if not MFRoot.mainUI.controlsReady do MFRoot.mainUI.mountTimer.tick()
 with undo off MFRoot.selectLayer 1
 MFRoot.populationUISlot.open=true;MFRoot.mainUI.bindEditors()
 MFRoot.mainUI.updateRadio.state=2;MFRoot.mainUI.updateRadio.changed 2
 MFState "baseline-5000"
 MFCheck ((MFHash())=="6d7c221c9a2768efaa114d606139f01e64f8d4ca78d368c462d76a4293b2bb11") "Baseline full rows equal 0.85.3"
 MFCheck ((theHold.GetUndoNames()).count==0) "First edit begins without old history"
 MFBefore=MFHash();MFCount 50000
 MFCheck ((MFHash())=="35c2706213cb957417417b6f1338fd0c9d3b02011ccfbff33b8bb630855c9c89") "50000 full rows equal 0.85.3"
 format "READY_FOR_UNDO\n" to:MFLog;flush MFLog
)catch(format "FAILED: %\n" (getCurrentException()) to:MFLog;flush MFLog;throw())
