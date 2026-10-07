-- New unified controller in a private copy of the supplied asset scene.
-- Every save destination is a new qualification artifact, never the input.
(
    if findString MCPFixtureDir "/real073-"==undefined do throw "Owned real-asset host required"
    global Real073Node,Real073Root,Real073Plants,Real073Parents,Real073Sets,Real073Surface,Real073Out,Real073Walk
    if (getClassInstances AminScatterObject).count>0 do throw "Build requires the asset-only private input"
    Real073Out=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/Cyrus_073_Qualification/"
    makeDir Real073Out all:true
    fn Real073Assert condition message = (if not condition do throw message;true)
    local names=#("crp_MT_PM_V33_Myrtle_01_003","crp_MT_PM_Rosa_rugosa_01_02","crp_MT_PM_Sambucus_nigra_02_01","MT_PM_V41_Arthropodium_01_01","MT_PM_V41_Arthropodium_01_04","crp_Lavander_01","crp_Lavander_05","crp_MT_PM_V33_Glossy_abelia_01_006","MT_PM_V41_Geranium_robertianum_01_04","MT_PM_V41_Lamium_maculatum_01_04","MT_PM_V41_Phlox_stolonifera_01_01","MT_PM_V41_Viola_sororia_01_05","clover_pack_004","grass_bush","grass_small")
    Real073Plants=for name in names collect getNodeByName name
    for model in Real073Plants do Real073Assert (isValidNode model) ("Missing plant: "+model.name)
    for model in Real073Plants do model.renderable=false
    saveNodes Real073Plants (Real073Out+"Cyrus_073_Plant_Library.max") quiet:true
    Real073Surface=getNodeByName "Garden receiver - flat meadow and curved berm"
    Real073Assert (isValidNode Real073Surface) "Receiving terrain missing"
    Real073Node=AminScatterObject name:"CYRUS 0.73 | Heavy garden - unified workflow" pos:[-1580,-1280,0]
    Real073Root=Real073Node.baseObject
    local root=Real073Root
    root.updateMode=1;root.surfaceNodes=#(Real073Surface);root.autoRender=true
    root.viewportMode=1;root.pointsPerPlant=12;root.previewBudget=200000;root.viewportInstances=3000;root.viewportFaces=1500000
    Real073Parents=#()
    for i=1 to 5 do (root.newLayer();append Real073Parents (root.selectedLayer()))
    local shrubs=Real073Parents[1],perennials=Real073Parents[2],lavender=Real073Parents[3],walk=Real073Parents[4],flowers=Real073Parents[5]
    local parentNames=#("01 | Structural shrubs","02 | Flowering perennials","03 | Lavender ribbons","04 | Painted curved walk","05 | Meadow tapestry")
    root.layerNames=parentNames
    local excludeNames=#("EXCLUDE | pavilion and terrace","EXCLUDE | reflecting pool","EXCLUDE | entry walk")
    local excludes=for name in excludeNames collect getNodeByName name
    for leaf in Real073Parents do (
        leaf.paintEnabled=false;leaf.randomSeed=730+113*(findItem Real073Parents leaf)
        leaf.areaNodes=excludes as array;leaf.areaModes=#(2,2,2)
        leaf.rotZMin=0;leaf.rotZMax=360;leaf.wholeScaleMin=.88;leaf.wholeScaleMax=1.15;leaf.alignNormal=true
        leaf.procPopulation=1;leaf.procAttemptFactor=16;leaf.procRounds=5
    )
    shrubs.amount=120;shrubs.sources=#(Real073Plants[1],Real073Plants[2],Real073Plants[3]);shrubs.sourceWeights=#(1.0,.56,.39);shrubs.sourceRadii=#(56,49,50)
    shrubs.sourceScales=#(1.1,1.05,1.15)
    shrubs.areaNodes=join (for name in #("INCLUDE | rear shrub band","INCLUDE | west shrub bed","INCLUDE | east shrub bed") collect getNodeByName name) (excludes as array)
    shrubs.areaModes=#(1,1,1,2,2,2);shrubs.procPopulation=2
    perennials.amount=260;perennials.sources=#(Real073Plants[4],Real073Plants[5]);perennials.sourceWeights=#(1.0,.33);perennials.sourceRadii=#(36,42)
    lavender.amount=220;lavender.sources=#(Real073Plants[6],Real073Plants[7],Real073Plants[8]);lavender.sourceWeights=#(1.0,1.0,.2);lavender.sourceRadii=#(22,22,30);lavender.sourceScales=#(.8,.8,.8)
    lavender.areaNodes=for name in #("INCLUDE | west lavender ribbon","INCLUDE | east lavender ribbon") collect getNodeByName name;lavender.areaModes=#(1,1);lavender.procPopulation=2
    flowers.amount=30000;flowers.paintSetName="Flower drifts";flowers.paintSetWeight=1.2
    flowers.sources=for i=9 to 12 collect Real073Plants[i];flowers.sourceWeights=#(.5,.3,1.0,.5);flowers.sourceScales=#(2.0,2.0,2.4,2.3);flowers.sourceRadii=#(8,7,6,5)
    local clover=root.addPaintSet flowers label:"Clover outside flower coverage"
    clover.sources=#(Real073Plants[13]);clover.sourceWeights=#(1.0);clover.sourceScales=#(3.4);clover.sourceRadii=#(2);clover.paintSetWeight=1.3;clover.paintEnabled=false
    clover.procBackground=2;clover.procBackgroundIDs=#(flowers.layerID)
    local grass=root.addPaintSet flowers label:"Grass between flowering plants"
    grass.sources=#(Real073Plants[14],Real073Plants[15]);grass.sourceWeights=#(.5,1.0);grass.sourceScales=#(2.6,2.6);grass.sourceRadii=#(1.5,1.0);grass.paintSetWeight=7.5;grass.paintEnabled=false
    grass.procBackground=3;grass.procBackgroundIDs=#(flowers.layerID)
    walk.amount=12000;walk.paintSetName="Outer walk flowers";walk.sources=#(getNodeByName "PATH | MT_PM_V41_Phlox_stolonifera_01_01",getNodeByName "PATH | MT_PM_V41_Viola_sororia_01_05")
    walk.sourceWeights=#(1.0,.75);walk.sourceScales=#(2.5,2.5);walk.sourceRadii=#(5,5)
    local inner=root.addPaintSet walk label:"Inner walk flowers"
    inner.sources=#(getNodeByName "PATH | MT_PM_V41_Lamium_maculatum_01_04",getNodeByName "PATH | MT_PM_V41_Geranium_robertianum_01_04")
    inner.sourceWeights=#(1.0,.75);inner.sourceScales=#(2.5,2.5);inner.sourceRadii=#(5,5);inner.paintEnabled=false
    Real073Sets=#(shrubs,perennials,lavender,walk,inner,flowers,clover,grass)
    local paletteNames=#("01 Shrubs","02 Perennials","03 Lavender","07 Path flowers","08 Path flowers","04 Flowers","05 Clover","06 Grasses")
    for i=1 to Real073Sets.count do (
        local leaf=Real073Sets[i],spline=getNodeByName ("SOURCE CONTAINER | "+paletteNames[i])
        Real073Assert (isValidNode spline) "Source palette missing"
        leaf.containerAdd spline;leaf.containerSetMode 4
        local c=leaf.containerNodes[1];c.name="CS 0.73 Sources | "+paletteNames[i]
        spline.isHidden=true
        leaf.sourceFollowScale=for s in leaf.sources collect true
        leaf.procSelfOverride=true;leaf.procSelfEnabled=true;leaf.procSelfMultiplier=.7;leaf.procSelfGap=1
    )
    for leaf in #(shrubs,perennials,lavender) do (leaf.procSelfGap=6;leaf.procSelfMultiplier=.85)
    for i=1 to Real073Parents.count-1 do for j=i+1 to Real073Parents.count do root.procSetPair 2 Real073Parents[i] Real073Parents[j] true .72 8 true
    root.procSetPair 1 flowers grass true .7 2 true
    root.procSetPair 1 walk inner true .7 1 true
    flowers.setFallConfig excludes[3] #(true,8.0,false,100.0,#(0.0,1.0),true,40.0,#(0.0,1.0))
    root.setGroupCoverage perennials true;cyrusBrushSettings perennials.paintDocument 360 1 .18 false 1
    for p in #([-970,-530,700],[990,-590,700],[1090,410,700]) do Real073Assert (cyrusBrushDab perennials.paintDocument p [0,0,-1] true) "Perennial Brush missed"
    root.setGroupCoverage flowers true;cyrusBrushSettings flowers.paintDocument 330 1 .35 false 1
    for p in #([-720,-660,700],[-910,-250,700],[820,-450,700],[1170,340,700]) do Real073Assert (cyrusBrushDab flowers.paintDocument p [0,0,-1] true) "Flower Brush missed"
    local controls=#([-1050,-1055,0],[-1020,-820,0],[-740,-610,0],[-840,-365,0],[-590,-125,0],[-560,105,0])
    Real073Walk=#();local normals=#()
    for segment=1 to controls.count-1 do (
        local p0=controls[amax 1 (segment-1)],p1=controls[segment],p2=controls[segment+1],p3=controls[amin controls.count (segment+2)]
        for j=0 to 15 do (local t=j/16.0;append Real073Walk (0.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)))
    )
    append Real073Walk controls[controls.count]
    for i=1 to Real073Walk.count do (local v=normalize (Real073Walk[amin Real073Walk.count (i+1)]-Real073Walk[amax 1 (i-1)]);append normals [-v.y,v.x,0])
    for leaf in #(clover,grass) do (root.setGroupCoverage leaf true;cyrusBrushFill leaf.paintDocument 1.0)
    for leaf in #(shrubs,perennials,lavender,flowers,clover,grass) do (
        if not leaf.paintEnabled do (root.setGroupCoverage leaf true;cyrusBrushFill leaf.paintDocument 1.0)
        cyrusBrushSettings leaf.paintDocument (if leaf==grass or leaf==clover then 105 else 140) 1 0 true 1
        for j=1 to Real073Walk.count do Real073Assert (cyrusBrushDab leaf.paintDocument (Real073Walk[j]+[0,0,700]) [0,0,-1] (j==Real073Walk.count)) "Walk erase missed"
    )
    for k=1 to 2 do (
        local leaf=if k==1 then walk else inner
        root.setGroupCoverage leaf true;cyrusBrushSettings leaf.paintDocument 38 1 .2 false 1
        local samples=for j=1 to Real073Walk.count where Real073Walk[j].y>=-980 and Real073Walk[j].y<60 collect (Real073Walk[j]+normals[j]*(if k==1 then 141 else -141)+[0,0,700])
        for j=1 to samples.count do Real073Assert (cyrusBrushDab leaf.paintDocument samples[j] [0,0,-1] (j==samples.count)) "Flower border missed"
    )
    perennials.finalCleanup=true;perennials.finalNeighborRadius=250;perennials.finalMinNeighbors=1;perennials.finalMinIsland=2
    local started=timeStamp();root.refreshAll()
    for leaf in root.layerObjects do Real073Assert (leaf.previewError=="") leaf.previewError
    CyrusContainerRefreshAll()
    for leaf in Real073Sets do Real073Assert ((leaf.outputSources()).count==leaf.sources.count) "Palette membership dropped a declared model"
    root.selectLayer (findItem root.layerObjects flowers);flowers.uiPaintSetID=flowers.layerID
    viewport.setCamera (getNodeByName "01 HERO | garden pavilion")
    select Real073Node;max modify mode;modPanel.setCurrentObject root
    saveMaxFile (Real073Out+"Cyrus_073_Heavy_Garden.max") quiet:true
    CSPWriteText (MCPFixtureDir+"real-scene-build.json") (CSPObject #(#("passed",true),#("scene",Real073Out+"Cyrus_073_Heavy_Garden.max"),#("unique_plant_models",Real073Plants.count),#("layer_count",Real073Parents.count),#("paint_sets",Real073Sets.count),#("requested",for p in Real073Parents collect p.amount),#("accepted",for leaf in root.layerObjects collect leaf.generatedCount),#("shown",for leaf in root.layerObjects collect leaf.cachedPointCount),#("build_ms",timeStamp()-started),#("curve_samples",Real073Walk.count),#("serialization",root.version)))
    completeRedraw()
)
