(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned brush host required"
 local output=createFile (MCPFixtureDir+"brush-ui-08672.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 try(
  local receiver=sphere radius:50 segs:24
  VRoot.setLayerSurfaces VLayer #(receiver)
  local area=VRoot.addPaintArea VLayer target:receiver
  cyrusSetSurfaceHidden receiver true
  select VController;max modify mode
  if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
  VRoot.mainUI.slots[7].open=true;VRoot.mainUI.bindSection VRoot.coverageUI
  if VRoot.mainUI.bindTimer.active do VRoot.mainUI.bindTimer.tick()
  local page=VRoot.coverageUI
  check (page.brushUI_obj==area and page.brushUI_beginButton.enabled) "Painting controls bind hidden sphere Paint Area" output
  page.brushUI_beginButton.pressed()
  check (CyrusBrushSessionLayer==area and CyrusBrushTimer.Enabled) "Actual Start Brush button starts the hidden-surface session" output
  check (cyrusBrushDab area.paintDocument [0,0,200] [0,0,-1] true) "Hidden sphere receives painted coverage" output
  for i=1 to 5 do CyrusBrushTick undefined undefined
  check (CyrusBrushSessionLayer==area and (cyrusBrushStats area.paintDocument)[5]==1) "Subsequent UI status ticks retain the active brush" output
  page.brushUI_stopButton.pressed()
  check (CyrusBrushSessionLayer==undefined and (cyrusBrushStats area.paintDocument)[5]==0) "Actual Stop button ends the session" output
  format "SUCCESS\n" to:output
 )catch(try(CyrusStopBrush())catch();format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
