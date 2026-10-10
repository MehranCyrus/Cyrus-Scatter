CYRebind()
if (for l in CYL where l.previewError!="" collect l).count>0 do throw "Final preview errors"
if CyrusPFLastError!="" do throw "Final render error"
if cyrusDiagnosticActive() do throw "Recorder left active"
CYLog "delivery-state" #(#("scene",maxFilePath+maxFileName),#("update_mode",CYR.updateMode),#("auto_render",CYR.autoRender),#("counts",for l in CYL collect l.generatedCount),#("errors",for l in CYL collect l.previewError),#("brush_valid",for a in CYPaint collect cyrusBrushStats a.paintDocument),#("diagnostics_active",cyrusDiagnosticActive()),#("render_error",CyrusPFLastError),#("pf_active",CyrusPFActive))
