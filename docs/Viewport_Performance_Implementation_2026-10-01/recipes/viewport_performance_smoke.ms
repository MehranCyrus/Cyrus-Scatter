-- Isolated Max process: proxy output parity, memory fallback and script lifecycle.
global VPRoot,VPLog,VPRequire,VPParity,VPGeometryTests,VPMemoryTests
VPRoot=(dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName()))+"../../")
VPLog=createFile (VPRoot+"build/viewport-performance-test/result.txt")
fn VPRequire condition reason = (if not condition do throw reason)
fn VPParity cache expectedFaces label = (
 local old=cyrusPreviewTriangles cache false 100000
 local prepared=cyrusPreviewTriangles cache true 100000
 VPRequire (old.count==expectedFaces and prepared.count==old.count) (label+": face count")
 for i=1 to old.count do (
  for j=1 to 3 do VPRequire (old[i][j]==prepared[i][j]) (label+": position/order mismatch")
  VPRequire (old[i][4]==prepared[i][4]) (label+": shade mismatch")
  VPRequire (old[i][5]==prepared[i][5]) (label+": source color mismatch")
 )
 format "PASS %: % triangles, exact positions/shades/colors\n" label old.count to:VPLog;flush VPLog
)
fn VPGeometryTests = (
 local sourceA=box length:13 width:27 height:42,sourceB=box length:7 width:9 height:2
 sourceA.objectOffsetPos=[1,3,-2]
 local mirrored=scaleMatrix [-2,0.5,3]
 mirrored.row4=[10000,-12000,3200]
 local sheared=matrix3 [1,0.3,0] [0.2,2,0.1] [0,0.2,1] [-30,55,20]
 local rows=#(#(matrix3 1,1),#(mirrored,2),#(sheared,1),#((rotateXMatrix 37)*(transMatrix [20,30,40]),2))
 for mode=1 to 3 do (
  local facesPer=(#(12,168,6))[mode]
  local cache=cyrusBuildGeometryPreview rows #(sourceA,sourceB) #(red,blue) mode 100 2000000
  VPRequire ((aminScatterPreviewCount cache)==4) "Displayed count"
  VPParity cache (facesPer*4) ("proxy mode "+(mode as string))
  local stats=cyrusPreviewDrawStats cache
  VPRequire (stats[2]==4 and stats[3]==2 and stats[4]==facesPer*4) "Source group batching"
 )
 local budgeted=cyrusBuildGeometryPreview rows #(sourceA,sourceB) #(red,blue) 3 2 12
 VPRequire ((aminScatterPreviewCount budgeted)==2) "Instance selection budget"
 VPParity budgeted 12 "selected row ordering"
 local placeholder=cyrusBuildGeometryPreview #(#(matrix3 1,1),#(mirrored,2)) #(sourceA,-1) #(red,green) 3 20 100
 VPRequire ((aminScatterPreviewCount placeholder)==2 and (cyrusPreviewFaces placeholder)==6) "Placeholder count"
 VPRequire ((aminScatterPreviewPoints placeholder).count==1) "Placeholder marker lost"
 VPParity placeholder 6 "mixed proxy/placeholder"
 local emptySource=mesh vertices:#() faces:#()
 local missing=cyrusBuildGeometryPreview #(#(matrix3 1,1),#(mirrored,2)) #(sourceA,emptySource) #(red,green) 3 20 100
 VPRequire ((aminScatterPreviewCount missing)==1 and (cyrusPreviewFaces missing)==6) "Empty source skip changed"
 VPParity missing 6 "empty source skip"
 local empty=cyrusBuildGeometryPreview #() #(sourceA) #(red) 3 20 100
 VPRequire ((cyrusPreviewDrawStats empty)[3]==0) "Empty cache allocated batches"
 local fullMesh=cyrusBuildGeometryPreview rows #(sourceA,sourceB) #(red,blue) 4 100 2000000
 VPRequire ((cyrusPreviewDrawStats fullMesh)[3]==0 and (cyrusPreviewFaces fullMesh)==48) "Mesh fallback"
 local many=for i=1 to 1500 collect #((transMatrix [i*2,0,0]),1)
 local chunked=cyrusBuildGeometryPreview many #(sourceA) #(red) 3 2000 2000000
 VPRequire ((cyrusPreviewDrawStats chunked)[3]==3) "4096-face chunk bound"
 VPParity chunked 9000 "chunk boundaries"
 format "PASS empty, mesh, missing-source and point-placeholder policies\n" to:VPLog;flush VPLog
)
fn VPMemoryTests = (
 local source=box length:1 width:1 height:1
 local rows=for i=1 to 1000 collect #((transMatrix [i,0,0]),1)
 local held=#(),fallbacks=0
 for i=1 to 12 do (
  local cache=cyrusBuildGeometryPreview rows #(source) #(red) 2 1000 2000000
  append held cache
  local s=cyrusPreviewDrawStats cache
  VPRequire (s[5]<=s[7] and s[6]<=s[8]) "Memory cap exceeded"
  VPRequire ((aminScatterPreviewCount cache)==1000 and (cyrusPreviewFaces cache)==168000) "Global fallback changed output"
  if s[3]==0 do fallbacks+=1
 )
 VPRequire (fallbacks>0) "Global cap did not select fallback"
 local largeRows=for i=1 to 3000 collect #((transMatrix [i,0,0]),1)
 local oversized=cyrusBuildGeometryPreview largeRows #(source) #(red) 2 3000 2000000
 VPRequire ((cyrusPreviewDrawStats oversized)[3]==0 and (cyrusPreviewFaces oversized)==504000) "Per-cache fallback"
 format "PASS 16 MiB/cache and 64 MiB/process caps; % global fallbacks preserve counts\n" fallbacks to:VPLog;flush VPLog
)
try (
 fileIn (VPRoot+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
 fileIn (VPRoot+"AminScatter/scripts/AminScatterObject.ms")
 VPGeometryTests();gc()
 VPMemoryTests();gc()
 local probe=cyrusBuildGeometryPreview #() #() #() 3 1 12
 VPRequire ((cyrusPreviewDrawStats probe)[6]==0) "Batch memory retained after cache collection"
 format "PASS batch payload released by cache GC\n" to:VPLog;flush VPLog
 local surface=plane length:1000 width:1000 lengthsegs:1 widthsegs:1
 local plant=box length:8 width:12 height:25 pos:[2000,0,0]
 local root=AminScatterObject name:"VP_Controller"
 root.surfaceNodes=#(surface);root.newLayer();root.newLayer();root.viewportMode=2;root.proxyShape=3;root.updateMode=2
 for l in root.layerObjects do (l.sources=#(plant);l.amount=40)
 local entries=root.layerEntries()
 VPRequire (entries.count==2) "Layer traversal"
 root.refreshDisplay()
 for e in entries do VPRequire ((cyrusPreviewDrawStats ((e[2].cacheSnapshot())[1]))[3]>0) "Layer not batched"
 local before=for e in entries collect e[2].cacheSnapshot()
 for i=1 to 5 do AminScatterObjectDraw()
 for i=1 to entries.count do VPRequire ((entries[i][2].cacheSnapshot())[6]==before[i][6]) "Unchanged redraw rebuilt"
 local iconA=root.iconLines(),iconB=root.iconLines()
 VPRequire (iconA==iconB) "Icon changed on unchanged redraw"
 root.iconSize*=2
 VPRequire ((root.iconLines())[1][1]==iconA[1][1]*2) "Icon-size invalidation"
 local l=entries[1][2],rows=l.placements(l.validSources())
 local signature=cyrusEditFingerprint rows "viewport"
 root.updateMode=1;root.layerEntries();l.amount=43
 local manual=l.previewCache interactionHeld:false
 VPRequire ((aminScatterPreviewCount manual)==40) "Manual mode lost old cache"
 l.refreshPreview()
 VPRequire ((aminScatterPreviewCount(l.previewCache interactionHeld:false))==43) "Explicit manual refresh"
 root.updateMode=2;root.layerEntries();l.amount=47
 VPRequire ((aminScatterPreviewCount(l.previewCache interactionHeld:true))==43) "Mouse-held deferral"
 VPRequire ((aminScatterPreviewCount(l.previewCache interactionHeld:false))==47) "Post-drag rebuild"
 root.layerEnabled[2]=false
 VPRequire ((root.layerEntries()).count==1) "Layer enable invalidation"
 local clone=copy root
 VPRequire ((clone.layerEntries()).count==1) "Clone layer state"
 l.amount=40;root.layerEntries();l.refreshPreview()
 VPRequire ((cyrusEditFingerprint (l.placements(l.validSources())) "viewport")==signature) "Placement parity after settings round trip"
 local savePath=VPRoot+"build/viewport-performance-test/lifecycle.max"
 VPRequire (saveMaxFile savePath quiet:true) "Save candidate scene"
 VPRequire (loadMaxFile savePath quiet:true) "Reopen candidate scene"
 root=getNodeByName "VP_Controller";root.refreshDisplay()
 VPRequire ((aminScatterPreviewCount ((root.layerObjects[1].cacheSnapshot())[1]))==40) "Reopen population"
 VPRequire ((cyrusPreviewDrawStats ((root.layerObjects[1].cacheSnapshot())[1]))[3]>0) "Reopen batch cache"
 format "PASS unchanged redraw, icon resize, Manual, drag deferral, layer enable, clone, placement parity and save/reopen\nSUCCESS\n" to:VPLog
 close VPLog
)catch(
 format "FAILED: %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:VPLog;close VPLog
 throw()
)
