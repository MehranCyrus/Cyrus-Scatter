RSAssert()
(
    append VChaos.targetNodes VTwentyExtra;append VChaos.targetFactors 1.
    redrawViews()
    RSWrite "stage.txt" "Twenty-one configured; wait for callback return before export"
)
