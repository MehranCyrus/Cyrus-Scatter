-- Actual optional feature/controller integration on a matched private pair.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native fields controller required."
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global FCGuide,FCArea,FCPath,FCPaint,FCBefore,FCAfter,FCPublished,FCUndoPaint
 fn FCapply=(NCRoot.refreshAll();for leaf in NCRoot.layerObjects where leaf.previewError!="" do throw leaf.previewError)
 fn FChash=(cyrusPlacementPublicationFingerprint NCRoot.groupSnapshotRows NCRoot.procPublishedRadii #("field-controller") (for leaf in NCRoot.layerObjects collect #(leaf.procLastStats,leaf.procLastRounds,leaf.procLastSurfaceStats)))
 fn FCcheck yes message=(if not yes do throw ("Field controller: "+message))
 fn FCwrite text=(local f=openFile(MCPFixtureDir+"field-controller.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"field-controller.txt");format "% %\n" NCKind text to:f;close f)
 fn FCparity label = (
  NCRoot.procNativeRoute=false;FCapply();local expected=FChash(),preview=NCLeaf.cachedPoints,inspection=NCLeaf.inspectionCache
  NCRoot.procNativeRoute=true;local before=cyrusPlacementTransportStats();FCapply()
  FCcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) (label+" creates no placement-sized script transport")
  FCcheck (expected==FChash()) (label+" complete ordered rows/radii/stats match")
  FCcheck (cyrusPreviewContentEqual preview NCLeaf.cachedPoints) (label+" complete draw content matches")
  if inspection!=undefined do FCcheck (cyrusPreviewContentEqual inspection NCLeaf.inspectionCache) (label+" inspection content matches")
  FCwrite ("PASS "+label+" accepted="+(NCLeaf.generatedCount as string)+" hash="+expected)
 )
 case command[1] of (
  "features": (
   NCRoot.updateMode=1
   with undo off (
    NCLeaf.amount=5000
    append NCModels (box name:"Native fields second model" width:0.2 length:0.3 height:0.5 pos:[75,5,0])
    NCLeaf.sources=NCModels;NCLeaf.sourceWeights=#(0.6,0.4);NCLeaf.sourceRadiiWU=#(0.15,0.25);NCLeaf.sourceFollowScale=#(true,true)
    NCLeaf.sourceColors=#(red,green);NCLeaf.wholeScaleMin=0.5;NCLeaf.wholeScaleMax=1.7
    FCArea=rectangle name:"Native field include" width:85 length:75
    NCLeaf.areaNodes=#(FCArea);NCLeaf.areaModes=#(1)
    NCLeaf.setFallConfig FCArea #(true,2.0,true,12.0,#(0.1,0.3,1.5),true,15.0,#(0,0.2,1))
   )
   FCparity "Area deletion density scale"
   NCLeaf.sourceShowRadius=#(true,true)
   for metric in #(1,2) do for limit in #(0,1,173,333) do (
    NCLeaf.radiusDisplayMetric=metric;NCLeaf.radiusDisplayLimit=limit;FCparity ("Radius "+(metric as string)+" limit="+(limit as string))
   )
   NCLeaf.radiusDisplayAll=true;NCLeaf.amount=300;FCparity "All radius rings"
   NCLeaf.radiusDisplayAll=false;NCLeaf.amount=5000;NCLeaf.sourceShowRadius=#(false,false)
   NCLeaf.diversityMode=2;NCLeaf.diversitySize=12.0;NCLeaf.roughness=35;NCLeaf.blurryEdge=20;FCparity "Clusters"
   NCLeaf.diversityMode=1
   NCLeaf.gridColumnWU=4.0;NCLeaf.gridRowWU=3.0;NCLeaf.gridHeading=17;NCLeaf.gridJitter=20
   for mode in #(2,3,4) do (NCLeaf.placementMode=mode;FCparity ("Grid "+(mode as string)))
   NCLeaf.placementMode=1;NCLeaf.amount=500
   NCLeaf.relaxEnabled=true;NCLeaf.relaxIterations=2;NCLeaf.relaxSpacing=2.0;FCparity "Initial Relax"
   NCLeaf.finalRelax=true;NCLeaf.finalIterations=2;NCLeaf.finalMaxMove=0.4;FCparity "Initial and final Relax"
   NCLeaf.finalRelax=false;NCLeaf.relaxEnabled=false;NCLeaf.amount=5000
   FCPath=rectangle name:"Native Band path" width:60 length:50
   NCLeaf.diversityMode=3;NCLeaf.addStroke FCPath side:2;NCLeaf.addStroke FCPath side:2
   NCLeaf.patternWidths[1]=8;NCLeaf.strokeStarts[1]=0;NCLeaf.strokeEnds[1]=8
   NCLeaf.patternWidths[2]=7;NCLeaf.strokeStarts[2]=8;NCLeaf.strokeEnds[2]=15
   NCLeaf.setStrokeSelection 1 2 #(NCLeaf.sourceRowIDs[1]);NCLeaf.setStrokeSelection 2 2 #(NCLeaf.sourceRowIDs[2])
   NCLeaf.strokeCurveEnabled[1]=true;NCLeaf.strokeCurveSamples[1]="1,0.3,0.1"
   NCLeaf.strokeScaleModes[2]=3;NCLeaf.strokeScaleSamples[2]="0.2,0.7,1.4"
   FCparity "Bands density scale"
   NCLeaf.fieldBoundaries=true;NCLeaf.fieldFalloff=true;NCLeaf.sourceShowRadius=#(true,true);NCLeaf.radiusDisplayLimit=100;FCparity "Bands field and radius overlay"
   NCLeaf.fieldBoundaries=false;NCLeaf.fieldFalloff=false;NCLeaf.sourceShowRadius=#(false,false);NCLeaf.diversityMode=1
   FCPaint=NCRoot.addPaintArea NCLeaf target:NCTerrain;FCPaint.paintView=0
   cyrusBrushFill FCPaint.paintDocument 1;cyrusBrushSettings FCPaint.paintDocument 15 true;cyrusBrushDab FCPaint.paintDocument [0,0,200] [0,0,-1] true
   cyrusBrushSetFalloff FCPaint.paintDocument #(10.0,5.0,true,true,0.15,1.4,#(0,0.2,1),#(0,0.5,1))
   FCPaint.paintDensity=0.8;FCPaint.publishPaint();NCLeaf.paintEnabled=true
   FCparity "Paint area hole feather density scale"
   NCLeaf.amount=50000;FCparity "Paint 50k"
   NCLeaf.amount=5000;FCapply();FCBefore=FChash();FCUndoPaint=(cyrusBrushRecipeExport FCPaint.paintDocument)[1]
   NCRoot.updateMode=2;undo "Native field clear Paint" on (cyrusBrushFill FCPaint.paintDocument 0;FCPaint.publishPaint())
  )
  "paintClear": (FCcheck (NCLeaf.previewError=="" and NCLeaf.generatedCount==0) "Actual Live Paint clear updates native output";FCAfter=FChash();max undo)
  "paintUndo": (FCcheck (FCBefore==FChash() and FCUndoPaint==(cyrusBrushRecipeExport FCPaint.paintDocument)[1]) "Paint Undo restores full native result and authored bytes";max redo)
  "paintRedo": (FCcheck (FCAfter==FChash()) "Paint Redo restores cleared native result";max undo;FCwrite "PASS Paint Live Undo Redo")
  "analyzer": (
   NCRoot.updateMode=1;NCLeaf.paintEnabled=false;NCLeaf.areaNodes=#();NCLeaf.areaModes=#()
   FCGuide=CyrusSurfaceAnalyzer name:"Native fields Analyzer"
   -- Analyzer 0.14 explicitly supports planar input. Its guides can feed a
   -- different Scatter receiver; use the same planar guide for both terrains.
   local guideTerrain=NCTerrain
   if NCKind=="mountain" do guideTerrain=plane name:"Native planar Analyzer input" width:100 length:100 widthsegs:32 lengthsegs:32
   FCGuide.surface=guideTerrain;FCGuide.resolution=48;FCGuide.pointRadius=3;FCGuide.fitRadius=6;FCGuide.relaxIterations=0;FCGuide.updateMode=1;FCGuide.runAnalysis()
   FCcheck (FCGuide.analysisCurrent() and FCGuide.boundaryVertices.count>0) "Actual independent Analyzer has current published guides"
   NCLeaf.areaAnalyzer=FCGuide;NCLeaf.areaUseLine=true;NCLeaf.areaLineWidth=12
   FCparity "Analyzer line Area"
   NCLeaf.areaUsePoints=true;NCLeaf.areaPointRadius=3;FCparity "Analyzer line and point Area"
   NCLeaf.areaUseLine=false;NCLeaf.areaUsePoints=false
   NCLeaf.fallAnalyzer=FCGuide;NCLeaf.fallScale=true;NCLeaf.fallScaleWidth=15;NCLeaf.fallDensity=true;NCLeaf.fallDensityWidth=12
   FCparity "Analyzer boundary falloff"
   NCLeaf.fallScale=false;NCLeaf.fallDensity=false
   for row=NCLeaf.patternLines.count to 1 by -1 do NCLeaf.removeStroke row
   NCLeaf.diversityMode=4;NCLeaf.analyzerNode=FCGuide;NCLeaf.addStroke FCGuide side:2
   NCLeaf.patternWidths[1]=12.0;NCLeaf.strokeModes[1]=2;NCLeaf.setStrokeSelection 1 2 #(NCLeaf.sourceRowIDs[1])
   NCLeaf.strokeMin[1]=0.8;NCLeaf.strokeMax[1]=1.2;NCLeaf.borderFaceOut=true
   FCparity "Analyzer assignment facing"
   NCLeaf.strokeSides=#(7);NCLeaf.patternWidths=#(8.0);FCparity "Analyzer fixed edge anchors"
   NCLeaf.diversityMode=1;NCLeaf.areaUsePoints=true;NCLeaf.areaAnalyzer=FCGuide;FCapply()
   FCBefore=FChash();FCPublished=NCRoot.procNativePublication;local runs=FCGuide.getAnalysisRuns()
   FCGuide.resolution=49
   NCRoot.refreshAll()
   FCcheck (NCLeaf.previewError!="" and FChash()==FCBefore and NCRoot.procNativePublication==FCPublished and FCGuide.getAnalysisRuns()==runs) "Stale Analyzer successor retains complete result without secretly analyzing"
   FCGuide.runAnalysis();FCapply();FCcheck (NCLeaf.previewError=="") "Explicit Analyze permits successor recovery"
   FCwrite "PASS Analyzer pending/current contract"
   FCPublished=undefined;FCBefore=FChash()
   saveMaxFile (MCPFixtureDir+"native-fields-controller.max") quiet:true
   loadMaxFile (MCPFixtureDir+"native-fields-controller.max") quiet:true useFileUnits:true
   NCNode=getNodeByName "Native controller";NCRoot=NCNode.baseObject;NCLeaf=NCRoot.layerObjects[1];NCModels=NCLeaf.validSources();NCTerrain=(NCLeaf.validSurfaces())[1]
   NCRoot.procNativeRoute=true;NCRoot.procExplicitUpdate=true;try(FCapply())catch(NCRoot.procExplicitUpdate=false;throw());NCRoot.procExplicitUpdate=false
   FCcheck (FCBefore==FChash()) "Optional features and actual Analyzer survive save/reopen"
   FCGuide=getNodeByName "Native fields Analyzer";FCPaint=undefined;FCArea=undefined;FCPath=undefined
   FCwrite "PASS optional save/reopen"
  )
  "release": (FCGuide=undefined;FCPaint=undefined;FCPublished=undefined;FCArea=undefined;FCPath=undefined)
  default:throw "Unknown field controller phase"
 )
)
