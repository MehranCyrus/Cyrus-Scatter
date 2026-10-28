for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned authoring fixture"
CyrusPointSuspended=false
SPRoot.invalidateGroups()
for leaf in SPRoot.layerObjects do leaf.procPreparedKey=""
with undo off SPRoot.refreshAll()
CyrusPointSync();completeRedraw()
