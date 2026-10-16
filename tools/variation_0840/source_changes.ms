-- Conditional matching after explicit source/transform changes, not reorder invariance.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"source-changes-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true;resetMaxFile #noPrompt
  local root,leaf,a,b,c
  undo off (
   local terrain=plane width:100 length:100
   a=pyramid width:1 depth:2 height:3 pos:[200,0,0];b=box width:2 length:3 height:2 pos:[200,10,0];c=sphere radius:1 pos:[200,20,0]
   root=(AminScatterObject name:"Variation source changes").baseObject;root.updateMode=1;root.newLayer();leaf=root.selectedLayer()
   root.setLayerSurfaces leaf #(terrain);leaf.sources=#(a,b);leaf.ensureSourceRows();leaf.amount=1000
   leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false;root.refreshAll()
  )
  local domains=CyrusReceiverVariationDomains leaf
  for stage=1 to 6 do (
   case stage of (
    1:(leaf.sources=#(a,b,c);leaf.ensureSourceRows();leaf.sourceWeights=#(0.2,0.3,0.5))
    2:(leaf.sources=#(c,a,b);leaf.ensureSourceRows();leaf.sourceWeights=#(0.5,0.2,0.3))
    3:(leaf.sources=#(c,a);leaf.ensureSourceRows();leaf.sourceWeights=#(0.5,0.5))
    4:(leaf.sourceWeights=#(1.0,0.0))
    5:(leaf.rotZMin=10;leaf.rotZMax=70)
    6:(leaf.sclXMin=0.5;leaf.sclXMax=1.5;leaf.sclYMin=0.5;leaf.sclYMax=1.5)
   )
   root.refreshAll();local rows=deepCopy root.groupSnapshotRows[1]
   check (rows.count==1000) ("Valid source/attribute change retains requested count: "+stage as string) log
   check ((CyrusReceiverVariationDomains leaf)[1]==domains[1]) "Source/attribute edits retain receiver random domain" log
   local copied=root.copyLogicalLayer leaf variation:#same;root.refreshAll()
   check (equalRows rows root.groupSnapshotRows[2]) ("Same copy exactly reproduces current source/attribute inputs: "+stage as string) log
   max undo;check (root.layerObjects.count==1) "Each source-case Copy remains one Undo" log
   root.refreshAll()
  )
  check (not theHold.Holding()) "No stranded source transaction" log
  CyrusPerfHeadless=false;format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
