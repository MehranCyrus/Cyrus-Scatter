RSAssert()
(
    VChaos.targetNodes=#();VChaos.targetFactors=#()
    VChaos.targetNodes=VTwenty;VChaos.targetFactors=for n in VTwenty collect 1.
    VChaos.surfaceRandomUseDensity=false;VChaos.surfaceRandomInstanceCount=10000
    select VChaos;max modify mode;modPanel.setCurrentObject VChaos;redrawViews()
    RSWrite "stage.txt" "Twenty configured; let host message loop run before capture"
)
