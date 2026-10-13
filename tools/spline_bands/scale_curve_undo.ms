-- Each phase is a separate native event, outside pymxs Undo holds.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
global ScaleUndoPhase,ScaleUndoRun,ScaleUndoRoot,ScaleUndoLeaf,ScaleUndoPage,ScaleUndoBand,ScaleUndoEpoch
if theHold.Holding() do throw "Unexpected enclosing test hold"
case ScaleUndoPhase of (
    "prepare": (
        resetMaxFile #noPrompt;ScaleUndoRun=CyrusNewLayerID()
        local node=AminScatterObject name:"Scale graph Undo"
        ScaleUndoRoot=node.baseObject;ScaleUndoRoot.updateMode=1;ScaleUndoRoot.autoRender=false;ScaleUndoRoot.newLayer()
        ScaleUndoLeaf=ScaleUndoRoot.selectedLayer();ScaleUndoLeaf.diversityMode=3
        ScaleUndoLeaf.addStroke (rectangle width:100 length:100)
        ScaleUndoBand=ScaleUndoLeaf.strokeIDs[1];ScaleUndoEpoch=ScaleUndoRoot.procEpoch
        select node;max modify mode
        if not ScaleUndoRoot.mainUI.controlsReady do ScaleUndoRoot.mainUI.mountTimer.tick()
        ScaleUndoRoot.layoutUI.open=true;ScaleUndoRoot.mainUI.bindSection ScaleUndoRoot.layoutUI
        ScaleUndoPage=ScaleUndoRoot.layoutUI;clearUndoBuffer()
    )
    "custom": (ScaleUndoPage.diversityUI_setBandScaleProfile 3)
    "undo-custom": (max undo)
    "redo-custom": (max redo)
    "open": (CyrusOpenFalloffGraph ScaleUndoLeaf undefined false bandID:ScaleUndoBand)
    "edit": (
        local c=CyrusFalloffGraph.graph.curves[1],a=c.points[1],b=c.points[2]
        a.value=[0,50];b.value=[1,75];a.bezier=false;b.bezier=false;c.points[1]=a;c.points[2]=b
    )
    "apply": (CyrusFalloffGraph.applyButton.pressed())
    "undo-curve": (max undo)
    "close": (destroyDialog CyrusFalloffGraph)
    "redo-curve": (max redo)
    default: throw "Unknown scale Undo phase"
)
local expectedMode=if findItem #("prepare","undo-custom") ScaleUndoPhase>0 then 1 else 3
if ScaleUndoLeaf.strokeScaleModes[1]!=expectedMode do throw "Scale mode did not Undo/Redo"
if findItem #("apply","redo-curve") ScaleUndoPhase>0 do (
    local values=CyrusFallUnpack ScaleUndoLeaf.strokeScaleSamples[1]
    if values.count!=257 or abs(values[1]-.5)>.00001 or abs(values[257]-.75)>.00001 do throw "Scale graph application/Redo trace mismatch"
)
if findItem #("undo-curve","close") ScaleUndoPhase>0 and ScaleUndoLeaf.strokeScaleSamples[1]!="1,1" do throw "Undo was lost or Close reapplied the graph"
if ScaleUndoLeaf.strokeCurveSamples[1]!="1,1" do throw "Scale graph changed density"
if ScaleUndoRoot.procEpoch!=ScaleUndoEpoch do throw "Manual scale editing published unexpectedly"
if theHold.Holding() do throw "Scale graph left an open Undo hold"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"scale-undo-"+ScaleUndoRun+"-"+ScaleUndoPhase+".json") ("{\"phase\":\""+ScaleUndoPhase+"\",\"passed\":true}")
)
