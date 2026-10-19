(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local log=createFile (MCPFixtureDir+"channels.txt")
 fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
 try (
  with undo off (
   local terrain=plane name:"Owned channel/UV preflight witness" width:100 length:100 widthsegs:1 lengthsegs:1 mapCoords:false
   convertToMesh terrain;meshop.setNumMaps terrain 8 keep:true
   for channel in #(0,2,7) do (
    meshop.setMapSupport terrain channel true;meshop.setNumMapVerts terrain channel terrain.numverts;meshop.setNumMapFaces terrain channel terrain.numfaces
    for i=1 to terrain.numverts do meshop.setMapVert terrain channel i [0.25,0.5,0.75]
    for i=1 to terrain.numfaces do meshop.setMapFace terrain channel i (getFace terrain i)
   )
   update terrain
   local mapping=#(1,1,20.,20.,1.,1.,0.,0.,0.,matrix3 1,#(0.,1.)),filters=#(false,0.,180.,0.,0.,false,0.,100.,0.,0.)
   for channel in #(0,2,7) do for component=1 to 3 do (
    local field=cyrusPrepareDensityOverlay #(terrain) #(true,channel,component,0.,1.,false,#(0.,1.)) undefined mapping 1 1 4096 false filters false #() #(#(),#()),info=cyrusDensityOverlayInfo field
    check (info[2]==component*0.25 and info[3]==component*0.25) ("Host mesh channel "+channel as string+" component "+component as string+" samples actual numeric values") log
   )
   local key=cyrusProceduralSurfaceKey #(terrain) true 7
   check (key!="") "Required receiver UV7 passes before staging" log
   meshop.setMapSupport terrain 7 false;update terrain
   local rejected=false,reason=""
   try(cyrusProceduralSurfaceKey #(terrain) true 7)catch(rejected=true;reason=getCurrentException())
   check (rejected and findString reason "7L"==undefined) "Missing UV7 is rejected with a plain channel number" log
   delete terrain
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
