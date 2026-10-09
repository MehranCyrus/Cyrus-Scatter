RSAssert()
(
    VForest.pf_aractivelist[3]=false
    VForest.surflist=#();append VForest.surflist (getNodeByName "VF_R1" exact:true)
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

    VForest.pf_aractivelist[3]=true
    append VForest.surflist (getNodeByName "VF_R2" exact:true)
    RSAssert()
(
    VFCapture "forest_two_regions"
    deleteItem VForest.surflist 2
    VFCapture "forest_two_regions_removed_receiver_two"
    append VForest.surflist (getNodeByName "VF_R2" exact:true)
    VFCapture "forest_two_regions_restored"
    -- Copying a region's opaque reference is deliberately avoided. Overlap
    -- is tested by moving the Forest-created spline after UI conversion.
)

)
