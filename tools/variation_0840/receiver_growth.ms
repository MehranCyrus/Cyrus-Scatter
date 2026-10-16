(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"receiver-growth-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true;resetMaxFile #noPrompt
  local root,leaf,a,b,c
  undo off (
   units.SystemType=#meters;units.SystemScale=1
   a=plane name:"Density receiver A" width:100 length:100;b=plane name:"Density receiver B" width:100 length:100 pos:[130,0,0]
   c=plane name:"Density receiver C" width:100 length:100 pos:[260,0,0]
   local source=pyramid width:1 depth:2 height:3 pos:[-200,0,0]
   root=(AminScatterObject name:"Variation receiver growth").baseObject;root.updateMode=1;root.newLayer();leaf=root.selectedLayer()
   root.setLayerSurfaces leaf #(a,b);leaf.sources=#(source);leaf.ensureSourceRows();leaf.populationMode=2;leaf.plantsPerM2=0.1
   leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false;root.refreshAll()
  )
  local original=deepCopy root.groupSnapshotRows[1],domains=CyrusReceiverVariationDomains leaf,builds=(leaf.receiverCacheStats())[1]
  check (original.count==2000) "Uncapped Density allocates independent receiver quotas" log
  leaf.procReceiverVariationIDs=#();root.refreshAll()
  check (equalRows original root.groupSnapshotRows[1]) "Legacy empty-domain fallback preserves complete density rows" log
  root.setLayerSurfaces leaf #(a,b,c);root.refreshAll()
  local oldRows=for row in root.groupSnapshotRows[1] where row[1].row4.x<195 collect row
  check (root.groupSnapshotRows[1].count==3000 and equalRows original oldRows) "Appending a Density receiver retains every existing row" log
  check (leaf.procReceiverVariationIDs.count==3 and leaf.procReceiverVariationIDs[1]==domains[1] and leaf.procReceiverVariationIDs[2]==domains[2]) "Receiver enrollment preserves legacy domains and adds one domain" log
  check ((leaf.receiverCacheStats())[1]==builds+1) "Appending a receiver calculates only its new candidate cache" log
  local threeRows=deepCopy root.groupSnapshotRows[1],thirdDomain=leaf.procReceiverVariationIDs[3]
  max undo;root.refreshAll()
  check ((leaf.validSurfaces()).count==2 and equalRows original root.groupSnapshotRows[1]) "One Undo removes the assigned receiver without rerolling" log
  max redo;root.refreshAll()
  check (leaf.procReceiverVariationIDs[3]==thirdDomain and equalRows threeRows root.groupSnapshotRows[1]) "Redo reuses the enrolled receiver domain and complete result" log
  leaf.populationMode=1;leaf.amount=2400;root.refreshAll()
  check (root.groupSnapshotRows[1].count==2400) "Fixed Total remains a controller allocation limit" log
  local fixed=deepCopy root.groupSnapshotRows[1],fixedDomains=CyrusReceiverVariationDomains leaf
  root.setLayerSurfaces leaf #(a,b);root.refreshAll()
  check (root.groupSnapshotRows[1].count==2400 and not equalRows fixed root.groupSnapshotRows[1]) "Fixed Total rebalances quotas when a receiver is removed" log
  check (leaf.procReceiverVariationIDs[1]==fixedDomains[1] and leaf.procReceiverVariationIDs[2]==fixedDomains[2]) "Quota changes do not reseed existing receivers" log
  check (not theHold.Holding()) "No stranded receiver transaction" log
  CyrusPerfHeadless=false;CyrusPointSync();format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
