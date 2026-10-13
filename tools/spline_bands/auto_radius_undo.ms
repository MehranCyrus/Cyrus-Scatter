-- Each phase is a separate native event before any pymxs fixture.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
global RadiusUndoPhase,RadiusUndoRun,RadiusUndoRoot,RadiusUndoLeaf,RadiusUndoEpoch
if theHold.Holding() do throw "Unexpected enclosing test hold"
local failure="",passed=false
try (
    case RadiusUndoPhase of (
        "prepare": (
            resetMaxFile #noPrompt;RadiusUndoRun=CyrusNewLayerID()
            local node=AminScatterObject name:"Auto Radius Undo"
            RadiusUndoRoot=node.baseObject;RadiusUndoRoot.updateMode=1;RadiusUndoRoot.autoRender=false;RadiusUndoRoot.newLayer()
            RadiusUndoLeaf=RadiusUndoRoot.selectedLayer()
            RadiusUndoRoot.setLayerSurfaces RadiusUndoLeaf #(plane width:500 length:500)
            RadiusUndoLeaf.sources=#(box width:3 length:4 height:12);RadiusUndoLeaf.amount=20
            RadiusUndoLeaf.sourceRadiiWU=#(7.);RadiusUndoLeaf.sourceFollowScale=#(true)
            RadiusUndoRoot.evaluateProcedural();RadiusUndoEpoch=RadiusUndoRoot.procEpoch;clearUndoBuffer()
        )
        "auto": RadiusUndoLeaf.setSourceRadius #{1} true kind:4
        "undo-auto": (max undo)
        "redo-auto": (max redo)
        "manual": RadiusUndoLeaf.setSourceRadius #{1} false kind:4
        "undo-manual": (max undo)
        "redo-manual": (max redo)
        default: throw "Unknown radius Undo phase"
    )
    local expected=findItem #("auto","redo-auto","undo-manual") RadiusUndoPhase>0
    if (RadiusUndoLeaf.sourceUsesAuto 1)!=expected do throw "Radius mode did not Undo/Redo in one transaction"
    if RadiusUndoLeaf.sourceRadiiWU[1]!=7. or not RadiusUndoLeaf.sourceFollowScale[1] do throw "Mode change lost saved Manual values"
    if RadiusUndoRoot.procEpoch!=RadiusUndoEpoch do throw "Manual radius authoring unexpectedly published"
    if theHold.Holding() do throw "Radius authoring left an open Undo hold"
    passed=true
)catch(failure=getCurrentException())
local output="{\"phase\":\""+RadiusUndoPhase+"\",\"passed\":"+(passed as string)+"}"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"auto-undo-"+RadiusUndoRun+"-"+RadiusUndoPhase+".json") output
if not passed do throw failure
)
