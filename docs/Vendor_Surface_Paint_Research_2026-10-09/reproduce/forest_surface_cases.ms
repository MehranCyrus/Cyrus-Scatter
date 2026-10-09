RSAssert()
(
    VFCapture "forest_paint_valid_baseline"
    append VForest.surflist (getNodeByName "VF_R2" exact:true)
    VFCapture "forest_paint_add_far"
    deleteItem VForest.surflist 2
    VFCapture "forest_paint_remove_far"
    deleteItem VForest.surflist 1
    VFCapture "forest_paint_no_receiver"
    append VForest.surflist (getNodeByName "VF_R1" exact:true)
    VFCapture "forest_paint_restore_receiver"
    RSWrite "stage.txt" "Forest paint surface cases complete"
)
