-- Check distinct authored stone rows rather than only the selected hero.
global TRoot,TEdit,TRocks,PSettle
local epoch=TRoot.procEpoch,builds=TRoot.groupBuilds
local inputs=for leaf in TRoot.layerObjects collect #(leaf.amount,leaf.randomSeed)
for id in #(2,3) do (
    cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(id);completeRedraw();PSettle 350
    local before=for row=1 to 3 collect (cyrusEditHandleMatrix TEdit TRocks.editLayerKey row).translation
    undo "Test a separate small stone" on cyrusEditTransform TEdit 0 [2,0,0] (matrix3 1) false
    completeRedraw();PSettle 350
    for row=1 to 3 do (
        local expected=before[row]+(if row==id then [2,0,0] else [0,0,0])
        if distance (cyrusEditHandleMatrix TEdit TRocks.editLayerKey row).translation expected>0.01 do throw "A small-stone command moved the wrong authored row."
    )
    if TRoot.interactionError!="" do throw TRoot.interactionError
    max undo;completeRedraw();PSettle 350
    for row=1 to 3 where distance (cyrusEditHandleMatrix TEdit TRocks.editLayerKey row).translation before[row]>0.01 do throw "Small-stone Undo did not restore all three stone rows."
    if TRoot.procEpoch!=epoch or TRoot.groupBuilds!=builds do throw "Small-stone edits rebuilt placements."
)
for i=1 to inputs.count where TRoot.layerObjects[i].amount!=inputs[i][1] or TRoot.layerObjects[i].randomSeed!=inputs[i][2] do throw "Small-stone edits consumed authored population changes."
cyrusEditSelect TEdit #(1);completeRedraw();PSettle 250
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"other-stones.json") "{\"status\":\"pass\",\"stone_rows\":[2,3],\"scope\":\"Each small stone moved independently through Cyrus Edit, the other two stone rows stayed fixed, Undo restored them, placement epoch/build counts and authored Manual inputs stayed unchanged.\"}"
