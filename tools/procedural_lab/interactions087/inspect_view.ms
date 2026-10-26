global TOwner,TRoot,TEdit,TRocks
local position=(cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation
local f=createFile (GardenRun+"near-visible-nodes.txt")
for node in geometry where not node.isHidden and not isDeleted node do (
    local lo=node.min,hi=node.max
    if lo.x<=position.x+200 and hi.x>=position.x-200 and lo.y<=position.y+200 and hi.y>=position.y-200 do format "% | % | % | % | render:%\n" node.name (classOf node.baseObject) lo hi node.renderable to:f
)
format "\nContact: %\n" (TRoot.interactionsStatistics()) to:f
close f
