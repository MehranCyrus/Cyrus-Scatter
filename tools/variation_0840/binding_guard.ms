(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"binding-guard-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true;resetMaxFile #noPrompt
  local root,leaf
  undo off (
   local receiver=plane width:100 length:100,source=pyramid width:1 depth:2 height:3 pos:[200,0,0]
   root=(AminScatterObject name:"Variation binding guard").baseObject;root.updateMode=1;root.newLayer();leaf=root.selectedLayer()
   root.setLayerSurfaces leaf #(receiver);leaf.sources=#(source);leaf.ensureSourceRows();leaf.amount=100
   leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false;root.refreshAll()
   leaf.procRadiusIDs=#(root.groupSnapshotRows[1][1][3]);leaf.procRadiusModes=#(1);leaf.procRadiusValues=#(1.0);leaf.procRadiusDistances=#(0.1);leaf.procRadiusBinding=leaf.procBindingKey
   root.refreshAll()
  )
  local domains=leaf.procReceiverVariationIDs as array,before=deepCopy root.groupSnapshotRows[1],epoch=root.procEpoch,binding=leaf.procRadiusBinding
  leaf.procReceiverVariationIDs[1]=CyrusNewLayerID();local failed=false
  try(root.refreshAll())catch(failed=true)
  format "BEFORE binding %\nAFTER binding %\nERROR %\n" binding leaf.procBindingKey (leaf.cacheSnapshot())[4] to:log
  check ((failed or (leaf.cacheSnapshot())[4]!="") and root.procEpoch==epoch and equalRows before root.groupSnapshotRows[1]) "Changed random domain rejects stale authored radius binding and retains publication" log
  check (leaf.procRadiusIDs.count==1 and leaf.procRadiusBinding==binding) "Failed variation keeps authored radius record" log
  leaf.procReceiverVariationIDs=domains;root.refreshAll()
  check (equalRows before root.groupSnapshotRows[1]) "Restoring random domain recovers bound result" log
  leaf.procReceiverVariationIDs=#();root.refreshAll()
  check (equalRows before root.groupSnapshotRows[1]) "Empty legacy domains preserve default receiver binding" log
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
