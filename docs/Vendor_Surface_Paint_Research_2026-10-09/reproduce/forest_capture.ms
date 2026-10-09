RSAssert()
global VFCapture,VFLabel="forest_capture_corrected"
(
    fn VFCapture label = (
        local s=stringStream "",start=timestamp()
        VForest.trees.update()
        format "count % updateMs %\n" (VForest.trees.count()) (timestamp()-start) to:s
        for key in #(#surflist,#aridlist,#arnamelist,#pf_aractivelist,#artypelist,#arincexclist,#arselspeclist,#arspeclist) do format "% %\n" key (getProperty VForest key) to:s
        for i=1 to VForest.arpaintlist.count where VForest.arpaintlist[i]!=undefined do (
            local shape=VForest.arpaintlist[i]
            try (
                format "paint % shape % splines %\n" i shape (numSplines shape) to:s
                for j=1 to numSplines shape do (
                    format "spline % knots % closed %\n" j (numKnots shape j) (isClosed shape j) to:s
                    for k=1 to numKnots shape j do format "knot %\n" (getKnotPoint shape j k) to:s
                )
            ) catch (format "shape inspection: %\n" (getCurrentException()) to:s)
        )
        for i=0 to (VForest.trees.count()-1) do format "tree % % %\n" i (VForest.trees.getGeomID i) (VForest.trees.getFullTransform i) to:s
        RSWrite ("valid_"+label+".txt") (s as string);close s
    )
    VFCapture VFLabel
)
