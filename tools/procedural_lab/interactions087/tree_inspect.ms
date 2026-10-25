global TRoot
local leaf=TRoot.layerObjects[5],node=leaf.sources[1],f=createFile (GardenRun+"tree-inspection.txt")
format "source=% class=% polygons=% scale=% bbox=% %\n" node.name (classOf node.baseObject) (getPolygonCount node) leaf.sourceScales[1] node.min node.max to:f
format "metadata=%\n" TRoot.procPublishedMetadata[5] to:f
close f
