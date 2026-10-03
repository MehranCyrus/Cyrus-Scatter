(
local node=BLCurved,mesh=snapshotAsMesh BLCurved
local screen=getViewSize()
local ray=mapScreenToWorldRay [screen.x*.5,screen.y*.5]
local tm=node.objectTransform
local camera=inverse (viewport.getTM())
local depth=dot ray.dir (-normalize camera.row3)
local origin=ray.pos*(inverse tm),direction=(ray.dir/depth)
local output=createFile (BLDir+"pick-fixture.txt")
format "% %\n" mesh.numverts mesh.numfaces to:output
for i=1 to mesh.numverts do (
    local v=(getVert mesh i)*(inverse tm)
    format "% % %\n" (CSPNumber v.x) (CSPNumber v.y) (CSPNumber v.z) to:output
)
for i=1 to mesh.numfaces do (
    local f=getFace mesh i
    format "% % %\n" ((f.x as integer)-1) ((f.y as integer)-1) ((f.z as integer)-1) to:output
)
format "% % % % % %\n" (CSPNumber origin.x) (CSPNumber origin.y) (CSPNumber origin.z) (CSPNumber direction.x) (CSPNumber direction.y) (CSPNumber direction.z) to:output
close output
)
