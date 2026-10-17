(
 if not (matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativegenerate-product-*/" or matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-*/") do throw "Owned generation boundary host required."
 global NGRequest,NGPrevious,NGOwner,cyrusOwnedPlacementProbeVersion
 local io=dotNetClass "System.IO.File",log=createFile(MCPFixtureDir+"generation-boundaries.txt")
 fn ECheck yes text log=(format "%: %\n" (if yes then "PASS" else "FAIL") text to:log;flush log;if not yes do throw text)
 try (
  ECheck (cyrusOwnedPlacementProbeVersion==undefined) "Product build excludes private SDK hold controls" log
  NGRequest=NGBase 100;NGPrevious=(NGCall true)[1]
  local hash=cyrusRecipePublicationFingerprint #(NGPrevious),token=cyrusPlacementToken NGPrevious,failed=false
  NGRequest[2]=1000001;try(NGCall true)catch(failed=true)
  ECheck failed "Existing one-million candidate bound remains" log
  NGRequest=NGBase 100;NGRequest[4]=0;failed=false;try(NGCall true)catch(failed=true)
  ECheck failed "Missing source table rejects before native result creation" log
  ECheck (hash==cyrusRecipePublicationFingerprint #(NGPrevious) and CyrusPresetSameValues token (cyrusPlacementToken NGPrevious)) "Failed successors retain complete previous native generation" log
  local edited=cyrusEditStack #() NGPrevious 1 "boundary-test",small=cyrusPlacementPage edited (cyrusPlacementToken edited) 0 1
  local radii=cyrusProceduralRadii small #(#(1,1.0,false,[0,0,0],[1,1,1]),#(1,2.0,false,[0,0,0],[1,1,1])) #() #() #()
  local a=cyrusPlacementCapture NGOwner 2 2 0 small,bindings=#("source-a","source-b"),stats=#(1,1)
  local full=cyrusPlacementPublicationFingerprint #(a) #(radii) bindings stats
  ECheck (full!=cyrusPlacementPublicationFingerprint #(a) #(radii) #("source-changed","source-b") stats) "Complete fingerprint detects correspondence changes" log
  local alternate=cyrusProceduralRadii small #(#(1,3.0,false,[0,0,0],[1,1,1]),#(1,4.0,false,[0,0,0],[1,1,1])) #() #() #()
  ECheck (full!=cyrusPlacementPublicationFingerprint #(a) #(alternate) bindings stats) "Complete fingerprint detects changed frozen radii" log
  failed=false;try(cyrusPlacementPublicationFingerprint #(a) #(#()) bindings stats)catch(failed=true)
  ECheck failed "Mismatched frozen radii are rejected" log
  local cyclic=#();append cyclic cyclic;failed=false
  try(cyrusPlacementPublicationFingerprint #(a) #(radii) cyclic stats)catch(failed=true)
  ECheck failed "Cyclic/overdeep metadata fails within its depth bound" log
  local longID="";for i=1 to 256 do longID+="x"
  small[1][3]=longID;small[1][7]=true
  local longNative=cyrusPlacementCapture NGOwner 2 2 0 small
  ECheck ((cyrusRecipePublicationFingerprint #(small))==(cyrusRecipePublicationFingerprint #(longNative))) "Full existing 256-byte authored identity fingerprints match" log
  ECheck (findItem (theHold.GetUndoNames()) "Native generation unrelated marker">0) "Boundary rejection preserves unrelated Undo" log
  NGRequest=undefined;NGPrevious=undefined
  format "PASS: complete\n" to:log;close log
 )catch(format "FAIL: %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log;flush log;close log;throw())
)
