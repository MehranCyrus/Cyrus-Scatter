(
 local log=createFile (MCPFixtureDir+"preparation-key-probe-"+(timeStamp() as string)+".txt")
 local root=(getNodeByName "Pressure preceding sentinel").baseObject
 for leaf in root.layerObjects do (
  local current=leaf.procPreparationKey leaf.amount (leaf.validSources()),old=leaf.procPreparedKey
  format "LAYER % oldLen=% currentLen=% equal=%\n" leaf.layerID old.count current.count (old==current) to:log
  local common=amin old.count current.count,index=1
  while index<=common and old[index]==current[index] do index+=1
  format "DIFF % OLD % NEW %\n" index (substring old (amax 1 (index-80)) 200) (substring current (amax 1 (index-80)) 200) to:log
 )
 close log
)
