-- Create a disposable artist example after qualification. Requires acceptance helpers.
(
    P07Case="artist example"
    P07New count:1800
    local root=P07Root,red=P07Layer
    P07Node.name="Cyrus_07_Procedural_Example";P07Surface.name="Garden_Receiver"
    P07Surface.wirecolor=color 105 105 95;P07Source.name="Grass_Asset"
    root.layerNames[1]="Flowers and Grass";red.paintSetName="Red flowers"
    local redAsset=sphere name:"Red_Flower_Asset" radius:10 segs:8 pos:[1200,0,0]
    local blueAsset=sphere name:"Blue_Flower_Asset" radius:12 segs:8 pos:[1250,0,0]
    local treeAsset=cone name:"Tree_Asset" radius1:23 radius2:0 height:110 sides:8 heightsegs:1 pos:[1350,0,0]
    redAsset.wirecolor=color 240 85 85;blueAsset.wirecolor=color 80 145 245;treeAsset.wirecolor=color 50 140 85
    for n in #(redAsset,blueAsset,treeAsset) do hide n
    red.sources=#(redAsset);red.sourceRadii=#(10.0);red.sourceColors=#(redAsset.wirecolor)
    root.setGroupCoverage red true;cyrusBrushFill red.paintDocument 0
    cyrusBrushSettings red.paintDocument 210 1 .3 false 1
    cyrusBrushDab red.paintDocument [-180,80,500] [0,0,-1] true
    local blue=root.addPaintSet red label:"Blue flowers"
    blue.sources=#(blueAsset);blue.sourceRadii=#(12.0);blue.sourceColors=#(blueAsset.wirecolor)
    cyrusBrushFill blue.paintDocument 0;cyrusBrushSettings blue.paintDocument 200 1 .3 false 1
    cyrusBrushDab blue.paintDocument [140,40,500] [0,0,-1] true
    local grass=root.addPaintSet red label:"Grass outside beds"
    grass.sources=#(P07Source);grass.sourceRadii=#(3.0);grass.sourceColors=#(color 100 195 90)
    grass.paintEnabled=false;grass.paintSetWeight=3
    grass.procBackground=4;grass.procBackgroundIDs=#(red.layerID,blue.layerID)
    red.procSiblingEnabled=true;red.procSiblingMultiplier=1;red.procSiblingGap=4
    for leaf in #(red,blue,grass) do (leaf.procSelfOverride=true;leaf.procSelfEnabled=true;leaf.procSelfMultiplier=1;leaf.procSelfGap=3)
    red.procPopulation=2;red.procAttemptFactor=8
    root.newLayer();local trees=root.selectedLayer()
    root.layerNames[findItem root.layerObjects trees]="Trees first"
    trees.paintSetName="Trees"
    trees.sources=#(treeAsset);trees.sourceRadii=#(40.0);trees.sourceColors=#(treeAsset.wirecolor);trees.amount=24;trees.paintEnabled=false
    trees.procSelfOverride=true;trees.procSelfEnabled=true;trees.procSelfMultiplier=1;trees.procSelfGap=40
    root.procSetPair 2 trees red true 1 10 false;root.procMove trees -1
    root.viewportInstances=20000;root.previewBudget=100000;root.setGroupDisplay 3
    root.refreshAll()
    for leaf in root.layerObjects do P07Assert (leaf.previewError=="") "Demo contains a preview error"
    viewport.setLayout #layout_1;viewport.setType #view_persp_user;viewport.setRenderLevel #smoothhighlights
    local eye=[1050,-1350,1550],look=normalize([0,0,0]-eye),right=normalize(cross look [0,0,1]),up=cross right look
    viewport.setTM (inverse(matrix3 right up (-look) eye))
    select P07Node;max modify mode;modPanel.setCurrentObject root;root.bindNativeUI()
    for r in root.nativeEditors() do r.open=false
    for p in root.layerPanels do p.open=false
    root.mainUI.layoutPanels();root.mainUI.scrollPos=0
    local path=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\procedural-0.7-candidate\CyrusScatter-0.7-Example-Max2027.max"
    saveMaxFile path quiet:true
    CSPWriteText (MCPFixtureDir+"artist-example.json") (CSPObject #(#("file",path),#("counts",for leaf in root.layerObjects collect #(leaf.paintSetName,leaf.generatedCount)),#("system_units",units.SystemType as string),#("display","Mesh")))
    completeRedraw()
)
