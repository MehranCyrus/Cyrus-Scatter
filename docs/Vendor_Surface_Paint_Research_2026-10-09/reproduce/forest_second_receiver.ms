RSAssert()
(
    append VForest.surflist (getNodeByName "VF_R2" exact:true)
    select (getNodeByName "VF_R2" exact:true)
    max zoomext sel all
    select VForest;max modify mode;modPanel.setCurrentObject VForest
    VFCapture "forest_before_second_paint"
)
