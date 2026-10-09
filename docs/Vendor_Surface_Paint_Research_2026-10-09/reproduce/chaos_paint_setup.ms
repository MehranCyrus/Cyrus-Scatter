RSAssert()
global VPScatter,VPReceivers
(
    for n in objects where matchPattern n.name pattern:"VS*" or matchPattern n.name pattern:"VF_*" do hide n
    VPReceivers=#(plane name:"VP_Flat" width:100 length:100,sphere name:"VP_Curved" radius:50 segs:24 pos:[300,0,0])
    VPScatter=ChaosScatter name:"VP_Scatter"
    for name in #("VS_Box","VS_Sphere") do VPScatter.FpInterface.addModelNode (getNodeByName name exact:true)
    VPScatter.targetNodes=VPReceivers;VPScatter.targetFactors=#(1.,1.)
    VPScatter.seed=42;VPScatter.surfaceRandomInstanceCount=400;VPScatter.surfaceRandomUseDensity=false;VPScatter.collisionAvoid=false
    VPScatter.clustersEnabled=true
    select VPReceivers;viewport.setType #view_top;max zoomext sel all
    select VPScatter;max modify mode;modPanel.setCurrentObject VPScatter;redrawViews()
    RSWrite "stage.txt" "Chaos curved paint fixture configured"
)
