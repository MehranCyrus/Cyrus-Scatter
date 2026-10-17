-- Native source correspondence and immutable data-frame tests, private host only.
(
 if not (matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-binding-*/" or matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/") do throw "Owned native binding host required."
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NBModels,NBContext,NBOwner,NBRootOwner,NBCurrent,NBPrevious,NBPayload,NBInfo,NBKey,NBCount
 fn NBCheck yes text=(if not yes do throw ("Native binding: "+text))
 fn NBWrite text=(local f=openFile(MCPFixtureDir+"native-binding.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-binding.txt");format "%\n" text to:f;close f)
 fn NBSpec a b = #(#("source-a",a,true,false,false),#("source-b",b,false,true,false))
 fn NBBound receiverID = (
  cyrusScatterCanonicalBound NBContext receiverID NGRequest[1] NGRequest[2] NGRequest[3] NGRequest[4] NGRequest[5] NGRequest[6] NGRequest[7] NGRequest[8] NGRequest[9] NGRequest[10] NGRequest[11] NGRequest[12] NGRequest[13] NGRequest[14] NGRequest[15] NGRequest[16] NGRequest[17] NGRequest[18] NGRequest[19] NGRequest[20] NGRequest[21] NGRequest[22] NGRequest[23] NGRequest[24] NGRequest[25] NGRequest[26] NGRequest[27] NGRequest[28] NGRequest[29]
 )
 fn NBNextInfo label = (
  local info=deepCopy (cyrusPlacementPublicationInfo NBCurrent)
  info[1]=label;info[2]+=1;deleteItem info 9;info
 )
 case command[1] of (
  "setup": (
   cyrusPlacementTransportStats true
   NBCurrent=undefined;NBPrevious=undefined;NBPayload=undefined;NBInfo=undefined;NBContext=undefined;gc light:true
   NBOwner=NGOwner;NBRootOwner=cyrusPlacementOwner()
   NBModels=#(box name:"Bound source A" width:1 length:1 height:2,sphere name:"Bound source B" radius:0.5 segments:12)
   local input=NBSpec NBModels[1] NBModels[2]
   NBContext=cyrusPlacementContextCreate NBOwner "native-pop" input;NGOwner=NBContext
   local first=cyrusPlacementContextSources NBContext
   input[1][1]="caller changed this ID"
   NBCheck (CyrusPresetSameValues first (cyrusPlacementContextSources NBContext)) "Frozen source context does not alias caller arrays/strings"
   local same=cyrusPlacementContextCreate NBOwner "native-pop" (NBSpec NBModels[1] NBModels[2])
   NBCheck (cyrusPlacementContextEqual NBContext same) "Equivalent contexts can reuse a source mapping"
   local changed=cyrusPlacementContextCreate NBOwner "native-pop" (NBSpec NBModels[2] NBModels[1])
   NBCheck (not cyrusPlacementContextEqual NBContext changed) "Equal-count asset replacement/order changes are detected"
   NBWrite ("SETUP "+NGKind)
  )
  "case": (
   local amount=command[2] as integer
   CyrusReserveScriptWorkspace (8388608L+(amount as integer64)*3072L);gc light:true
   NGRequest=NGBase amount
   local old=NGCall false,native=NBBound "terrain"
   local provenance=cyrusPlacementReceivers native[1]
   NBCheck (provenance.count==1 and provenance[1][2]=="terrain" and provenance[1][5]==cyrusProceduralSurfaceKey #(NGTerrain) false and provenance[1][6]==getHandleByAnim NGTerrain) "Generator freezes the actual used mesh revision and persistent receiver binding"
   NBCheck (cyrusPlacementContextEqual NBContext (cyrusPlacementContextOf native[1])) "Generator retains source correspondence"
   local orientation=#(1,true,0.65,[1,2,0.1],[100,200,5]),axes=#(1,4)
   old=cyrusOrientSurfaceRows old[1] #(#(1,0,old[2])) orientation axes
   native=cyrusOrientSurfaceRows native[1] #(#(1,0,native[2])) orientation axes
   old=cyrusApplySourceTransforms old #(0.0,0.1) #(0.75,1.5);native=cyrusApplySourceTransforms native #(0.0,0.1) #(0.75,1.5)
   old=cyrusEditStack #() old 1 "binding";native=cyrusEditStack #() native 1 "binding"
   NBCheck (cyrusPlacementContextEqual NBContext (cyrusPlacementContextOf native)) "Preparation/normalization retain correspondence"
   local filter=#(true,0.0,180.0,0.0,0.0,false,0.0,100.0,0.0,0.0)
   local oldFilter=cyrusSurfaceFilter old #(NGTerrain) #(#(1,"terrain")) 42 filter,newFilter=cyrusSurfaceFilter native #(NGTerrain) #(#(1,"terrain")) 42 filter
   old=oldFilter[1];native=newFilter[1]
   native=cyrusPlacementSealPrepared native "owned-preparation" "owned-binding"
   local specs=#(#(1,0.05,true,[-0.1,-0.2,0],[0.1,0.2,0.3]),#(2,0.0,true,[-0.1,-0.1,0],[0.1,0.1,0.2]))
   local oldRadius=cyrusProceduralRadii old specs #() #() #(),newRadius=cyrusProceduralRadii native specs #() #() #()
   local plan=cyrusReceiverPlan #(#(1,"terrain",10000.0,0)) amount -1.0 1 1000000
   local oldSet=#("native-pop",old,oldRadius,#(true,1.0,0.025,true),amount,amount,plan[2]),newSet=#("native-pop",native,newRadius,#(true,1.0,0.025,true),amount,amount,plan[2])
   local oldResult=cyrusEvaluateProcedural #(#("logical-layer",false,false,1,#(false,1.0,0.0,true),#(false,0.3,1,2,true),#(oldSet))) #() 1000000
   local newResult=cyrusEvaluateProcedural #(#("logical-layer",false,false,1,#(false,1.0,0.0,true),#(false,0.3,1,2,true),#(newSet))) #() 1000000
   local rows=newResult[1][1][1],radius=newResult[4][1][1]
   NBCheck (cyrusPlacementContextEqual NBContext (cyrusPlacementContextOf rows)) "Accepted selections retain source correspondence"
   NBCheck (CyrusPresetSameValues provenance (cyrusPlacementReceivers rows)) "Preparation and acceptance preserve evaluated receiver provenance"
   NBPayload=#(#(rows,radius,NBContext,provenance,"owned-binding",newResult[2][1][1],newResult[3][1],newFilter[2],"owned-preparation"))
   local epoch=if NBCurrent==undefined then 1L else NBCurrent.epoch+1L
   NBKey="owned-input-"+NGKind+"-"+(amount as string)
   NBInfo=#("owned-pub-"+NGKind+"-"+(epoch as string),epoch,0,1.0,rows.count,#(#("native-pop","logical-layer",1,1,rows.count,amount,amount,amount,0L,(cyrusPlacementContextSources NBContext))),#(),CyrusLoadedScriptFingerprint)
   -- Exercise the actual IntegerPtr type returned by Max, rather than only
   -- the Integer64 representation returned by native metadata readback.
   for s=1 to NBModels.count do NBInfo[6][1][10][s][2]=getHandleByAnim NBModels[s]
   local before=cyrusPlacementMemoryStats(),counters=cyrusPlacementTransportStats()
   NBPrevious=NBCurrent
   NBCurrent=cyrusPlacementPublicationCreate NBRootOwner NBPrevious NBInfo NBKey NBPayload
   NBCheck (before[1]==(cyrusPlacementMemoryStats())[1] and before[4]==(cyrusPlacementMemoryStats())[4]) "Publication does not copy placement vector payload"
   NBCheck (NGAllCoveredSame counters (cyrusPlacementTransportStats())) "Publication creates no script placement population"
   local published=cyrusPlacementPublicationRows NBCurrent 1,frozenRadius=cyrusPlacementPublicationRadii NBCurrent 1
   NBCheck (CyrusPresetSameValues (cyrusPlacementToken published) (cyrusPlacementToken rows)) "Publication shares the exact immutable placement view"
   local actual=cyrusPlacementPublicationInfo NBCurrent,expected=deepCopy NBInfo;append expected NBKey
   NBCheck (CyrusPresetSameValues actual expected) "Existing manifest contract and input signature round-trip exactly"
   local stats=cyrusPlacementPublicationStatistics NBCurrent 1
   NBCheck (CyrusPresetSameValues stats[1] newResult[2][1][1] and CyrusPresetSameValues stats[2] newResult[3][1] and CyrusPresetSameValues stats[3] newFilter[2]) "Frozen statistics/rounds/surface data are coherent"
   local expectedCounts=#(0,0);for row in oldResult[1][1][1] do expectedCounts[row[2]]+=1
   NBCheck (CyrusPresetSameValues stats[4] expectedCounts) "Source histogram is frozen for bounded passive reads"
   NBCheck ((cyrusPlacementPublicationFingerprint #(published) #(frozenRadius) (cyrusPlacementContextSources NBContext) stats)==(cyrusPlacementPublicationFingerprint #(oldResult[1][1][1]) #(oldResult[4][1][1]) (cyrusPlacementContextSources NBContext) stats)) "Full accepted ordered fields/radii/metadata parity"
   local limit=amin 500 rows.count,page=cyrusPlacementPublicationPage NBCurrent NBInfo[1] 0 (amax 1 limit)
   NBCheck (page[2]==rows.count and page[3]==limit and page[4].count==limit) "Bounded cached page has correct continuation"
   for i=1 to limit do (
    local original=oldResult[1][1][1][i],item=page[4][i]
    NBCheck (item[1]==1 and item[2]==original[1] and item[3]==original[2] and item[4]==original[3] and item[5]==original[7] and CyrusPresetSameValues item[6] oldResult[4][1][1][i] and item[7]==(original[2]==1)) "Every bounded page field is exact"
   )
   NBCount=rows.count
   NBWrite ("PASS "+NGKind+" count="+(amount as string)+" accepted="+(NBCount as string)+" epoch="+(epoch as string))
  )
  "failure": (
   local before=NBCurrent,info=NBNextInfo "rejected-source",payload=deepCopy NBPayload,rejected=false
   payload[1][3]=cyrusPlacementContextCreate NBOwner "native-pop" (NBSpec NBModels[2] NBModels[1])
   try(cyrusPlacementPublicationCreate NBRootOwner NBCurrent info NBKey payload)catch(rejected=true)
   NBCheck rejected "Stale same-cardinality model correspondence rejects"
   info=NBNextInfo "rejected-manifest";info[6][1][10][1][2]+=1;rejected=false
   try(cyrusPlacementPublicationCreate NBRootOwner NBCurrent info NBKey NBPayload)catch(rejected=true)
   NBCheck rejected "Manifest asset binding mismatch rejects"
   payload=deepCopy NBPayload;payload[1][6][2]+=1;info=NBNextInfo "rejected-stats";rejected=false
   try(cyrusPlacementPublicationCreate NBRootOwner NBCurrent info NBKey payload)catch(rejected=true)
   NBCheck rejected "Mismatched statistics reject"
   payload=deepCopy NBPayload;payload[1][9]="stale-preparation";rejected=false
   try(cyrusPlacementPublicationCreate NBRootOwner NBCurrent info NBKey payload)catch(rejected=true)
   NBCheck rejected "Stale preparation receipt rejects without relabeling cached rows"
   payload=deepCopy NBPayload;payload[1][4][1][3]=1000000;rejected=false
   try(cyrusPlacementPublicationCreate NBRootOwner NBCurrent info NBKey payload)catch(rejected=true)
   NBCheck rejected "Foreign receiver face range rejects"
   payload=deepCopy NBPayload;payload[1][4][1][6]+=1;rejected=false
   try(cyrusPlacementPublicationCreate NBRootOwner NBCurrent info NBKey payload)catch(rejected=true)
   NBCheck rejected "Equal-face-count receiver replacement rejects"
   local originalVertex=getVert NGTerrain 1
   setVert NGTerrain 1 (originalVertex+[0,0,0.25]);update NGTerrain
   payload=deepCopy NBPayload;payload[1][4][1][5]=cyrusProceduralSurfaceKey #(NGTerrain) false;rejected=false
   try(cyrusPlacementPublicationCreate NBRootOwner NBCurrent info NBKey payload)catch(rejected=true)
   setVert NGTerrain 1 originalVertex;update NGTerrain
   NBCheck rejected "Same-frame equal-topology terrain edit rejects stale cached placements"
   info=deepCopy NBInfo;rejected=false
   try(cyrusPlacementPublicationCreate NBRootOwner NBCurrent info NBKey NBPayload)catch(rejected=true)
   NBCheck rejected "Stale successor epoch rejects"
   rejected=false;try(cyrusPlacementPublicationPage NBCurrent "wrong-id" 0 1)catch(rejected=true);NBCheck rejected "Stale page ID rejects"
   rejected=false;try(cyrusPlacementPublicationPage NBCurrent NBInfo[1] 0 501)catch(rejected=true);NBCheck rejected "Unbounded readback rejects"
   NBCheck (before==NBCurrent and NBCurrent.count==NBCount) "Failed successors retain exact complete previous frame"
   local mutable=cyrusPlacementPublicationInfo NBCurrent;mutable[6][1][10][1][1]="caller mutated source ID"
   NBCheck ((cyrusPlacementPublicationInfo NBCurrent)[6][1][10][1][1]=="source-a") "Manifest returns detached metadata"
   NBWrite ("PASS "+NGKind+" rejection/metadata isolation")
  )
  "receivers": (
   NGRequest=NGBase 200
   local a=(NBBound "terrain")[1],other=copy NGTerrain
   other.pos=[150,0,0];NGRequest[1]=#(other);NGRequest[29][11]=2
   local b=(NBBound "terrain-b")[1],offset=cyrusReceiverOffsetRows b NGTerrain.numfaces
   local combined=cyrusPlacementJoin #(a,offset),provenance=cyrusPlacementReceivers combined
   NBCheck (provenance.count==2 and provenance[1][3]==0 and provenance[2][3]==NGTerrain.numfaces and provenance[2][2]=="terrain-b") "Joined receiver metadata follows global face offsets"
   local compact=cyrusPlacementCompact combined (cyrusPlacementToken combined)
   local empty=cyrusPlacementSelect compact (cyrusPlacementToken compact) #()
   NBCheck (CyrusPresetSameValues provenance (cyrusPlacementReceivers compact) and CyrusPresetSameValues provenance (cyrusPlacementReceivers empty)) "Compaction and empty selections preserve provenance"
   local rejected=false
   try(cyrusPlacementJoin #(a,b))catch(rejected=true)
   NBCheck rejected "Unshifted overlapping receiver ranges reject"
   NGRequest[1]=#(NGTerrain);NGRequest[29][11]=1
   local originalVertex=getVert NGTerrain 1
   setVert NGTerrain 1 (originalVertex+[0,0,0.25]);update NGTerrain
   local changed=(NBBound "terrain")[1]
   setVert NGTerrain 1 originalVertex;update NGTerrain;rejected=false
   try(cyrusPlacementJoin #(a,changed))catch(rejected=true)
   NBCheck rejected "Join cannot mix two same-slot geometry revisions"
   NGRequest=NGBase 0
   local zero=(NBBound "terrain")[1]
   NBCheck (zero.count==0 and (cyrusPlacementReceivers zero).count==1) "Zero-candidate generations retain the evaluated terrain signature"
   delete other
   NBWrite ("PASS "+NGKind+" receiver revision/join/offset/empty")
  )
  "pins": (
   NBPrevious=undefined;NBPayload=undefined;NGRequest=undefined;gc light:true
   local radiusBefore=cyrusScriptBufferStats(),radius=cyrusPlacementPublicationRadii NBCurrent 1,radiusAfter=cyrusScriptBufferStats()
   NBCheck (radiusBefore[3]==radiusAfter[3] and radiusBefore[4]==radiusAfter[4]) "Extra radius wrapper shares unique native storage"
   local rows=cyrusPlacementPublicationRows NBCurrent 1
   NBCheck (rows.count==NBCount and radius.count==NBCount) "Root retains placements/radii after original transport values are collected"
   NBCheck ((cyrusPlacementPublicationPage NBCurrent NBInfo[1] 0 1)[4].count==(amin NBCount 1)) "Retained root remains readable after GC"
   NBWrite ("PASS "+NGKind+" shared ownership after GC")
  )
  "release": (
   NBCurrent=undefined;NBPrevious=undefined;NBPayload=undefined;NBInfo=undefined;NBContext=undefined;NBModels=undefined
   NGOwner=undefined;NGRequest=undefined;NGPrevious=undefined;NGHashes=undefined
   resetMaxFile #noPrompt;gc light:true
   local placement=cyrusPlacementMemoryStats(),buffers=cyrusScriptBufferStats()
   NBCheck (placement[1]==0 and placement[6]==0 and placement[7]==0 and buffers[3]==0 and buffers[4]==0) "Last publication/history/value pin releases placement/radius storage"
   NBWrite "PASS RELEASE"
  )
  default: throw "Unknown binding phase"
 )
)
