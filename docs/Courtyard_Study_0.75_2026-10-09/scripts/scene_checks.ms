-- Runs against a saved disposable scene; retains individual operation evidence.
global CYBench,CYFP,CYCheck,CYChecks,CYStroke
local r=CYR,a=CYPaint[1],l=CYL[3],fp=CYFP(),areas=l.paintAreas.count
CYBench "warm-evaluate-1" (fn action=(r.evaluateGroups()))
CYBench "warm-evaluate-2" (fn action=(r.evaluateGroups()))
CYCheck "warm-output" ((CYFP()) as string==fp as string) "Unchanged evaluation returns identical rows"
local epoch=r.procEpoch,seed0=CYL[10].randomSeed
CYL[10].randomSeed+=1;CYL[10].refreshPreview()
CYCheck "manual-pending" (r.procEpoch==epoch and (CYFP()) as string==fp as string) "Seed edit awaits Update"
CYBench "manual-explicit-update" (fn action=(r.refreshAll()))
CYCheck "manual-update-published" (r.procEpoch>epoch) "Explicit update published"
r.updateMode=2;CYL[10].randomSeed=seed0
CYBench "live-seed-edit" (fn action=(CYL[10].refreshPreview()))
CYCheck "live-seed-restored" ((CYFP()) as string==fp as string) "Seed restored entire output"
r.updateMode=1
local p=[-1070,-270,650],before=r.groupSnapshotRows[3].count
CYBench "brush-erase-author" (fn action=(CYStroke a #(p) 170 0 erase:true))
CYCheck "paint-manual-pending" ((CYFP()) as string==fp as string) "Erase preserved published rows before Update"
CYBench "brush-erase-evaluate" (fn action=(r.evaluateGroups()))
local erased=CYFP(),after=r.groupSnapshotRows[3].count
CYCheck "erase-changes-output" (after<before) #(before,after)
max undo
CYBench "brush-undo-evaluate" (fn action=(r.evaluateGroups()))
CYCheck "brush-undo" ((CYFP()) as string==fp as string) "Exact output restored"
max redo;r.evaluateGroups()
CYCheck "brush-redo" ((CYFP()) as string==erased as string) "Erase reproduced"
max undo;r.evaluateGroups()
CYCheck "stroke-keeps-area" (l.paintAreas.count==areas) "Additional gesture did not create a named area/population"
-- Fill/Empty on the independent curved Paint Area; Undo restores authored history.
local curved=CYPaint[3],curveFP=CYFP(),history=cyrusBrushHistory curved.paintDocument
cyrusBrushFill curved.paintDocument 0;r.evaluateGroups()
CYCheck "empty-curved" (r.groupSnapshotRows[7].count==0) "Empty removes curved layer coverage"
max undo;r.evaluateGroups()
CYCheck "empty-undo" ((CYFP()) as string==curveFP as string and (cyrusBrushHistory curved.paintDocument) as string==history as string) "Undo restores curved strokes"
cyrusBrushFill curved.paintDocument 1;r.evaluateGroups()
CYCheck "fill-curved" (r.groupSnapshotRows[7].count>0) "Full curved receiver accepted"
max undo;r.evaluateGroups()
CYCheck "fill-undo" ((CYFP()) as string==curveFP as string) "Fill is reversible"
-- Target removal preserves history; restoration is tested with same receiver order.
local hist=cyrusBrushHistory CYPaint[2].paintDocument,original=r.groupSnapshotRows[3].count
r.setLayerSurfaces l #(CYReceivers[1]);r.evaluateGroups()
CYCheck "inactive-target-history" ((cyrusBrushHistory CYPaint[2].paintDocument) as string==hist as string) "East receiver unlinked; paint preserved"
r.setLayerSurfaces l CYReceivers;r.evaluateGroups()
CYCheck "target-restore" ((CYFP()) as string==fp as string) "Original receiver list restored exact placements"
-- Passive selection and local labels do not change generated output.
epoch=r.procEpoch
for i=1 to 10 do r.selectLayer i
CYCheck "layer-selection" (r.procEpoch==epoch and (CYFP()) as string==fp as string) "Browsing layers does not regenerate"
local model=CYL[4].sources[1],name0=model.name
CYL[4].setSourceLabel 1 "Geranium | low flower"
CYCheck "local-source-label" (model.name==name0) "Alias leaves actual scene node name intact"
CYCheck "all-final-layers-valid" ((for v in CYL where v.previewError!="" collect v).count==0) "No preview errors"
r.selectLayer 3;r.updateMode=1
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
