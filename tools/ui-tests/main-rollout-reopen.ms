-- Invocation-only asynchronous regression: setup.ms must have run in a private fixture.
(
    RIAssert (matchPattern RIDir pattern:"*ui-layer-status-*/") "Wrong fixture directory"
    global UIRootTestTimer,UIRootTestTick,UIRootTestUI,UIRootTestRows,UIRootTestPhase,UIRootTestStarted
    global UIRootTestHandles,UIRootTestCaches,UIRootTestValues,UIRootTestStates
    try(UIRootTestTimer.Stop())catch()
    UIRootTestUI=UILayerNode.mainUI
    UIRootTestUI.open=true
    for r in UIRootTestUI.roots do r.open=false
    for r in UIRootTestUI.layerPanels do r.open=false
    UIRootTestUI.layerPanels[1].open=true
    UIRootTestUI.layerPanels[1].children[3].open=true
    UIRootTestUI.layoutPanels()
    UILayerNode.refreshAll()
    UIRootTestHandles=for r in (UIRootTestUI.roots+UIRootTestUI.layerPanels+UIRootTestUI.layerPanels[1].children) collect r.hwnd
    UIRootTestCaches=for l in UILayerNode.layerObjects collect (l.previewStats())[1]
    UIRootTestValues=for l in UILayerNode.layerObjects collect #(l.amount,l.collisionRadius)
    UIRootTestStates=for r in (UIRootTestUI.roots+UIRootTestUI.layerPanels+UIRootTestUI.layerPanels[1].children) collect r.open
    UIRootTestRows=#();UIRootTestPhase=0
    fn UIRootTestTick sender args = (
        try (
            local ui=UIRootTestUI
            if UIRootTestPhase==0 then (
                ui.open=false
                RIAssert (ui.widthTimer.interval==300) "Collapsed rollout must not poll at the expedited interval"
                UIRootTestStarted=RIStamp()
                ui.open=true
                UIRootTestPhase=1
            ) else (
                local b=windows.getWindowPos ui.hwnd,pb=windows.getWindowPos (windows.getParentHWND ui.hwnd)
                local elapsed=RIStamp()-UIRootTestStarted
                if abs(b.w-(amax 160 (pb.w-8)))<=1 and abs(b.x-pb.x-4)<=1 and ui.widthTimer.interval==300 then (
                    local handles=for r in (ui.roots+ui.layerPanels+ui.layerPanels[1].children) collect r.hwnd
                    local states=for r in (ui.roots+ui.layerPanels+ui.layerPanels[1].children) collect r.open
                    RIAssert ((handles as string)==(UIRootTestHandles as string)) "Reopening must retain control HWNDs"
                    RIAssert ((states as string)==(UIRootTestStates as string)) "Reopening must retain nested expansion states"
                    for i=1 to UILayerNode.layerObjects.count do (
                        local layer=UILayerNode.layerObjects[i]
                        RIAssert ((layer.previewStats())[1]==UIRootTestCaches[i] and not layer.dirty) "Reopening must not rebuild or dirty scatter caches"
                        RIAssert (layer.amount==UIRootTestValues[i][1] and layer.collisionRadius==UIRootTestValues[i][2]) "Reopening must retain layer values"
                    )
                    append UIRootTestRows #(UIRootTestRows.count+1,elapsed,b.w,pb.w)
                    UIRootTestPhase=0
                    if UIRootTestRows.count==30 do (
                        UIRootTestTimer.Stop()
                        CSPWriteText (RIDir+"main-rollout-reopen.json") (CSPObject #(#("passed",true),#("ui_version",UILayerNode.uiVersion()),#("samples",UIRootTestRows),#("unchanged_controls_states_values_and_caches",true),#("timing_note","50 ms polling observes settled geometry; this is not a paint latency or flicker measurement.")))
                    )
                ) else RIAssert (elapsed<2000) "Main rollout did not restore its width and normal timer interval"
            )
        ) catch (
            UIRootTestTimer.Stop()
            CSPWriteText (RIDir+"main-rollout-reopen.json") (CSPObject #(#("passed",false),#("error",getCurrentException()),#("samples",UIRootTestRows)))
        )
    )
    UIRootTestTimer=dotNetObject "System.Windows.Forms.Timer"
    UIRootTestTimer.Interval=50
    dotNet.addEventHandler UIRootTestTimer "Tick" UIRootTestTick
    UIRootTestTimer.Start()
)
