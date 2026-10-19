(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local log=createFile (MCPFixtureDir+"demo-verify.txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  check (Demo0862Root.layerObjects.count==6) "Integrated scene has six editable layers" log
  local hash=cyrusRecipePublicationFingerprint Demo0862Root.groupSnapshotRows
  check (loadMaxFile (MCPFixtureDir+"Feature Demo 0.86.2 - working.max") quiet:true useFileUnits:true) "Integrated scene reopens" log
  Demo0862Node=getNodeByName "CYRUS 0.86.2 | SELECT ME - six feature layers";Demo0862Root=Demo0862Node.baseObject
  Demo0862Root.refreshAll()
  check ((cyrusRecipePublicationFingerprint Demo0862Root.groupSnapshotRows)==hash) "Reopen reproduces every full placement record" log
  local buffer=Demo0862Root.groupSnapshotRows[6],upright=true
  local rows=cyrusPlacementPage buffer (cyrusPlacementToken buffer) 0 (amin 32 buffer.count)
  for i=1 to amin 32 rows.count do if dot (normalize rows[i][1].row3) [0,0,1]<0.99999 do upright=false
  check upright "Normals-off mountain models remain world upright" log
  local tilted=false;buffer=Demo0862Root.groupSnapshotRows[5];rows=cyrusPlacementPage buffer (cyrusPlacementToken buffer) 0 (amin 64 buffer.count)
  for i=1 to amin 64 rows.count do if dot (normalize rows[i][1].row3) [0,0,1]<0.99 do tilted=true
  check tilted "Normals-on mountain models follow terrain orientation" log
  local material=(Demo0862Root.layerObjects[1].validSurfaces())[1].material
  CyrusMaskView=3;CyrusMaskDetail=2
  for index in #(1,2,4,6) do (
   local count=CyrusShowMeshMaskPreview Demo0862Root.layerObjects[index],info=cyrusDensityOverlayInfo CyrusMeshMaskPreviewRows
   check (count>0 and count<=32768 and info[2]>=0 and info[3]<=1 and info[2]<info[3]) ("Continuous combined field is nonuniform and bounded for layer "+index as string) log
  )
  check ((Demo0862Root.layerObjects[1].validSurfaces())[1].material==material) "Painting and mountain overlays preserve terrain material" log
  check ((cyrusRecipePublicationFingerprint Demo0862Root.groupSnapshotRows)==hash) "All demo mask views preserve Manual plants" log
  CyrusClearMeshMaskPreview undefined
  DNode=Demo0862Node;DRoot=Demo0862Root;DLayer=DRoot.layerObjects[4];DTerrain=(DLayer.validSurfaces())[1]
  select DNode;max modify mode;DRoot.selectLayer 4;DRoot.bindNativeUI()
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
