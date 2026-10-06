global CyrusFlowRolloutExtent,CyrusFlowLayerSummary
global CyrusRetainListItems
fn CyrusRetainListItems control values = (
    local previous=control.items,changed=previous.count!=values.count
    if not changed do for i=1 to values.count while not changed do changed=previous[i]!=values[i]
    if changed do control.items=values
    changed
)
global CyrusSourceContainerFilter
fn CyrusSourceContainerFilter node = (isValidNode node and classof node.baseObject==Rectangle and node.modifiers.count==0)
-- Native rollup headers occupy 21 logical pixels with 2 pixels between pages.
-- Body heights remain MAXScript logical units; automatic layout applies DPI.
fn CyrusFlowRolloutExtent r = (23+(if r.open then r.height else 0))
fn CyrusFlowLayerSummary root parent = (
    local placed=0,shown=0,pending=false,failed=false,index=findItem root.layerObjects parent
    for leaf in root.layerSets parent do (
        local state=leaf.uiLayerStats()
        if state.hasResult do (placed+=state.placements;shown+=state.previewCount)
        pending=pending or state.needsUpdate;failed=failed or state.errorText!=""
    )
    local status=if failed then "Error" else if index==0 or not root.layerEnabled[index] then "Disabled" else if not root.layerVisible[index] then "Hidden" else if pending then "Pending" else "Cached"
    #(placed,shown,status)
)
