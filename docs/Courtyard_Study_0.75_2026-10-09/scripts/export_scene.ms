CYRebind()
CYR.evaluateGroups()
local f=createFile (CYOut+"Placements.tsv")
format "layer\tsource\tx\ty\tz\n" to:f
for i=1 to CYR.groupSnapshotRows.count do for row in CYR.groupSnapshotRows[i] do format "%\t%\t%\t%\t%\n" i row[2] row[1].row4.x row[1].row4.y row[1].row4.z to:f
close f
local definitions=#()
for l in CYL do append definitions #(l.layerID,for s in l.outputSources() collect #(s.name,(nodeGetBoundingBox s (matrix3 1)) as string),l.sourceScales as array,l.areaModes as array,for n in l.areaNodes collect n.name,l.patternWidths as array,l.strokeSides as array)
CYLog "layer-definitions" #(#("layers",definitions))
local polys=#()
for n in shapes where matchPattern n.name pattern:"*path*" or matchPattern n.name pattern:"INCLUDE*" or n.name=="EXCLUDE | tent footprint" do (
 if numSplines n>0 do append polys #(n.name,for i=1 to numKnots n 1 collect (getKnotPoint n 1 i)*n.objectTransform)
)
CYLog "polygons" #(#("polygons",for p in polys collect #(p[1],for v in p[2] collect #(v.x,v.y,v.z))))

local msh=snapshotAsMesh CYMound,tm=CYMound.objectTransform
CYLog "curved-receiver" #(#("vertices",for i=1 to msh.numverts collect (local p=(getVert msh i)*tm;#(p.x,p.y,p.z))),#("faces",for i=1 to msh.numfaces collect (local f=getFace msh i;#(f.x as integer,f.y as integer,f.z as integer))))
