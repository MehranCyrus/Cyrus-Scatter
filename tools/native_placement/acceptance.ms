-- Stage comparisons only: never switches the shipping controller's row route.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-*/" do throw "Owned native acceptance host required."
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global ACLast,ACHash
 fn ACCheck yes text=(if not yes do throw ("Native acceptance: "+text))
 fn ACWrite text=(local f=openFile(MCPFixtureDir+"acceptance.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"acceptance.txt");format "%\n" text to:f;close f)
 fn ACPair amount slot seed = (
  NGRequest=NGBase amount;NGRequest[3]=seed;NGRequest[29][11]=slot
  local old=NGCall false,new=NGCall true
  #(old[1],new[1])
 )
 fn ACRawEqual pair label=(ACCheck ((cyrusRecipePublicationFingerprint #(pair[1]))==(cyrusRecipePublicationFingerprint #(pair[2]))) label)
 fn ACPrepare pair = (
  local old=cyrusApplySourceTransforms pair[1] #(0.0,0.1) #(0.75,1.5),before=cyrusPlacementTransportStats()
  local new=cyrusApplySourceTransforms pair[2] #(0.0,0.1) #(0.75,1.5)
  ACCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Source transforms have no script population materialization"
  ACRawEqual #(old,new) "Exact source scale/offset rounding"
  old=cyrusFilterSourceRows old #(true,true);new=cyrusFilterSourceRows new #(true,true)
  #(cyrusEditStack #() old 1 "acceptance",cyrusEditStack #() new 1 "acceptance")
 )
 fn ACSpecs=#(#(1,0.05,true,[-0.1,-0.2,0],[0.1,0.2,0.3]),#(2,0.0,true,[-0.1,-0.1,0],[0.1,0.1,0.2]))
 fn ACFlatten resolved = (
  local groups=#(),radii=#()
  for l=1 to resolved[1].count do for s=1 to resolved[1][l].count do (append groups resolved[1][l][s];append radii resolved[4][l][s])
  #(groups,radii)
 )
 fn ACResolvedEqual old new label = (
  local a=ACFlatten old,b=ACFlatten new
  ACCheck ((cyrusPlacementPublicationFingerprint a[1] a[2] #("owned-acceptance") #(old[2],old[3]))==(cyrusPlacementPublicationFingerprint b[1] b[2] #("owned-acceptance") #(new[2],new[3]))) label
  ACLast=new;ACHash=cyrusPlacementPublicationFingerprint b[1] b[2] #("owned-acceptance") #(new[2],new[3])
 )
 fn ACSet id rows budget attempts schedule radiusIDs:#() radiusModes:#() radiusValues:#() selfRule:#(true,1.0,0.025,true) = (
  #(id,rows,cyrusProceduralRadii rows (ACSpecs()) radiusIDs radiusModes radiusValues,selfRule,budget,attempts,schedule)
 )
 fn ACLayer id sets target:false cleanup:false = (
  #(id,target,target,4,#(true,1.0,0.05,true),#(cleanup,0.3,1,2,true),sets)
 )
 case command[1] of (
  "case": (
   local label=command[2],amount=command[3] as integer
   CyrusReserveScriptWorkspace (8388608L+(amount as integer64)*3072L)
   cyrusPlacementTransportStats true
   local pair=ACPair amount 1 42,plan=cyrusReceiverPlan #(#(1,"accept-a",10000.0,0)) amount -1.0 1 1000000
   if label=="receivers" do (
    local second=ACPair amount 128 17
    pair[1]=cyrusReceiverOffsetRows pair[1] 0;pair[2]=cyrusReceiverOffsetRows pair[2] 0
    second[1]=cyrusReceiverOffsetRows second[1] NGTerrain.numfaces;second[2]=cyrusReceiverOffsetRows second[2] NGTerrain.numfaces
    ACRawEqual second "Nonzero receiver offsets preserve all fields"
    join pair[1] second[1];pair[2]=cyrusPlacementJoin #(pair[2],second[2]);ACRawEqual pair "Native receiver join preserves exact order"
    plan=cyrusReceiverPlan #(#(1,"accept-a",10000.0,0),#(128,"accept-b",10000.0,0)) (2*amount) -1.0 1 1000000
   )
   if label=="grid" do (
    NGRequest=NGBase 0
    local snapshot=cyrusGridPrepare NGTerrain #(4,3.0,2.5,0.0,0.0,13.0,15.0) 42 NGRequest[29][10] false 1 1000000
    plan=cyrusGridPlan #(#(1,snapshot));NGRequest[2]=plan[3];append NGRequest[29] snapshot
    local old=NGCall false,new=NGCall true;pair=#(old[1],new[1])
   )
   pair=ACPrepare pair
   if label=="sourceFilter" do (pair[1]=cyrusFilterSourceRows pair[1] #(false,true);pair[2]=cyrusFilterSourceRows pair[2] #(false,true))
   if label=="empty" do (pair[1]=cyrusFilterSourceRows pair[1] #(false,false);pair[2]=cyrusFilterSourceRows pair[2] #(false,false))
   if label=="surface" or label=="receivers" do (
    local targets=if label=="receivers" then #(NGTerrain,NGTerrain) else #(NGTerrain)
    local keys=if label=="receivers" then #(#(1,"accept-a"),#(128,"accept-b")) else #(#(1,"accept-a"))
    local settings=#(true,0.0,45.0,0.0,10.0,true,0.0,20.0,0.0,2.0)
    local old=cyrusSurfaceFilter pair[1] targets keys 42 settings,before=cyrusPlacementTransportStats(),new=cyrusSurfaceFilter pair[2] targets keys 42 settings
    ACCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Native eligibility has no script materialization"
    ACCheck (CyrusPresetSameValues old[2] new[2]) "Surface statistics parity"
    pair=#(old[1],new[1])
   )
   ACRawEqual pair "Full prepared/filtered row parity"
   local ids=#(),modes=#(),values=#()
   if label=="overrides" do (
    ids=#(pair[1][1][3],pair[1][2][3],"c:0000000001");modes=#(1,2,1);values=#(0.25,0.5,30.0)
   )
   local oldSet=ACSet "set-a" pair[1] plan[3] plan[4] plan[2] radiusIDs:ids radiusModes:modes radiusValues:values
   local before=cyrusPlacementTransportStats(),newSet=ACSet "set-a" pair[2] plan[3] plan[4] plan[2] radiusIDs:ids radiusModes:modes radiusValues:values
   ACCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Native radii create no script population"
   ACCheck ((cyrusPlacementPublicationFingerprint #(pair[1]) #(oldSet[3]) #() #())==(cyrusPlacementPublicationFingerprint #(pair[2]) #(newSet[3]) #() #())) "Every effective radius matches"
   local target=(label=="target"),clean=(label=="cleanup")
   if target do (oldSet[5]=amax 1 (amount/8);newSet[5]=oldSet[5])
   local old=cyrusEvaluateProcedural #(ACLayer "layer-a" #(oldSet) target:target cleanup:clean) #() 1000000
   before=cyrusPlacementTransportStats()
   local new=cyrusEvaluateProcedural #(ACLayer "layer-a" #(newSet) target:target cleanup:clean) #() 1000000
   ACCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Native acceptance creates no script population"
   ACResolvedEqual old new "Full accepted order, radii, reasons and round statistics"
   ACWrite ("PASS "+NGKind+" "+label+" requested="+(amount as string)+" accepted="+(new[1][1][1].count as string)+" hash="+ACHash)
  )
  "scopes": (
   local plans=#(),oldSets=#(),newSets=#(),pairs=#(#(1,"set-a","set-b",#(true,1.0,0.2,true)),#(2,"layer-a","layer-b",#(true,1.0,0.3,false)))
   CyrusReserveScriptWorkspace (8388608L+15000L*8192L);cyrusPlacementTransportStats true
   for s=1 to 3 do (
    local pair=ACPrepare (ACPair 5000 1 (42+s)),plan=cyrusReceiverPlan #(#(1,"accept-a",10000.0,0)) 5000 -1.0 1 1000000
    if s==2 do (
     local pin=deepCopy pair[1][1];pin[3]="copy:protected-zero-quota";pin[7]=true
     append pair[1] pin;pair[2]=cyrusPlacementJoin #(pair[2],cyrusPlacementCapture NGOwner 2 2 0 #(pin))
    )
    local id=#("set-a","set-b","set-c")[s],budget=if s==2 then 0 else 5000
    local ids=if s==2 then #("copy:protected-zero-quota") else #(),modes=if s==2 then #(1) else #(),values=if s==2 then #(0.75) else #()
    append oldSets (ACSet id pair[1] budget 5000 plan[2] radiusIDs:ids radiusModes:modes radiusValues:values)
    append newSets (ACSet id pair[2] budget 5000 plan[2] radiusIDs:ids radiusModes:modes radiusValues:values)
   )
   local old=cyrusEvaluateProcedural #(ACLayer "layer-a" #(oldSets[1],oldSets[2]),ACLayer "layer-b" #(oldSets[3])) pairs 1000000,before=cyrusPlacementTransportStats()
   local new=cyrusEvaluateProcedural #(ACLayer "layer-a" #(newSets[1],newSets[2]),ACLayer "layer-b" #(newSets[3])) pairs 1000000
   ACCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Three scopes stay native"
   ACResolvedEqual old new "Protected zero-quota, sibling and layer rules retain complete parity"
   ACCheck (new[1][1][2].count==1) "Protected authored copy survives zero quota"
   ACWrite ("PASS "+NGKind+" scopes hash="+ACHash)
  )
  "failure": (
   local saved=ACFlatten ACLast,digest=cyrusPlacementPublicationFingerprint saved[1] saved[2] #("owned-acceptance") #(ACLast[2],ACLast[3])
   local pair=ACPrepare(ACPair 10 1 42),plan=cyrusReceiverPlan #(#(1,"accept-a",10000.0,0)) 10 -1.0 1 1000000
   local good=ACSet "failure" pair[2] 10 10 plan[2],rejected=false
   try(cyrusEvaluateProcedural #(ACLayer "failure-layer" #(good)) #() 1)catch(rejected=true)
   ACCheck rejected "Root admission rejects before replacing previous native result"
   good[3]=#();rejected=false;try(cyrusEvaluateProcedural #(ACLayer "failure-layer" #(good)) #() 1000000)catch(rejected=true)
   ACCheck rejected "Radius length mismatch is rejected"
   local pin=deepCopy pair[1][1];pin[3]="c:000000001";pin[7]=true
   local bad=cyrusPlacementCapture NGOwner 2 2 0 #(pin);good=ACSet "bad" bad 0 10 plan[2];rejected=false
   try(cyrusEvaluateProcedural #(ACLayer "bad-layer" #(good)) #() 1000000)catch(rejected=true)
   ACCheck rejected "Protected candidate-like malformed identity still fails schedule validation"
   pin=deepCopy pair[1][1];bad=cyrusPlacementCapture NGOwner 2 2 127 #(pin);good=ACSet "bad-receiver" bad 10 10 plan[2];rejected=false
   try(cyrusEvaluateProcedural #(ACLayer "bad-layer" #(good)) #() 1000000)catch(rejected=true)
   ACCheck rejected "Explicit native receiver must match the candidate key"
   local foreign=cyrusPlacementCapture (cyrusPlacementOwner()) 2 2 0 #(pair[1][1]);rejected=false
   try(cyrusPlacementJoin #(pair[2],foreign))catch(rejected=true)
   ACCheck rejected "Receiver join rejects a different owner"
   rejected=false;try(cyrusReceiverOffsetRows (NGCall true)[1] 2147483647)catch(rejected=true)
   ACCheck rejected "Face-offset arithmetic rejects overflow"
   rejected=false;try(cyrusProceduralRadii pair[2] #(#(2,0.0,true,[1,0,0],[-1,0,0])) #() #() #())catch(rejected=true)
   ACCheck rejected "Invalid Auto bounds reject without publication"
   ACCheck (digest==ACHash and digest==cyrusPlacementPublicationFingerprint saved[1] saved[2] #("owned-acceptance") #(ACLast[2],ACLast[3])) "All rejected successors retain complete prior rows/radii/stats"
   ACWrite ("PASS "+NGKind+" failure retention")
  )
  "protectedSurface": (
   local native=ACLast[1][1][2],old=cyrusPlacementPage native (cyrusPlacementToken native) 0 1
   ACCheck (native.count==1 and old[1][7]) "Previous accepted protected copy available"
   local settings=#(true,90.0,180.0,0.0,0.0,true,1000.0,2000.0,0.0,0.0)
   local a=cyrusSurfaceFilter old #(NGTerrain) #(#(1,"accept-a")) 42 settings,before=cyrusPlacementTransportStats()
   local b=cyrusSurfaceFilter native #(NGTerrain) #(#(1,"accept-a")) 42 settings
   ACCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Protected eligibility stays native"
   ACCheck (CyrusPresetSameValues a[2] b[2] and b[2][3]==1 and b[1].count==1) "Protected edit survives otherwise ineligible surface"
   ACRawEqual #(a[1],b[1]) "Protected transform/anchor/identity unchanged"
   ACWrite ("PASS "+NGKind+" protected surface")
  )
  "release": (
   ACLast=undefined;ACHash=undefined;NGPrevious=undefined;NGRequest=undefined;NGHashes=undefined
   gc light:true
   local memory=cyrusPlacementMemoryStats();ACCheck (memory[1]==0 and memory[5]==0 and memory[6]==0 and memory[7]==0) "All generations and accepted views release"
   cyrusPlacementTransportStats false;ACWrite "PASS RELEASE"
  )
  default: throw "Unknown acceptance command"
 )
 ACCheck (findItem (theHold.GetUndoNames()) "Native generation unrelated marker">0) "Unrelated Undo retained"
)
