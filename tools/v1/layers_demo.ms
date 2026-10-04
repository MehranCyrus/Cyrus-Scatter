if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Private profile required"
resetMaxFile #noPrompt
(
    local surface=plane name:"Garden_surface" width:200 length:200 widthsegs:24 lengthsegs:24 wirecolor:(color 100 110 90)
    local sources=#(cone name:"Grass_asset" radius1:.7 radius2:0 height:3 sides:5 heightsegs:1 capsegs:1 pos:[140,0,0],sphere name:"Red_flower" radius:1.3 segs:8 pos:[140,10,0],sphere name:"Blue_flower" radius:1.3 segs:8 pos:[140,20,0],sphere name:"Yellow_flower" radius:1.3 segs:8 pos:[140,30,0])
    local colors=#(color 65 135 45,color 220 60 70,color 65 100 230,color 240 205 40)
    local node=CyrusScatterObject name:"Cyrus_Scatter_1_Demo",root=node.baseObject
    root.surfaceNodes=#(surface);root.viewportMode=3;root.viewportInstances=20000;root.updateMode=1
    root.newLayer();root.layerNames[1]="Grass"
    local grass=root.layerObjects[1]
    grass.sources=#(sources[1]);grass.sourceColors=#(colors[1]);grass.amount=6000;grass.collisionEnabled=true;grass.collisionRadius=.7
    root.newLayer();root.layerNames[2]="Flowers"
    local flowers=root.layerObjects[2]
    flowers.paintSetName="Red";flowers.amount=21000;flowers.collisionEnabled=true;flowers.collisionRadius=2
    root.setGroupCoverage flowers true
    local blue=root.addPaintSet flowers label:"Blue",yellow=root.addPaintSet flowers label:"Yellow",sets=root.layerSets flowers
    for i=1 to 3 do (
        local leaf=sets[i]
        leaf.sources=#(sources[i+1]);leaf.sourceColors=#(colors[i+1]);leaf.sourceZOffsets=#(1.8);leaf.paintColor=colors[i+1]
        cyrusBrushSettings leaf.paintDocument 48 1 .4 false 1
        cyrusBrushDab leaf.paintDocument [(i-2)*38,10,100] [0,0,-1] true
    )
    root.setGroupPair grass flowers true 3 false true
    for i=1 to 4 do (sources[i].wirecolor=colors[i];hide sources[i])
    root.refreshAll();flowers.uiPaintSetID=flowers.layerID
    for leaf in root.layerObjects where leaf.previewError!="" do throw leaf.previewError
    viewport.setLayout #layout_1;viewport.setType #view_persp_user
    local eye=[170,-220,230],look=normalize(-eye),right=normalize(cross look [0,0,1]),up=cross right look
    viewport.setTM (inverse(matrix3 right up (-look) eye))
    select node;max modify mode;root.bindNativeUI()
    root.mainUI.open=false;root.layersUI.open=true
    for p in root.layerPanels do p.open=false
    root.layerPanels[2].open=true;root.layerPanels[2].mount()
    saveMaxFile (BLDir+"Cyrus_Scatter_1.2_Layers_Demo.max") quiet:true
    CSPWriteText (BLDir+"layers-demo.json") (CSPObject #(#("version",root.uiVersion()),#("logical_layers",2),#("populations",4),#("placed",for leaf in root.layerObjects collect leaf.generatedCount)))
)
