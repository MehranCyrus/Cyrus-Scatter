global CYR,CYL,CYRebind,CYLog,FXTrace
if not loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/Courtyard_Study_075/Courtyard_075.max" quiet:true useFileUnits:true do throw "Load failed"
CYRebind()
local times=#(),s=dotNetObject "System.Diagnostics.Stopwatch"
s.Start();CYR.procManualRevision+=1;CYR.procExplicitUpdate=true;local entries=CYR.layerEntries();s.Stop();append times #("layer_entries",s.Elapsed.TotalMilliseconds)
FXTrace=#();s.Restart();for entry in entries do entry[2].refreshPreview();s.Stop();append times #("refresh_leaves",s.Elapsed.TotalMilliseconds)
CYR.procExplicitUpdate=false
s.Restart();if (CyrusContainerPanel CYR).controlsReady do (CyrusContainerPanel CYR).refreshStats();s.Stop();append times #("refresh_stats",s.Elapsed.TotalMilliseconds)
s.Restart();CYR.refreshBrushEditors();s.Stop();append times #("brush_editors",s.Elapsed.TotalMilliseconds)
s.Restart();CyrusViewportRedraw();s.Stop();append times #("redraw",s.Elapsed.TotalMilliseconds)
CYLog "cold-parts" #(#("timings",times),#("trace",FXTrace),#("errors",for l in CYL collect l.previewError))
