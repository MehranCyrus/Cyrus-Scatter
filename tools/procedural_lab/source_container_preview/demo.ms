-- Called only by this launcher's fresh, isolated Max process.
(
    local ground=plane name:"DEMO - Receiving surface" width:400 length:400 widthsegs:4 lengthsegs:4 wirecolor:(color 100 120 100)
    local tree=cone name:"DEMO - Move this tree outside the rectangle" radius1:8 radius2:0 height:35 sides:10 heightsegs:1 pos:[320,0,0] wirecolor:(color 60 160 70)
    local shrub=sphere name:"DEMO - Shrub source" radius:12 segs:12 pos:[380,0,12] wirecolor:(color 145 190 60)
    local container=rectangle name:"DEMO - Trees and shrubs source container" width:180 length:120 pos:[350,0,0] wirecolor:(color 80 180 240)
    local controller=AminScatterObject name:"DEMO - SELECT THIS for Source containers",root=controller.baseObject
    root.setLayerTransfer true
    root.autoRender=false;root.updateMode=1;root.surfaceNodes=#(ground);root.newLayer()
    local layer=root.selectedLayer()
    layer.amount=64;layer.sources=#(tree);layer.sourceWeights=#(1.0);layer.paintEnabled=false;layer.randomSeed=42
    layer.viewportMode=3;layer.containerNodes=#(container);layer.containerMode=4
    root.setLayerTransfer false;root.procUpgrade();root.refreshAll()
    if layer.sources.count!=2 or root.groupSnapshotRows[1].count!=64 do throw "Demo source registration/population failed"
    local originalPosition=tree.pos,ids=layer.procSourceSlots as string,originalRows=root.groupSnapshotRows[1].count
    tree.pos=[520,0,0];root.evaluateGroups()
    if root.groupSnapshotRows[1].count>=originalRows do throw "Demo parking failed"
    tree.pos=originalPosition;root.evaluateGroups()
    if root.groupSnapshotRows[1].count!=originalRows or layer.procSourceSlots as string!=ids do throw "Demo reentry failed"
    root.updateMode=2;root.refreshAll()
    select controller
    max modify mode
    root.bindNativeUI()
    completeRedraw()
)
