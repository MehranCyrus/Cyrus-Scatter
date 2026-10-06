-- Disposable scene, invoked only by the private preview launcher.
(
    units.SystemType=#Centimeters;units.SystemScale=1
    local ground=plane name:"Demo receiving surface" width:600 length:500 widthsegs:8 lengthsegs:8 wirecolor:(color 115 125 105)
    local tree=cone name:"Tree model - move out to park" radius1:12 radius2:0 height:55 sides:10 heightsegs:1 pos:[470,80,0] wirecolor:(color 45 130 75)
    local shrub=sphere name:"Shrub model" radius:10 segs:12 pos:[470,-100,10] wirecolor:(color 120 180 75)
    local treeBox=rectangle name:"Trees - source rectangle" width:200 length:130 pos:[470,80,0] wirecolor:(color 80 180 240)
    local shrubBox=rectangle name:"Shrubs - source rectangle" width:200 length:130 pos:[470,-100,0] wirecolor:(color 80 180 240)
    local controller=AminScatterObject name:"Cyrus 0.7.1 - Select me and Edit layer",root=controller.baseObject
    root.setLayerTransfer true
    root.autoRender=false;root.updateMode=1;root.surfaceNodes=#(ground);root.viewportMode=3
    root.newLayer();local trees=root.selectedLayer()
    trees.amount=120;trees.sources=#(tree);trees.sourceWeights=#(1.0);trees.sourceRadii=#(12.0);trees.paintEnabled=false
    trees.containerNodes=#(treeBox);trees.containerMode=4
    root.newLayer();local shrubs=root.selectedLayer()
    shrubs.amount=260;shrubs.sources=#(shrub);shrubs.sourceWeights=#(1.0);shrubs.sourceRadii=#(10.0);shrubs.paintEnabled=false
    shrubs.containerNodes=#(shrubBox);shrubs.containerMode=4
    root.layerNames=#("Trees","Shrubs");root.setLayerTransfer false;root.procUpgrade()
    trees.procSelfOverride=true;trees.procSelfEnabled=true;trees.procSelfMultiplier=1;trees.procSelfGap=8
    root.procSetPair 2 trees shrubs true 1 8 false
    root.updateMode=2;root.refreshAll()
    select controller;max modify mode;modPanel.setCurrentObject root
    if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
    root.mainUI.selectLayerView trees expand:true
    viewport.setLayout #layout_1;viewport.setType #view_persp_user
    local eye=[1000,-1300,1200],target=[120,0,0],look=normalize(target-eye),right=normalize(cross look [0,0,1]),up=cross right look
    viewport.setTM (inverse(matrix3 right up (-look) eye))
    completeRedraw()
    saveMaxFile (MCPFixtureDir+"project/scenes/Layer_Editor_0.7.1_Demo.max") quiet:true
)
