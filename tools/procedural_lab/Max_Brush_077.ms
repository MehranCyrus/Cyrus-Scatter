-- Owned private Max host only. Load Max_Layer_Regions_074.ms first.
global B77Checks=#(),B77Check,B77Feedback
fn B77Check condition label = (
 if not condition do throw ("Brush 0.77: "+label)
 append B77Checks label
 CSPWriteText (MCPFixtureDir+"brush077-checks.json") (CSPObject #(#("checks",B77Checks)))
 true
)
fn B77Feedback = (
 LRSetup();local r=LRRoot,a=LRLayer
 B77Check (r.uiVersion()=="0.77") "Current generated UI is 0.77"
 r.setLayerSurfaces a #(LRPlane)
 local area=r.addPaintArea a target:LRPlane,d=area.paintDocument
 cyrusBrushDisplay d 2 (color 100 200 100)
 cyrusBrushSettings d 18 .35 .6 false 1
 cyrusBrushBegin d
 local times=#(),wall=#(),watch=dotNetObject "System.Diagnostics.Stopwatch"
 for i=1 to 1000 do (
  cyrusBrushSettings d 18 .35 .6 (mod i 4==0) 1
  watch.Restart();cyrusBrushDab d [0,0,200] [0,0,-1] true;cyrusBrushRefreshMask d;watch.Stop()
  if i<=10 or i>970 do (append times (cyrusBrushStats d)[13];append wall watch.Elapsed.TotalMilliseconds)
 )
 local stats=cyrusBrushStats d
 B77Check (stats[2]==1000 and stats[19]>0 and stats[18]==0 and stats[5]==1) "1000 mixed soft strokes retain active, unlimited tint"
 local builds=stats[9],queries=stats[10]
 for i=1 to 10 do (cyrusBrushRefreshMask d;redrawViews())
 stats=cyrusBrushStats d
 B77Check (stats[9]==builds and stats[10]==queries and stats[20]>0) "Idle redraw draws tint without recomputing field"
 r.refreshAll();local fp=cyrusEditFingerprint r.groupSnapshotRows[1] "paint077"
 cyrusBrushSettings d 18 .5 .6 false 1
 local drag=#()
 for i=1 to 300 do (
  watch.Restart();cyrusBrushDab d [((mod i 31)-15),0,200] [0,0,-1] false;cyrusBrushRefreshMask d;watch.Stop()
  if mod i 30==0 do append drag watch.Elapsed.TotalMilliseconds
 )
 B77Check ((cyrusBrushStats d)[2]==1000 and (cyrusBrushStats d)[6]==1) "300 pending dabs remain one unfinished gesture"
 cyrusBrushCancel d;cyrusBrushRefreshMask d;r.refreshAll()
 B77Check ((cyrusEditFingerprint r.groupSnapshotRows[1] "paint077")==fp) "Cancel restores exact committed placements"
 cyrusBrushSettings d 1000 1 0 true 1;cyrusBrushDab d [0,0,200] [0,0,-1] true;cyrusBrushRefreshMask d
 B77Check ((cyrusEditFingerprint r.groupSnapshotRows[1] "paint077")==fp) "Manual keeps publication while tint follows erase"
 r.refreshAll();B77Check (r.groupSnapshotRows[1].count==0) "Update applies opaque erase"
 max undo;cyrusBrushRefreshMask d;r.refreshAll()
 B77Check ((cyrusEditFingerprint r.groupSnapshotRows[1] "paint077")==fp) "Compact stroke Undo restores exact result"
 max redo;cyrusBrushRefreshMask d;r.refreshAll()
 B77Check (r.groupSnapshotRows[1].count==0) "Compact stroke Redo restores erase"
 max undo;cyrusBrushRefreshMask d;r.refreshAll()
 B77Check ((cyrusEditFingerprint r.groupSnapshotRows[1] "paint077")==fp) "Repeated Undo remains exact"
 cyrusBrushStop()
 saveMaxFile (MCPFixtureDir+"brush077-feedback.max") quiet:true
 loadMaxFile (MCPFixtureDir+"brush077-feedback.max") quiet:true
 r=(getNodeByName "LR_Controller").baseObject;r.refreshAll()
 B77Check ((cyrusEditFingerprint r.groupSnapshotRows[1] "paint077")==fp) "Save/reopen reconstructs exact paint result"
 CSPWriteText (MCPFixtureDir+"brush077-timing.json") (CSPObject #(#("evaluation_ms_first10_last30",times),#("dab_and_refresh_ms_first10_last30",wall),#("pending_30_to_300_dabs_ms",drag),#("tint_faces",stats[19]),#("presented_fps_measured",false)))
 true
)
