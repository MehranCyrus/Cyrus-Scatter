-- Run manually through Scripting > Run Script with Cyrus selected in Modify.
-- One-shot report; no startup hook, permanent timer, installation or scene save.
global CyrusMount,CyrusUIDiagnose,CyrusUIDiagMount,CyrusUIDiagLog
fn CyrusUIDiagnose = (
    if selection.count!=1 do throw "Select one Cyrus Scatter controller in Modify."
    local obj=selection[1].baseObject
    if not isProperty obj #layerObjects do throw "Select the Cyrus Scatter controller."
    local ui=obj.mainUI
    if not ui.controlsReady or not ui.open or ui.layerPanels.count==0 do throw "Open the Cyrus Scatter panel and add a layer first."
    local p=ui.layerPanels[amax 1 obj.activeLayer],wasOpen=p.open,scroll=ui.scrollPos
    local handles=for r in ui.roots collect r.hwnd
    local before=for l in obj.layerObjects collect #((l.previewStats())[1],l.dirty)
    local clock=dotNetClass "System.Diagnostics.Stopwatch"
    local path=(getDir #temp)+"/CyrusUI-"+((dotNetClass "System.DateTime").Now.ToString "yyyyMMdd-HHmmss-fff")+".txt"
    CyrusUIDiagLog=createFile path
    if CyrusUIDiagLog==undefined do throw "Could not create the diagnostic report."
    CyrusUIDiagMount=CyrusMount
    fn CyrusMount host section collapsed = (
        local timer=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
        local result=CyrusUIDiagMount host section collapsed
        format "Mount %: % ms\n" section.title timer.Elapsed.TotalMilliseconds to:CyrusUIDiagLog
        result
    )
    local failure=undefined
    try (
        format "UI revision: %\nMax: %\nLayer: %\nAlready constructed: %\n" (try(obj.uiVersion())catch("untagged")) (maxVersion()) p.title (p.children.count>0) to:CyrusUIDiagLog
        format "Panel width: %; timer active: %\n" ui.panels.width ui.widthTimer.active to:CyrusUIDiagLog
        for pass=1 to 2 do (
            p.open=false
            local timer=clock.StartNew()
            p.open=true
            format "Open pass %: % ms (synchronous handler only)\n" pass timer.Elapsed.TotalMilliseconds to:CyrusUIDiagLog
            windows.processPostedMessages()
        )
        local timer=clock.StartNew()
        for i=1 to 10 do ui.layoutPanels()
        format "Ten unchanged layout calls: % ms\n" timer.Elapsed.TotalMilliseconds to:CyrusUIDiagLog
        timer=clock.StartNew();ui.roots[4].refreshStats()
        format "Statistics refresh: % ms\n" timer.Elapsed.TotalMilliseconds to:CyrusUIDiagLog
        format "Root controls remounted: %\n" ((handles as string)!=((for r in ui.roots collect r.hwnd) as string)) to:CyrusUIDiagLog
    )catch(failure=getCurrentException())
    CyrusMount=CyrusUIDiagMount
    try(p.open=wasOpen;ui.scrollPos=scroll)catch(if failure==undefined do failure=getCurrentException())
    local after=for l in obj.layerObjects collect #((l.previewStats())[1],l.dirty)
    format "Build/dirty state changed: %\nError: %\n" ((before as string)!=(after as string)) failure to:CyrusUIDiagLog
    close CyrusUIDiagLog;CyrusUIDiagLog=undefined
    format "Cyrus UI report: %\n" path
    if failure!=undefined do throw failure
    path
)
CyrusUIDiagnose()
