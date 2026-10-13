-- Separate native events, outside pymxs holds, in a disposable host only.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
global BandUndoPhase,BandUndoRun,BandUndoRoot,BandUndoLeaf,BandUndoPage,BandUndoEpoch
if theHold.Holding() do throw "Unexpected enclosing hold"
case BandUndoPhase of (
    "prepare": (
        resetMaxFile #noPrompt;BandUndoRun=CyrusNewLayerID()
        local node=AminScatterObject name:"Band selection Undo"
        BandUndoRoot=node.baseObject;BandUndoRoot.updateMode=1;BandUndoRoot.autoRender=false;BandUndoRoot.newLayer()
        BandUndoLeaf=BandUndoRoot.selectedLayer();BandUndoLeaf.diversityMode=3
        BandUndoLeaf.addPointSource();BandUndoLeaf.addStroke (rectangle width:100 length:100)
        BandUndoLeaf.setStrokeSelection 1 2 #(BandUndoLeaf.sourceRowIDs[1])
        select node;max modify mode
        if not BandUndoRoot.mainUI.controlsReady do BandUndoRoot.mainUI.mountTimer.tick()
        BandUndoRoot.layoutUI.open=true;BandUndoRoot.mainUI.bindSection BandUndoRoot.layoutUI
        BandUndoPage=BandUndoRoot.layoutUI;BandUndoEpoch=BandUndoRoot.procEpoch
        clearUndoBuffer()
    )
    "clear": (BandUndoPage.diversityUI_strokeChoices_colored.SetSelected 0 false)
    "undo": (max undo)
    "redo": (max redo)
    "refresh": (BandUndoPage.diversityUI_refreshGroups.pressed())
    default: throw "Unknown Band Undo phase"
)
local expected=if findItem #("prepare","undo") BandUndoPhase>0 then 1 else 0
if BandUndoLeaf.bandAssignmentCount 1!=expected do throw "Band membership did not Undo/Redo"
if BandUndoRoot.procEpoch!=BandUndoEpoch do throw "Manual assignment edit published unexpectedly"
if theHold.Holding() do throw "Assignment edit left an open hold"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"band-undo-"+BandUndoRun+"-"+BandUndoPhase+".json") ("{\"phase\":\""+BandUndoPhase+"\",\"passed\":true}")
)
