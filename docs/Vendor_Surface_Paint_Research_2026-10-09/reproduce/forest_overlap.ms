RSAssert()
(
    VFCapture "forest_overlap_include"
    VForest.arincexclist[3]=1
    VFCapture "forest_overlap_exclude_upper"
    VForest.arincexclist[3]=0
    VFCapture "forest_overlap_include_restored"
    VForest.trees.update_ui();clearSelection();redrawViews();select VForest
    VFCapture "forest_after_interface_redraw"
)
