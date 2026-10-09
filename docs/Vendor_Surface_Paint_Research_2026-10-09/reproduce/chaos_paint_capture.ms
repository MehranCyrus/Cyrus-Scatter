RSAssert()
global VPCapture
(
    fn VPCapture label = (
        local previous=VChaos
        VChaos=VPScatter
        try (VCapture ("paint_"+label);VChaos=previous) catch (VChaos=previous;throw())
        local s=stringStream ""
        for key in #(#targetNodes,#clustersMode,#layerData,#layerRecords,#layerList,#layerListRecords,#layerDetails,#layerLabels) do format "% %\n" key (getProperty VPScatter key) to:s
        RSWrite ("paint_"+label+"_records.txt") (s as string);close s
    )
    VPCapture "before_strokes"
)
