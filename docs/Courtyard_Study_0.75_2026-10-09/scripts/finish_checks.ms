CYRebind()
CYR.updateMode=1;CYR.setGroupDisplay 1;CYR.viewportInstances=10000;CYR.autoRender=true;CYR.refreshDisplay()
local fp=CYFP(),paint=for a in CYPaint collect #(a.layerID,a.areaTarget.name,cyrusBrushHistory a.paintDocument)
local assets=#(),missing=#()
for m in (join (getClassInstances Bitmaptexture) (getClassInstances CoronaBitmap)) do (
 append assets #(m.name,m.filename)
 if m.filename!="" and not doesFileExist m.filename do append missing m.filename
)
CYLog "asset-inventory" #(#("bitmaps",assets),#("missing",missing))
if missing.count>0 do throw "Missing texture files"
CYR.selectLayer 3;select CYNode;max modify mode;modPanel.setCurrentObject CYR
renderWidth=1400;renderHeight=875;renderers.current.progressive_passLimit=8;renderers.current.progressive_timeLimit=0
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
if not (loadMaxFile (CYOut+"Courtyard_075.max") quiet:true useFileUnits:true) do throw "Scene reopen failed"
CYRebind()
CYBench "reopen-explicit-update" (fn action=(CYR.refreshAll()))
local exact=(CYFP()) as string==fp as string,paintAfter=for a in CYPaint collect #(a.layerID,a.areaTarget.name,cyrusBrushHistory a.paintDocument)
CYCheck "save-reopen-placements" exact "Per-layer identities/models/transforms preserved"
CYCheck "save-reopen-paint" (paintAfter as string==paint as string) "Named target-bound Paint Areas and history preserved"
if not exact or paintAfter as string!=paint as string do throw "Reopen mismatch"
CYBench "final-warm-read-1" (fn action=(CYR.evaluateGroups()))
CYBench "final-warm-read-2" (fn action=(CYR.evaluateGroups()))
cyrusDiagnosticStart "courtyard_design_study" 4096 4194304 600000
CYR.refreshDisplay()
local log=cyrusDiagnosticSnapshot 0 100
cyrusDiagnosticStop()
CSPWriteText (MCPFixtureDir+"diagnostic-sample.json") log
CYLog "final-scene-checks" #(#("save_reopen_exact",exact),#("paint_preserved",paintAfter as string==paint as string),#("fingerprints",fp),#("counts",for l in CYL collect l.generatedCount),#("area_count",CYPaint.count),#("paint_stats",for a in CYPaint collect cyrusBrushStats a.paintDocument),#("bitmap_nodes",assets.count),#("missing",missing),#("analyzer_runs",CYAnalyzer.getAnalysisRuns()),#("layers",for i=1 to CYL.count collect #(CYR.layerNames[i],for n in CYL[i].validSurfaces() collect n.name,CYL[i].generatedCount,CYL[i].previewError)))
viewport.setCamera CYCam;CYR.selectLayer 3
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true

