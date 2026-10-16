-- Bounded, exact-placement Scanline thumbnail in an owned example scene.
(
 local temporary=#()
 try (
  for layerIndex=1 to DemoRoot.layerObjects.count do (
   local leaf=DemoRoot.layerObjects[layerIndex],vertices=#(),faces=#(),materialIDs=#(),sourceMeshes=#()
   for source in leaf.sources do (
    local origin=copy source;origin.transform=matrix3 1
    append sourceMeshes (snapshotAsMesh origin);delete origin
   )
   for row in DemoRoot.groupSnapshotRows[layerIndex] do (
    local shape=sourceMeshes[row[2]],offset=vertices.count
    for i=1 to shape.numverts do append vertices ((getVert shape i)*row[1])
    for i=1 to shape.numfaces do (append faces ((getFace shape i)+[offset,offset,offset]);append materialIDs row[2])
   )
   if faces.count>500000 do throw "Owned thumbnail fixture exceeded its face bound."
   local snapshot=mesh name:"TEMP owned thumbnail" vertices:vertices faces:faces;append temporary snapshot
   local materials=multiMaterial numsubs:leaf.sources.count
   for i=1 to leaf.sources.count do materials.materialList[i]=leaf.sources[i].material
   snapshot.material=materials
   for i=1 to materialIDs.count do setFaceMatID snapshot i materialIDs[i]
   update snapshot
  )
  append temporary (omniLight pos:[-18,-25,40] multiplier:1.1)
  append temporary (omniLight pos:[25,15,30] multiplier:0.55)
  renderers.current=Default_Scanline_Renderer();renderWidth=640;renderHeight=480;backgroundColor=color 38 43 41;ambientLight=color 35 35 35
  local frame=render camera:DemoCamera outputFile:DemoImagePath vfb:false;close frame
 )catch(delete temporary;throw())
 delete temporary
)
