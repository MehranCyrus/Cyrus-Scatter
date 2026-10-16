(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"heavy-state-"+(timeStamp() as string)+".txt")
 format "heap=% free=% undo=%\n" heapSize heapFree (theHold.GetUndoNames()) to:log
 for node in objects where classof node.baseObject==AminScatterObject do (
  local root=node.baseObject
  format "ROOT rows=% epoch=% builds=% error=% mode=%\n" (for rows in root.groupSnapshotRows collect rows.count) root.procEpoch root.groupBuilds root.previewError root.updateMode to:log
  for leaf in root.layerObjects do (
   local current=leaf.procPreparationKey leaf.amount (leaf.validSources()),old=leaf.procPreparedKey
   format "LAYER rows=% prepared=% error=% oldLen=% newLen=% equal=%\n" leaf.procPreparedRows.count leaf.procPreparedBuilds leaf.previewError old.count current.count (old==current) to:log
   local common=amin old.count current.count,index=1
   while index<=common and old[index]==current[index] do index+=1
   if old!=current do format "DIFF % OLD % NEW %\n" index (substring old (amax 1 (index-80)) 200) (substring current (amax 1 (index-80)) 200) to:log
  )
 )
 format "END free=%\n" heapFree to:log
 close log
)
