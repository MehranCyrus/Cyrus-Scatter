-- Author an editable multi-sample Brush trail in the disposable demonstration.
(
 fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/real_scene_071/common.ms"
 RSReload()
 RSAssert (RSRoot.layerObjects.count==6) "Run this fixture on the six-population baseline only"
 global RSPathSamples,RSPathNormals
 local controls=#([-1050,-1055,0],[-1020,-820,0],[-740,-610,0],[-840,-365,0],[-590,-125,0],[-560,105,0])
 RSPathSamples=#();RSPathNormals=#()
 -- Catmull-Rom interpolation is a scene-design utility, not a Scatter algorithm.
 for segment=1 to controls.count-1 do (
  local p0=controls[amax 1 (segment-1)],p1=controls[segment],p2=controls[segment+1],p3=controls[amin controls.count (segment+2)]
  for j=0 to 15 do (
   local t=j/16.0
   append RSPathSamples (0.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
  )
 )
 append RSPathSamples controls[controls.count]
 for i=1 to RSPathSamples.count do (
  local tangent=normalize (RSPathSamples[amin RSPathSamples.count (i+1)]-RSPathSamples[amax 1 (i-1)])
  append RSPathNormals [-tangent.y,tangent.x,0]
 )
 local group=LayerManager.newLayerFromName "08 Painted meadow walk"
 local gravel=CoronaLegacyMtl name:"Meadow walk | warm fine gravel" colorDiffuse:(color 94 85 65) levelReflect:.12 reflectGlossiness:.2
 gravel.texmapDiffuse=Noise size:3 color1:(color 73 66 48) color2:(color 123 112 87)
 local stone=CoronaLegacyMtl name:"Meadow walk | narrow stone edge" colorDiffuse:(color 120 116 101) levelReflect:.15 reflectGlossiness:.3
 fn RSRibbon label inner outer material group = (
  local vs=#(),fs=#()
  for i=1 to RSPathSamples.count do (
   append vs (RSPathSamples[i]+RSPathNormals[i]*inner+[0,0,4])
   append vs (RSPathSamples[i]+RSPathNormals[i]*outer+[0,0,4])
  )
  for i=1 to RSPathSamples.count-1 do (
   local a=(i-1)*2+1;append fs [a,a+2,a+1];append fs [a+1,a+2,a+3]
  )
  local n=mesh name:label vertices:vs faces:fs material:material
  group.addNode n;addModifier n (UVWMap maptype:0 width:300 length:300)
  n
 )
 RSRibbon "CURVED WALK | 1.4m painted meadow trail" -70 70 gravel group
 RSRibbon "Meadow walk | left edging" 70 76 stone group
 RSRibbon "Meadow walk | right edging" -76 -70 stone group
 -- The hardscape is independent from the saved Brush coverage. No hidden Area
 -- mask substitutes for the Brush erase: the publication must clear this curve.
 local eraseRadii=#(165.0,150.0,120.0,116.0,97.0,100.0)
 for i=1 to RSRoot.layerObjects.count do (
  local leaf=RSRoot.layerObjects[i]
  if leaf.paintDocument==undefined or not leaf.paintEnabled do (
   leaf.paintDocument=cyrusBrushCreate RSSurface
   cyrusBrushFill leaf.paintDocument 1.0
  )
  leaf.paintEnabled=true;leaf.paintIdentity=true
  cyrusBrushSettings leaf.paintDocument eraseRadii[i] 1 0 true 1
  cyrusBrushBind leaf.paintDocument
  for j=1 to RSPathSamples.count do RSAssert (cyrusBrushDab leaf.paintDocument (RSPathSamples[j]+[0,0,700]) [0,0,-1] (j==RSPathSamples.count)) "Path erase ray missed the receiving terrain"
 )
 RSRoot.newLayer();local flowers=RSRoot.selectedLayer()
 RSRoot.layerNames[findItem RSRoot.layerObjects flowers]="04 | Painted meadow walk"
 RSRoot.layerNames[findItem RSRoot.layerObjects RSFlowers]="05 | Meadow tapestry"
 flowers.paintSetName="Outer edge | Phlox and Viola"
 flowers.randomSeed=1729;flowers.amount=40000;flowers.procPopulation=1;flowers.procAttemptFactor=32;flowers.procRounds=6
 flowers.areaNodes=RSFlowers.areaNodes as array;flowers.areaModes=RSFlowers.areaModes as array
 flowers.rotZMin=0;flowers.rotZMax=360;flowers.wholeScaleMin=.88;flowers.wholeScaleMax=1.15;flowers.alignNormal=true
 flowers.collisionEnabled=false;flowers.relaxEnabled=false;flowers.finalRelax=false
 flowers.procSelfOverride=true;flowers.procSelfEnabled=true;flowers.procSelfMultiplier=.65;flowers.procSelfGap=2
 local inner=RSRoot.addPaintSet flowers label:"Inner edge | Lamium and Geranium"
 local originals=#(#("MT_PM_V41_Phlox_stolonifera_01_01","MT_PM_V41_Viola_sororia_01_05"),#("MT_PM_V41_Lamium_maculatum_01_04","MT_PM_V41_Geranium_robertianum_01_04"))
 for k=1 to 2 do (
  local leaf=if k==1 then flowers else inner,y=-2460-(k-1)*410.0
  local rect=rectangle name:("SOURCE CONTAINER | 0"+((k+6) as string)+" Path flowers") width:920 length:310 pos:[4550,y,0] wirecolor:(color 222 157 198)
  rect.renderable=false;(LayerManager.getLayerFromName "07 Source models - drag to park").addNode rect
  local caption=text name:("Library label | path flowers "+(k as string)) text:(if k==1 then "07 Outer path flowers" else "08 Inner path flowers") size:45 pos:[4100,y+170,0]
  caption.renderable=false;(LayerManager.getLayerFromName "07 Source models - drag to park").addNode caption
  local sources=#()
  for s=1 to 2 do (
   local source=instance (getNodeByName originals[k][s]);source.name="PATH | "+originals[k][s]
   source.pos=[4300+(s-1)*340,y,0];source.renderable=false
   (LayerManager.getLayerFromName "07 Source models - drag to park").addNode source;append sources source
  )
  leaf.sources=sources;leaf.sourceWeights=#(1.0,.75);leaf.sourceScales=#(2.5,2.5);leaf.sourceRadii=#(9.0,9.0)
  leaf.containerMode=4;leaf.containerNodes=#(rect);leaf.paintEnabled=true;leaf.paintIdentity=true;leaf.paintDocument=cyrusBrushCreate RSSurface
  cyrusBrushSettings leaf.paintDocument 38 1 .2 false 1
  cyrusBrushBind leaf.paintDocument
  -- Stop at y=-980 so the flower borders do not spill onto the sidewalk.
  local stroke=for i=1 to RSPathSamples.count where RSPathSamples[i].y>=-980 and RSPathSamples[i].y<60 collect (RSPathSamples[i]+RSPathNormals[i]*(if k==1 then 141 else -141)+[0,0,700])
  for j=1 to stroke.count do RSAssert (cyrusBrushDab leaf.paintDocument stroke[j] [0,0,-1] (j==stroke.count)) "Flower border ray missed"
 )
 RSAssert (RSRoot.procMove flowers -1) "Could not order the flower border before the meadow"
 for other in RSOwners do RSRoot.procSetPair 2 other flowers true .72 10 true
 RSRoot.procSetPair 1 flowers inner true .65 2 true
 RSBind();RSRoot.updateMode=1;RSRoot.refreshAll();RSRoot.evaluateGroups()
 for leaf in RSRoot.layerObjects do RSAssert ((leaf.cacheSnapshot())[4]=="") (leaf.cacheSnapshot())[4]
 local rows=RSRows();RSAssert (rows[7].count>75 and rows[8].count>75) "Curved flower borders are underpopulated"
 -- A low camera explicitly shows the S-curve and both painted flower borders.
 local detail=getNodeByName "02 WALK | planting detail"
 detail.pos=[-1190,-1500,340];detail.target.pos=[-580,-50,95];detail.fov=66
 local sourcesCamera=getNodeByName "04 SOURCES | model containers"
 sourcesCamera.pos=[4550,-4050,3850];sourcesCamera.target.pos=[4550,-1450,0];sourcesCamera.fov=54
 local plan=getNodeByName "03 PLAN | layout and roads"
 viewport.setCamera plan;RSRoot.setGroupDisplay 1;select RSNode;max modify mode;modPanel.setCurrentObject RSRoot
 local f=createFile (MCPFixtureDir+"curved-path.csv");format "x,y\n" to:f
 for p in RSPathSamples do format "%,%\n" p.x p.y to:f
 close f
 local history=for leaf in RSRoot.layerObjects collect #(leaf.paintSetName,cyrusBrushHistory leaf.paintDocument)
 local before=RSRows()
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 RSReload();RSAssert (RSEqual before (RSRows())) "Curved path did not preserve output on save/reopen"
 CSPWriteText (MCPFixtureDir+"curved-path.json") (CSPObject #(#("passed",true),#("walk_width_cm",140),#("centerline_samples",RSPathSamples.count),#("counts",for r in before collect r.count),#("history",history),#("save_reopen_exact",true)))
 completeRedraw()
)
