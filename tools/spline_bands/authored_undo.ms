-- Run phases as separate native requests, outside a pymxs transaction.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
global BandUndoRoot,BandUndoLeaf,BandUndoIDs,BandUndoSources,BandUndoPhase
if theHold.Holding() do throw "Unexpected outer test hold; do not interpret this as a Band Undo result."
local failure="",passed=false
try (
    if BandUndoPhase=="prepare" then (
        resetMaxFile #noPrompt
        local node=AminScatterObject name:"Band native Undo",surface=plane width:500 length:500
        BandUndoRoot=node.baseObject;BandUndoRoot.updateMode=1;BandUndoRoot.autoRender=false;BandUndoRoot.newLayer()
        BandUndoLeaf=BandUndoRoot.selectedLayer();BandUndoRoot.setLayerSurfaces BandUndoLeaf #(surface)
        local source=box pos:[500,0,0],path=rectangle width:100 length:100
        BandUndoLeaf.sources=#(source);BandUndoLeaf.diversityMode=3;BandUndoLeaf.amount=1000
        for i=1 to 3 do (BandUndoLeaf.addStroke path side:1;BandUndoLeaf.setStrokeSelection i 2 #(source))
        BandUndoLeaf.patternWidths=#(10.,25.,100.)
        BandUndoRoot.evaluateProcedural()
        BandUndoIDs=BandUndoLeaf.strokeIDs as array;BandUndoSources=BandUndoLeaf.strokeSourceIDs as array
        clearUndoBuffer()
    ) else case BandUndoPhase of (
        "delete": (undo "Delete authored Band" on BandUndoLeaf.removeStroke 2)
        "undo": (max undo)
        "redo": (max redo)
        default: throw "Unknown Undo phase"
    )
    local restored=BandUndoPhase=="prepare" or BandUndoPhase=="undo"
    local expected=if restored then BandUndoIDs else #(BandUndoIDs[1],BandUndoIDs[3])
    if BandUndoLeaf.strokeIDs.count!=expected.count do throw "Wrong Band count"
    for i=1 to expected.count where BandUndoLeaf.strokeIDs[i]!=expected[i] do throw "Surviving Band identity changed"
    if BandUndoLeaf.strokeSourceIDs.count!=expected.count or BandUndoLeaf.strokeSourceRows.count!=expected.count do throw "Membership Undo is incomplete"
    if restored and BandUndoLeaf.patternWidths[2]!=25. do throw "Width Undo is incomplete"
    if theHold.Holding() do throw "Band edit left an open Undo hold"
    passed=true
) catch(failure=getCurrentException())
local output="{\"phase\":\""+BandUndoPhase+"\",\"passed\":"+(passed as string)+",\"band_count\":"+(BandUndoLeaf.strokeIDs.count as string)+"}"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"band-undo-"+BandUndoPhase+".json") output
if not passed do throw failure
)
