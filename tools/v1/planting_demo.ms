-- Clean synthetic artist exercise; never execute in an artist's open scene.
global CyrusGroupsDemo,CyrusGroupsUIHistory,CyrusGroupsUICount
(
    if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Private profile required"
    resetMaxFile #noPrompt
    local target=plane name:"Shared_garden_surface" width:200 length:200 widthsegs:24 lengthsegs:24 wirecolor:(color 95 100 90)
    local sources=#(
        cone name:"Grass_asset" radius1:0.7 radius2:0 height:3 sides:5 heightsegs:1 capsegs:1 pos:[140,0,0],
        sphere name:"Red_flower_asset" radius:1.3 segs:8 pos:[140,10,0],
        sphere name:"Blue_flower_asset" radius:1.3 segs:8 pos:[140,20,0],
        sphere name:"Yellow_flower_asset" radius:1.3 segs:8 pos:[140,30,0]
    )
    local colors=#(color 65 135 45,color 220 60 70,color 65 100 230,color 240 205 40)
    local node=CyrusScatterObject name:"Cyrus_Scatter_1_Demo",root=node.baseObject
    root.surfaceNodes=#(target);root.viewportMode=3;root.viewportInstances=20000;root.viewportFaces=2000000;root.updateMode=1
    viewport.setLayout #layout_1;viewport.setType #view_persp_user
    local eye=[170,-220,230],look=normalize(-eye),right=normalize(cross look [0,0,1]),up=cross right look
    viewport.setTM (inverse(matrix3 right up (-look) eye))
    for i=1 to 4 do (
        sources[i].wirecolor=colors[i];hide sources[i]
        root.newLayer();root.layerNames[i]=(#("Grass","Red flowers","Blue flowers","Yellow flowers"))[i]
        local group=root.layerObjects[i]
        group.sources=#(sources[i]);group.sourceColors=#(colors[i]);group.randomSeed=73+i
        group.amount=if i==1 then 6000 else 7000
        group.collisionEnabled=true;group.collisionRadius=if i==1 then .7 else 2.0
        group.sourceZOffsets=#(if i==1 then 0.0 else 1.8)
        if i>1 do (
            root.setGroupCoverage group true
            group.paintColor=colors[i]
            cyrusBrushSettings group.paintDocument 48 1 .4 false 1
            cyrusBrushDab group.paintDocument [(i-3)*38,10,100] [0,0,-1] true
        )
    )
    for i=1 to 3 do for j=i+1 to 4 do root.setGroupPair root.layerObjects[i] root.layerObjects[j] true (if i==1 then 3 else 4) false true
    root.activeLayer=2;root.refreshAll()
    for group in root.layerObjects where (group.cacheSnapshot())[4]!="" do throw (group.cacheSnapshot())[4]
    select node;max modify mode;root.bindNativeUI()
    for panel in root.nativeEditors() do panel.open=false
    root.mainUI.open=true
    saveMaxFile (BLDir+"Cyrus_Scatter_1.1_Plant_Groups_Demo.max") quiet:true
    CyrusGroupsDemo=node
    CyrusGroupsUIHistory=(cyrusBrushHistory root.layerObjects[2].paintDocument).count
    CyrusGroupsUICount=root.layerObjects[2].generatedCount
    CSPWriteText (BLDir+"groups-demo.json") (CSPObject #(#("version",root.uiVersion()),#("scene",BLDir+"Cyrus_Scatter_1.1_Plant_Groups_Demo.max"),#("names",root.layerNames as array),#("placed",for group in root.layerObjects collect group.generatedCount),#("shared_surface",target.name)))
)
