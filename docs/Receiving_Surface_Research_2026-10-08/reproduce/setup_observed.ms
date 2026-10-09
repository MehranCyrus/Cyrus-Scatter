RSAssert()
global RSReceivers,RSModels,RSForest,RSChaos,RSCyrus
(
    units.SystemType=#Centimeters;units.SystemScale=1.0
    RSWrite "stage.txt" "Create three receivers and two models"
    RSReceivers=#()
    for spec in #(#(100,0),#(200,400),#(300,900)) do append RSReceivers (plane name:("RS_Surface_"+((RSReceivers.count+1) as string)) width:100 length:spec[1] widthsegs:1 lengthsegs:1 pos:[spec[2],0,0])
    RSModels=#(box name:"RS_Model_Box" width:2 length:3 height:5 pos:[-1000,-1000,0],sphere name:"RS_Model_Sphere" radius:2 segs:8 pos:[-1100,-1000,0])
    RSForest=Forest_Lite name:"RS_Forest"
    RSWrite "stage.txt" "Configure Forest geometry"
    RSForest.cobjlist=RSModels;RSForest.geomlist=#(0,0);RSForest.namelist=#("Box","Sphere")
    RSForest.widthlist=#(2.0,4.0);RSForest.heightlist=#(5.0,4.0);RSForest.scalelist=#(100.0,100.0)
    RSForest.problist=#(1.0,1.0);RSForest.usemeshdimlist=#(true,true)
    RSWrite "stage.txt" "Configure Forest receiving surfaces"
    RSForest.surflist=RSReceivers;RSForest.pf_aractivelist=#(true)
    RSForest.units_x=1000;RSForest.units_y=1000;RSForest.pixels_x=100;RSForest.pixels_y=100
    RSForest.seed=42;RSForest.collision=false;RSForest.manualupdate=false
    RSWrite "stage.txt" "Read Forest count without forcing API update"
    local f=stringStream ""
    format "Forest count % surface references % geometry types %\n" (RSForest.trees.count()) RSForest.surflist RSForest.geomlist to:f
    try(format "Forest first transform % geom %\n" (RSForest.trees.getFullTransform 0) (RSForest.trees.getGeomID 0) to:f)catch(format "Forest read error %\n" (getCurrentException()) to:f)
    RSWrite "forest-smoke.txt" (f as string);close f
    RSWrite "stage.txt" "Configure Chaos without explicit update method"
    RSChaos=ChaosScatter name:"RS_Chaos"
    RSChaos.modelNodes=RSModels;RSChaos.modelFrequencies=#(1.0,1.0)
    RSChaos.targetNodes=RSReceivers;RSChaos.targetFactors=#(1.0,1.0,1.0)
    RSChaos.seed=42;RSChaos.surfaceRandomInstanceCount=600;RSChaos.surfaceRandomUseDensity=false
    RSChaos.collisionAvoid=false;RSChaos.scaleFrom=[80,80,80];RSChaos.scaleTo=[120,120,120]
    RSChaos.displayInstanceCountLimit=10000;RSChaos.instanceCountLimit=10000;RSChaos.adaptivePreview=false
    RSWrite "stage.txt" "Read Chaos count"
    RSWrite "chaos-smoke.txt" ("Count "+((RSChaos.FpInterface.getInstanceCount()) as string))
    RSWrite "stage.txt" "Redraw both plugins"
    redrawViews()
    RSWrite "counts-after-redraw.txt" ("Forest "+((RSForest.trees.count()) as string)+" Chaos "+((RSChaos.FpInterface.getInstanceCount()) as string))
    RSWrite "stage.txt" "Setup completed"
)
