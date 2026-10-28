for leaf in SPRoot.layerObjects do (leaf.interactionReact=false;leaf.interactionCollider=false;leaf.procPreparedKey="")
SPRoot.refreshAll();CyrusPointSync();completeRedraw()
cyrusEditActiveLayers SPUpper #(SPRoot.layerObjects[1].editLayerKey)
cyrusEditSelect SPUpper #(4)
