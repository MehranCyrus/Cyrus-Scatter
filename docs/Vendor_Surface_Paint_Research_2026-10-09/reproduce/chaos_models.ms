RSAssert()
(
    local s=stringStream ""
    format "before modelCount % groupIDs %\n" (VChaos.FpInterface.getModelCount()) VChaos.modelClusterGroupIds to:s
    VChaos.modelNodes=#();VChaos.modelFrequencies=#();VChaos.modelClusterGroupIds=#()
    for model in VModels do format "addModelNode % result %\n" model (VChaos.FpInterface.addModelNode model) to:s
    format "after modelCount % models % frequencies % groupIDs %\n" (VChaos.FpInterface.getModelCount()) VChaos.modelNodes VChaos.modelFrequencies VChaos.modelClusterGroupIds to:s
    RSWrite "chaos-model-add.txt" (s as string);close s
    VCapture "fixed_three_supported_models"
)
