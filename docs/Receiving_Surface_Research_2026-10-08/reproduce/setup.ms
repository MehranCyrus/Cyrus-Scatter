RSAssert()
global RSReceivers,RSModels,RSForest,RSChaos,RSCyrus
(
    units.SystemType=#Centimeters;units.SystemScale=1.0
    if RSReceivers==undefined do (
        RSReceivers=#()
        for spec in #(#(100,0),#(200,400),#(300,900)) do append RSReceivers (plane name:("RS_Surface_"+((RSReceivers.count+1) as string)) width:100 length:spec[1] widthsegs:1 lengthsegs:1 pos:[spec[2],0,0])
        RSModels=#(box name:"RS_Model_Box" width:2 length:3 height:5 pos:[-1000,-1000,0],sphere name:"RS_Model_Sphere" radius:2 segs:8 pos:[-1100,-1000,0])
    )
    RSChaos=getNodeByName "Research_ChaosScatter"
    RSChaos.modelNodes=#();RSChaos.modelNodes=RSModels;RSChaos.modelFrequencies=#(1.0,1.0)
    RSChaos.targetNodes=#();RSChaos.targetNodes=RSReceivers;RSChaos.targetFactors=#(1.0,1.0,1.0)
    RSChaos.seed=42;RSChaos.surfaceRandomInstanceCount=600;RSChaos.surfaceRandomUseDensity=false
    RSChaos.collisionAvoid=false;RSChaos.scaleFrom=[80,80,80];RSChaos.scaleTo=[120,120,120]
    RSChaos.displayInstanceCountLimit=10000;RSChaos.instanceCountLimit=10000;RSChaos.adaptivePreview=false
    local f=stringStream ""
    format "Chaos version: %\n" (RSChaos.StaticFpInterface.getVersionString()) to:f
    local started=timeStamp(),result=RSChaos.FpInterface.update (interval 0 0) 0
    format "Chaos update result %, count %, elapsed %\n" result (RSChaos.FpInterface.getInstanceCount()) (timeStamp()-started) to:f
    RSForest=getNodeByName "Research_Forest_Lite"
    RSForest.cobjlist=RSModels;RSForest.geomlist=#(0,0);RSForest.namelist=#("Box","Sphere")
    RSForest.widthlist=#(2.0,4.0);RSForest.heightlist=#(5.0,4.0);RSForest.scalelist=#(100.0,100.0)
    RSForest.problist=#(1.0,1.0);RSForest.usemeshdimlist=#(true,true)
    RSForest.surflist=RSReceivers;RSForest.pf_aractivelist=#(true)
    RSForest.units_x=1000;RSForest.units_y=1000;RSForest.pixels_x=100;RSForest.pixels_y=100
    RSForest.seed=42;RSForest.collision=false;RSForest.manualupdate=false
    started=timeStamp();RSForest.trees.update()
    format "Forest count %, elapsed %, areas % active % surfaces %\n" (RSForest.trees.count()) (timeStamp()-started) RSForest.artypelist RSForest.pf_aractivelist RSForest.surflist to:f
    try(format "Forest first transform: % geom %\n" (RSForest.trees.getFullTransform 0) (RSForest.trees.getGeomID 0) to:f)catch(format "Forest read error %\n" (getCurrentException()) to:f)
    RSWrite "setup-result.txt" (f as string);close f
)
