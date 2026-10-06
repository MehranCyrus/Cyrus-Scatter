-- Callbacks only request deferred work. No idle signature/scene polling.
global CyrusScheduleRelease,CyrusScheduleUI,CyrusPFRequestCheck,CyrusRenderNodeChanged
global CyrusPFCheckPending=false,CyrusPFResumeMode=3,CyrusPFTicking=false
global CyrusReleaseTimer,CyrusPFTimer,CyrusPFBusy,CyrusLayerEditor,CyrusPointPending,AminScatterObject
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
