(
 RSBind()
 local originalBrush=#(RSOwners[2].paintDocument,RSFlowers.paintDocument)
 convertToMesh RSSurface
 -- This generated Gaussian created denormal values far below visible precision.
 -- Snap only its numerical tail before authoring fresh diagnostic strokes.
 for i=1 to (getNumVerts RSSurface) do (
  local p=getVert RSSurface i
  if abs p.z<.001 do (p.z=0;setVert RSSurface i p)
 )
 update RSSurface
 RSOwners[2].paintDocument=cyrusBrushCreate RSSurface
 cyrusBrushSettings RSOwners[2].paintDocument 360 1 .18 false 1
 for p in #([-970,-530,700],[990,-590,700],[1090,410,700]) do cyrusBrushDab RSOwners[2].paintDocument p [0,0,-1] true
 RSFlowers.paintDocument=cyrusBrushCreate RSSurface
 cyrusBrushSettings RSFlowers.paintDocument 330 1 .35 false 1
 for p in #([-720,-660,700],[-910,-250,700],[820,-450,700],[1170,340,700]) do cyrusBrushDab RSFlowers.paintDocument p [0,0,-1] true
 RSRoot.refreshAll()
 local before=RSRows()
 saveMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true
 loadMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true useFileUnits:true;RSBind();RSRoot.refreshAll()
 RSAssert (RSEqual before (RSRows())) "Normalized terrain Brush roundtrip still differs"
 CSPWriteText (MCPFixtureDir+"terrain-roundtrip.json") (CSPObject #(#("passed",true),#("treatment","Generated Gaussian heights below 0.001 cm normalized to zero before creating Brush documents"),#("counts",for rows in before collect rows.count)))
)
