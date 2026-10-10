global CYBench,CYNavigate,CYFP,CYRebind,CYCheck,CYChecks=#()
fn CYFP = (for rows in CYR.groupSnapshotRows collect cyrusEditFingerprint rows "courtyard")
fn CYCheck name ok detail = (
 append CYChecks #(name,ok,detail)
 CYLog "scene-checks" #(#("checks",CYChecks))
 if not ok do format "CHECK FAILED: % -- %\n" name detail
 ok
)
fn CYRebind = (
 CYNode=getNodeByName "CYRUS 0.75 | Courtyard feature study";CYR=CYNode.baseObject;CYL=CYR.logicalLayers()
 CYReceivers=#(getNodeByName "RECEIVER | west courtyard",getNodeByName "RECEIVER | east courtyard")
 CYMound=getNodeByName "RECEIVER | curved sensory mound";CYCam=getNodeByName "01 HERO | courtyard garden";CYAnalyzer=getNodeByName "ANALYZER | island border"
 CYPaths=for i=1 to 3 collect getNodeByName ("EXCLUDE + BANDS | path "+i as string)
 CYPathMeshes=for i=1 to 3 collect getNodeByName ("PATH | branching gravel "+i as string)
 CYBeds=for i=1 to 8 collect getNodeByName ("INCLUDE | planting bed "+i as string)
 CYPaint=join (for a in CYL[3].paintAreas collect a) (for a in CYL[7].paintAreas collect a)
)
fn CYBench label action = (
 local before=#(CYR.procEpoch,for l in CYL collect l.procStatistics()),t=dotNetObject "System.Diagnostics.Stopwatch"
 t.Start();action();t.Stop()
 CYSample label t.Elapsed.TotalMilliseconds
 CYLog (label+"-delta") #(#("before",before),#("after",#(CYR.procEpoch,for l in CYL collect l.procStatistics())),#("elapsed_ms",t.Elapsed.TotalMilliseconds))
)
fn CYNavigate label mode shape limit = (
 CYR.updateMode=1;CYR.viewportInstances=limit;CYR.viewportFaces=2000000;CYR.proxyShape=shape;CYR.setGroupDisplay mode
 local t=dotNetObject "System.Diagnostics.Stopwatch";t.Start();CYR.refreshDisplay();t.Stop();local switchMs=t.Elapsed.TotalMilliseconds
 for i=1 to 3 do (completeRedraw();windows.processPostedMessages())
 local before=#(CYR.procEpoch,for l in CYL collect #(l.procPreparedBuilds,l.previewBuildCount)),fp=CYFP(),owner=CyrusPointOwner CYNode
 local retained=if isValidNode owner then cyrusRetainedStats owner else #(),times=#(),original=CYCam.pos
 for i=1 to 20 do (
  t.Restart();CYCam.pos=original+[12*sin(i*18),0,0];completeRedraw();windows.processPostedMessages();t.Stop();append times t.Elapsed.TotalMilliseconds
 )
 CYCam.pos=original
 local after=#(CYR.procEpoch,for l in CYL collect #(l.procPreparedBuilds,l.previewBuildCount)),now=if isValidNode owner then cyrusRetainedStats owner else #()
 local reused=true
 if retained.count!=now.count then reused=false else if retained.count>0 do for k in #(3,4,5,6,7,9) where retained[k]!=now[k] do reused=false
 CYLog label #(#("metric","synchronous camera mutation + completeRedraw + posted messages; not presented FPS"),#("mode",mode),#("shape",shape),#("instance_limit",limit),#("switch_ms",switchMs),#("frame_ms",times),#("viewport",#(gw.getWinSizeX(),gw.getWinSizeY())),#("accepted",for l in CYL collect l.generatedCount),#("shown",for l in CYL collect l.cachedPointCount),#("faces",for l in CYL collect cyrusPreviewFaces l.cachedPoints),#("proxy_stats",for l in CYL collect cyrusPreviewDrawStats l.cachedPoints),#("before",before),#("after",after),#("retained_before",retained),#("retained_after",now),#("retained_unchanged",reused),#("placements_unchanged",(CYFP()) as string==fp as string))
 CYCheck label (before as string==after as string and reused and (CYFP()) as string==fp as string) "Navigation: placements, preparation and retained upload counters"
)
