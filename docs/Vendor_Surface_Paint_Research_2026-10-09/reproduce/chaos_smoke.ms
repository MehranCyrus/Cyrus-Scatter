RSAssert()
global VReceivers,VModels,VChaos,VForest
(
    units.SystemType=#Centimeters;units.SystemScale=1.0
    VReceivers=#(plane name:"VS_R1" width:100 length:100,plane name:"VS_R2" width:100 length:200 pos:[400,0,0],plane name:"VS_R3" width:100 length:300 pos:[900,0,0])
    VModels=#(box name:"VS_Box" width:2 length:3 height:5 pos:[-1000,-1000,0],sphere name:"VS_Sphere" radius:2 segs:8 pos:[-1100,-1000,0])
    RSWrite "stage.txt" "Create Chaos"
    VChaos=ChaosScatter name:"VS_Chaos"
    RSWrite "vendor-version.txt" (VChaos.StaticFpInterface.getVersionString())
    RSWrite "stage.txt" "Disable automatic updates"
    VChaos.automaticUpdates=false
    RSWrite "stage.txt" "Set model list"
    VChaos.modelNodes=VModels
    RSWrite "stage.txt" "Set model frequencies"
    VChaos.modelFrequencies=#(1.0,1.0)
    RSWrite "stage.txt" "Set target list"
    VChaos.targetNodes=VReceivers
    RSWrite "stage.txt" "Set target factors"
    VChaos.targetFactors=#(1.0,1.0,1.0)
    RSWrite "stage.txt" "Set seed and count"
    VChaos.seed=42;VChaos.surfaceRandomInstanceCount=600;VChaos.surfaceRandomUseDensity=false;VChaos.collisionAvoid=false
    RSWrite "stage.txt" "Read cached instance count"
    RSWrite "cached-count.txt" ((VChaos.FpInterface.getInstanceCount()) as string)
    RSWrite "stage.txt" "Enable normal automatic updates"
    VChaos.automaticUpdates=true
    RSWrite "stage.txt" "Normal redraw"
    redrawViews()
    RSWrite "stage.txt" "Redraw returned"
)
