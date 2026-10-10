-- Owned private profile only. Load Max_Layer_Regions_074.ms first.
global B76Checks=#(),B76Check,B76History,B76Limit
fn B76Check condition label = (
 if not condition do throw ("Brush 0.76: "+label)
 append B76Checks label
 CSPWriteText (MCPFixtureDir+"brush076-checks.json") (CSPObject #(#("checks",B76Checks)))
 true
)
fn B76History = (
 LRSetup();local r=LRRoot,a=LRLayer
 B76Check (r.uiVersion()=="0.76") "Current generated UI is 0.76"
 r.setLayerSurfaces a #(LRPlane)
 local area=r.addPaintArea a target:LRPlane,d=area.paintDocument
 cyrusBrushDisplay d 0 (color 100 200 100)
 for i=1 to 1000 do (
  cyrusBrushSettings d 18 .35 .6 (mod i 4==0) 1
  local x=-75+15*(mod i 11),y=-75+15*(mod (i/11) 11)
  cyrusBrushDab d [x,y,200] [0,0,-1] true
 )
 local watch=dotNetObject "System.Diagnostics.Stopwatch";watch.Start();r.refreshAll();watch.Stop()
 local ms=watch.Elapsed.TotalMilliseconds,fp=cyrusEditFingerprint r.groupSnapshotRows[1] "brush076",stats=cyrusBrushStats d
 B76Check (a.previewError=="" and stats[2]==1000 and r.groupSnapshotRows[1].count>0) "1000 soft paint/erase gestures publish"
 local epoch=r.procEpoch,builds=stats[9]
 r.evaluateProcedural()
 B76Check ((cyrusBrushStats d)[9]==builds and r.procEpoch==epoch) "Unchanged read reuses prepared history and publication"
 cyrusBrushSettings d 1000 1 0 true 1;cyrusBrushDab d [0,0,200] [0,0,-1] true
 B76Check ((cyrusEditFingerprint r.groupSnapshotRows[1] "brush076")==fp) "Manual erase waits for Update"
 r.refreshAll();B76Check (r.groupSnapshotRows[1].count==0) "Opaque erase overrides long soft history"
 max undo;r.refreshAll();B76Check ((cyrusEditFingerprint r.groupSnapshotRows[1] "brush076")==fp) "Undo restores exact long-history publication"
 max redo;r.refreshAll();B76Check (r.groupSnapshotRows[1].count==0) "Redo restores erase"
 max undo;r.refreshAll()
 local scene=MCPFixtureDir+"brush076-history.max";saveMaxFile scene quiet:true
 loadMaxFile scene quiet:true;r=(getNodeByName "LR_Controller").baseObject;a=r.layerObjects[1];r.refreshAll()
 B76Check ((cyrusEditFingerprint r.groupSnapshotRows[1] "brush076")==fp) "Long history save/reopen preserves result"
 CSPWriteText (MCPFixtureDir+"brush076-history.json") (CSPObject #(#("strokes",1000),#("update_ms",ms),#("placed",r.groupSnapshotRows[1].count),#("fingerprint",fp)))
 true
)
fn B76Limit = (
 LRSetup();local r=LRRoot,a=LRLayer
 local dense=plane name:"B76_Dense" width:200 length:200 widthsegs:200 lengthsegs:200
 r.setLayerSurfaces a #(dense)
 local area=r.addPaintArea a target:dense,d=area.paintDocument
 cyrusBrushDisplay d 0 (color 100 200 100)
 cyrusBrushSettings d 1000 1 0 false 1
 -- 80,000 faces per connected patch; 100 dabs meet 8,000,000 links exactly.
 for i=1 to 100 do cyrusBrushDab d [0,0,200] [0,0,-1] true
 r.refreshAll()
 B76Check (a.previewError=="" and r.groupSnapshotRows[1].count==1000) "Production face-link limit accepts exact boundary"
 local fp=cyrusEditFingerprint r.groupSnapshotRows[1] "bounded",epoch=r.procEpoch,cache=a.cachedPoints
 cyrusBrushDab d [0,0,200] [0,0,-1] true;r.refreshAll()
 B76Check (findString a.previewError "face-link limit"!=undefined) "Production aggregate overflow reports a specific error"
 B76Check (r.procEpoch==epoch and a.cachedPoints==cache and (cyrusEditFingerprint r.groupSnapshotRows[1] "bounded")==fp) "Overflow retains complete placements, epoch and preview cache"
 B76Check ((cyrusBrushStats d)[2]==101) "Overflow does not silently delete authored paint"
 cyrusBrushDeleteStroke d 101;r.refreshAll()
 B76Check (a.previewError=="" and (cyrusEditFingerprint r.groupSnapshotRows[1] "bounded")==fp) "Removing over-budget stroke recovers exact result"
 max undo;r.refreshAll();B76Check (findString a.previewError "face-link limit"!=undefined) "Undo rechecks aggregate limits"
 max redo;r.refreshAll();B76Check (a.previewError=="") "Redo recovers after limit failure"
 true
)
