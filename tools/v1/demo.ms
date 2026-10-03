-- Synthetic trial scene, deliberately confined to a private test profile.
global CyrusV1UIBaselineCount,CyrusV1UIBaselineHistory
(
    if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Demo requires a private v1 profile"
    resetMaxFile #noPrompt
    local target=plane name:"Cyrus_Brush_Surface" width:200 length:200 widthsegs:24 lengthsegs:24 wirecolor:(color 125 125 125)
    local tree=cone name:"Cyrus_Tree_Source" radius1:2.5 radius2:0 height:12 sides:8 heightsegs:1 capsegs:1 pos:[140,0,0]
    tree.wirecolor=color 48 140 55
    local shrub=sphere name:"Cyrus_Shrub_Source" radius:1.6 segs:8 pos:[140,15,0]
    shrub.wirecolor=color 115 165 70
    hide tree;hide shrub
    local node=CyrusScatterObject name:"Cyrus_Scatter_1_Demo",root=node.baseObject
    root.surfaceNodes=#(target);root.viewportMode=3;root.updateMode=1
    root.newLayer();root.layerNames[1]="Trees | Brush"
    local layer=root.layerObjects[1]
    layer.sources=#(tree);layer.sourceColors=#(tree.wirecolor);layer.amount=8000;layer.randomSeed=73
    layer.paintDocument=cyrusBrushCreate target;layer.paintIdentity=true;layer.paintEnabled=true
    cyrusBrushSettings layer.paintDocument 32 1 .5 false 1
    viewport.setLayout #layout_1;viewport.setType #view_persp_user
    local eye=[170,-220,190],look=normalize(-eye),right=normalize(cross look [0,0,1]),up=cross right look
    viewport.setTM (inverse(matrix3 right up (-look) eye))
    for p in #([-45,35,100],[0,0,100],[45,-35,100]) do cyrusBrushDab layer.paintDocument p [0,0,-1] true
    root.newLayer();root.layerNames[2]="Shrubs"
    root.layerObjects[2].sources=#(shrub);root.layerObjects[2].sourceColors=#(shrub.wirecolor);root.layerObjects[2].amount=700
    root.activeLayer=1;root.refreshAll()
    CyrusV1UIBaselineCount=layer.generatedCount
    CyrusV1UIBaselineHistory=(cyrusBrushHistory layer.paintDocument).count
    select node;max modify mode;root.bindNativeUI()
    saveMaxFile (BLDir+"Cyrus_Scatter_1_Demo.max") quiet:true
    CSPWriteText (BLDir+"demo-ready.json") (CSPObject #(#("scene",BLDir+"Cyrus_Scatter_1_Demo.max"),#("version",root.uiVersion()),#("layers",2),#("brush_placed",layer.generatedCount),#("manual_mode",true)))
    CSPWriteText (BLDir+"ui-baseline.json") (CSPObject #(#("placed",CyrusV1UIBaselineCount),#("strokes",CyrusV1UIBaselineHistory)))
)
