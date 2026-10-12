-- Owned host; requests run outside pymxs and outside an outer Undo hold.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/refine0791-layer0792-*" do throw "Owned 0.79.2 host required"
global R792UndoRoot,R792UndoLeaf,R792UndoEpoch,R792UndoFP
if R792UndoPhase=="prepare" then (
 resetMaxFile #noPrompt
 local surface=plane width:300 length:300,node=AminScatterObject name:"Radius_Undo"
 R792UndoRoot=node.baseObject;R792UndoRoot.updateMode=1;R792UndoRoot.autoRender=false
 R792UndoRoot.newLayer();R792UndoLeaf=R792UndoRoot.selectedLayer()
 R792UndoRoot.setLayerSurfaces R792UndoLeaf #(surface)
 R792UndoLeaf.addPointSource();R792UndoLeaf.amount=60
 R792UndoLeaf.setSourceRadius #{1} 5.0;R792UndoLeaf.setSourceRadius #{1} true kind:3
 R792UndoRoot.setGroupDisplay 4;R792UndoRoot.refreshAll()
 select node;max modify mode;modPanel.setCurrentObject R792UndoRoot
 if not R792UndoRoot.mainUI.controlsReady do R792UndoRoot.mainUI.mountTimer.tick()
 R792UndoRoot.previewUI.open=true;R792UndoRoot.mainUI.bindSection R792UndoRoot.previewUI
 R792UndoEpoch=R792UndoRoot.procEpoch;R792UndoFP=cyrusEditFingerprint R792UndoRoot.groupSnapshotRows[1] "areas"
 R792UndoLeaf.amount=81
 clearUndoBuffer()
) else case R792UndoPhase of (
 "edit": undo "Radius control test" on R792UndoRoot.previewUI.flow_previewUI_radiusLimitSpin.changed 7
 "undo": (max undo)
 "redo": (max redo)
)
CyrusPointSync();completeRedraw();windows.processPostedMessages()
local expected=if R792UndoPhase=="prepare" or R792UndoPhase=="undo" then 60 else 7
local passed=R792UndoLeaf.radiusDisplayCount()==expected and R792UndoRoot.procEpoch==R792UndoEpoch and R792UndoLeaf.amount==81 and cyrusEditFingerprint R792UndoRoot.groupSnapshotRows[1] "areas"==R792UndoFP
local data="{\"phase\":\""+R792UndoPhase+"\",\"passed\":"+(passed as string)+",\"radius_count\":"+(R792UndoLeaf.radiusDisplayCount() as string)+",\"limit\":"+(R792UndoRoot.radiusDisplayLimit as string)+",\"epoch\":"+(R792UndoRoot.procEpoch as string)+"}"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"radius-undo-"+R792UndoPhase+".json") data
if not passed do throw "Radius Undo/Redo did not preserve Manual publication and current display"
)
