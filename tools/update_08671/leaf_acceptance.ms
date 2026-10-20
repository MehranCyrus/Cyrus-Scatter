(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-2027/" do throw "Owned real leaf host required"
 local output=createFile (MCPFixtureDir+"leaf-acceptance.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn draw=(LRoot.refreshDisplay();redrawViews();completeRedraw())
 fn capture label=(local image=gw.getViewportDib();image.filename=MCPFixtureDir+label+".png";save image;close image)
 try(
  local epoch=LRoot.procEpoch,builds=LRoot.groupBuilds,geometry=(cyrusRetainedStreamStats())[2]
  local original=LMaterial.texmapDiffuse,opacity=LMaterial.texmapOpacity
  check (LRoot.groupSnapshotRows[1].count==16 and LLayer.previewError=="") "Actual A027 Corona leaf imports through library command" output
  LCC=ColorCorrection map:original hueShift:120 saturation:70 brightness:15
  undo "Leaf color correction" on (LMaterial.texmapDiffuse=LCC)
  draw();capture "real-leaves-corrected"
  check (LLayer.previewError=="" and LRoot.procEpoch==epoch and LRoot.groupBuilds==builds and (cyrusRetainedStreamStats())[2]==geometry) "Color Correction around Forest/Corona map updates appearance only" output
  local before=cyrusMaterialPreviewKey #(LSource)
  LLayer.amount=42
  LCC.hueShift=240;LCC.saturation=30;draw();capture "real-leaves-edited"
  check (before!=cyrusMaterialPreviewKey #(LSource) and LRoot.groupSnapshotRows[1].count==16 and LLayer.amount==42 and LRoot.procEpoch==epoch) "Editing correction properties preserves pending Manual amount" output
  undo "Leaf clear diffuse" on (LMaterial.texmapDiffuse=undefined)
  draw();capture "real-leaves-diffuse-cleared"
  check (LLayer.previewError=="" and LMaterial.texmapOpacity==opacity and LRoot.procEpoch==epoch) "Clearing diffuse keeps opacity and placement state" output
  max undo;draw()
  check (LMaterial.texmapDiffuse==LCC and LLayer.previewError=="") "Undo restores the material graph" output
  LMaterial.texmapOnOpacity=false;draw();capture "real-leaves-opacity-off"
  LMaterial.texmapOnOpacity=true;draw();capture "real-leaves-opacity-restored"
  check (LLayer.previewError=="" and LRoot.procEpoch==epoch) "Opacity off/on updates real leaf cutouts independently" output
  local stats=cyrusRetainedStats (CyrusPointOwner LNode),uploads=stats[6],bytes=stats[7]
  for i=1 to 10 do (local tm=viewport.getTM();tm.row4.x+=0.1;viewport.setTM tm;redrawViews();completeRedraw())
  stats=cyrusRetainedStats (CyrusPointOwner LNode)
  check (stats[6]==uploads and stats[7]==bytes and (cyrusRetainedStreamStats())[2]==geometry) "Warm navigation reuses real leaf geometry and textures" output
  with animate on (at time 0 LCC.hueShift=0;at time 20 LCC.hueShift=180)
  sliderTime=10;draw();capture "real-leaves-animated"
  check (LLayer.previewError=="" and LRoot.procEpoch==epoch and LRoot.groupSnapshotRows[1].count==16) "Animated correction updates without applying Manual placements" output
  sliderTime=0
  saveMaxFile (MCPFixtureDir+"real-leaf-textured.max") quiet:true
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
