(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned variation host required."
 local log=createFile (MCPFixtureDir+"unsampled-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true;resetMaxFile #noPrompt
  local root,leaf,terrain,source
  undo off (
   terrain=plane name:"Unsolved receiver" width:100 length:100
   source=pyramid name:"Unsolved model" width:1 depth:2 height:3 pos:[200,0,0]
   root=(AminScatterObject name:"Unsolved setup").baseObject;root.updateMode=1;root.newLayer();leaf=root.selectedLayer()
   root.setLayerSurfaces leaf #(terrain);leaf.sources=#(source);leaf.ensureSourceRows();leaf.amount=300
   leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
  )
  local oldCurves=leaf.fallDensityCurve as array,oldEpoch=root.procEpoch,oldNormals=cyrusOrientationStats(),oldReceiver=leaf.receiverCacheStats(),oldPreparation=leaf.procPreparedBuilds
  check (leaf.procReceiverIDs.count==0) "Fixture has never enrolled or sampled receivers" log
  local document=CyrusRecipeCapture root #(leaf) "Saved before first Update",settings=CyrusRecipeGet (CyrusRecipeGet document "layers")[1] "settings"
  check ((CyrusRecipeGet settings "procReceiverVariationIDs").count==1) "Save freezes an unsampled layer's future variation" log
  check (root.procReceiverIDs.count==0 and root.fallDensityCurve.count==0 and leaf.fallDensityCurve.count==oldCurves.count) "Save does not initialize unrelated root metadata or authored curves" log
  format "COUNTERS BEFORE epoch=% normals=% receiver=% prepare=%\nAFTER epoch=% normals=% receiver=% prepare=%\n" oldEpoch oldNormals oldReceiver oldPreparation root.procEpoch (cyrusOrientationStats()) (leaf.receiverCacheStats()) leaf.procPreparedBuilds to:log
  check (root.procEpoch==oldEpoch and (leaf.receiverCacheStats())[1]==oldReceiver[1] and (cyrusOrientationStats())[1]==oldNormals[1] and leaf.procPreparedBuilds==oldPreparation) "Unsampled Save performs no placement, mesh/normal extraction or preparation" log
  root.refreshAll();local before=deepCopy root.groupSnapshotRows[1]
  local imported=CyrusRecipeImport root document (CyrusRecipeSuggestBindings root document) newSetup:true variation:#same
  imported[1].refreshAll()
  check (equalRows before imported[1].groupSnapshotRows[1]) "Saved unsampled variation reproduces the later first result" log
  local copyNode=copy (CyrusRecipeOwnerNode root),instanceNode=instance (CyrusRecipeOwnerNode root)
  check (copyNode.baseObject!=root and copyNode.baseObject.layerObjects[1]!=leaf and instanceNode.baseObject==root) "Max Copy and Instance retain native ownership semantics" log
  copyNode.baseObject.refreshAll()
  check (equalRows before copyNode.baseObject.groupSnapshotRows[1]) "Native Max Copy preserves complete variation rows" log
  check (copyNode.baseObject.layerObjects[1].overlapOwner==copyNode.baseObject) "Copied layer binds its own controller" log
  delete instanceNode
  check (not theHold.Holding()) "No stranded transaction" log
  CyrusPerfHeadless=false;CyrusPointSync();format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
