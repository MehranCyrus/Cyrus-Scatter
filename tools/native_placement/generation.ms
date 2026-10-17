-- Native producer/preparation parity, executed only in an owned Max 2027 host.
(
 if not (matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativegenerate-*/" or matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-*/") do throw "Owned native-generation host required."
 local io=dotNetClass "System.IO.File",clock=dotNetClass "System.Diagnostics.Stopwatch"
 local command=filterString (io.ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NGOwner,NGTerrain,NGKind,NGRequest,NGPrevious,NGHashes,NGOriginalHeap
 global NGA,NGB,NGC,NGHoldBefore,NGHoldAfter,NGHoldState
 global NGCall,NGBase,NGCheck,NGAllCoveredSame,NGWrite
 fn NGCheck yes text=(if not yes do throw ("Native generation: "+text))
 fn NGCall native = (
  if native then cyrusScatterCanonicalNative NGOwner NGRequest[1] NGRequest[2] NGRequest[3] NGRequest[4] NGRequest[5] NGRequest[6] NGRequest[7] NGRequest[8] NGRequest[9] NGRequest[10] NGRequest[11] NGRequest[12] NGRequest[13] NGRequest[14] NGRequest[15] NGRequest[16] NGRequest[17] NGRequest[18] NGRequest[19] NGRequest[20] NGRequest[21] NGRequest[22] NGRequest[23] NGRequest[24] NGRequest[25] NGRequest[26] NGRequest[27] NGRequest[28] NGRequest[29]
  else cyrusScatterCanonical NGRequest[1] NGRequest[2] NGRequest[3] NGRequest[4] NGRequest[5] NGRequest[6] NGRequest[7] NGRequest[8] NGRequest[9] NGRequest[10] NGRequest[11] NGRequest[12] NGRequest[13] NGRequest[14] NGRequest[15] NGRequest[16] NGRequest[17] NGRequest[18] NGRequest[19] NGRequest[20] NGRequest[21] NGRequest[22] NGRequest[23] NGRequest[24] NGRequest[25] NGRequest[26] NGRequest[27] NGRequest[28] NGRequest[29]
 )
 fn NGBase amount = (
  #(#(NGTerrain),amount,42,2,[0.5,0.75,1.0],[1.5,1.25,2.0],[-10,-20,-180],[20,30,180],[0,0,0],[0,0,0],false,true,0,#(),8,#(1,2),false,10.0,42,0.0,0.0,0.0,#(),#(),#(false,#()),#(false,0.2,10,0.5),#(0.7,0.3),undefined,#(true,0.8,1.2,8.0,-90.0,90.0,0.0,1,0L,"11111111-1111-4111-8111-111111111111",1,1))
 )
 fn NGAllCoveredSame a b = (
  for stage=2 to a.count where a[stage][1] do for k=2 to a[stage].count where a[stage][k]!=b[stage][k] do return false
  true
 )
 fn NGWrite text=(local f=openFile (MCPFixtureDir+"generation.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"generation.txt");format "%\n" text to:f;close f)
 case command[1] of (
  "setup": (
   NGKind=command[2];NGCheck (findItem #("plane","mountain") NGKind>0) "Known terrain"
   CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
   NGTerrain=plane name:("Native generation "+NGKind) width:100 length:100 widthsegs:64 lengthsegs:64 mapCoords:true
   convertToMesh NGTerrain
   if NGKind=="mountain" do (
    for i=1 to NGTerrain.numverts do (local p=getVert NGTerrain i;p.z=18.0*exp(-((p.x/20.0)^2+(p.y/24.0)^2))+3.0*sin(p.x*5.0)*cos(p.y*4.0);setVert NGTerrain i p);update NGTerrain
   )
   NGOwner=cyrusPlacementOwner();NGRequest=NGBase 5000;NGHashes=#();NGPrevious=undefined
   undo "Native generation unrelated marker" on (box name:"Unrelated native-generation history" pos:[-75,0,0])
   NGOriginalHeap=heapSize;NGWrite ("SETUP "+NGKind)
  )
  "case": (
   local label=command[2],amount=command[3] as integer,variant=command[4] as integer
   NGRequest=NGBase amount
   case label of (
    "advanced": (NGRequest[29][1]=false)
    "slot128": (NGRequest[29][11]=128;NGRequest[29][9]=137L)
    "cluster": (NGRequest[17]=true;NGRequest[18]=15.0;NGRequest[20]=0.35;NGRequest[21]=0.2;NGRequest[22]=0.4)
    "uv": (NGRequest[13]=2;NGRequest[14]=for i=1 to 64 collect (if mod i 3==0 then 0.0 else 0.7))
    "empty": (NGRequest[13]=2;NGRequest[14]=for i=1 to 64 collect 0.0)
    "areas": (
     local area=rectangle name:"Owned native include" width:35 length:45
     NGRequest[23]=#(area);NGRequest[24]=#(1)
    )
    "project": (NGRequest[29][1]=false;NGRequest[9]=[-1,-1,0];NGRequest[10]=[1,1,0])
    "rectangular": (local snapshot=cyrusGridPrepare NGTerrain #(2,7.0,5.0,0.0,0.0,13.0,15.0) 42 NGRequest[29][10] false 1 1000000;NGRequest[2]=(cyrusGridPlan #(#(1,snapshot)))[3];append NGRequest[29] snapshot)
    "staggered": (local snapshot=cyrusGridPrepare NGTerrain #(3,7.0,5.0,0.0,0.0,13.0,15.0) 42 NGRequest[29][10] false 1 1000000;NGRequest[2]=(cyrusGridPlan #(#(1,snapshot)))[3];append NGRequest[29] snapshot)
    "hexagonal": (local snapshot=cyrusGridPrepare NGTerrain #(4,7.0,5.0,0.0,0.0,13.0,15.0) 42 NGRequest[29][10] false 1 1000000;NGRequest[2]=(cyrusGridPlan #(#(1,snapshot)))[3];append NGRequest[29] snapshot)
   )
   -- Preserve unrelated Undo even while explicitly exercising the legacy path.
   CyrusReserveScriptWorkspace (8388608L+(NGRequest[2] as integer64)*2048L)
   cyrusPlacementTransportStats true
   local before=cyrusPlacementTransportStats(),legacy=NGCall false,afterLegacy=cyrusPlacementTransportStats()
   NGCheck (afterLegacy[2][2]-before[2][2]==legacy[1].count and afterLegacy[2][3]-before[2][3]==legacy[1].count) "Legacy generator row/matrix allocations counted"
   local beforeNative=cyrusPlacementTransportStats(),native=NGCall true,afterNative=cyrusPlacementTransportStats()
   NGCheck (NGAllCoveredSame beforeNative afterNative) "Native generation creates no covered placement-sized script data"
   local legacyHash=cyrusRecipePublicationFingerprint #(legacy[1]),nativeHash=cyrusRecipePublicationFingerprint #(native[1])
   NGCheck (native[1].count==legacy[1].count and legacyHash==nativeHash) "Complete ordered generator fields match"
   local slot=NGRequest[29][11],orientation=#(variant,true,0.65,[1,2,0.1],[100,200,5]),axes=#(1,4)
   local legacyOriented=cyrusOrientSurfaceRows legacy[1] #(#(slot,0,legacy[2])) orientation axes
   beforeNative=cyrusPlacementTransportStats()
   local nativeOriented=cyrusOrientSurfaceRows native[1] #(#(slot,0,native[2])) orientation axes
   NGCheck (NGAllCoveredSame beforeNative (cyrusPlacementTransportStats())) "Native orientation creates no script rows/matrices"
   NGCheck ((cyrusRecipePublicationFingerprint #(legacyOriented))==(cyrusRecipePublicationFingerprint #(nativeOriented))) "Full orientation transforms/anchors/IDs match"
   local legacyEdited=cyrusEditStack #() legacyOriented 1 "owned-native-parity"
   local memoryBefore=cyrusPlacementMemoryStats();beforeNative=cyrusPlacementTransportStats()
   local nativeEdited=cyrusEditStack #() nativeOriented 1 "owned-native-parity",memoryAfter=cyrusPlacementMemoryStats()
   NGCheck (NGAllCoveredSame beforeNative (cyrusPlacementTransportStats()) and memoryBefore[1]==memoryAfter[1] and memoryBefore[4]==memoryAfter[4]) "No-modifier normalization shares native records without allocating payload or script identities"
   NGCheck ((cyrusRecipePublicationFingerprint #(legacyEdited))==(cyrusRecipePublicationFingerprint #(nativeEdited))) "Edited identity interpretation matches every legacy field"
   local specs=#(#(1,1.25,true,[-1,-2,0],[1,2,3]),#(2,0.0,true,[-1,-1,0],[1,1,2]))
   local radii=cyrusProceduralRadii legacyEdited specs #() #() #(),bindings=#("owned-layer",#("source-a","source-b"),#(#(slot,NGRequest[29][10],0,NGTerrain.numfaces))),stats=#(NGRequest[2],nativeEdited.count)
   local complete=cyrusPlacementPublicationFingerprint #(nativeEdited) #(radii) bindings stats
   NGCheck (complete==cyrusPlacementPublicationFingerprint #(legacyEdited) #(radii) bindings stats) "Full fingerprint includes rows, radii, correspondence and statistics"
   NGCheck (complete!=cyrusPlacementPublicationFingerprint #(nativeEdited) #(radii) bindings #(NGRequest[2],-1)) "Fingerprint notices changed statistics"
   NGCheck (findItem (theHold.GetUndoNames()) "Native generation unrelated marker">0) "Producer/preparation preserves unrelated Undo"
   NGPrevious=nativeEdited
   NGWrite ("PASS CASE "+NGKind+" "+label+" requested="+(NGRequest[2] as string)+" rows="+(nativeEdited.count as string)+" mode="+(variant as string)+" raw="+nativeHash+" complete="+complete)
   cyrusPlacementTransportStats false
  )
  "prepareHold": (
   NGRequest=NGBase 5000;NGA=(NGCall true)[1]
   NGRequest[2]=50000;NGB=(NGCall true)[1]
   NGRequest[2]=90000;NGC=(NGCall true)[1]
   NGRequest=undefined;NGPrevious=undefined;NGTerrain=undefined
   resetMaxFile #noPrompt
   undo "Owned prior scene edit" on (box name:"Prior marker")
   cyrusOwnedPlacementProbeSeed NGA;NGHoldBefore=cyrusOwnedPlacementProbeState()
   NGWrite ("HOLD SEED "+(NGHoldBefore as string))
  )
  "bench": (
   local amount=command[2] as integer,iteration=command[3] as integer,mode=command[4]
   NGCheck (findItem #("legacy","native","observed") mode>0) "Known benchmark mode"
   NGRequest=NGBase amount;NGPrevious=undefined
   CyrusReserveScriptWorkspace (8388608L+(amount as integer64)*2048L)
   gc light:true;cyrusPlacementTransportStats (mode=="observed")
   local heapBefore=heapSize,freeBefore=heapFree,bytesBefore=(cyrusPlacementMemoryStats())[1],start=clock.GetTimestamp()
   local result=NGCall (mode=="native")
   local finish=clock.GetTimestamp(),heapAfter=heapSize,freeAfter=heapFree,bytesAfter=(cyrusPlacementMemoryStats())[1]
   local hashStart=clock.GetTimestamp(),digest=cyrusRecipePublicationFingerprint #(result[1]),hashEnd=clock.GetTimestamp()
   local prior=for row in NGHashes where row[1]==amount collect row[2]
   if prior.count==0 then append NGHashes #(amount,digest) else NGCheck (prior[1]==digest) "Repeated benchmark output matches complete ordered fields"
   local f=openFile (MCPFixtureDir+"generation-benchmark.tsv") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"generation-benchmark.tsv")
   format "%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\t%\n" NGKind amount iteration mode start finish clock.Frequency heapBefore freeBefore heapAfter freeAfter bytesBefore bytesAfter digest hashStart hashEnd to:f;close f
   cyrusPlacementTransportStats false
   NGCheck (findItem (theHold.GetUndoNames()) "Native generation unrelated marker">0) "Benchmark preserves unrelated history"
  )
  "release": (
   NGRequest=undefined;NGPrevious=undefined;NGA=undefined;NGB=undefined;NGC=undefined;NGHashes=undefined
   gc light:true
   local memory=cyrusPlacementMemoryStats();NGCheck (memory[1]==0 and memory[5]==0 and memory[6]==0 and memory[7]==0) "All native generations, views and aliases released"
   NGWrite "PASS RELEASE"
  )
  default: throw "Unknown native generation command"
 )
)
