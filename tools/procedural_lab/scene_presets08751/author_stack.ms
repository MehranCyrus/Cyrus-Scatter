-- Own setup only: lower clone, an upper move/clone, deletion and clone radius.
select SPOwner
SPRoot.refreshAll();CyrusPointSync();completeRedraw()
global SPLower=(SPRoot.procModifiers())[1]
cyrusEditActiveLayers SPLower #(SPRoot.layerObjects[1].editLayerKey)
cyrusEditSelect SPLower #(1)
undo "Owned lower clone" on cyrusEditCommand SPLower 3 0
SPRoot.refreshAll();CyrusPointSync();completeRedraw()
addModifier SPOwner (CyrusScatterEdit())
SPRoot.refreshAll();CyrusPointSync();completeRedraw()
global SPUpper=(SPRoot.procModifiers())[1]
cyrusEditActiveLayers SPUpper #(SPRoot.layerObjects[1].editLayerKey)
cyrusEditSelect SPUpper #(4)
undo "Owned upper clone move" on cyrusEditTransform SPUpper 0 [7,0,0] (matrix3 1) false
SPRoot.refreshAll();CyrusPointSync();completeRedraw()
undo "Owned upper clone" on cyrusEditCommand SPUpper 3 0
SPRoot.refreshAll();CyrusPointSync();completeRedraw()
cyrusEditSelect SPLower #()
cyrusEditSelect SPUpper #(5)
SPRoot.layerObjects[1].procSelectedRadius 1 0.25
SPRoot.refreshAll();CyrusPointSync();completeRedraw()
cyrusEditSelect SPUpper #(2)
undo "Owned instance deletion" on cyrusEditCommand SPUpper 2 0
SPRoot.refreshAll();CyrusPointSync();completeRedraw()
