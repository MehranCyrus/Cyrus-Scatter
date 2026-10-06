-- Callbacks only request deferred work. No idle signature/scene polling.
global CyrusScheduleRelease,CyrusScheduleUI,CyrusPFRequestCheck,CyrusRenderNodeChanged
global CyrusPFCheckPending=false,CyrusPFResumeMode=3,CyrusPFTicking=false
global CyrusReleaseTimer,CyrusPFTimer,CyrusPFBusy,CyrusLayerEditor,CyrusPointPending,AminScatterObject
global CyrusPFStopIR,CyrusPFLastError
-- Corona stop can pump messages and deliver nested host callbacks. Keep bridge
-- mutation excluded through the stop, and verify the resulting render state.
-- A nonzero return alone cannot distinguish a nested/already-stopped request.
-- The optional provider exists for deterministic failure/reentrancy fixtures.
fn CyrusPFStopIR renderer:undefined = (
    if CyrusPFBusy==true do (CyrusPFLastError="Corona Stop deferred while the Cyrus bridge is busy.";return false)
    if renderer==undefined do renderer=CoronaRenderer
    local previousBusy=CyrusPFBusy,stopped=false
    CyrusPFBusy=true
    try (
        local before=renderer.getRenderType()
        if before==0 then stopped=true
        else if findItem #(2,3) before>0 then (
            CyrusDiagnosticEmit "ir.stop_requested" "renderer" "" 0 "bridge"
            local result=renderer.stopRender(),after=renderer.getRenderType()
            CyrusDiagnosticEmit "ir.stop_result" "renderer" "" 0 ((result as string)+":"+(after as string))
            stopped=after==0
            if not stopped do CyrusPFLastError="Corona IR remains active after Stop (status "+(result as string)+", render type "+(after as string)+")."
        ) else CyrusPFLastError="Corona render is not an interactive session; its bridge was preserved."
    )catch(CyrusPFLastError=getCurrentException())
    CyrusPFBusy=previousBusy
    stopped
)
fn CyrusScheduleRelease = (
    if CyrusReleaseTimer!=undefined do CyrusReleaseTimer.Start()
)
fn CyrusScheduleUI = (
    if CyrusLayerEditor!=undefined do CyrusLayerEditor.statusTimer.active=true
    local obj=try(modPanel.getCurrentObject())catch(undefined)
    if obj!=undefined and classof obj==AminScatterObject and obj.mainUI.controlsReady do obj.mainUI.statusTimer.active=true
)
fn CyrusPFRequestCheck = (
    if CyrusPFBusy!=true do (
        CyrusPFCheckPending=true
        if CyrusPFTimer!=undefined and not CyrusPFTicking do CyrusPFTimer.Start()
    )
)
fn CyrusRenderNodeChanged event handles = (
    if CyrusPFBusy==true do return false
    local nodes=for h in handles collect (getAnimByHandle h),relevant=false
    for n in nodes where isValidNode n do (
        if classof n.baseObject==AminScatterObject then (
            CyrusScheduleUI()
            if event==#hideChanged do (relevant=true;CyrusPointPending=true)
        ) else if event!=#nameChanged and event!=#hideChanged do (
            for owner in objects where classof owner.baseObject==AminScatterObject do
                for leaf in owner.baseObject.layerObjects where findItem leaf.sources n>0 do relevant=true
        )
    )
    if relevant do CyrusPFRequestCheck()
    true
)
