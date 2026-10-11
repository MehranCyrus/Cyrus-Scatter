-- Run only through the owned qualification transport, outside pymxs.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/refine0791-*" do throw "Private refinement profile required"
local checks=#()
fn R791UndoCheck value label = (
    if not value do throw label
    true
)
if R791Phase=="undo_prepare" then (
    resetMaxFile #noPrompt
    local node=AminScatterObject name:"Point_Undo",root=node.baseObject
    root.updateMode=1;root.autoRender=false;root.newLayer()
    select node;max modify mode;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.modelsUI.open=true;root.mainUI.bindSection root.modelsUI;root.modelsUI.layout()
    R791UndoCheck (not theHold.Holding()) "No outer test hold before Add Point"
    root.modelsUI.sourceUI_addPoint.pressed()
    local leaf=root.selectedLayer()
    R791UndoCheck (leaf.sources.count==1 and leaf.isPointSource 1) "Add Point button created one Point"
    R791UndoCheck (not theHold.Holding()) "Add Point closed its hold"
) else (
    local root=(getNodeByName "Point_Undo").baseObject,leaf=root.selectedLayer(),key=leaf.sourceRowIDs[1]
    R791UndoCheck (not theHold.Holding()) "No outer test hold before Undo"
    max undo
    R791UndoCheck (leaf.sources.count==0 and leaf.sourcePoint.count==0 and leaf.sourceRowIDs.count==0) "One Undo removes the complete Point row"
    max redo
    R791UndoCheck (leaf.sources.count==1 and leaf.isPointSource 1 and leaf.sourceRowIDs[1]==key) "Redo restores the Point and its identity"
    R791UndoCheck (not theHold.Holding()) "Undo and Redo closed their holds"
)
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+R791Phase+"-native.json") ("{\"phase\":\""+R791Phase+"\",\"passed\":true}")
)
