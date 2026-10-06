-- Creates a new scene from the prepared copy; never opens or overwrites the artist file.
(
 if findString MCPFixtureDir "/procedural07-real-scene-071"==undefined do throw "Private real-scene host required"
 if not(loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/real-scene-071/Prepared_Library.max" quiet:true useFileUnits:true) do throw "Prepared library unavailable"
 global RSRoot,RSNode,RSSurface,RSOwners,RSFlowers,RSGrass,RSClover,RSContainers,RSOut
 RSOut=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/Cyrus_071_Courtyard/"
 makeDir RSOut all:true
 units.SystemType=#Centimeters;units.SystemScale=1;units.DisplayType=#Metric;units.MetricType=#Meters
 fn RSLayer name = (local layer=LayerManager.getLayerFromName name;if layer==undefined do layer=LayerManager.newLayerFromName name;layer)
 fn RSMaterial name rgb gloss:0.35 = (
  local m=CoronaLegacyMtl name:name colorDiffuse:rgb levelReflect:0.25 reflectGlossiness:gloss
  m
 )
 fn RSBox name p w l h m group:"02 Architecture" = (
  local n=box name:name pos:p width:w length:l height:h widthsegs:1 lengthsegs:1 heightsegs:1 material:m
  n.wirecolor=m.colorDiffuse;(RSLayer group).addNode n;n
 )
 fn RSArea name p w l = (
  local n=rectangle name:name pos:p width:w length:l wirecolor:(color 255 165 60)
  n.renderable=false;(RSLayer "05 Area guides").addNode n;n
 )
 fn RSCamera name eye target focal = (
  local c=TargetCamera name:name pos:eye target:(Targetobject pos:target) fov:focal
  (RSLayer "06 Cameras and light").addNode c;(RSLayer "06 Cameras and light").addNode c.target;c
 )
 with redraw off (
 local ivory=RSMaterial "Pavilion | warm limestone" (color 184 177 157)
 local concrete=RSMaterial "Paths | sandwashed concrete" (color 142 139 125)
 local trim=RSMaterial "Frames | graphite" (color 26 31 30) gloss:0.6
 local timber=RSMaterial "Cedar | oiled warm timber" (color 105 62 30)
 local asphalt=RSMaterial "Road | charcoal aggregate" (color 31 34 34)
 local paint=RSMaterial "Road | warm white paint" (color 195 189 166)
 local soil=RSMaterial "Garden | living ground" (color 49 59 24)
 local glass=RSMaterial "Glazing | pale smoked glass" (color 20 33 34) gloss:0.95
 glass.levelDiffuse=0.05;glass.levelReflect=1;glass.levelRefract=0.9;glass.thin=true;glass.ior=1.5
 local water=RSMaterial "Pool | reflecting water" (color 18 37 39) gloss:0.98
 water.levelReflect=1;water.fresnelIor=1.33
 soil.texmapDiffuse=Noise name:"Fine soil variation" size:38 color1:(color 31 39 18) color2:(color 63 76 31)
 asphalt.texmapDiffuse=Noise name:"Fine asphalt" size:1.5 color1:(color 25 27 27) color2:(color 42 43 40)
 RSBox "Site base" [0,80,-45] 3440 2540 40 concrete group:"01 Site and roads"
 RSBox "South access road" [200,-1450,-24] 4500 470 16 asphalt group:"01 Site and roads"
 RSBox "East access road" [1930,100,-24] 500 3570 16 asphalt group:"01 Site and roads"
 RSBox "South pavement" [0,-1130,-5] 3420 160 8 concrete group:"01 Site and roads"
 RSBox "West pavement" [-1590,110,-5] 160 2350 8 concrete group:"01 Site and roads"
 RSBox "East pavement" [1590,110,-5] 160 2350 8 concrete group:"01 Site and roads"
 for x=-2050 to 2200 by 350 do RSBox "Road dash" [x,-1450,-7.5] 160 10 0.5 paint group:"01 Site and roads"
 for y=-2000 to 1600 by 350 do RSBox "Road dash east" [1930,y,-7.5] 10 160 0.5 paint group:"01 Site and roads"
 for x=-240 to 240 by 80 do RSBox "Crosswalk" [x,-1450,-7] 42 320 0.5 paint group:"01 Site and roads"
 for x in #(-1507,1507) do RSBox "Garden side curb" [x,90,-3] 14 2320 18 ivory group:"01 Site and roads"
 for y in #(-1067,1247) do RSBox "Garden end curb" [0,y,-3] 3014 14 18 ivory group:"01 Site and roads"
 local verts=#(),faces=#(),nx=60,ny=46
 for j=0 to ny do for i=0 to nx do (
  local x=-1500+i*50.0,y=-1060+j*50.0
  local z=80.0*exp(-(((x-1080)/365.0)^2+((y-400)/470.0)^2)*2)
  if z<.001 do z=0
  append verts [x,y,z]
 )
 for j=0 to ny-1 do for i=0 to nx-1 do (
  local a=j*(nx+1)+i+1,b=a+1,c=a+nx+1,d=c+1
  append faces [a,b,d];append faces [a,d,c]
 )
 RSSurface=mesh name:"Garden receiver - flat meadow and curved berm" vertices:verts faces:faces material:soil
 (RSLayer "03 Receiving landscape").addNode RSSurface;RSSurface.wirecolor=color 83 102 52
 for f=1 to RSSurface.numfaces do setFaceSmoothGroup RSSurface f 1
 update RSSurface
 addModifier RSSurface (UVWMap maptype:0 width:3000 length:2300 height:100)
 convertToMesh RSSurface
 -- Pavilion: a small glazed volume, deep eaves and a timber screen.
 RSBox "Terrace foundation" [0,650,0] 1490 1110 16 ivory
 for i=0 to 11 do for j=0 to 8 do RSBox "Terrace stone" [-687+i*125,145+j*125,16] 121 121 4 concrete
 RSBox "Pavilion floor" [0,670,20] 1180 760 14 timber
 RSBox "Back limestone wall" [0,1040,34] 1180 24 304 ivory
 RSBox "West limestone wall" [-578,670,34] 24 760 304 ivory
 RSBox "East limestone wall" [578,670,34] 24 760 304 ivory
 RSBox "Garden glazing" [-70,292,34] 990 3 285 glass
 for x=-565 to 475 by 130 do RSBox "Glazing mullion" [x,289,34] 4 10 285 trim
 RSBox "Glazing head" [-45,288,314] 1060 12 8 trim
 RSBox "Glazing sill" [-45,288,34] 1060 12 8 trim
 RSBox "Floating roof" [0,660,336] 1320 910 24 ivory
 RSBox "Roof shadow joint" [0,660,329] 1230 805 7 trim
 for x=330 to 550 by 22 do RSBox "Cedar entrance fins" [x,246,34] 8 42 300 timber
 for x in #(-693,693) do RSBox "Canopy column" [x,137,20] 14 14 315 trim
 RSBox "Terrace seat" [-720,730,35] 42 330 12 timber
 for y in #(600,850) do RSBox "Bench support" [-720,y,17] 33 16 18 trim
 RSBox "Interior counter" [170,925,34] 430 64 90 ivory
 RSBox "Table top" [-210,610,107] 180 85 6 timber
 for x in #(-270,-150) do RSBox "Table leg" [x,610,34] 6 60 73 trim
 for y in #(530,690) do RSBox "Interior bench" [-210,y,75] 180 35 7 timber
 -- Reflecting pool and broad, jointed entry path.
 RSBox "Pool coping" [-1050,670,0] 530 650 17 ivory group:"01 Site and roads"
 RSBox "Reflecting water" [-1050,670,17.2] 486 606 1 water group:"01 Site and roads"
 for j=0 to 8 do RSBox "Entry slab" [0,-985+j*125,1] 280 119 11 concrete group:"01 Site and roads"
 for side in #(-1,1) do (
  RSBox "Entry edging" [side*151,-485,0] 12 1130 17 ivory group:"01 Site and roads"
  for y in #(-870,-370) do (
   RSBox "Path light base" [side*205,y,0] 11 11 52 trim group:"01 Site and roads"
   RSBox "Path light cap" [side*205,y,51] 16 16 4 ivory group:"01 Site and roads"
  )
 )
 local plaque=text name:"Pavilion identity" text:"CYRUS / GARDEN" size:23 pos:[-525,270,226] rotation:(eulerAngles 90 0 0) material:trim
 plaque.renderable=true;addModifier plaque (Extrude amount:0.5);(RSLayer "02 Architecture").addNode plaque
 -- Closed guide shapes are intentionally editable and non-rendering.
 local terraceArea=RSArea "EXCLUDE | pavilion and terrace" [0,650,0] 1550 1170
 local poolArea=RSArea "EXCLUDE | reflecting pool" [-1050,670,0] 590 710
 local pathArea=RSArea "EXCLUDE | entry walk" [0,-480,0] 355 1200
 local shrubArea=RSArea "INCLUDE | rear shrub band" [0,1130,0] 2870 160
 local shrubArea2=RSArea "INCLUDE | west shrub bed" [-1310,-430,0] 260 1090
 local shrubArea3=RSArea "INCLUDE | east shrub bed" [1260,0,0] 390 1950
 local lavArea=RSArea "INCLUDE | west lavender ribbon" [-400,-445,0] 170 1000
 local lavArea2=RSArea "INCLUDE | east lavender ribbon" [400,-445,0] 170 1000
 -- Off-site source library. Moving a model out of its rectangle parks its row.
 local originalNames=#("crp_MT_PM_V33_Myrtle_01_003","crp_MT_PM_Rosa_rugosa_01_02","crp_MT_PM_Sambucus_nigra_02_01","MT_PM_V41_Arthropodium_01_01","MT_PM_V41_Arthropodium_01_04","crp_Lavander_01","crp_Lavander_05","crp_MT_PM_V33_Glossy_abelia_01_006","MT_PM_V41_Geranium_robertianum_01_04","MT_PM_V41_Lamium_maculatum_01_04","MT_PM_V41_Phlox_stolonifera_01_01","MT_PM_V41_Viola_sororia_01_05","clover_pack_004","grass_bush","grass_small")
 local models=for name in originalNames collect getNodeByName name
 for m in models do (if not isValidNode m do throw "Plant asset missing";m.renderable=false;m.isHidden=false;(RSLayer "07 Source models - drag to park").addNode m)
 local groups=#(#(1,2,3),#(4,5),#(6,7,8),#(9,10,11,12),#(13),#(14,15))
 local groupNames=#("01 Shrubs","02 Perennials","03 Lavender","04 Flowers","05 Clover","06 Grasses")
 RSContainers=#()
 for i=1 to groups.count do (
  local y=(i-1)*-410.0
  local rect=rectangle name:("SOURCE CONTAINER | "+groupNames[i]) width:920 length:310 pos:[4550,y,0] wirecolor:(color 63 182 167)
  rect.renderable=false;(RSLayer "07 Source models - drag to park").addNode rect;append RSContainers rect
  local caption=text name:("Library label | "+groupNames[i]) text:groupNames[i] size:45 pos:[4100,y+170,0]
  caption.renderable=false;(RSLayer "07 Source models - drag to park").addNode caption
  for k=1 to groups[i].count do models[groups[i][k]].pos=[4250+(k-1)*200,y,0]
 )
 RSNode=AminScatterObject name:"CYRUS 0.7.1 | Courtyard - Edit layer" pos:[-1580,-1280,0]
 RSRoot=RSNode.baseObject;(RSLayer "04 Cyrus Scatter controls").addNode RSNode
 RSRoot.setLayerTransfer true;RSRoot.updateMode=1;RSRoot.surfaceNodes=#(RSSurface);RSRoot.autoRender=true
 RSRoot.viewportMode=1;RSRoot.pointsPerPlant=35;RSRoot.previewBudget=350000;RSRoot.viewportInstances=10000;RSRoot.viewportFaces=1500000
 RSOwners=#()
 for i=1 to 4 do (RSRoot.newLayer();append RSOwners (RSRoot.selectedLayer()))
 RSRoot.layerNames=#("01 | Structural shrubs","02 | Flowering perennials","03 | Lavender ribbons","04 | Meadow tapestry")
 for i=1 to 4 do (
  local leaf=RSOwners[i]
  leaf.randomSeed=701+i*113;leaf.paintEnabled=false;leaf.collisionEnabled=false;leaf.relaxEnabled=false;leaf.finalRelax=false
  leaf.areaNodes=#(terraceArea,poolArea,pathArea);leaf.areaModes=#(2,2,2)
  leaf.wholeScaleMin=0.88;leaf.wholeScaleMax=1.15;leaf.rotZMin=0;leaf.rotZMax=360;leaf.alignNormal=true
  leaf.containerMode=4;leaf.containerNodes=#(RSContainers[i]);leaf.autoRender=true
 )
 RSOwners[1].sources=#(models[1],models[2],models[3]);RSOwners[1].sourceWeights=#(1.0,.56,.39)
 RSOwners[1].sourceRadii=#(56,49,50);RSOwners[1].sourceScales=#(1.1,1.05,1.15);RSOwners[1].amount=52
 RSOwners[1].areaNodes=#(shrubArea,shrubArea2,shrubArea3,terraceArea,poolArea,pathArea);RSOwners[1].areaModes=#(1,1,1,2,2,2)
 RSOwners[2].sources=#(models[4],models[5]);RSOwners[2].sourceWeights=#(1.0,.33);RSOwners[2].sourceRadii=#(43,48);RSOwners[2].amount=110
 RSOwners[2].paintDocument=cyrusBrushCreate RSSurface;RSOwners[2].paintIdentity=true;RSOwners[2].paintEnabled=true
 cyrusBrushSettings RSOwners[2].paintDocument 360 1 .18 false 1
 for p in #([-970,-530,700],[990,-590,700],[1090,410,700]) do if not(cyrusBrushDab RSOwners[2].paintDocument p [0,0,-1] true) do throw "Perennial stroke missed terrain"
 RSOwners[3].sources=#(models[6],models[7],models[8]);RSOwners[3].sourceWeights=#(1.0,1.0,.3);RSOwners[3].sourceRadii=#(25,25,36);RSOwners[3].sourceScales=#(.8,.8,.8);RSOwners[3].amount=95
 RSOwners[3].areaNodes=#(lavArea,lavArea2);RSOwners[3].areaModes=#(1,1)
 RSFlowers=RSOwners[4];RSFlowers.sources=#(models[9],models[10],models[11],models[12]);RSFlowers.sourceWeights=#(.5,.3,1.0,.5)
 RSFlowers.sourceScales=#(2.0,2.0,2.4,2.3);RSFlowers.sourceRadii=#(12,11,10,9);RSFlowers.amount=18000;RSFlowers.paintSetWeight=1.2
 RSFlowers.paintSetName="Painted flower drifts";RSFlowers.paintDocument=cyrusBrushCreate RSSurface;RSFlowers.paintIdentity=true;RSFlowers.paintEnabled=true
 cyrusBrushSettings RSFlowers.paintDocument 330 1 .35 false 1
 for p in #([-720,-660,700],[-910,-250,700],[820,-450,700],[1170,340,700]) do if not(cyrusBrushDab RSFlowers.paintDocument p [0,0,-1] true) do throw "Flower stroke missed terrain"
 RSRoot.setLayerTransfer false;RSRoot.procUpgrade()
 RSClover=RSRoot.addPaintSet RSFlowers label:"Clover outside flower coverage"
 RSClover.sources=#(models[13]);RSClover.sourceWeights=#(1.0);RSClover.sourceScales=#(3.4);RSClover.sourceRadii=#(4)
 RSClover.paintEnabled=false;RSClover.paintSetWeight=1.3;RSClover.containerMode=4;RSClover.containerNodes=#(RSContainers[5])
 RSClover.procBackground=2;RSClover.procBackgroundIDs=#(RSFlowers.layerID)
 RSGrass=RSRoot.addPaintSet RSFlowers label:"Grass between flowering plants"
 RSGrass.sources=#(models[14],models[15]);RSGrass.sourceWeights=#(.5,1.0);RSGrass.sourceScales=#(2.6,2.6);RSGrass.sourceRadii=#(3,2.5)
 RSGrass.paintEnabled=false;RSGrass.paintSetWeight=7.5;RSGrass.containerMode=4;RSGrass.containerNodes=#(RSContainers[6]);RSGrass.procBackground=3;RSGrass.procBackgroundIDs=#(RSFlowers.layerID)
 for i=1 to 3 do (
  RSOwners[i].procPopulation=2;RSOwners[i].procAttemptFactor=16;RSOwners[i].procRounds=5
  RSOwners[i].procSelfOverride=true;RSOwners[i].procSelfEnabled=true;RSOwners[i].procSelfMultiplier=.85;RSOwners[i].procSelfGap=6
 )
 RSOwners[2].finalCleanup=true;RSOwners[2].finalNeighborRadius=250;RSOwners[2].finalMinNeighbors=1;RSOwners[2].finalMinIsland=2
 for i=1 to 3 do for j=i+1 to 4 do RSRoot.procSetPair 2 RSOwners[i] RSOwners[j] true .72 10 true
 RSRoot.procSetPair 1 RSFlowers RSGrass true .7 2 true
 RSRoot.procSetPair 1 RSFlowers RSClover false 1 0 true
 RSRoot.procSetPair 1 RSClover RSGrass false 1 0 true
 RSFlowers.setFallConfig pathArea #(true,8.0,false,100.0,#(0.0,1.0),true,40.0,#(0.0,1.0))
 RSRoot.updateMode=1;RSRoot.refreshAll()
 -- Corona setup keeps the supplied plant materials intact.
 renderers.current=Corona();renderers.current.system_numThreads=8;renderers.current.progressive_passLimit=12;renderers.current.progressive_timeLimit=0
 renderers.current.denoise_filterType=2;renderers.current.denoise_blendAmount=.65;renderers.current.renderstamp_use=false
 local sun=CoronaSun name:"Afternoon sun" pos:[-2400,-2700,3300] target:(Targetobject pos:[0,0,0])
 sun.sizeMultiplier=5;sun.intensity=1
 local sky=CoronaSky name:"Clear afternoon sky";sky.selectedSun=sun;sky.sunSelectionMode=1
 environmentMap=sky;useEnvironmentMap=true
 (RSLayer "06 Cameras and light").addNode sun;(RSLayer "06 Cameras and light").addNode sun.target
 local hero=RSCamera "01 HERO | garden pavilion" [2850,-3850,2500] [0,120,90] 52
 local detail=RSCamera "02 WALK | planting detail" [740,-1500,265] [-180,410,140] 64
 local plan=RSCamera "03 PLAN | layout and roads" [0,-10,5000] [0,0,0] 44
 renderWidth=1400;renderHeight=1000;rendSaveFile=false
 viewport.setLayout #layout_1;viewport.setCamera hero
 clearSelection();select RSNode;max modify mode;modPanel.setCurrentObject RSRoot
 if not RSRoot.mainUI.controlsReady do RSRoot.mainUI.mountTimer.tick()
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 CSPWriteText (MCPFixtureDir+"scene-build.json") (CSPObject #(#("version",RSRoot.uiVersion()),#("scene",RSOut+"Cyrus_071_Garden_Pavilion.max"),#("counts",for l in RSRoot.layerObjects collect #(l.paintSetName,l.generatedCount,(l.cacheSnapshot())[4])),#("status",RSRoot.allStatus())) )
 )
 completeRedraw()
)
