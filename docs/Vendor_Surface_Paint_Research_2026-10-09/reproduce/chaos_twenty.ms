RSAssert()
global VTwenty,VTwentyExtra
(
    VTwenty=for i=1 to 20 collect (getNodeByName ("VS20_R"+i as string) exact:true)
    if VTwenty[1]==undefined do VTwenty=for i=1 to 20 collect (plane name:("VS20_R"+i as string) width:100 length:100 pos:[3000.+(i-1)*200.,0,0])
    VTwentyExtra=getNodeByName "VS20_R21" exact:true
    if VTwentyExtra==undefined do VTwentyExtra=plane name:"VS20_R21" width:100 length:100 pos:[9000,0,0]
    unhide VChaos
    for n in VTwenty do unhide n
    unhide VTwentyExtra
    VChaos.targetNodes=#();VChaos.targetFactors=#()
    VChaos.targetNodes=VTwenty;VChaos.targetFactors=for n in VTwenty collect 1.
    VChaos.surfaceRandomUseDensity=false;VChaos.surfaceRandomInstanceCount=10000
    VCapture "redraw_twenty_fixed_baseline" normalRedraw:true
    append VChaos.targetNodes VTwentyExtra;append VChaos.targetFactors 1.
    VCapture "redraw_twenty_fixed_add" normalRedraw:true
    deleteItem VChaos.targetNodes 21;deleteItem VChaos.targetFactors 21
    VChaos.surfaceRandomInstanceCount=500;VChaos.surfaceRandomEdgeSize=100.;VChaos.surfaceRandomUseDensity=true
    VCapture "redraw_twenty_density_baseline" normalRedraw:true
    append VChaos.targetNodes VTwentyExtra;append VChaos.targetFactors 1.
    VCapture "redraw_twenty_density_add" normalRedraw:true
    RSWrite "stage.txt" "Chaos twenty to twenty-one complete"
)
