-- Passive state recorder. Start deliberately with fileIn; stop with
-- CyrusLayerWatchStop(). Does not write plugin parameters or rebuild caches.
(
global CyrusLayerWatchTimer,CyrusLayerWatchPath,CyrusLayerWatchLast,CyrusLayerWatchStarted
global CyrusLayerWatchTick,CyrusLayerWatchStop,CyrusLayerWatchRead

fn CyrusLayerWatchStop = (
    try(CyrusLayerWatchTimer.Stop();CyrusLayerWatchTimer.Dispose())catch()
    CyrusLayerWatchTimer=undefined
    if CyrusLayerWatchPath!=undefined do format "Cyrus layer recording: %\n" CyrusLayerWatchPath
    CyrusLayerWatchPath
)
fn CyrusLayerWatchRead = (
    local stream=stringStream ""
    with printAllElements on (
        format "hold=% dragging=% pending=%\n" (theHold.Holding()) CyrusWasDragging CyrusPointPending to:stream
        for n in objects where classof n.baseObject==AminScatterObject do (
            local root=n.baseObject,panel=root.mainUI,modelOwner=undefined,uiRows=#()
            try(modelOwner=root.modelsUI.sourceUI_obj;uiRows=root.modelsUI.sourceUI_plantList.items)catch()
            format "ROOT handle=% name=% mode=% active=% epoch=% uiOwner=% uiRows=%\n" (getHandleByAnim n) n.name root.updateMode root.activeLayer root.procEpoch (if modelOwner==undefined then "none" else modelOwner.layerID) uiRows to:stream
            for i=1 to root.layerObjects.count do (
                local leaf=root.layerObjects[i]
                format "LAYER index=% id=% name=% enabled=% visible=% amount=% dirty=% built=% shown=% error=%\n" i leaf.layerID root.layerNames[i] root.layerEnabled[i] root.layerVisible[i] leaf.amount leaf.dirty leaf.generatedCount leaf.cachedPointCount leaf.previewError to:stream
                format "  sources=% rowIDs=% point=% empty=% weights=%\n" (for source in leaf.sources collect if isValidNode source then #(getHandleByAnim source,source.name) else undefined) (leaf.sourceRowIDs as array) (leaf.sourcePoint as array) (leaf.sourceEmpty as array) (leaf.sourceWeights as array) to:stream
                format "  receivers=% containerMode=%\n" (for receiver in leaf.surfaceNodes collect if isValidNode receiver then #(getHandleByAnim receiver,receiver.name) else undefined) leaf.containerMode to:stream
            )
        )
    )
    stream as string
)
fn CyrusLayerWatchTick sender args = (
    if timeStamp()-CyrusLayerWatchStarted>900000 do (CyrusLayerWatchStop();return false)
    try (
        local state=CyrusLayerWatchRead()
        if state!=CyrusLayerWatchLast do (
            (dotNetClass "System.IO.File").AppendAllText CyrusLayerWatchPath ("\nTIME "+localTime+"\n"+state)
            CyrusLayerWatchLast=state
        )
    )catch(
        try((dotNetClass "System.IO.File").AppendAllText CyrusLayerWatchPath ("\nRECORDER ERROR "+getCurrentException()+"\n"))catch()
        CyrusLayerWatchStop()
    )
)
CyrusLayerWatchStop()
local root=(dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName()))+"../../build/layer-source-watch")
makeDir root all:true
local token=(dotNetClass "System.Guid").NewGuid()
CyrusLayerWatchPath=root+"/"+token.ToString()+".log"
CyrusLayerWatchLast="";CyrusLayerWatchStarted=timeStamp()
(dotNetClass "System.IO.File").WriteAllText CyrusLayerWatchPath "Cyrus passive layer/source recorder. State changes sampled every 200 ms; automatic stop after 15 minutes.\n"
CyrusLayerWatchTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusLayerWatchTimer.Interval=200
dotNet.addEventHandler CyrusLayerWatchTimer "Tick" CyrusLayerWatchTick
CyrusLayerWatchTick undefined undefined
CyrusLayerWatchTimer.Start()
format "Cyrus layer recorder started. Stop: CyrusLayerWatchStop(). Log: %\n" CyrusLayerWatchPath
)
