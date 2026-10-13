-- Run each phase in a separate native transport event before any pymxs tests.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
global BandUIPhase,BandUIRunID,BandUIRoot,BandUILeaf,BandUIIDs,BandUIChecks=0
if theHold.Holding() do throw "Unexpected enclosing test hold"
local failure="",passed=false
try (
    case BandUIPhase of (
        "prepare": (
            resetMaxFile #noPrompt
            BandUIRunID=CyrusNewLayerID()
            local node=AminScatterObject name:"Band UI Undo",surface=plane width:500 length:500
            BandUIRoot=node.baseObject;BandUIRoot.updateMode=1;BandUIRoot.autoRender=false;BandUIRoot.newLayer()
            BandUILeaf=BandUIRoot.selectedLayer();BandUIRoot.setLayerSurfaces BandUILeaf #(surface)
            local model=box pos:[500,0,0],path=rectangle width:100 length:100
            BandUILeaf.sources=#(model);BandUILeaf.diversityMode=3;BandUILeaf.amount=1000
            for i=1 to 3 do (BandUILeaf.addStroke path;BandUILeaf.setStrokeSelection i 2 #(model))
            BandUILeaf.patternWidths=#(10.,25.,100.)
            BandUIIDs=BandUILeaf.strokeIDs as array
            BandUIRoot.evaluateProcedural();clearUndoBuffer()
        )
        "convert": (BandUILeaf.convertBandArrangement 2)
        "undo-convert": (max undo)
        "redo-convert": (max redo)
        "reorder": (BandUILeaf.moveBand BandUIIDs[3] 1)
        "undo-reorder": (max undo)
        "redo-reorder": (max redo)
        "curve-open": (
            CyrusOpenFalloffGraph BandUILeaf undefined true bandID:BandUIIDs[2]
            local row=findItem BandUILeaf.strokeIDs BandUIIDs[2]
            if BandUILeaf.strokeCurveSamples[row]!="1,1" or BandUILeaf.strokeCurveGraphs[row]!="" do throw "Opening the graph modified its saved curve"
            for p in CyrusFalloffGraph.graph.curves[1].points where p.value.y!=100. do throw "Initial graph fitting changed the control points"
            clearUndoBuffer()
        )
        "curve-unchanged-close": (
            local trace=CyrusFalloffGraph.curveTrace(),samples=trace[1]
            if abs((amin samples)-1.)>0.000001 or abs((amax samples)-1.)>0.000001 do throw "Settled initial curve is not constant"
            CyrusFalloffGraph.storeCurve();destroyDialog CyrusFalloffGraph
            local row=findItem BandUILeaf.strokeIDs BandUIIDs[2]
            if BandUILeaf.strokeCurveSamples[row]!="1,1" or BandUILeaf.strokeCurveGraphs[row]!="" do throw "Closing an unchanged graph rewrote its recipe"
        )
        "curve-reopen": (CyrusOpenFalloffGraph BandUILeaf undefined true bandID:BandUIIDs[2])
        "curve-edit": (
            local c=CyrusFalloffGraph.graph.curves[1],p=c.points[2]
            p.value.y=40.;c.points[2]=p
            CyrusFalloffGraph.storeCurve()
        )
        "undo-curve": (max undo)
        "redo-curve": (max redo)
        "curve-close": (destroyDialog CyrusFalloffGraph)
        "undo-after-close": (max undo)
        default: throw "Unknown native authoring phase"
    )
    BandUILeaf.syncStrokes()
    if BandUILeaf.strokeIDs.count!=3 or BandUILeaf.strokeSourceIDs.count!=3 do throw "An Undo step lost authored records"
    if findItem #("convert","redo-convert") BandUIPhase>0 do (
        if BandUILeaf.bandArrangement!=2 or BandUILeaf.strokeStarts[2]!=10. or BandUILeaf.strokeEnds[2]!=35. do throw "Independent conversion failed"
    )
    if BandUIPhase=="undo-convert" and BandUILeaf.bandArrangement!=1 do throw "Conversion did not undo in one step"
    if findItem #("reorder","redo-reorder") BandUIPhase>0 and BandUILeaf.strokeIDs[1]!=BandUIIDs[3] do throw "Reorder failed"
    if BandUIPhase=="undo-reorder" and BandUILeaf.strokeIDs[1]!=BandUIIDs[1] do throw "Reorder did not undo in one step"
    local row=findItem BandUILeaf.strokeIDs BandUIIDs[2]
    if findItem #("curve-edit","redo-curve","curve-close") BandUIPhase>0 do (
        local values=CyrusFallUnpack BandUILeaf.strokeCurveSamples[row]
        if values.count!=257 or abs(values[257]-.4)>.001 do throw "Curve samples were not committed coherently"
    )
    if findItem #("undo-curve","undo-after-close") BandUIPhase>0 do (
        if BandUILeaf.strokeCurveSamples[row]!="1,1" or BandUILeaf.strokeCurveGraphs[row]!="" do throw "Curve did not undo in one step"
    )
    if theHold.Holding() do throw "Authoring left an open Undo hold"
    BandUIChecks+=1;passed=true
)catch(failure=getCurrentException())
local output="{\"phase\":\""+BandUIPhase+"\",\"passed\":"+(passed as string)+",\"checks\":"+(BandUIChecks as string)+"}"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"band-ui-undo-"+BandUIRunID+"-"+BandUIPhase+".json") output
if not passed do throw failure
)
