-- Native Undo/Redo runs in separate requests, outside a pymxs transaction.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/refine0791-layer*" do throw "Owned investigation host required"
global L791Root,L791First,L791Second,L791Fingerprint
local error="",passed=false
try (
    if L791Phase=="prepare" then (
        L791Root=(getNodeByName "Point_model_lifecycle").baseObject
        L791First=L791Root.layerObjects[1]
        L791Root.mainUI.selectLayerView L791First
        L791Root.managerUI.flow_layersUI_addButton.pressed()
        L791Second=L791Root.selectedLayer()
        L791Root.setLayerSurfaces L791Second #((getNodeByName "Point_receiver"))
        L791Root.modelsUI.sourceUI_addPoint.pressed()
        L791Root.refreshAll()
        L791Fingerprint=cyrusEditFingerprint L791Root.groupSnapshotRows[1] "areas"
        clearUndoBuffer()
    ) else (
        if theHold.Holding() do throw "Unexpected outer test hold"
        case L791Phase of (
            "delete": L791Root.managerUI.flow_layersUI_removeButton.pressed()
            "undo": (max undo)
            "redo": (max redo)
            default: throw "Unknown probe phase"
        )
    )
    CyrusPointSync();completeRedraw();windows.processPostedMessages()
    local expected=if L791Phase=="prepare" or L791Phase=="undo" then 2 else 1
    if L791Root.layerObjects.count!=expected do throw "Wrong layer count"
    if L791Root.layerObjects[1]!=L791First do throw "Original owner changed"
    local slot=findItem L791Root.procPublishedOwners L791First
    if slot==0 or cyrusEditFingerprint L791Root.groupSnapshotRows[slot] "areas"!=L791Fingerprint do throw "Original placements changed"
    if L791First.cachedPointCount!=137 or L791First.previewError!="" do throw "Original preview not restored"
    if expected==2 do (
        if L791Root.layerObjects[2]!=L791Second or not (L791Second.isPointSource 1) do throw "Point layer not restored"
    )
    if theHold.Holding() do throw "Open hold left behind"
    passed=true
)catch(error=getCurrentException())
local data="{\"phase\":\""+L791Phase+"\",\"passed\":"+(passed as string)+",\"layer_count\":"+(L791Root.layerObjects.count as string)+",\"original_shown\":"+(L791First.cachedPointCount as string)+"}"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"layer-undo-"+L791Phase+".json") data
if not passed do throw error
)
