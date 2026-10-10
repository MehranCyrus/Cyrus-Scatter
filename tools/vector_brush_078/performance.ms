(
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
CyrusStopBrush();VRoot.updateMode=1;cyrusBrushBind VD;cyrusBrushFill VD 0
local cfg=cyrusBrushFalloff VD;cfg[1]=8;cfg[2]=4;cfg[3]=true;cfg[4]=true;cfg[5]=.25;cfg[6]=1;cfg[7]=#(0.0,1.0);cfg[8]=#(0.0,1.0)
cyrusBrushSetFalloff VD cfg;cyrusBrushSettings VD 15 false;VRoot.refreshAll()
local before=VLayer.receiverCacheStats(),combinedBefore=VLayer.paintCacheStats(),watch=dotNetObject "System.Diagnostics.Stopwatch"
local out=createFile (MCPFixtureDir+"population-timings.csv")
format "edit,author_ms,border_ms,update_ms,accepted\n" to:out
cyrusBrushBegin VD
for i=1 to 40 do (
 watch.Restart();cyrusBrushDab VD [60*sin(i*17),60*cos(i*13),200] [0,0,-1] true;watch.Stop();local edit=watch.Elapsed.TotalMilliseconds
 watch.Restart();cyrusBrushRefreshMask VD;watch.Stop();local border=watch.Elapsed.TotalMilliseconds
 watch.Restart();VRoot.refreshAll();watch.Stop();local update=watch.Elapsed.TotalMilliseconds
 format "%,%,%,%,%\n" i edit border update VRoot.groupSnapshotRows[1].count to:out
)
cyrusBrushStop();close out
local after=VLayer.receiverCacheStats(),combinedAfter=VLayer.paintCacheStats()
out=createFile (MCPFixtureDir+"cache-counters.txt")
format "Receiver caches before % after %\nCombined row assembly before % after %\n" before after combinedBefore combinedAfter to:out;close out
VAssert (after[1]==before[1]) "40 feathered paint edits reuse the layer base candidates"
VAssert (VLayer.previewError=="") "40 paint-plus-publication updates complete without an error"
)
