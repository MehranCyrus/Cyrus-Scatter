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
