case CVProfileCase of (
    "lower-ready":(
        subObjectLevel=0;select SPOwner;max modify mode
        while (SPRoot.procModifiers()).count>1 do deleteModifier SPOwner ((SPRoot.procModifiers())[1])
        SPLower=(SPRoot.procModifiers())[1]
        SPRoot.refreshAll();CyrusPointSync();completeRedraw()
        modPanel.setCurrentObject SPLower;subObjectLevel=1
        cyrusEditActiveLayers SPLower #(SPRoot.layerObjects[1].editLayerKey)
        cyrusEditSelect SPLower #(1)
    )
    "lower-clone":(undo "Owned lower clone" on cyrusEditCommand SPLower 3 0)
    "upper-ready":(
        subObjectLevel=0
        addModifier SPOwner (CyrusScatterEdit())
        SPRoot.refreshAll();CyrusPointSync();completeRedraw()
        SPUpper=(SPRoot.procModifiers())[1]
        modPanel.setCurrentObject SPUpper;subObjectLevel=1
        cyrusEditActiveLayers SPUpper #(SPRoot.layerObjects[1].editLayerKey)
        cyrusEditSelect SPUpper #(4)
    )
    "upper-move":(undo "Owned upper move" on cyrusEditTransform SPUpper 0 [7,0,0] (matrix3 1) false)
    "upper-clone":(undo "Owned upper clone" on cyrusEditCommand SPUpper 3 0)
    "radius-ready":(cyrusEditSelect SPLower #();cyrusEditSelect SPUpper #(4))
    "radius":(SPRoot.layerObjects[1].procSelectedRadius 1 0.25)
    "delete-ready":(cyrusEditSelect SPUpper #(2))
    "delete":(undo "Owned deletion" on cyrusEditCommand SPUpper 2 0)
)
if findString CVProfileCase "-ready"==undefined do SPRoot.refreshAll()
CyrusPointSync();completeRedraw()
