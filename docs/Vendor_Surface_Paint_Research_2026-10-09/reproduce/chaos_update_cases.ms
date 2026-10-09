RSAssert()
(
    VModels=for name in #("VS_Box","VS_Sphere") collect getNodeByName name exact:true
    local first=getNodeByName "VS_R1" exact:true
    unhide VChaos
    VChaos.targetNodes=#();VChaos.targetFactors=#()
    VChaos.targetNodes=for name in #("VS_R1","VS_R2","VS_R3") collect getNodeByName name exact:true
    VChaos.targetFactors=#(1.,1.,1.)
    for n in VChaos.targetNodes do unhide n
    VChaos.surfaceRandomUseDensity=true;VChaos.surfaceRandomInstanceCount=100
    VChaos.automaticUpdates=true
    VCapture "update_baseline"
    VChaos.automaticUpdates=false
    first.pos.z=200.;redrawViews()
    VCapture "manual_external_move_before_update" force:false
    VCapture "manual_external_move_after_update"
    VChaos.surfaceRandomInstanceCount=101
    VCapture "manual_scatter_parameter_before_update" force:false
    first.pos.z=0.;VChaos.surfaceRandomInstanceCount=100;VChaos.automaticUpdates=true
    VCapture "update_restored"
    clearSelection();redrawViews();select VChaos;redrawViews()
    VCapture "interface_selection_only" force:false
    RSWrite "stage.txt" "Chaos update cases complete"
)
