-- Separate native events exercise the generated control's actual Undo hold.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
global FieldUndoPhase,FieldUndoRun,FieldUndoRoot,FieldUndoLeaf,FieldUndoEpoch,FieldUndoRows,FieldUndoMetadata
if theHold.Holding() do throw "Unexpected enclosing test hold"
local failure="",passed=false
try (
    case FieldUndoPhase of (
        "prepare": (
            resetMaxFile #noPrompt;FieldUndoRun=CyrusNewLayerID()
            local node=AminScatterObject name:"Field display Undo"
            FieldUndoRoot=node.baseObject;FieldUndoRoot.updateMode=1;FieldUndoRoot.autoRender=false;FieldUndoRoot.newLayer()
            FieldUndoLeaf=FieldUndoRoot.selectedLayer()
            FieldUndoRoot.setLayerSurfaces FieldUndoLeaf #(plane width:150 length:150)
            local model=box width:3 length:4 height:12 pos:[300,0,0],path=rectangle width:80 length:80
            FieldUndoLeaf.sources=#(model);FieldUndoLeaf.amount=40;FieldUndoLeaf.diversityMode=3
            FieldUndoLeaf.addStroke path;FieldUndoLeaf.setStrokeSelection 1 2 #(model);FieldUndoLeaf.patternWidths[1]=30.
            FieldUndoRoot.setGroupDisplay 4;FieldUndoRoot.evaluateProcedural()
            FieldUndoEpoch=FieldUndoRoot.procEpoch;FieldUndoRows=cyrusEditFingerprint FieldUndoRoot.groupSnapshotRows[1] "field-undo"
            FieldUndoMetadata=FieldUndoRoot.procPublishedMetadata[1][5]
            select node;max modify mode
            if not FieldUndoRoot.mainUI.controlsReady do FieldUndoRoot.mainUI.mountTimer.tick()
            FieldUndoRoot.mainUI.selectLayerView FieldUndoLeaf;FieldUndoRoot.layoutUI.open=true;FieldUndoRoot.mainUI.bindSection FieldUndoRoot.layoutUI
            clearUndoBuffer()
        )
        "falloff": FieldUndoRoot.layoutUI.diversityUI_changeFieldDisplay #fieldFalloff true
        "undo-falloff": (max undo)
        "redo-falloff": (max redo)
        "boundaries": FieldUndoRoot.layoutUI.diversityUI_changeFieldDisplay #fieldBoundaries true
        "undo-boundaries": (max undo)
        "redo-boundaries": (max redo)
        "samples": FieldUndoRoot.layoutUI.diversityUI_changeFieldDisplay #fieldSamples 250
        "undo-samples": (max undo)
        "redo-samples": (max redo)
        "combined": FieldUndoRoot.layoutUI.diversityUI_changeFieldDisplay #fieldCombined true
        "undo-combined": (max undo)
        "redo-combined": (max redo)
        default: throw "Unknown field Undo phase"
    )
    FieldUndoRoot.refreshDisplay()
    local falloff=findItem #("prepare","undo-falloff") FieldUndoPhase==0
    local boundaries=findItem #("redo-boundaries","samples","undo-samples","redo-samples","combined","undo-combined","redo-combined","boundaries") FieldUndoPhase>0
    local samples=if findItem #("samples","redo-samples","combined","undo-combined","redo-combined") FieldUndoPhase>0 then 250 else 4000
    local combined=findItem #("combined","redo-combined") FieldUndoPhase>0
    if FieldUndoLeaf.fieldFalloff!=falloff or FieldUndoLeaf.fieldBoundaries!=boundaries or FieldUndoLeaf.fieldSamples!=samples or FieldUndoLeaf.fieldCombined!=combined do throw "Display settings did not Undo/Redo in one transaction"
    if FieldUndoRoot.procEpoch!=FieldUndoEpoch or (cyrusEditFingerprint FieldUndoRoot.groupSnapshotRows[1] "field-undo")!=FieldUndoRows or FieldUndoRoot.procPublishedMetadata[1][5]!=FieldUndoMetadata do throw "Display Undo changed the published population"
    if FieldUndoLeaf.previewError!="" or (falloff and FieldUndoLeaf.procFieldCache==undefined) do throw "Display Undo failed to reconstruct its cache"
    if theHold.Holding() do throw "Display control left an open Undo hold"
    passed=true
)catch(failure=getCurrentException())
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"field-undo-"+FieldUndoRun+"-"+FieldUndoPhase+".json") ("{\"phase\":\""+FieldUndoPhase+"\",\"passed\":"+(passed as string)+"}")
if not passed do throw failure
)
