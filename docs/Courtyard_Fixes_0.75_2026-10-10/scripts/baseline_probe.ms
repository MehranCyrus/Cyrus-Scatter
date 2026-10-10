global CYNode,CYR,CYL,CYReceivers,CYMound,CYCam,CYAnalyzer,CYPaths,CYPathMeshes,CYBeds,CYPaint,CYLog,CYSample,CYRebind,CYFP,CYNavigate,CYCheck
global FXTrace=#(),CyrusPerfTraceBegin,CyrusPerfTraceEnd
fn CYLog label pairs = CSPWriteText (MCPFixtureDir+label+".json") (CSPObject pairs)
fn CYSample label elapsed = CYLog label #(#("elapsed_ms",elapsed))
fn CyrusPerfTraceBegin obj kind = (local s=dotNetObject "System.Diagnostics.Stopwatch";s.Start();#(s,obj.layerID,kind))
fn CyrusPerfTraceEnd token result = (token[1].Stop();append FXTrace #(token[2],token[3],token[1].Elapsed.TotalMilliseconds,result))
if not loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/Courtyard_Study_075/Courtyard_075.max" quiet:true useFileUnits:true do throw "Scene load failed"
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/courtyard-study075/bench_definitions.ms"
CYRebind()
local t=dotNetObject "System.Diagnostics.Stopwatch"
FXTrace=#();t.Start();CYR.refreshAll();t.Stop()
CYLog "cold-update" #(#("ms",t.Elapsed.TotalMilliseconds),#("trace",FXTrace),#("counts",for l in CYL collect l.generatedCount),#("errors",for l in CYL collect l.previewError))
FXTrace=#();t.Restart();CYR.refreshAll();t.Stop()
CYLog "warm-update" #(#("ms",t.Elapsed.TotalMilliseconds),#("trace",FXTrace))
clearSelection();max create mode
viewport.setLayout #layout_1;viewport.setCamera CYCam;viewport.setRenderLevel #smoothhighlights
for spec in #(#("nav-box",2,1),#("nav-sphere",2,2),#("nav-pyramid",2,3),#("nav-mesh",3,1),#("nav-points",1,1)) do CYNavigate spec[1] spec[2] spec[3] 10000
CYLog "baseline-final" #(#("fp",CYFP()),#("analyzer",CYAnalyzer.getLiveStats()),#("retained_error",CyrusPointLastError))
