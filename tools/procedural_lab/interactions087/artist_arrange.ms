-- Derived trial scene only. Original architecture, source files and artist profile stay intact.
global TOwner,TRoot,TEdit,TRocks,PSettle
TRoot.layerObjects[1].amount=10000
TRoot.layerObjects[5].sourceScales[1]=0.15
TRoot.identificationMode=4;TRoot.refreshAll();CyrusPointSync();completeRedraw();PSettle 500
fn ASelect leaf index = (
    cyrusEditActiveLayers TEdit #(leaf.editLayerKey);cyrusEditSelect TEdit #(index)
    completeRedraw();PSettle 350
    -- These trial layers retain historical rows from the density tiers. A
    -- visible selection index is not an authored row index (notably the tree).
    local total=(cyrusEditInspect TEdit 0 1)[2] as integer
    for offset=(amax 0 (total-2000)) to (total-1) by 500 do (
        for row in (cyrusEditInspect TEdit offset (amin 500 (total-offset)))[4] where row[1]==leaf.editLayerKey and row[8] do return (row[2] as integer)
    )
    throw "Selected trial row was not in the bounded final-layer history window."
)
fn AMove leaf index target = (
    local authored=ASelect leaf index
    local handle=cyrusEditHandleMatrix TEdit leaf.editLayerKey authored
    if handle==undefined do throw ("Arrangement handle unavailable, layer key "+(leaf.editLayerKey as string)+", row "+(index as string))
    local current=handle.translation
    if distance target current>0.001 do undo "Arrange interaction garden" on cyrusEditTransform TEdit 0 (target-current) (matrix3 1) false
    completeRedraw();PSettle 400
)
fn AScale leaf index factor = (
    local authored=ASelect leaf index,tm=cyrusEditHandleMatrix TEdit leaf.editLayerKey authored
    local relative=factor/(length tm.row1)
    if abs (relative-1)>0.00001 do undo "Size interaction stone" on cyrusEditTransform TEdit 2 [relative,relative,relative] (matrix3 1) true
    completeRedraw();PSettle 400
)
AMove TRocks 1 [-8000,-3100,-988.8409];AScale TRocks 1 1.3
AMove TRocks 2 [-8130,-3260,-988.8409];AScale TRocks 2 0.55
AMove TRocks 3 [-7840,-3250,-988.8409];AScale TRocks 3 0.7
AMove TRoot.layerObjects[5] 1 [-8180,-3170,-988.8409]
TRoot.refreshAll();CyrusPointSync();completeRedraw();PSettle 600
if TRoot.interactionError!="" do throw TRoot.interactionError
ASelect TRocks 1
local eye=[-7700,-3550,-730],target=[-8020,-3120,-930],look=normalize(target-eye)
local right=normalize(cross look [0,0,1]),up=normalize(cross right look)
viewport.setType #view_persp_user;viewport.setTM (inverse(matrix3 right up (-look) eye));viewport.setRenderLevel #smoothhighlights
completeRedraw();PSettle 500
saveMaxFile (GardenRun+"Terraces_087_Artist_Stage.max") quiet:true
PSettle 500
local image=gw.getViewportDib();image.filename=GardenRun+"artist-stage.png";save image;close image
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"artist-stage-statistics.json") (TRoot.interactionsStatistics())
