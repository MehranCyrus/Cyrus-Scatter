(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local f=createFile (MCPFixtureDir+"probe-"+(timeStamp() as string)+".txt")
 try (
  local node=getNodeByName "Variation qualification"
  if node==undefined do node=getNodeByName "Variation heavy setup"
  local root=node.baseObject
  format "UNDO %\nREDO %\n" (theHold.GetUndoNames()) (theHold.GetRedoNames()) to:f
  for owner in root.layerObjects do (
   format "cache %\nreceiver IDs % domains %\n" (owner.cacheSnapshot()) owner.procReceiverIDs owner.procReceiverVariationIDs to:f
   format "copy-array % class %\n" (copy (owner.procReceiverIDs as array)) (classof (copy (owner.procReceiverIDs as array))) to:f
   try(format "effective %\n" (CyrusReceiverVariationDomains owner) to:f)catch(format "effective ERROR %\n" (getCurrentException()) to:f)
   format "root layers % published % epoch %\n" root.layerObjects.count root.groupSnapshotRows.count root.procEpoch to:f
  )
 )catch(format "ERROR %\n" (getCurrentException()) to:f)
 close f
)
