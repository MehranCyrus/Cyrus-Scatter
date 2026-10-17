-- Optional preparation parity. Only an owned, source-matched Max 2027 host.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native preparation host required."
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NPContext,NPModels,NPMap,NPCheck,NPWrite
 fn NPCheck yes message=(if not yes do throw ("Native preparation: "+message))
 fn NPWrite message=(local f=openFile(MCPFixtureDir+"native-preparation.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-preparation.txt");format "%\n" message to:f;close f)
 fn NPMap node channel mode = (
  meshop.setNumMaps node (amax (channel+1) (meshop.getNumMaps node)) keep:true
  meshop.setMapSupport node channel true
  meshop.setNumMapVerts node channel node.numverts
  meshop.setNumMapFaces node channel node.numfaces
  for i=1 to node.numverts do (
   local p=getVert node i,x=(p.x+50.0)/100.0,y=(p.y+50.0)/100.0
   local value=case mode of (0:[0,0,0];1:[1,1,1];2:[x,y,1-x];3:[1-x,1-y,x];default:[-2+4*x,-1+3*y,2-4*x])
   meshop.setMapVert node channel i value
  )
  for i=1 to node.numfaces do meshop.setMapFace node channel i (getFace node i)
  update node
 )
 fn bound = (
  cyrusScatterCanonicalBound NPContext "preparation-terrain" NGRequest[1] NGRequest[2] NGRequest[3] NGRequest[4] NGRequest[5] NGRequest[6] NGRequest[7] NGRequest[8] NGRequest[9] NGRequest[10] NGRequest[11] NGRequest[12] NGRequest[13] NGRequest[14] NGRequest[15] NGRequest[16] NGRequest[17] NGRequest[18] NGRequest[19] NGRequest[20] NGRequest[21] NGRequest[22] NGRequest[23] NGRequest[24] NGRequest[25] NGRequest[26] NGRequest[27] NGRequest[28] NGRequest[29]
 )
 fn parity legacy native provenance label = (
  NPCheck (cyrusPlacementIsNative native) (label+": native output")
  NPCheck ((cyrusRecipePublicationFingerprint #(legacy))==(cyrusRecipePublicationFingerprint #(native))) (label+": every ordered raw field matches")
  NPCheck (cyrusPlacementContextEqual NPContext (cyrusPlacementContextOf native)) (label+": source correspondence retained")
  NPCheck (CyrusPresetSameValues provenance (cyrusPlacementReceivers native)) (label+": receiver provenance retained")
 )
 case command[1] of (
  "setup": (
   NPModels=#(box name:"Preparation source A",sphere name:"Preparation source B")
   NPContext=cyrusPlacementContextCreate NGOwner "preparation-pop" #(#("source-a",NPModels[1],true,false,false),#("source-b",NPModels[2],true,false,false))
   for channel in #(0,2) do NPMap NGTerrain channel 2
   cyrusPlacementTransportStats true
  )
  "case": (
   local amount=command[2] as integer
   CyrusReserveScriptWorkspace (8388608L+(amount as integer64)*4096L);gc light:true
   NGRequest=NGBase amount;NGRequest[29][11]=128
   local old=(NGCall false)[1],native=(bound())[1],provenance=cyrusPlacementReceivers native
   local original=cyrusRecipePublicationFingerprint #(native)
   for limits in #(#(0.25,2.5),#(1.0,1.0),#(0.0001,0.0001)) do (
    local expected=cyrusWholeScale old limits[1] limits[2] 87,before=cyrusPlacementTransportStats()
    local actual=cyrusWholeScale native limits[1] limits[2] 87
    NPCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Whole Scale creates no script population"
    parity expected actual provenance "Whole Scale"
   )
   local paths=#(#([-30,0,0],[0,0,3],[30,20,4]),#([-10,-10,0],[10,-10,0],[10,10,0],[-10,10,0],[-10,-10,0]))
   for caps in #(1,2) do for width in #(0.0,2.5,200.0) do (
    local expected=cyrusAnalyzerArea old paths #([-25,25,0],[25,-25,9]) width 4.0 caps,before=cyrusPlacementTransportStats()
    local actual=cyrusAnalyzerArea native paths #([-25,25,0],[25,-25,9]) width 4.0 caps
    NPCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Analyzer Area creates no script population"
    parity expected actual provenance "Analyzer Area"
   )
   local empty=cyrusAnalyzerArea native #() #() 1.0 1.0 1
   parity #() empty provenance "Empty Analyzer Area"
   for channel in #(0,2) do for component=1 to 3 do for inverse in #(false,true) do (
    local settings=#(true,channel,component,0.15,0.85,inverse,#(0.0,0.2,0.8,1.0))
    local expected=cyrusMeshDensityFilter old NGTerrain settings 42 NGRequest[29][10],before=cyrusPlacementTransportStats()
    local actual=cyrusMeshDensityFilter native NGTerrain settings 42 NGRequest[29][10]
    NPCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Mesh density creates no script population"
    parity expected actual provenance "Mesh density"
   )
   local expected=cyrusWholeScale old 0.5 1.7 42,before=cyrusPlacementTransportStats()
   local actual=cyrusWholeScale native 0.5 1.7 42
   NPCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Combined Whole Scale stays native"
   expected=cyrusMeshDensityFilter expected NGTerrain #(true,2,1,0.0,1.0,false,#(0.0,1.0)) 42 NGRequest[29][10]
   before=cyrusPlacementTransportStats();actual=cyrusMeshDensityFilter actual NGTerrain #(true,2,1,0.0,1.0,false,#(0.0,1.0)) 42 NGRequest[29][10]
   NPCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Combined mask stays native"
   expected=cyrusAnalyzerArea expected paths #() 12.0 0.0 2
   before=cyrusPlacementTransportStats();actual=cyrusAnalyzerArea actual paths #() 12.0 0.0 2
   NPCheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Combined Area stays native"
   parity expected actual provenance "Combined preparation"
   NPCheck (original==cyrusRecipePublicationFingerprint #(native)) "All input records remain immutable"
   NPCheck (findItem (theHold.GetUndoNames()) "Native generation unrelated marker">0) "Unrelated Undo preserved"
   NPWrite ("PASS "+NGKind+" count="+(amount as string)+" combined="+(actual.count as string)+" hash="+(cyrusRecipePublicationFingerprint #(actual)))
  )
  "fields": (
   NGRequest=NGBase 5000
   local old=(NGCall false)[1],native=(bound())[1],provenance=cyrusPlacementReceivers native,settings=#(true,2,1,0.0,1.0,false,#(0.0,1.0))
   local geometry=cyrusProceduralSurfaceKey #(NGTerrain) false,key=cyrusMeshDensityKey NGTerrain settings
   local first=cyrusMeshDensityFilter native NGTerrain settings 42 NGRequest[29][10]
   NPMap NGTerrain 2 3
   NPCheck (geometry==cyrusProceduralSurfaceKey #(NGTerrain) false and key!=cyrusMeshDensityKey NGTerrain settings) "Same-frame channel revision independent of geometric revision"
   local second=cyrusMeshDensityFilter native NGTerrain settings 42 NGRequest[29][10]
   parity (cyrusMeshDensityFilter old NGTerrain settings 42 NGRequest[29][10]) second provenance "Changed channel"
   NPCheck ((cyrusRecipePublicationFingerprint #(first))!=(cyrusRecipePublicationFingerprint #(second))) "Changed channel actually changes accepted identities"
   for value in #(0,1,4) do (
    NPMap NGTerrain 2 value
    local a=cyrusMeshDensityFilter old NGTerrain settings 42 NGRequest[29][10],b=cyrusMeshDensityFilter native NGTerrain settings 42 NGRequest[29][10]
    parity a b provenance "Constant/out-of-range channel"
    if value==0 do NPCheck (b.count==0) "Zero field excludes all"
    if value==1 do NPCheck (b.count==native.count) "One field retains all"
   )
   local digest=cyrusRecipePublicationFingerprint #(native),failed=false
   meshop.setMapSupport NGTerrain 2 false;update NGTerrain
   try(cyrusMeshDensityFilter native NGTerrain settings 42 NGRequest[29][10])catch(failed=true)
   NPCheck failed "Missing channel fails explicitly"
   settings[1]=false;parity old (cyrusMeshDensityFilter native NGTerrain settings 42 NGRequest[29][10]) provenance "Disabled missing channel"
   failed=false;try(cyrusWholeScale native 2.0 1.0 42)catch(failed=true);NPCheck failed "Invalid scale fails"
   failed=false;try(cyrusAnalyzerArea native #() #() -1.0 0.0 1)catch(failed=true);NPCheck failed "Invalid Area fails"
   NPCheck (digest==cyrusRecipePublicationFingerprint #(native)) "Failed stages preserve original native input"
   NPMap NGTerrain 2 2
   NPWrite ("PASS "+NGKind+" numeric-field freshness/missing/disabled/empty/full/failure")
  )
  "release": (
   NPContext=undefined;NPModels=undefined;NGRequest=undefined;NGPrevious=undefined
   gc light:true
   local memory=cyrusPlacementMemoryStats()
   NPCheck (memory[1]==0 and memory[5]==0 and memory[6]==0 and memory[7]==0) "All optional native stores/selections released"
   NPWrite "PASS RELEASE"
  )
  default:throw "Unknown preparation command"
 )
)
