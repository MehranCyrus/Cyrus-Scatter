global RGLayer,RGMat,RGBox,RGCurve,RGEllipse,RGFill,RGStem,RGRock
if findString MCPFixtureDir "courtyard-study075"==undefined do throw "Owned host required"
resetMaxFile #noPrompt
mergeMAXFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/Reference_Garden_075/Source_Plants.max" #select #autoRenameDups quiet:true
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/courtyard-study075/functions.ms"
global CYNode,CYR,CYL,CYM,CYReceivers,CYBeds,CYPaths,CYPathMeshes,CYMound,CYAnalyzer,CYCam,CYOut,CYPaint,CYBedSpecs,CYHards,CYSample,CYMeasure,CYLog,CYStroke
CYOut=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/Courtyard_Study_075/"
units.SystemType=#Centimeters;units.SystemScale=1;units.DisplayType=#Metric;units.MetricType=#Meters
CYM=for s in #("crp_MT_PM_V33_Myrtle_01_003","crp_MT_PM_Rosa_rugosa_01_02","crp_MT_PM_Sambucus_nigra_02_01","MT_PM_V41_Arthropodium_01_01","MT_PM_V41_Arthropodium_01_04","crp_Lavander_01","crp_Lavander_05","crp_MT_PM_V33_Glossy_abelia_01_006","MT_PM_V41_Geranium_robertianum_01_04","MT_PM_V41_Lamium_maculatum_01_04","MT_PM_V41_Phlox_stolonifera_01_01","MT_PM_V41_Viola_sororia_01_05","clover_pack_004","grass_bush","grass_small") collect getNodeByName s
fn CYLog label pairs = CSPWriteText (MCPFixtureDir+label+".json") (CSPObject pairs)
fn CYSample label elapsed = (
 local view=CyrusPointOwner CYNode,p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess();p.Refresh()
 CYLog label #(#("elapsed_ms",elapsed),#("epoch",CYR.procEpoch),#("names",CYR.layerNames),#("accepted",for l in CYL collect l.generatedCount),#("prepared",for l in CYL collect l.procPreparedBuilds),#("preview_builds",for l in CYL collect l.previewBuildCount),#("shown",for l in CYL collect l.cachedPointCount),#("errors",for l in CYL collect l.previewError),#("proc_stats",for l in CYL collect l.procStatistics()),#("retained",if isValidNode view then cyrusRetainedStats view else #()),#("retained_mesh",if isValidNode view then cyrusRetainedMeshStats view else #()),#("working_bytes",p.WorkingSet64),#("private_bytes",p.PrivateMemorySize64),#("peak_working_bytes",p.PeakWorkingSet64),#("brush",for a in CYPaint collect cyrusBrushStats a.paintDocument))
)
fn CYMeasure label = (local t=dotNetObject "System.Diagnostics.Stopwatch";t.Start();CYR.refreshAll();t.Stop();CYSample label t.Elapsed.TotalMilliseconds)
fn CYStroke area pts radius softness erase:false = (
 cyrusBrushSettings area.paintDocument radius 1 softness erase 1
 local timings=#()
 for i=1 to pts.count do (
  local t=timestamp()
  local inv=inverse area.areaTarget.objectTransform
  if not(cyrusBrushDab area.paintDocument (pts[i]*inv) (normalize(([0,0,-1]*inv)-inv.row4)) (i==pts.count)) do throw "Brush ray missed"
  append timings (timestamp()-t)
 )
 timings
)
fn RGMat label rgb rough:.65 = (CoronaPhysicalMtl name:label baseColor:rgb baseRoughness:rough)
with redraw off (
 local lawn=RGMat "Lawn | moss and meadow green" (color 48 68 24)
 lawn.baseTexmap=Noise size:85 color1:(color 31 48 14) color2:(color 76 92 35);lawn.baseTexmapOn=true
 local soil=RGMat "Beds | dark cultivated earth" (color 43 32 21)
 local gravel=RGMat "Paths | warm buff gravel" (color 143 119 87)
 gravel.baseTexmap=Noise size:.8 color1:(color 101 81 57) color2:(color 179 155 112);gravel.baseTexmapOn=true
 local wood=RGMat "Play and seating | honey oak" (color 117 65 25)
 wood.baseTexmap=Noise size:12 color1:(color 70 35 12) color2:(color 150 92 39);wood.baseTexmapOn=true
 local cutwood=RGMat "Logs | cut end grain" (color 164 116 60)
 local bark=RGMat "Trees | bark" (color 65 49 30)
 local stone=RGMat "Retaining wall | sandstone" (color 114 86 61)
 local fabric=RGMat "Play tent | canvas" (color 193 180 147)
 local metal=RGMat "Rail | dark charcoal" (color 17 23 21)
 local rock=RGMat "Boulders | warm grey" (color 104 93 70)
 CYReceivers=#()
 for side=1 to 2 do (
  local n=plane name:(if side==1 then "RECEIVER | west courtyard" else "RECEIVER | east courtyard") width:1600 length:3500 widthsegs:24 lengthsegs:48 pos:[if side==1 then -800 else 800,1150,0] material:lawn
  (RGLayer "01 Ground and path").addNode n;append CYReceivers n
 )
 -- Irregular drifts leave most of the middle courtyard open as usable lawn.
 CYBedSpecs=#(#([-1260,-260,0],390,520),#([1090,-150,0],500,370),#([-1200,650,0],350,380),#([1220,700,0],330,330),#([-780,1640,0],400,260),#([50,2290,0],490,310),#([1270,2420,0],290,390),#([-1390,2400,0],200,440))
 CYBeds=#()
 for i=1 to CYBedSpecs.count do (
  local spec=CYBedSpecs[i],pts=for a=0 to 350 by 10 collect spec[1]+[spec[2]*cos(a)*(1+.055*sin(3*a)),spec[3]*sin(a)*(1+.045*cos(5*a)),0]
  append CYBeds (RGCurve ("INCLUDE | planting bed "+i as string) pts)
  RGFill ("Soil | bed "+i as string) pts soil z:.3
 )
 CYPaths=#();CYPathMeshes=#()
 for route=1 to 3 do (
  local left=#(),right=#(),verts=#(),faces=#()
  for i=0 to 64 do (
   local t=i/64.0,p=case route of (1:[120+220*sin(t*300)-160*t,-700+3650*t,0];2:[-1640+3280*t,1060+90*sin(180*t),0];3:[-1630+3260*t,2050-90*sin(180*t),0])
   local tangent=case route of (1:[220*(300*pi/180)*cos(t*300)-160,3650,0];2:[3280,90*pi*cos(t*180),0];3:[3260,-90*pi*cos(t*180),0])
   local normal=normalize [tangent.y,-tangent.x,0],w=if route==1 then 90 else 67
   append left (p+normal*w);append right (p-normal*w)
  )
  for i=1 to left.count do (append verts (left[i]+[0,0,.8]);append verts (right[i]+[0,0,.8]))
  for i=1 to left.count-1 do (local a=2*i-1;append faces [a,a+1,a+2];append faces [a+1,a+3,a+2])
  local n=mesh name:("PATH | branching gravel "+route as string) vertices:verts faces:faces material:gravel
  (RGLayer "01 Ground and path").addNode n;append CYPathMeshes n
  local polygon=left as array;for i=right.count to 1 by -1 do append polygon right[i]
  append CYPaths (RGCurve ("EXCLUDE + BANDS | path "+route as string) polygon)
 )
 -- A genuinely non-planar receiver supports surface-bound Brush coverage.
 local verts=#(),faces=#(),center=[890,1640,0]
 for j=0 to 24 do for i=0 to 24 do (
  local x=-310+i*620/24.0,y=-300+j*600/24.0,z=85*exp(-(x*x/42000+y*y/39000))
  append verts (center+[x,y,z])
 )
 for j=0 to 23 do for i=0 to 23 do (local a=j*25+i+1;append faces [a,a+1,a+26];append faces [a,a+26,a+25])
 CYMound=mesh name:"RECEIVER | curved sensory mound" vertices:verts faces:faces material:soil
 (RGLayer "01 Ground and path").addNode CYMound
 local moundMask=RGCurve "EXCLUDE | mound footprint" #([580,1340,0],[1200,1340,0],[1200,1940,0],[580,1940,0])
 CYHards=#(moundMask)
 -- Sandbox, low masonry seat wall and timber play tower, all without buildings.
 local sandPts=#([530,790,0],[1230,790,0],[1230,1190,0],[530,1190,0])
 local sandMask=RGCurve "EXCLUDE | sand play" sandPts;append CYHards sandMask
 RGFill "PLAY | sand floor" sandPts gravel z:1
 for y in #(790,1190) do RGBox "PLAY | timber sand edging" [880,y,0] 724 15 16 wood rounded:1
 for x in #(530,1230) do RGBox "PLAY | timber sand edging" [x,990,0] 15 400 16 wood rounded:1
 for course=0 to 3 do for k=0 to 17 do (
  local n=RGBox "WALL | individual sandstone block" [450+k*43+(mod course 2)*21,420,course*14] 41 38 13 stone rounded:1
 )
 local wallMask=RGCurve "EXCLUDE | masonry seat" #([420,380,0],[1290,380,0],[1290,465,0],[420,465,0]);append CYHards wallMask
 for p in #([860,430,57],[-770,340,0],[-350,1740,0]) do (
  if p.z==0 then (
   for y in #(-65,65) do (
    RGBox "PICNIC | bench" (p+[0,y,43]) 205 26 7 wood rounded:1
    for x in #(-70,70) do RGBox "PICNIC | legs" (p+[x,y,0]) 10 20 43 wood
   )
   for y in #(-30,-10,10,30) do RGBox "PICNIC | tabletop boards" (p+[0,y,74]) 220 18 5 wood rounded:1
   for x in #(-75,75) do RGBox "PICNIC | table supports" (p+[x,0,0]) 11 65 74 wood
   append CYHards (RGEllipse "EXCLUDE | picnic clearance" p 125 95)
  ) else (
   for y in #(-12,0,12) do RGBox "WALL | timber seat slat" (p+[0,y,0]) 260 10 6 wood rounded:1
  )
 )
 for i=1 to 7 do (
  local p=[420+i*75,60+75*sin(i*48),0],h=22+mod(i*17)35
  local log=cylinder name:"PLAY | stepping log" radius:23 height:h sides:16 pos:p material:bark
  (RGLayer "02 Seating and water").addNode log
  local top=cylinder name:"PLAY | cut log top" radius:22.5 height:1 sides:16 pos:(p+[0,0,h]) material:cutwood
  (RGLayer "02 Seating and water").addNode top
  append CYHards (RGEllipse "EXCLUDE | stepping log" p 29 29)
 )
 local tee=[260,650,0],top=tee+[0,0,280]
 for a=0 to 300 by 60 do RGStem (tee+[150*cos(a),150*sin(a),0]) (top+[15*cos(a),15*sin(a),45]) 3 2 wood
 local pts=#();for a=0 to 360 by 30 do append pts (tee+[145*cos(a),145*sin(a),1])
 for i=1 to pts.count-1 where i!=9 and i!=10 do (
  local n=mesh name:"PLAY | canvas tent panel" vertices:#(pts[i],pts[i+1],top) faces:#([1,2,3],[3,2,1]) material:fabric
  (RGLayer "02 Seating and water").addNode n
 )
 append CYHards (RGEllipse "EXCLUDE | tent footprint" tee 160 160)
 local tower=[1050,1000,0]
 for x in #(-80,80) do for y in #(-70,70) do RGBox "PLAY | tower post" (tower+[x,y,0]) 10 10 290 wood
 RGBox "PLAY | raised platform" (tower+[0,0,135]) 180 160 12 wood
 for k=-3 to 3 do RGBox "PLAY | balustrade" (tower+[k*24,76,145]) 7 7 70 wood
 for y in #(-65,65) do RGStem (tower+[-95,y,280]) (tower+[0,y,355]) 5 5 wood
 for y in #(-65,65) do RGStem (tower+[95,y,280]) (tower+[0,y,355]) 5 5 wood
 local roof=mesh name:"PLAY | pitched timber roof" vertices:#(tower+[-110,-95,278],tower+[-110,95,278],tower+[0,-95,360],tower+[0,95,360],tower+[110,-95,278],tower+[110,95,278]) faces:#([1,2,3],[2,4,3],[3,4,5],[4,6,5]) material:wood
 (RGLayer "02 Seating and water").addNode roof
 local ramp=RGBox "PLAY | climbing ramp" (tower+[0,-185,0]) 92 270 8 wood
 ramp.rotation=eulerangles -29 0 0;ramp.pos=tower+[0,-185,60]
 for k=1 to 9 do (
  local hold=geosphere name:"PLAY | climbing hold" radius:6 segs:1 material:(RGMat "Hold | muted green" (color 75 108 80))
  hold.pos=tower+[if mod k 2==0 then -24 else 24,-300+k*20,6+k*11]
  (RGLayer "02 Seating and water").addNode hold
 )
 for spec in #(#([-450,570,30],[1.3,.85,.65],91),#([740,260,28],[1.3,1.0,.8],92),#([990,150,25],[1.0,.8,.7],93)) do (
  RGRock "PLAY | sandstone boulder" spec[1] spec[2] rock spec[3]
  append CYHards (RGEllipse "EXCLUDE | boulder" spec[1] (75*spec[2].x) (75*spec[2].y))
 )
 -- Smaller, varied canopy groups; existing plant assets remain clearly identified.
 seed 7536
 for tree in #(#([-830,1220,0],620),#([-400,2330,0],690),#([1430,1950,0],650),#([-1420,1850,0],560),#([380,2660,0],650)) do (
  local base=tree[1],height=tree[2]
  RGStem base (base+[15,12,height*.58]) 13 7 bark
  for j=1 to 5 do (
   local a=j*72+random -20 20,tip=base+[135*cos(a),110*sin(a),height*.76+random -55 45]
   RGStem (base+[10,8,height*.35]) tip 7 2 bark
   for k=1 to 2 do (
    local leaf=instance CYM[if j==2 or j==4 then 3 else 1]
    leaf.name="TREE | adapted shrub foliage";leaf.scale=[1.6,1.6,1.65]*(random .8 1.1);leaf.rotation=eulerangles 0 0 (random 0 360);leaf.pos=tip+[random -40 40,random -40 40,random -40 25];leaf.renderable=true
    (RGLayer "03 Canopy and boulders").addNode leaf
   )
  )
 )
 -- Perimeter fence and a simple distant hedge replace the architectural enclosure.
 for i=0 to 25 do (
  RGStem [-1620,-600+i*140,0] [-1620,-600+i*140,105] 2 2 metal
 )
 RGStem [-1620,-600,100] [-1620,2900,100] 3 3 metal
 for i=1 to CYM.count do (CYM[i].pos=[4500+mod(i-1)5*240,400+floor((i-1)/5)*350,0];CYM[i].renderable=false;(RGLayer "07 Plant source library").addNode CYM[i])
 CYNode=AminScatterObject name:"CYRUS 0.75 | Courtyard feature study" pos:[-1700,-720,0];CYR=CYNode.baseObject
 (RGLayer "05 Cyrus Scatter and Analyzer").addNode CYNode
 CYR.updateMode=1;CYR.autoRender=true;CYR.viewportMode=1;CYR.pointsPerPlant=18;CYR.previewBudget=350000;CYR.viewportInstances=10000;CYR.viewportFaces=2000000
 CYR.setLayerTransfer true;CYL=#();CYPaint=#()
 for i=1 to 10 do (CYR.newLayer();append CYL (CYR.selectedLayer()))
 CYR.layerNames=#("01 | Structural shrub islands","02 | White flowering matrix","03 | PAINT - lavender ribbons","04 | Clustered low flowers","05 | SPLINE - path edge bands","06 | Open lawn grass and clover","07 | PAINT - curved sensory mound","08 | ANALYZER - precise bed edging","09 | Gravel grains","10 | Texture-sampled accents")
 for i=1 to 10 do (
  local l=CYL[i];l.ownsReceivers=true;l.surfaceNodes=CYReceivers;l.randomSeed=75120+i*79;l.paintEnabled=false;l.areaMode=false
  l.areaNodes=join (copy CYBeds #noMap) (join (copy CYPaths #noMap) (copy CYHards #noMap));l.areaModes=join (for b in CYBeds collect 1) (for b in (join (copy CYPaths #noMap) (copy CYHards #noMap)) collect 2)
  l.wholeScaleMin=.8;l.wholeScaleMax=1.18;l.alignNormal=true;l.procPopulation=1;l.procSelfOverride=true;l.procSelfEnabled=true;l.procSelfMultiplier=.8;l.procSelfGap=2;l.rotZMin=0;l.rotZMax=360
 )
 local l=CYL[1]
 l.sources=#(CYM[1],CYM[2],CYM[8]);l.sourceWeights=#(.35,1.0,.5);l.sourceScales=#(.8,.95,.7);l.sourceRadii=#(56,53,88);l.amount=1800;l.diversityMode=2;l.diversitySize=230;l.sourceColors=#((color 50 80 40),(color 135 80 105),(color 50 80 40));l.procSelfGap=12
 l=CYL[2];l.sources=#(CYM[4],CYM[5]);l.sourceWeights=#(1.0,.3);l.sourceScales=#(.48,.43);l.sourceRadii=#(55,66);l.amount=5200;l.procSelfMultiplier=.8
 l=CYL[3];l.sources=#(CYM[6],CYM[7]);l.sourceWeights=#(1.0,.35);l.sourceScales=#(.5,.4);l.sourceRadii=#(55,50);l.amount=10000;l.procSelfMultiplier=.82
 l=CYL[4];l.sources=#(CYM[9],CYM[10],CYM[11],CYM[12]);l.sourceWeights=#(.45,.5,1.0,.6);l.sourceScales=#(1.65,1.6,1.9,1.8);l.sourceRadii=#(12,11,10,10);l.amount=9500;l.diversityMode=2;l.diversitySize=210;l.sourceColors=#((color 160 90 135),(color 70 130 80),(color 160 90 135),(color 115 105 155));l.finalCleanup=true;l.finalNeighborRadius=100;l.finalMinNeighbors=1;l.finalMinIsland=2
 l=CYL[5];l.sources=#(CYM[10],CYM[13]);l.sourceWeights=#(1.0,.5);l.sourceScales=#(1.35,2.0);l.sourceRadii=#(11,4);l.amount=12000;l.diversityMode=3
 l.areaNodes=join (copy CYPaths #noMap) (copy CYHards #noMap);l.areaModes=for n in l.areaNodes collect 2
 for path in CYPaths do (
  l.addStroke path side:1;local k=l.patternWidths.count;l.patternWidths[k]=55;l.strokeModes[k]=2;l.setStrokeSelection k 2 #(CYM[13]);l.strokeMin[k]=.7;l.strokeMax[k]=1.15
  l.addStroke path side:1;k=l.patternWidths.count;l.patternWidths[k]=90;l.strokeModes[k]=2;l.setStrokeSelection k 2 #(CYM[10])
 )
 l=CYL[6];l.sources=#(CYM[15],CYM[14],CYM[13]);l.sourceWeights=#(1.0,.2,.3);l.sourceScales=#(1.25,1.0,1.3);l.sourceRadii=#(5,7,4);l.populationMode=2;l.plantsPerM2=42;l.procSelfMultiplier=.6;l.procSelfGap=0;l.sclZMin=.8;l.sclZMax=1.5
 l.areaNodes=join (copy CYBeds #noMap) (join (copy CYPaths #noMap) (copy CYHards #noMap));l.areaModes=for n in l.areaNodes collect 2
 l=CYL[7];l.surfaceNodes=#(CYMound);l.sources=#(CYM[6],CYM[14],CYM[4]);l.sourceWeights=#(.4,1.0,.35);l.sourceScales=#(.45,3.0,.4);l.sourceRadii=#(55,8,55);l.amount=1800;l.procSelfMultiplier=.7;l.areaNodes=#();l.areaModes=#()
 l=CYL[8];l.sources=#(CYM[11]);l.sourceScales=#(1.5);l.sourceWeights=#(1.0);l.sourceRadii=#(10);l.amount=6000;l.diversityMode=4;l.areaNodes=#();l.areaModes=#()
 local guide=copy (getNodeByName "Soil | bed 5");guide.name="GUIDE | Analyzer bed boundary";convertToMesh guide
 for i=1 to guide.numverts do (local v=getVert guide i;v.z=0;setVert guide i v);update guide;guide.renderable=false;guide.isHidden=true
 CYAnalyzer=CyrusSurfaceAnalyzer name:"ANALYZER | island border" surface:guide;CYAnalyzer.updateMode=1;CYAnalyzer.resolution=72;CYAnalyzer.relaxIterations=0;CYAnalyzer.runAnalysis()
 (RGLayer "05 Cyrus Scatter and Analyzer").addNode CYAnalyzer
 l.analyzerNode=CYAnalyzer;l.addStroke CYAnalyzer side:7;l.patternWidths[1]=30;l.edgeOffsets[1]=0;l.edgeAcross[1]=2;l.edgeAlong[1]=3;l.strokeModes[1]=2;l.setStrokeSelection 1 2 #(CYM[11])
 local chip=geosphere name:"SOURCE | gravel chip" radius:.65 segs:1 pos:[4500,1700,0] material:gravel;chip.scale=[1,.7,.45];chip.renderable=false
 (RGLayer "07 Plant source library").addNode chip
 l=CYL[9];l.surfaceNodes=CYPathMeshes;l.sources=#(chip);l.sourceWeights=#(1.0);l.sourceScales=#(1.0);l.sourceRadii=#(.5);l.amount=12000;l.areaNodes=#();l.areaModes=#();l.procSelfEnabled=false
 l=CYL[10];l.sources=#(CYM[3],CYM[14]);l.sourceWeights=#(.2,1.0);l.sourceScales=#(.45,3.5);l.sourceRadii=#(55,8);l.amount=2600
 CYR.setLayerTransfer false
 for side=1 to 2 do (
  local a=CYR.addPaintArea CYL[3] target:CYReceivers[side];a.paintSetName=if side==1 then "West lavender sweeps" else "East lavender sweeps";append CYPaint a
  local pts=if side==1 then (for i=0 to 22 collect [-1070+70*sin(i*16),-490+i*55,650]) else (for i=0 to 20 collect [1010+110*sin(i*19),-330+i*52,650])
  local times=CYStroke a pts 145 .5
  CYLog ("paint-flat-"+side as string) #(#("dab_ms",times),#("stats",cyrusBrushStats a.paintDocument))
 )
 local a=CYR.addPaintArea CYL[7] target:CYMound;a.paintSetName="Curved mound - sensory ribbon";append CYPaint a
 local pts=for i=0 to 20 collect [700+i*18,1480+100*sin(i*9),700]
 CYLog "paint-curved" #(#("dab_ms",CYStroke a pts 100 .35),#("stats",cyrusBrushStats a.paintDocument))
 CYL[2].setFallConfig CYBeds[1] #(false,0.0,false,100.0,#(0.0,1.0),true,85.0,#(.25,1.0))
 CYL[4].setFallConfig CYPaths[1] #(true,16.0,true,100.0,#(0.0,.3,1.0),true,90.0,#(.35,1.0))
 for i=1 to 3 do for j=i+1 to 5 do CYR.procSetPair 2 CYL[i] CYL[j] true .55 3 true
 for spec in #(#(1,#(1,2,8),0),#(2,#(4,5),400),#(3,#(6,7),800)) do (
  local owner=CYL[spec[1]],ids=spec[2],y=spec[3]
  for k=1 to ids.count do CYM[ids[k]].pos=[4500+(k-1)*240,y,0]
  local c=owner.containerCreate();c.name="PALETTE | "+CYR.layerNames[spec[1]];c.pos=[4500+(ids.count-1)*120,y,0];c.width=ids.count*240;c.length=240;(RGLayer "07 Plant source library").addNode c
 )
 for i in #(3,9,10,11,12,13,14,15) do CYM[i].pos=[4500+i*180,1400,0]
 CYMeasure "initial-build"
 renderers.current=Corona();renderers.current.system_numThreads=12;renderers.current.progressive_passLimit=4;renderers.current.denoise_filterType=2;renderers.current.denoise_blendAmount=.65;renderers.current.renderstamp_use=false
 local sun=CoronaSun name:"LIGHT | afternoon sun";sun.targeted=true;sun.target.pos=[0,1100,0];sun.pos=[-1800,-2600,4500];sun.sizeMultiplier=5;sun.intensity=.7
 local sky=CoronaSky name:"LIGHT | clear daylight";sky.selectedSun=sun;sky.sunSelectionMode=1;environmentMap=sky;useEnvironmentMap=true
 local op=renderers.current.colorMap_pipeline
 while op!=undefined do (if classof op==AcesOtOperatorPlugin do op.colorMappingOperator_enabled=true;if isProperty op #colorMappingOperator_simpleExposure do op.colorMappingOperator_simpleExposure=-3.0;op=op.colorMappingOperator_nextOperator)
 CYCam=TargetCamera name:"01 HERO | courtyard garden" pos:[-1330,-1770,950] target:(Targetobject pos:[80,1120,50]) fov:59
 local overview=TargetCamera name:"02 OVERVIEW | design and planting" pos:[-2400,-2450,3650] target:(Targetobject pos:[0,1000,0]) fov:54
 renderWidth=960;renderHeight=640;viewport.setLayout #layout_1;viewport.setCamera CYCam
 select CYNode;max modify mode;modPanel.setCurrentObject CYR
 saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
)
