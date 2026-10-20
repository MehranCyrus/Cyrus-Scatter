(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-*-2027/" do throw "Owned clearance host required"
 local root=(getNodeByName "Leaf clearance showcase").baseObject,leaf=root.layerObjects[1]
 local page=root.groupSnapshotRows[1],rows=cyrusPlacementPage page (cyrusPlacementToken page) 0 page.count
 local source=leaf.sources[1],log=createFile (MCPFixtureDir+"bake-diagnostic.txt")
 local maxError=0.,materialErrors=0
 format "Published % baked %\n" rows.count leaf.bakedNodes.count to:log
 for i=1 to rows.count do (
  local baked=leaf.bakedNodes[i]
  if baked.material!=source.material do (
   materialErrors+=1
   format "Material mismatch %: % / %\n" i baked.material source.material to:log
  )
  for axis=1 to 4 do (
   local error=distance baked.transform[axis] rows[i][1][axis]
   maxError=amax maxError error
   if error>0.00001 do (
    local probe=point()
    probe.transform=rows[i][1]
    format "Transform mismatch row % axis % delta %: % / %; plain Max assignment delta %\n" i axis error baked.transform[axis] rows[i][1][axis] (distance probe.transform[axis] rows[i][1][axis]) to:log
    delete probe
   )
  )
 )
 format "Maximum error % material errors %\n" maxError materialErrors to:log
 close log
)
