(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"heap-stages-"+(timeStamp() as string)+".txt")
 fn stamp label before size log = (format "% consumed=% free=% heap=% grew=%\n" label (before-heapFree) heapFree heapSize (size!=heapSize) to:log;flush log)
 try (
  CyrusPerfHeadless=true
  global GalleryHeapStageContinue
  if GalleryHeapStageContinue!=true do loadMaxFile (MCPFixtureDir+"variation-heavy.max") quiet:true useFileUnits:true
  local root=(getNodeByName "Variation heavy setup").baseObject
  if GalleryHeapStageContinue!=true do (root.updateMode=1;root.refreshAll())
  local leaf=root.layerObjects[1],plants=leaf.validSources(),before=heapFree,size=heapSize
  leaf.randomSeed+=41
  leaf.procPlanReceivers #();stamp "30k receiver schedule" before size log
  before=heapFree;size=heapSize
  local rows=leaf.procPrepare 30000 plants;stamp "30k new preparation" before size log
  before=heapFree;size=heapSize
  local radii=leaf.procRadii rows plants;stamp "30k radii" before size log
  before=heapFree;size=heapSize
  local plan=#(#(leaf.layerID,false,false,1,#(false,1.,0.,true),#(false,0.,0,0,true),#(#(leaf.layerID,rows,radii,#(false,1.,0.,true),30000,30000,leaf.procReceiverPlanData[2]))))
  local result=cyrusEvaluateProcedural plan #() 1000000;stamp "30k acceptance output" before size log
  before=heapFree;size=heapSize
  local geometry=leaf.procRadiusGeometry plants rows:rows,metadata=leaf.procPreviewMetadata plants geometry:geometry
  local display=leaf.procStagePreview result[1][1][1] placementRadiusValues:result[4][1][1] displayEpoch:(root.procEpoch+1) metadata:metadata
  stamp "30k preview staging (point budget 3000)" before size log
  format "COMPLETE: row counts %/%\n" rows.count result[1][1][1].count to:log
  GalleryHeapStageContinue=true
  close log
 )catch(format "ERROR %\n" (getCurrentException()) to:log;close log;throw())
)
