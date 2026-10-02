-- Invocation-only transport for a disposable interactive Max process.
-- HVPRoot/HVPDir are supplied by launch.py. Never install this at startup.
global HVPCommandTimer, HVPLastRequest="", HVPCommandTick
global HVPCaches=#(), HVPNode, HVPArm="off", HVPCallbackMS=0.0, HVPCallbackCalls=0
global HVPBaseTM, HVPDraw, HVPFixtureInfo, HVPClockClass, HVPStopwatchFrequency
try(unregisterRedrawViewsCallback HVPDraw)catch()
global CyrusPerfHeadless=true
fileIn (HVPRoot+"tools/performance/CyrusPerformanceMonitor.ms")
HVPClockClass=dotNetClass "System.Diagnostics.Stopwatch"
HVPStopwatchFrequency=HVPClockClass.Frequency as double
fn HVPStamp = ((HVPClockClass.GetTimestamp() as double)*1000.0/HVPStopwatchFrequency)
fn HVPStats = (
    local s=cyrusPointProbeStats HVPNode
    local out=for i=1 to 10 collect (s[i] as integer)
    append out s[11]; out
)
fn HVPDraw = (
    if HVPArm=="gw" do (
        local started=HVPStamp()
        for cache in HVPCaches do aminScatterDrawPreview cache false white
        HVPCallbackMS+=(HVPStamp()-started); HVPCallbackCalls+=1
    )
)
registerRedrawViewsCallback HVPDraw

fn HVPCapture name = (
    redrawViews(); windows.processPostedMessages()
    local bitmap=gw.getViewportDib()
    bitmap.filename=HVPDir+name+".png"; save bitmap; close bitmap
)
fn HVPMode mode = (
    if findItem #("off","gw","retained") mode==0 do throw "Unknown probe arm"
    HVPArm=mode; cyrusPointProbeShow HVPNode (mode=="retained")
    completeRedraw(); windows.processPostedMessages()
)
fn HVPBuild pointCount sourceCount = (
    if pointCount<100 or pointCount>2000000 or sourceCount<1 or sourceCount>64 do throw "Fixture bounds exceeded"
    HVPMode "off"
    local clock=HVPClockClass.StartNew()
    local source=cone radius1:42 radius2:0 height:160 sides:8 heightsegs:1 capsegs:1
    local samples=for i=1 to sourceCount collect (aminScatterSourcePoints source 100 (27000+i))
    delete source
    local colors=for i=1 to sourceCount collect (color (40+mod (i*17) 95) (90+mod (i*23) 140) (25+mod (i*13) 75))
    local plants=ceil(pointCount/100.0) as integer
    local columns=ceil(sqrt plants) as integer
    local spacing=8000.0/columns
    local total=0, exported=#(), batches=#()
    seed 19471
    HVPCaches=#()
    for first=0 to (plants-1) by 5000 do (
        local last=amin (plants-1) (first+4999)
        local rows=for i=first to last collect (
            local x=((mod i columns)+0.5)*spacing-4000.0
            local y=((floor(i/columns as float))+0.5)*spacing-4000.0
            local tm=rotateZMatrix (random 0.0 359.9)
            tm.translation=[x+(random -0.3 0.3)*spacing,y+(random -0.3 0.3)*spacing,0]
            #(tm,1+mod i sourceCount)
        )
        local cache=aminScatterBuildPreview rows samples colors 500000
        append HVPCaches cache
        total+=aminScatterPreviewCount cache
        join exported (aminScatterPreviewPoints cache)
    )
    cyrusPointProbeSet HVPNode exported
    exported=undefined
    clock.Stop()
    HVPFixtureInfo=#(#("requested_points",pointCount),#("actual_points",total),#("plants",plants),#("source_groups",sourceCount),#("cache_count",HVPCaches.count),#("prepare_ms",clock.Elapsed.TotalMilliseconds))
    CSPWriteText (HVPDir+"fixture.json") (CSPObject HVPFixtureInfo)
    gc light:true
    HVPMode "gw"
    total
)

fn HVPCase writer label mode frames:120 repeat:1 = (
    viewport.setTM HVPBaseTM
    local cold=HVPStamp()
    HVPMode mode
    cold=HVPStamp()-cold
    for i=1 to 12 do (
        if not (viewport.setTM ((rotateZMatrix (6.0*sin(i*7.0)))*HVPBaseTM)) do throw "Viewport transform rejected"
        completeRedraw(); windows.processPostedMessages()
    )
    local before=HVPStats(), start=HVPStamp()
    for frame=1 to frames do (
        HVPCallbackMS=0.0; HVPCallbackCalls=0
        local tick=HVPStamp()
        if not (viewport.setTM ((rotateZMatrix (6.0*sin(frame*7.0)))*HVPBaseTM)) do throw "Viewport transform rejected"
        completeRedraw(); windows.processPostedMessages()
        local finish=HVPStamp()
        CSPRow writer #(label,mode,repeat,frame,tick,finish,finish-tick,HVPCallbackMS,HVPCallbackCalls)
    )
    local finish=HVPStamp(), after=HVPStats()
    if before[1]!=after[1] or before[3]!=after[3] or before[11]!=after[11] do throw "Point data changed during navigation"
    if mode=="retained" and before[6]!=after[6] do throw "Unexpected upload during unchanged navigation"
    if mode=="retained" and after[8]-before[8]<frames do throw "Retained draw path did not execute on every step"
    if after[9]!=0 do throw "GPU realization failed"
    #(#("case",label),#("arm",mode),#("repeat",repeat),#("begin_qpc_ms",start),#("end_qpc_ms",finish),#("cold_mode_switch_ms",cold),#("before",before),#("after",after))
)
fn HVPBenchmark name frames:120 repeats:3 = (
    local writer=CSPWriter (HVPDir+name+"-frames.csv") "case,arm,repeat,frame,begin_qpc_ms,end_qpc_ms,step_ms,callback_ms,callback_calls"
    local cases=#()
    try (
        for repeat=1 to repeats do (
            local arms=if mod repeat 2==0 then #("retained","gw","off") else #("off","gw","retained")
            for mode in arms do append cases (CSPObject (HVPCase writer name mode frames:frames repeat:repeat))
        )
        writer.Close()
        local joined="["
        for i=1 to cases.count do (if i>1 do joined+=","; joined+=cases[i])
        CSPWriteText (HVPDir+name+"-cases.json") (joined+"]")
        CSPWriteText (HVPDir+name+"-fixture.json") (CSPObject HVPFixtureInfo)
    ) catch (writer.Close(); throw())
    viewport.setTM HVPBaseTM; HVPMode "retained"
)

try (
    if cyrusPointProbeSet==undefined or aminScatterBuildPreview==undefined do throw "Probe or production native binary missing"
    if objects.count!=0 do throw "Probe requires an empty newly launched Max session"
    HVPNode=CyrusRetainedPointProbe name:"Cyrus Retained Point Experiment"
    HVPNode.renderable=false
    viewport.setLayout #layout_1
    viewport.setType #view_persp_user
    local camera=targetCamera pos:[7000,-8500,9200] target:(targetObject pos:[0,0,0])
    HVPBaseTM=inverse camera.transform
    viewport.setType #view_persp_user; viewport.setTM HVPBaseTM
    local cameraTarget=camera.target
    delete camera
    if isValidNode cameraTarget do delete cameraTarget
    viewport.setRenderLevel #smoothhighlights
    local viewportSettings=NitrousGraphicsManager.GetActiveViewportSetting()
    viewportSettings.AdaptiveDegradeNeverDegradeGeometry=true
    HVPBuild 25000 3
    HVPMode "retained"
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    local modules=#()
    for index=0 to (process.Modules.Count-1) do (
        local loadedModule=process.Modules.Item[index]
        if matchPattern loadedModule.ModuleName pattern:"*Cyrus*" or matchPattern loadedModule.ModuleName pattern:"AminScatter*" do append modules #(loadedModule.ModuleName,loadedModule.FileName)
    )
    CSPWriteText (HVPDir+"ready.json") (CSPObject #(#("pid",process.Id),#("host",maxVersion()),#("modules",modules),#("viewport_size",#(gw.getWinSizeX(),gw.getWinSizeY())),#("stats",HVPStats())))
    HVPCapture "pilot-retained"
) catch (CSPWriteText (HVPDir+"startup-error.txt") (getCurrentException()+"\n"+getCurrentExceptionStackTrace()))
