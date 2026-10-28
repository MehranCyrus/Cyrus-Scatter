global DGTimer,DGTick,DGFile,DGStep,DGView,DGSavedHeld,DGSceneMode
if DGTimer!=undefined do DGTimer.Stop()
DGFile=createFile (GardenRun+CVProfileCase+".txt");DGStep=0;DGView=viewport.getTM();DGSavedHeld=CyrusInteractionHeld
DGSceneMode=(findString CVProfileCase "scene")!=undefined
WFRoot.interactionsEnsure();CyrusPointSync()
fn CyrusInteractionHeld = true
fn DGTick sender args = (
    try(
        DGStep+=1
        local start=timeStamp(),nativeMS=0
        if DGStep<=12 then (
            if DGSceneMode then DGStone.pos+=[(if DGStep<=6 then 5 else -5),0,0]
            else cyrusEditCommand WFEdit 4 (transMatrix [(if DGStep<=6 then 5 else -5),0,0])
            nativeMS=timeStamp()-start
        ) else viewport.setTM ((rotateZMatrix ((DGStep-12)*.8))*DGView)
        redrawViews()
        format "STEP % native_ms:% redraw_ms:% stats:%\nFRAME %\n" DGStep nativeMS (timeStamp()-start-nativeMS) (WFRoot.interactionsStatistics()) (cyrusRetainedPresentationStats (CyrusPointOwner WFOwner)) to:DGFile
        flush DGFile
        if DGStep>=24 do (
            DGTimer.Stop();close DGFile;CyrusInteractionHeld=DGSavedHeld;viewport.setTM DGView
            local bitmap=gw.getViewportDib();bitmap.filename=GardenRun+"drag-finished.png";save bitmap;close bitmap
        )
    )catch(DGTimer.Stop();format "ERROR %\n" (getCurrentException()) to:DGFile;close DGFile;CyrusInteractionHeld=DGSavedHeld)
)
DGTimer=dotNetObject "System.Windows.Forms.Timer";DGTimer.Interval=if matchPattern CVProfileCase pattern:"rapid-*" then 40 else 200
dotNet.addEventHandler DGTimer "Tick" DGTick
windows.postMessage (windows.getMAXHWND()) 0x0112 0xF120 0
DGTimer.Start()
