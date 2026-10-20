-- Bounded test-only readback of immutable native placements for library thumbnails.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/" do throw "Owned reliability profile required"
 local temporary=#(),metre=units.decodeValue "1m"
 try (
  for layerIndex=1 to DemoRoot.layerObjects.count do (
   local leaf=DemoRoot.layerObjects[layerIndex],vertices=#(),faces=#(),materialIDs=#(),sourceMeshes=#()
   for source in leaf.sources do (
    local origin=copy source;append temporary origin;origin.transform=matrix3 1
    append sourceMeshes (snapshotAsMesh origin);delete origin
   )
   local rows=DemoRoot.groupSnapshotRows[layerIndex],token=cyrusPlacementToken rows
   for start=0 to (rows.count-1) by 500 do for row in (cyrusPlacementPage rows token start (amin 500 (rows.count-start))) do (
    local shape=sourceMeshes[row[2]],offset=vertices.count
    if faces.count+shape.numfaces>500000 or vertices.count+shape.numverts>1000000 do throw "Owned thumbnail exceeds its mesh budget"
    for i=1 to shape.numverts do append vertices ((getVert shape i)*row[1])
    for i=1 to shape.numfaces do (append faces ((getFace shape i)+[offset,offset,offset]);append materialIDs row[2])
   )
   if faces.count>0 do (
    local snapshot=mesh name:"TEMP reliability thumbnail" vertices:vertices faces:faces;append temporary snapshot
    local materials=multiMaterial numsubs:leaf.sources.count
    for i=1 to leaf.sources.count do materials.materialList[i]=leaf.sources[i].material
    snapshot.material=materials
    for i=1 to materialIDs.count do setFaceMatID snapshot i materialIDs[i]
    update snapshot
   )
  )
  append temporary (omniLight pos:([-18,-25,40]*metre) multiplier:1.1)
  append temporary (omniLight pos:([25,15,30]*metre) multiplier:0.55)
  renderers.current=Default_Scanline_Renderer();renderWidth=640;renderHeight=480;backgroundColor=color 38 43 41;ambientLight=color 35 35 35
  local frame=render camera:DemoCamera outputFile:DemoImagePath vfb:false;close frame
 )catch(delete (for n in temporary where isValidNode n collect n);throw())
 delete (for n in temporary where isValidNode n collect n)
)
