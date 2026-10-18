-- Same saved multi-area Paint scene, baseline and native; no Modify UI timing.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-*/" do throw "Owned Paint benchmark required"
 local args=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global PBNode,PBRoot,PBLeaf,PBExpected,cyrusPlacementMemoryStats
 fn PBcheck yes text=(if not yes do throw ("Paint benchmark: "+text))
 fn PBapply=(PBRoot.refreshAll();PBcheck (PBLeaf.previewError=="") PBLeaf.previewError)
 fn PBhash=(cyrusRecipePublicationFingerprint PBRoot.groupSnapshotRows)
 local original="F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/foundation-memory0854-nativeobserve-baseline-20261018-02/"
 case args[1] of (
  "setup": (
   if args[2]=="old" then (
    with undo off (
     resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
     local terrain=plane width:100 length:100 widthsegs:64 lengthsegs:64,model=pyramid width:.3 depth:.3 height:1 pos:[75,0,0]
     PBNode=AminScatterObject name:"Multi-area Paint benchmark";PBRoot=PBNode.baseObject;PBRoot.updateMode=1;PBRoot.autoRender=false
     PBRoot.newLayer();PBLeaf=PBRoot.selectedLayer();PBRoot.setLayerSurfaces PBLeaf #(terrain);PBLeaf.sources=#(model);PBLeaf.amount=5000
     PBLeaf.procSelfOverride=true;PBLeaf.procSelfEnabled=false;PBLeaf.sourceRadiiWU=#(0.0)
     local area=PBRoot.addPaintArea PBLeaf target:terrain;area.paintView=0
     cyrusBrushFill area.paintDocument 1;cyrusBrushSettings area.paintDocument 15 true;cyrusBrushDab area.paintDocument [0,0,200] [0,0,-1] true
     cyrusBrushSetFalloff area.paintDocument #(10.0,5.0,true,true,0.15,1.4,#(0,0.2,1),#(0,0.5,1));area.paintDensity=.8;area.publishPaint()
     area=PBRoot.addPaintArea PBLeaf target:terrain;area.paintView=0
     cyrusBrushSettings area.paintDocument 25 false;cyrusBrushDab area.paintDocument [15,0,200] [0,0,-1] true
     cyrusBrushSetFalloff area.paintDocument #(4.0,3.0,true,true,0.2,1.2,#(0,0.5,1),#(0,1));area.paintDensity=.9;area.publishPaint()
     PBLeaf.paintEnabled=true;PBRoot.viewportMode=1;PBRoot.pointsPerPlant=1;PBapply()
    )
    saveMaxFile(original+"paint-benchmark.max") quiet:true
   ) else (
    loadMaxFile(original+"paint-benchmark.max") quiet:true useFileUnits:true
    PBNode=getNodeByName "Multi-area Paint benchmark";PBRoot=PBNode.baseObject;PBLeaf=PBRoot.layerObjects[1];PBapply()
   )
   clearSelection();max create mode;PBExpected=undefined
  )
  "sample": (
   local amount=args[2] as integer,iteration=args[3] as integer,clock=dotNetClass "System.Diagnostics.Stopwatch"
   PBLeaf.amount=amount;local start=clock.GetTimestamp(),heapBefore=heapSize,freeBefore=heapFree
   PBapply();local finish=clock.GetTimestamp(),heapAfter=heapSize,freeAfter=heapFree,hash=PBhash()
   if amount==200000 do (
    if PBExpected==undefined then PBExpected=hash else PBcheck (PBExpected==hash) "Repeated complete output"
    if args[4]=="old" then (dotNetClass "System.IO.File").WriteAllText(original+"paint-benchmark-hash.txt") hash
    else PBcheck (hash==(dotNetClass "System.IO.File").ReadAllText(original+"paint-benchmark-hash.txt")) "Full output equals saved baseline scene"
   )
   local f=openFile(MCPFixtureDir+"paint-benchmark.tsv") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"paint-benchmark.tsv")
   format "%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\n" iteration amount start finish clock.Frequency heapBefore freeBefore heapAfter freeAfter PBLeaf.generatedCount hash to:f;close f
   if amount==200000 do (
    gc light:true
    local values=cyrusObservePlacementValues #(PBRoot.groupSnapshotRows,PBLeaf.procPreparedRows,PBLeaf.procReceiverCache,PBLeaf.paintBaseRows)
    f=openFile(MCPFixtureDir+"paint-owned-memory.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"paint-owned-memory.txt")
    format "% values=% placement=% buffers=%\n" iteration values (if cyrusPlacementMemoryStats==undefined then undefined else cyrusPlacementMemoryStats()) (cyrusScriptBufferStats()) to:f;close f
   )
  )
  default:throw "Unknown Paint benchmark phase"
 )
)
