(
 local log=createFile (MCPFixtureDir+"heap-cached-stage-"+(timeStamp() as string)+".txt")
 local root=(getNodeByName "Pressure preceding sentinel").baseObject,leaf=root.layerObjects[1],plants=leaf.validSources()
 leaf.procGeometryRevision+=1;leaf.procPlanReceivers #()
 local before=heapFree,size=heapSize,builds=leaf.procReceiverBuilds
 local rows=leaf.procPrepare 30000 plants
 format "30k cached-generation preparation bytes=% grew=% rawRebuilt=% rows=%\n" (before-heapFree) (heapSize!=size) (leaf.procReceiverBuilds!=builds) rows.count to:log
 close log
)
