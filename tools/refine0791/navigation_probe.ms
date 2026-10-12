-- Disposable-host profiling only. Diagnostic callback variants are restored.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/refine0791-navigation*" do throw "Private navigation host required"
global N79OriginalDraw=AminScatterObjectDraw,N79Draw,N79Mode=0,N79Held=0
global N79Totals=#(),N79Callbacks=0,N79Watch=dotNetClass "System.Diagnostics.Stopwatch"
global N79Cached=#(),N79View,N79Frames,N79Measure,N79SetMode,N79Restore
N79View=viewport.getTM()
N79Cached=for node in objects where classof node.baseObject==AminScatterObject collect #(node,(for entry in node.baseObject.viewportLayerEntries false collect #(entry[1],entry[2],entry[2].cachedPoints)))
fn N79Draw = (
    local started=N79Watch.GetTimestamp(),t=started
    local held=if N79Held==0 then false else if N79Held==1 then true else CyrusInteractionHeld()
    gw.setTransform (matrix3 1)
    for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
        t=N79Watch.GetTimestamp()
        gw.setTransform n.objectTransform;gw.setColor #line red
        for path in n.baseObject.iconLines() do gw.polyline path false
        gw.setTransform (matrix3 1)
        N79Totals[1]+=N79Watch.GetTimestamp()-t
        local caches=#(),styles=#(),entries=#()
        t=N79Watch.GetTimestamp()
        if N79Mode>=2 then (
            for pair in N79Cached where pair[1]==n do entries=pair[2]
        ) else entries=n.baseObject.viewportLayerEntries held
        N79Totals[2]+=N79Watch.GetTimestamp()-t
        for entry in entries do (
            local obj=entry[2]
            t=N79Watch.GetTimestamp()
            local cache=if N79Mode>=2 then entry[3] else obj.previewCache interactionHeld:held
            N79Totals[3]+=N79Watch.GetTimestamp()-t
            t=N79Watch.GetTimestamp()
            if N79Mode==0 or N79Mode==2 do obj.drawRadii()
            N79Totals[4]+=N79Watch.GetTimestamp()-t
            if (obj.showPoints or obj.showCenters) and cache!=undefined do (
                if (obj.viewportMode==1 and CyrusPointEnabled) or ((obj.viewportMode==2 or obj.viewportMode==3) and CyrusMeshEnabled) then (append caches cache;append styles #(obj.pointColorMode==1,obj.solidPointColor))
                else aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
            )
        )
        t=N79Watch.GetTimestamp()
        local ready=false,owner=CyrusPointOwner n
        if (CyrusPointEnabled or CyrusMeshEnabled) and isValidNode owner do ready=cyrusRetainedMatches owner caches styles
        N79Totals[5]+=N79Watch.GetTimestamp()-t
        t=N79Watch.GetTimestamp()
        if not ready do (
            for i=1 to caches.count do aminScatterDrawPreview caches[i] styles[i][1] styles[i][2]
            if caches.count>0 and CyrusPointAvailable and not CyrusPointSuspended do (
                local failed=false
                if isValidNode owner do failed=(cyrusRetainedStats owner)[12]==2
                if not failed do (CyrusPointPending=true;CyrusScheduleRelease())
            )
        )
        N79Totals[6]+=N79Watch.GetTimestamp()-t
    )
    gw.enlargeUpdateRect #whole
    N79Totals[7]+=N79Watch.GetTimestamp()-started
    N79Callbacks+=1
)
fn N79SetMode mode held:0 = (
    unregisterRedrawViewsCallback N79OriginalDraw
    unregisterRedrawViewsCallback N79Draw
    N79Mode=mode;N79Held=held
    N79Totals=for i=1 to 7 collect 0.0d0;N79Callbacks=0
    if mode == -1 then registerRedrawViewsCallback N79OriginalDraw
    else if mode<4 do registerRedrawViewsCallback N79Draw
)
fn N79Measure mode motion count held:0 = (
    N79SetMode mode held:held
    viewport.setTM N79View
    completeRedraw();completeRedraw()
    N79Totals=for i=1 to 7 collect 0.0d0;N79Callbacks=0
    local results=#(),frequency=N79Watch.Frequency as double
    for i=1 to count do (
        local started=N79Watch.GetTimestamp()
        case motion of (
            1: viewport.setTM ((rotateZMatrix (0.25*i))*N79View)
            2: (local tm=copy N79View;tm.row4+= [i*2.0,0,0];viewport.setTM tm)
            3: viewport.zoom (if mod i 2==0 then 1.01 else (1.0/1.01))
        )
        completeRedraw()
        append results (((N79Watch.GetTimestamp()-started) as double)*1000.0/frequency)
    )
    local totals=for ticks in N79Totals collect ticks*1000.0/frequency
    local result=#(results,N79Callbacks,totals)
    N79SetMode -1
    viewport.setTM N79View;completeRedraw()
    result
)
fn N79Restore = (N79SetMode -1;viewport.setTM N79View;completeRedraw())
)
