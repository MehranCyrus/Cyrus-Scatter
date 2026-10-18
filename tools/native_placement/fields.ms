-- Boundary and Paint native adapters; complete raw parity in an owned host.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned native field host required."
 local command=filterString ((dotNetClass "System.IO.File").ReadAllText(MCPFixtureDir+"generation-command.txt")) " "
 global NFContext,NFModels,NFDocs,NFArea,NFTerrain2,NFExpected,NFNative
 fn NFcheck yes message=(if not yes do throw ("Native fields: "+message))
 fn NFwrite message=(local f=openFile(MCPFixtureDir+"native-fields.txt") mode:"a";if f==undefined do f=createFile(MCPFixtureDir+"native-fields.txt");format "%\n" message to:f;close f)
 fn NFbound = (cyrusScatterCanonicalBound NFContext NGRequest[29][10] NGRequest[1] NGRequest[2] NGRequest[3] NGRequest[4] NGRequest[5] NGRequest[6] NGRequest[7] NGRequest[8] NGRequest[9] NGRequest[10] NGRequest[11] NGRequest[12] NGRequest[13] NGRequest[14] NGRequest[15] NGRequest[16] NGRequest[17] NGRequest[18] NGRequest[19] NGRequest[20] NGRequest[21] NGRequest[22] NGRequest[23] NGRequest[24] NGRequest[25] NGRequest[26] NGRequest[27] NGRequest[28] NGRequest[29])
 fn NFparity old native original label = (
  NFcheck (cyrusPlacementIsNative native) (label+" returns native storage")
  NFcheck ((cyrusRecipePublicationFingerprint #(old))==(cyrusRecipePublicationFingerprint #(native))) (label+" every ordered field matches")
  NFcheck (cyrusPlacementContextEqual NFContext (cyrusPlacementContextOf native)) (label+" retains source cohort")
  NFcheck (CyrusPresetSameValues (cyrusPlacementReceivers original) (cyrusPlacementReceivers native)) (label+" retains receiver cohort")
 )
 case command[1] of (
  "setup": (
   NFModels=#(box name:"Field source A",pyramid name:"Field source B")
   NFContext=cyrusPlacementContextCreate NGOwner "field-population" #(#("source-a",NFModels[1],true,false,false),#("source-b",NFModels[2],true,false,false))
   NFArea=rectangle name:"Field area" width:68 length:54 pos:[3,-4,17]
   NFDocs=#(cyrusBrushCreate NGTerrain,cyrusBrushCreate NGTerrain)
   cyrusBrushFill NFDocs[1] 1
   cyrusBrushSettings NFDocs[1] 12 true;cyrusBrushDab NFDocs[1] [0,0,200] [0,0,-1] true
   cyrusBrushSettings NFDocs[2] 28 false;cyrusBrushDab NFDocs[2] [18,0,200] [0,0,-1] true
   cyrusPlacementTransportStats true
  )
  "case": (
   local amount=command[2] as integer
   CyrusReserveScriptWorkspace (8388608L+(amount as integer64)*4096L);gc light:true
   NGRequest=NGBase amount
   local old=(NGCall false)[1],native=(NFbound())[1],original=cyrusRecipePublicationFingerprint #(native)
   local loops=#(#([-43,-41,0],[43,-41,2],[43,41,8],[-43,41,3]),#([-8,-8,6],[8,-8,6],[8,8,6],[-8,8,6]))
   for cfg in #(#(false,0.0,false,2.0,#(0,1),false,2.0,#(0,1)),#(true,4.0,false,1.0,#(0,1),false,1.0,#(0,1)),#(false,0.0,true,16.0,#(0.1,0.7,1.8),false,1.0,#(0,1)),#(true,2.0,true,15.0,#(0.0,0.2,1.0),true,20.0,#(0,0.1,0.7,1)),#(false,0.0,true,0.0,#(0,2),true,0.0,#(0,1))) do (
    local expected=cyrusBoundaryFalloff old loops cfg 42,before=cyrusPlacementTransportStats()
    local actual=cyrusBoundaryFalloff native loops cfg 42
    NFcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Boundary stays native"
    NFparity expected actual native "Boundary"
    for side in #(1,2) do (
     expected=cyrusAreaFalloff old NFArea cfg 54 side;before=cyrusPlacementTransportStats()
     actual=cyrusAreaFalloff native NFArea cfg 54 side
     NFcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Area falloff stays native"
     NFparity expected actual native "Area falloff"
    )
   )
   for mode=1 to 3 do (
    cyrusBrushSetFalloff NFDocs[1] #(8.0,4.0,mode!=2,mode!=1,0.15,1.4,#(0,0.2,1),#(0,0.3,0.7,1))
    cyrusBrushSetFalloff NFDocs[2] #(13.0,2.0,true,true,0.7,2.1,#(0,0.8,1),#(0,0.5,1))
    local bytes=for d in NFDocs collect (cyrusBrushRecipeExport d)[1]
    for weights in #(#(1.0,0.0),#(0.0,1.0),#(0.4,0.9),#(0.7,0.7),#(0.0,0.0)) do (
     local expected=cyrusBrushRegionFilter old NFDocs weights #(NGTerrain) #(NGTerrain.numfaces) "Field population فارسی",before=cyrusPlacementTransportStats()
     local actual=cyrusBrushRegionFilter native NFDocs weights #(NGTerrain) #(NGTerrain.numfaces) "Field population فارسی"
     NFcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Paint stays native"
     NFparity expected actual native "Paint union/scales/holes"
    )
    NFcheck (CyrusPresetSameValues bytes (for d in NFDocs collect (cyrusBrushRecipeExport d)[1])) "Paint evaluation leaves authored bytes unchanged"
   )
   NFcheck (original==cyrusRecipePublicationFingerprint #(native)) "Inputs immutable"
   NFcheck (findItem (theHold.GetUndoNames()) "Native generation unrelated marker">0) "Unrelated Undo preserved"
   NFwrite ("PASS "+NGKind+" fields Count="+(amount as string)+" input="+original)
  )
  "receivers": (
   NGRequest=NGBase 5000;local old=(NGCall false)[1],native=(NFbound())[1]
   NFTerrain2=copy NGTerrain;NFTerrain2.pos.x=120
   NGRequest[1]=#(NFTerrain2);NGRequest[29][11]=2;NGRequest[29][10]="22222222-2222-4222-8222-222222222222"
   local otherOld=(NGCall false)[1],otherNative=(NFbound())[1]
   join old (cyrusReceiverOffsetRows otherOld NGTerrain.numfaces)
   native=cyrusPlacementJoin #(native,cyrusReceiverOffsetRows otherNative NGTerrain.numfaces)
   local second=cyrusBrushCreate NFTerrain2;cyrusBrushFill second 1
   local docs=#(NFDocs[1],NFDocs[2],second),weights=#(0.4,0.9,0.6),targets=#(NGTerrain,NFTerrain2),faces=#(NGTerrain.numfaces,NFTerrain2.numfaces)
   local expected=cyrusBrushRegionFilter old docs weights targets faces "receivers",before=cyrusPlacementTransportStats()
   NFNative=cyrusBrushRegionFilter native docs weights targets faces "receivers";NFExpected=cyrusRecipePublicationFingerprint #(NFNative)
   NFcheck (NGAllCoveredSame before (cyrusPlacementTransportStats())) "Multiple Paint receivers stay native"
   NFparity expected NFNative native "Multiple receiver offsets"
   local failed=false
   try(cyrusBrushRegionFilter native docs weights #(NFTerrain2,NGTerrain) faces "receivers")catch(failed=true)
   NFcheck failed "Mismatched receiver correspondence rejects before output"
   failed=false;try(cyrusBrushRegionFilter native docs #(0.4,1.9,0.6) targets faces "receivers")catch(failed=true)
   NFcheck failed "Invalid Paint density rejects"
   failed=false;try(cyrusBoundaryFalloff native #() #(false,0.0,true,1.0,#(0,1),false,1.0,#(0,1)) 42)catch(failed=true)
   NFcheck failed "Missing boundary rejects"
   NFcheck (NFExpected==cyrusRecipePublicationFingerprint #(NFNative)) "Failures preserve prior output"
   NFwrite ("PASS "+NGKind+" multi-receiver/failure "+NFExpected)
  )
  "release": (
   NFNative=undefined;NFContext=undefined;NFDocs=undefined;NGRequest=undefined;NGPrevious=undefined
   gc light:true
   local memory=cyrusPlacementMemoryStats()
   NFcheck (memory[1]==0 and memory[5]==0 and memory[6]==0 and memory[7]==0) "No abandoned native field buffers"
   NFwrite "PASS RELEASE"
  )
  default:throw "Unknown native field test"
 )
)
