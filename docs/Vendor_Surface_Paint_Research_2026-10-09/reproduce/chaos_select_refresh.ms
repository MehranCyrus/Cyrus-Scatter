RSAssert()
(
    select VChaos;max modify mode;modPanel.setCurrentObject VChaos
    redrawViews()
    local s=stringStream ""
    format "hidden % automatic % countParameter % density % targets % cachedCount %\n" VChaos.isHidden VChaos.automaticUpdates VChaos.surfaceRandomInstanceCount VChaos.surfaceRandomUseDensity VChaos.targetNodes (VChaos.FpInterface.getInstanceCount()) to:s
    RSWrite "chaos-selected-refresh.txt" (s as string);close s
)
