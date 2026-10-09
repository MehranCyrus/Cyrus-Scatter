RSAssert()
(
    VForest.problist=#(100.)
    VForest.units_x=100.;VForest.units_y=100.;VForest.pixels_x=50;VForest.pixels_y=50
    VForest.distmap=Gradient color1:white color2:white color3:white
    VFCapture "forest_constant_after_conversion"
    local s=stringStream ""
    local shape=getNodeByName "paint_area001" exact:true
    format "node % splines %\n" shape (numSplines shape) to:s
    for j=1 to numSplines shape do (
        format "spline % knots % closed %\n" j (numKnots shape j) (isClosed shape j) to:s
        for k=1 to numKnots shape j do format "knot %\n" (getKnotPoint shape j k) to:s
    )
    RSWrite "forest-converted-contours.txt" (s as string);close s
)
