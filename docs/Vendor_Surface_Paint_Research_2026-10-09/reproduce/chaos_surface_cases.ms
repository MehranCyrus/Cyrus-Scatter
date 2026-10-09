RSAssert()
(
    local original=for n in VReceivers collect n
    local extra=getNodeByName "VS_R4" exact:true
    if extra==undefined do extra=plane name:"VS_R4" width:100 length:100 pos:[2000,0,0]
    fn VResetTargets nodes = (
        VChaos.targetNodes=#();VChaos.targetFactors=#()
        VChaos.targetNodes=nodes
        VChaos.targetFactors=for n in nodes collect 1.0
    )
    VResetTargets original
    VCapture "fixed_valid_baseline"
    VChaos.surfaceRandomUseDensity=false;VChaos.surfaceRandomInstanceCount=600
    VCapture "fixed_repeat"
    append VChaos.targetNodes extra;append VChaos.targetFactors 1.0
    VCapture "fixed_add"
    deleteItem VChaos.targetNodes 4;deleteItem VChaos.targetFactors 4
    VCapture "fixed_restore"
    VResetTargets #(original[3],original[2],original[1])
    VCapture "fixed_reverse_rebuild_list"
    VResetTargets original
    VCapture "fixed_order_restore"
    deleteItem VChaos.targetNodes 2;deleteItem VChaos.targetFactors 2
    VCapture "fixed_remove_middle"
    VResetTargets original
    VChaos.surfaceRandomInstanceCount=100;VChaos.surfaceRandomEdgeSize=100.;VChaos.surfaceRandomUseDensity=true
    VCapture "density_three"
    VCapture "density_repeat"
    append VChaos.targetNodes extra;append VChaos.targetFactors 1.0
    VCapture "density_add"
    deleteItem VChaos.targetNodes 4;deleteItem VChaos.targetFactors 4
    VCapture "density_restore"
    VResetTargets #(original[3],original[2],original[1])
    VCapture "density_reverse_rebuild_list"
    VResetTargets original
    VCapture "density_order_restore"
    deleteItem VChaos.targetNodes 2;deleteItem VChaos.targetFactors 2
    VCapture "density_remove_middle"
    VResetTargets original
    original[1].pos.z=100.
    VCapture "density_move_first"
    original[1].pos.z=0.
    VCapture "density_move_restore"
    clearSelection();redrawViews();select original[2];redrawViews();select VChaos
    VCapture "density_after_selection_redraw"
    RSWrite "stage.txt" "Chaos surface cases complete"
)
