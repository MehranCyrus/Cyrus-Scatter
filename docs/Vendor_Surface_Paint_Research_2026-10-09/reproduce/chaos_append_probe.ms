RSAssert()
(
    local extra=getNodeByName "VS_R4" exact:true
    RSWrite "stage.txt" "Append one target"
    append VChaos.targetNodes extra
    append VChaos.targetFactors 1.0
    RSWrite "target-append.txt" (VChaos.targetNodes as string)
    VCapture "fixed_append_probe"
)
