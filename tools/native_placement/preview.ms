-- Actual native draw inputs, cache content and retained publication. Private host.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-preview-*/" do throw "Owned native preview host required."
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global PVRows,PVModels,PVCache,PVOwner,PVController,PVStyle,PVStats,PVPoints
 fn PVCheck yes label=(if not yes do throw ("Native preview: "+label))
 fn PVWrite label=(local f=openFile(MCPFixtureDir+"native-preview.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-preview.txt");format "%\n" label to:f;close f)
 fn PVPalette mode:1 band:false=#(1,mode,#(red,green),(if band then #(#(123L,blue)) else #()),band)
 fn PVRedraw=(for i=1 to 3 do (completeRedraw();windows.processPostedMessages();sleep 0.05))
 case command[1] of (
  "prepare": (
   local amount=command[2] as integer
   PVRows=undefined;PVCache=undefined;gc light:true
   CyrusReserveScriptWorkspace (8388608L+(amount as integer64)*2048L)
   if PVModels==undefined or not isValidNode PVModels[1] do PVModels=#(box name:"Native preview source A" width:1 length:1 height:2,sphere name:"Native preview source B" radius:0.7 segments:12)
   NGRequest=NGBase amount
   local old=NGCall false,native=NGCall true
   PVRows=#(cyrusEditStack #() old[1] 1 "preview",cyrusEditStack #() native[1] 1 "preview")
   PVCheck ((cyrusRecipePublicationFingerprint #(PVRows[1]))==(cyrusRecipePublicationFingerprint #(PVRows[2]))) "Complete draw input parity"
   local usage=cyrusPlacementSourceUsage PVRows[2],expected=#(0,0)
   for row in PVRows[1] do expected[row[2]]+=1
   PVCheck (CyrusPresetSameValues usage expected) "Bounded source-use summary matches every input"
   PVWrite ("PREPARE "+NGKind+" "+(amount as string))
  )
  "point": (
   local budget=command[2] as integer,samples=#(#([-0.5,0,0],[0,0,1]),#([0.5,0,0],[0,0.5,1])),palette=PVPalette()
   gc light:true;cyrusPlacementTransportStats true
   local old=aminScatterBuildPreview PVRows[1] samples palette budget,before=cyrusPlacementTransportStats()
   local native=aminScatterBuildPreview PVRows[2] samples palette budget
   PVCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Preview uses no placement readback/materialization"
   PVCheck (cyrusPreviewContentEqual old native) "All point values, owners, colors and bounds match"
   PVCheck (cyrusPreviewPlacementsEqual PVRows[1] PVRows[2] and cyrusPreviewPlacementsEqual PVRows[2] PVRows[1]) "Mixed/native display equivalence"
   PVCheck ((aminScatterPreviewCount native)==(if budget==0 then 2*PVRows[2].count else amin budget (2*PVRows[2].count))) "Point subset/count rule preserved"
   local recolor=cyrusRecolorPreview native (PVPalette mode:2)
   PVCheck (not cyrusPreviewContentEqual native recolor) "Content comparison notices palette changes"
   PVCache=native
   PVWrite ("PASS "+NGKind+" points rows="+(PVRows[2].count as string)+" budget="+(budget as string))
  )
  "mesh": (
   local mode=command[2] as integer,limit=command[3] as integer,placeholder=command[4]=="placeholder"
   gc light:true
   local sources=if placeholder then #(PVModels[1],-1) else PVModels
   local palette=PVPalette(),old=cyrusBuildGeometryPreview PVRows[1] sources palette mode limit 0,before=cyrusPlacementTransportStats()
   local native=cyrusBuildGeometryPreview PVRows[2] sources palette mode limit 0
   PVCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Geometry preview uses no placement readback/materialization"
   PVCheck (cyrusPreviewContentEqual old native) "Every source face, instance matrix, marker, owner, color and bound matches"
   PVCheck ((aminScatterPreviewCount native)==(if limit==0 then PVRows[2].count else amin limit PVRows[2].count)) "Geometry subset/count rule preserved"
   PVCheck ((cyrusPreviewFaces old)==(cyrusPreviewFaces native)) "Exact displayed face count"
   PVCache=native
   PVWrite ("PASS "+NGKind+" mesh mode="+(mode as string)+" rows="+(PVRows[2].count as string)+" limit="+(limit as string)+" placeholder="+(placeholder as string))
  )
  "bands": (
   local old=for i=1 to (amin 500 PVRows[1].count) collect (deepCopy PVRows[1][i])
   for row in old do row[6]=123L
   local native=cyrusPlacementCapture NGOwner 2 2 0 old,palette=PVPalette mode:3 band:true
   local a=cyrusBuildGeometryPreview old PVModels palette 4 37 0,b=cyrusBuildGeometryPreview native PVModels palette 4 37 0
   PVCheck (cyrusPreviewContentEqual a b) "Band-owned geometry and identification colors match"
   local rejected=false;old[old.count][6]=456L
   local invalid=cyrusPlacementCapture NGOwner 2 2 0 old
   try(cyrusBuildGeometryPreview invalid PVModels palette 4 1 0)catch(rejected=true)
   PVCheck rejected "Unshown native Band owner is validated"
   PVWrite ("PASS "+NGKind+" bands and unshown validation")
  )
  "failure": (
   local before=PVCache,rejected=false
   try(cyrusBuildGeometryPreview PVRows[2] #(PVModels[1]) #(1,1,#(red),#(),false) 4 1 0)catch(rejected=true)
   PVCheck rejected "Unshown source indices are validated"
   rejected=false;try(aminScatterBuildPreview PVRows[2] #(#([0,0,0]),#()) (PVPalette()) 1)catch(rejected=true)
   PVCheck rejected "Inconsistent source samples reject"
   rejected=false;try(cyrusBuildGeometryPreview PVRows[2] PVModels (PVPalette()) 5 1 0)catch(rejected=true)
   PVCheck rejected "Invalid display mode rejects"
   PVCheck (cyrusPreviewContentEqual before PVCache) "Rejected successors do not mutate previous draw content"
   PVWrite ("PASS "+NGKind+" rejected-successor retention")
  )
  "comparison": (
   local first=deepCopy PVRows[1][1]
   first[2]=1 -- The geometry mutation below deliberately edits source A.
   local shifted=deepCopy first
   shifted[1].row4+= [0.25,0.5,1.0]
   local a=cyrusPlacementCapture NGOwner 2 2 0 #(first),b=cyrusPlacementCapture NGOwner 2 2 0 #(shifted),palette=PVPalette()
   local points=#(#([0,0,0]),#([0,0,0])),p=aminScatterBuildPreview a points palette 0,q=aminScatterBuildPreview b points palette 0
   PVCheck (not cyrusPreviewContentEqual p q) "Content comparison detects changed point positions with equal counts"
   p=cyrusBuildGeometryPreview a PVModels palette 4 0 0;q=cyrusBuildGeometryPreview b PVModels palette 4 0 0
   PVCheck (not cyrusPreviewContentEqual p q) "Content comparison detects changed instance transforms with equal source faces/counts"
   local height=PVModels[1].height
   try (
    PVModels[1].height=height+0.5
    q=cyrusBuildGeometryPreview a PVModels palette 4 0 0
    PVCheck (not cyrusPreviewContentEqual p q) "Cached geometry owns its copied faces and bounds after source edits"
   )catch(PVModels[1].height=height;throw())
   PVModels[1].height=height
   PVWrite ("PASS "+NGKind+" content-comparison negative cases")
  )
  "publish": (
   CyrusPerfHeadless=true
   PVController=box name:"Native preview retained controller" width:100 length:100 height:1
   PVOwner=cyrusRetainedCreate();PVStyle=#(#(false,white))
   hideByCategory.helpers=false;viewport.setType #view_top
   viewport.ZoomToBounds false [-75,-75,-10] [75,75,30]
   PVCheck (cyrusRetainedPublish PVOwner PVController #(PVCache) PVStyle) "Native cache publishes through retained draw path"
   PVRedraw();PVStats=cyrusRetainedStats PVOwner
   PVCheck (PVStats[12]==1 and cyrusRetainedMatches PVOwner #(PVCache) PVStyle) "Actual draw preparation is complete"
   PVCheck (cyrusRetainedPublish PVOwner PVController #(PVCache) PVStyle) "Unchanged retained publication succeeds"
   PVRedraw();local after=cyrusRetainedStats PVOwner
   PVCheck (after[3]==PVStats[3] and after[6]==PVStats[6]) "Unchanged publication adds no revision/upload"
   PVWrite ("PASS "+NGKind+" retained publish and upload reuse")
  )
  "releaseInput": (
   PVRows=undefined;NGRequest=undefined;NGPrevious=undefined;NGHashes=undefined
   gc light:true
   PVCheck ((cyrusPlacementMemoryStats())[1]==0) "Display owns copied native data after placement generation is released"
   PVCheck (cyrusRetainedMatches PVOwner #(PVCache) PVStyle) "Retained cache remains usable without input placements"
   PVRedraw();PVWrite ("PASS "+NGKind+" detached native input lifetime")
  )
  "release": (
   PVRows=undefined;PVCache=undefined;PVModels=undefined;PVOwner=undefined;PVController=undefined;PVStyle=undefined;PVStats=undefined
   NGRequest=undefined;NGPrevious=undefined;NGHashes=undefined
   resetMaxFile #noPrompt;PVRedraw();gc light:true
   local bytes=cyrusPlacementMemoryStats(),resources=cyrusPreviewResourceStats()
   PVCheck (bytes[1]==0 and bytes[6]==0 and bytes[7]==0) "All placement generations/views release"
   PVCheck (resources[1]==1 and resources[2]==0 and resources[5]==0) "All Point/Mesh reservations release after scene departure"
   cyrusPlacementTransportStats false;PVWrite "PASS RELEASE"
  )
  default: throw "Unknown native preview phase"
 )
)
