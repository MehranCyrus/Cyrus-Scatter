-- Execute each phase as a separate native event, outside any pymxs hold.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
global SourceUndoPhase,SourceUndoRun,SourceUndoRoot,SourceUndoLeaf,SourceUndoModel,SourceUndoIDs,SourceUndoEpoch
if theHold.Holding() do throw "Unexpected enclosing test hold"
case SourceUndoPhase of (
    "prepare": (
        resetMaxFile #noPrompt;SourceUndoRun=CyrusNewLayerID()
        local node=AminScatterObject name:"Source conversion Undo"
        SourceUndoRoot=node.baseObject;SourceUndoRoot.updateMode=1;SourceUndoRoot.autoRender=false;SourceUndoRoot.newLayer()
        SourceUndoLeaf=SourceUndoRoot.selectedLayer()
        SourceUndoRoot.setLayerSurfaces SourceUndoLeaf #(plane width:500 length:500)
        SourceUndoModel=box width:3 length:4 height:12 pos:[700,0,0]
        SourceUndoLeaf.sources=#(SourceUndoModel);SourceUndoLeaf.amount=20
        SourceUndoLeaf.sourceRadiiWU=#(7.);SourceUndoLeaf.sourceFollowScale=#(true)
        SourceUndoLeaf.setSourceRadius #{1} true kind:4
        SourceUndoRoot.evaluateProcedural();SourceUndoEpoch=SourceUndoRoot.procEpoch
        SourceUndoIDs=SourceUndoLeaf.sourceRowIDs as array;clearUndoBuffer()
    )
    "point": (if not SourceUndoLeaf.makePointSource 1 do throw "Conversion rejected")
    "undo-point": (max undo)
    "redo-point": (max redo)
    "model": (if not SourceUndoLeaf.replacePointSource 1 SourceUndoModel do throw "Restoring registered model rejected")
    "undo-model": (max undo)
    "redo-model": (max redo)
    default: throw "Unknown source Undo phase"
)
local pointExpected=findItem #("point","redo-point","undo-model") SourceUndoPhase>0
if (SourceUndoLeaf.isPointSource 1)!=pointExpected or (SourceUndoLeaf.isEmptySource 1)!=pointExpected do throw "Source kind did not Undo/Redo in one transaction"
if (SourceUndoLeaf.sourceUsesAuto 1)==pointExpected do throw "Auto mode applicability changed incorrectly"
if SourceUndoLeaf.sourceRowIDs[1]!=SourceUndoIDs[1] or SourceUndoLeaf.sources[1]!=SourceUndoModel do throw "Source registration or row identity changed"
if SourceUndoLeaf.sourceRadiiWU[1]!=7. or not SourceUndoLeaf.sourceFollowScale[1] do throw "Conversion lost Manual radius settings"
if SourceUndoRoot.procEpoch!=SourceUndoEpoch do throw "Manual conversion unexpectedly published"
if theHold.Holding() do throw "Source conversion left an open Undo hold"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"source-undo-"+SourceUndoRun+"-"+SourceUndoPhase+".json") ("{\"phase\":\""+SourceUndoPhase+"\",\"passed\":true}")
)
