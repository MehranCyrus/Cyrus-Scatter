-- Session scheduling observes only the active Brush. Idle viewport drawing
-- does not scan documents, pick meshes, replay strokes or upload buffers.
global CyrusBrushSessionRoot,CyrusBrushSessionLayer,CyrusBrushSessionRevision=0,CyrusBrushTimer,CyrusBrushBusy=false
global CyrusStartBrush,CyrusStopBrush,CyrusBrushTick
fn CyrusStopBrush = (
    cyrusBrushStop()
    local root=CyrusBrushSessionRoot,layer=CyrusBrushSessionLayer
    CyrusBrushSessionRoot=undefined;CyrusBrushSessionLayer=undefined
    if layer!=undefined do layer.checkPaintRevision()
    if root!=undefined do root.bindNativeUI()
    CyrusViewportRedraw()
)
fn CyrusStartBrush root layer = (
    CyrusStopBrush()
    if layer==undefined or layer.paintDocument==undefined do throw "Pick a Brush receiving surface first."
    cyrusBrushBegin layer.paintDocument
    CyrusBrushSessionRoot=root;CyrusBrushSessionLayer=layer;CyrusBrushSessionRevision=0
    cyrusBrushRefreshMask layer.paintDocument;redrawViews()
)
fn CyrusBrushTick sender args = (
    if CyrusBrushBusy or CyrusBrushSessionLayer==undefined do return false
    CyrusBrushBusy=true
    try (
        local layer=CyrusBrushSessionLayer,root=CyrusBrushSessionRoot,state=cyrusBrushStats layer.paintDocument
        if state[1]!=CyrusBrushSessionRevision do (
            cyrusBrushRefreshMask layer.paintDocument
            CyrusBrushSessionRevision=state[1]
            if state[6]==0 then (layer.checkPaintRevision();CyrusViewportRedraw()) else redrawViews()
            if root.brushUI.controlsReady do (root.brushUI.refreshHistory();root.brushUI.status())
        )
        if state[5]==0 do (
            layer.checkPaintRevision()
            if root.brushUI.controlsReady do root.brushUI.status()
            CyrusBrushSessionLayer=undefined;CyrusBrushSessionRoot=undefined
        )
    ) catch (
        local failure=getCurrentException()
        cyrusBrushStop();CyrusBrushSessionLayer=undefined;CyrusBrushSessionRoot=undefined
        format "Cyrus Brush: %\n" failure
    )
    CyrusBrushBusy=false
)
try(CyrusBrushTimer.Stop())catch()
CyrusBrushTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusBrushTimer.Interval=150
dotNet.addEventHandler CyrusBrushTimer "Tick" CyrusBrushTick
CyrusBrushTimer.Start()
callbacks.removeScripts id:#CyrusBrushSession
callbacks.addScript #filePreOpen "CyrusStopBrush()" id:#CyrusBrushSession
callbacks.addScript #systemPreReset "CyrusStopBrush()" id:#CyrusBrushSession
