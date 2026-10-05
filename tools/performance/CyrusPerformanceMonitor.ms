-- Standalone, local-only observer and explicit preview benchmark. No plugin install.
-- The rebuild button deliberately invokes the existing refreshDisplay() operation.
global CyrusPerf, CyrusPerfPanel, CyrusPerfHeadless
global AminScatterObject, AminScatterLayerFields, CyrusPFBuilds, CyrusPFProduction, CyrusPFBusy, CoronaRenderer
global CSPToolPath = getSourceFileName()
try (if CyrusPerf != undefined do CSPStop "tool_reloaded") catch ()
try (destroyDialog CyrusPerfPanel) catch ()

struct CSPRunState (
    target, folder="", active=false, clock, observations, operations, events, corona,
    sampler, previous=#(), rowCount=0, durations=#(), failures=0,
    queued=false, warmups=1, repeats=3, step=0, fpsEnabled=false,
    status="Select a Cyrus controller to begin.", caseId="heavy_preview", context="idle"
)
CyrusPerf = CSPRunState()
fileIn ((getFilenamePath CSPToolPath)+"CyrusEditTrace.ms")

fn CSPUtc = ((dotNetClass "System.DateTime").UtcNow.ToString "o")
fn CSPText value = (with printAllElements on (value as string))
fn CSPNumber value = (
    -- MAXScript Double and Integer64 literals have suffixes that JSON/CSV cannot use.
    local s=if classof value==Float or classof value==Double then formattedPrint value format:".17g" else CSPText value
    if classof value==Integer64 do s=substituteString s "L" ""
    substituteString (substituteString s "d" "e") "," "."
)
fn CSPJson value = (
    if value == undefined then "null"
    else if classof value == BooleanClass then (if value then "true" else "false")
    else if isKindOf value Number then CSPNumber value
    else if classof value == Array then (
        local s="["
        for i=1 to value.count do (if i>1 do s+=","; s+=CSPJson value[i])
        s+"]"
    ) else (
        local s=CSPText value
        s=substituteString s "\\" "\\\\"
        s=substituteString s "\"" "\\\""
        s=substituteString s "\r" "\\r"
        s=substituteString s "\n" "\\n"
        s=substituteString s "\t" "\\t"
        "\""+s+"\""
    )
)
fn CSPObject pairs = (
    local s="{"
    for i=1 to pairs.count do (
        if i>1 do s+=","
        s+=(CSPJson pairs[i][1])+":"+(CSPJson pairs[i][2])
    )
    s+"}"
)
fn CSPWriteText path value = (
    (dotNetClass "System.IO.File").WriteAllText path value (dotNetObject "System.Text.UTF8Encoding" false)
)
fn CSPWriter path header = (
    local w=dotNetObject "System.IO.StreamWriter" path false (dotNetObject "System.Text.UTF8Encoding" false)
    w.AutoFlush=true; w.WriteLine header; w
)
fn CSPRow writer values = (
    local s=""
    for i=1 to values.count do (
        if i>1 do s+=","
        local v=if values[i]==undefined then "" else CSPText values[i]
        if isKindOf values[i] Number do v=CSPNumber values[i]
        s+="\""+(substituteString v "\"" "\"\"")+"\""
    )
    writer.WriteLine s
)
fn CSPIsTarget node = (
    try (
        isValidNode node and AminScatterObject!=undefined and classof node.baseObject==AminScatterObject
    ) catch (false)
)
fn CSPElapsed = (if CyrusPerf.clock==undefined then 0.0 else CyrusPerf.clock.Elapsed.TotalMilliseconds)
fn CSPMark text = (
    if CyrusPerf.active do CSPRow CyrusPerf.events #(CSPUtc(),CSPElapsed(),text)
)
fn CSPSettings node = (
    -- Direct parameter reads only: layerEntries/allStatus would synchronize and mutate caches.
    local r=node.baseObject
    local keys=#(#cyrusEnabled,#surfaceNodes,#surface,#viewportMode,#proxyShape,#viewportInstances,#viewportFaces,#previewBudget,#showPoints,#pointsPerPlant,#updateMode,#showCenters,#autoRender,#layerEnabled,#layerNames)
    local pairs=#()
    for k in keys where isProperty r k do append pairs #("root."+(k as string),CSPText (getProperty r k))
    local layerKeys=if AminScatterLayerFields==undefined then #(#amount,#randomSeed,#sources) else (copy AminScatterLayerFields #noMap)
    join layerKeys #(#viewportMode,#proxyShape,#viewportInstances,#viewportFaces,#strokeSides,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceNodes,#strokeMin,#strokeMax,#analyzerNode,#surfaceNodes)
    for i=1 to r.layerObjects.count do (
        local obj=r.layerObjects[i]
        for k in layerKeys where isProperty obj k do append pairs #("layer."+(i as string)+"."+(k as string),CSPText (getProperty obj k))
    )
    CSPObject pairs
)
fn CSPSnapshot node = (
    local r=node.baseObject; local rows=#()
    for i=1 to r.layerObjects.count do (
        local layer=r.layerObjects[i]
        local state=layer.cacheSnapshot()
        local cache=layer.blockerCacheStats()
        local enabled=r.cyrusEnabled and i<=r.layerEnabled.count and r.layerEnabled[i]
        local label=if i<=r.layerNames.count then r.layerNames[i] else ("Layer "+i as string)
        -- Never retain state[1], the native preview cache, in the monitor or export.
        append rows #(i,label,enabled,state[3],state[4],state[6],state[7],state[5],state[8],state[2],
            (if layer.viewportMode==1 then "points" else "shown_instances"),cache[1],cache[2],state[9])
        state=undefined
    )
    rows
)
fn CSPOutputSignature rows = (
    CSPJson (for r in rows where r[3] collect #(r[1],r[8],r[9],r[10],r[11],r[14]))
)
fn CSPObserve phase fps:false = (
    if not CSPIsTarget CyrusPerf.target do throw "The selected Cyrus controller is no longer available."
    local rows=CSPSnapshot CyrusPerf.target
    local rate=if fps then (try(viewport.GetFPS())catch(undefined)) else undefined
    local pf=try(CyrusPFBuilds)catch(undefined)
    for r in rows do (
        local previous=if r[1]<=CyrusPerf.previous.count then CyrusPerf.previous[r[1]] else undefined
        local delta=undefined; local reset=false
        if previous!=undefined do (
            if r[6]>=previous[6] then delta=r[6]-previous[6] else reset=true
        )
        CSPRow CyrusPerf.observations (join #(CSPUtc(),CSPElapsed(),phase) (join (copy r #noMap) #(delta,reset,rate,pf)))
        CyrusPerf.rowCount+=1
    )
    CyrusPerf.previous=rows
    rows
)
fn CSPStop reason = (
    if CyrusPerf.active do (
        CyrusPerf.queued=false
        CSPTraceStop()
        CSPMark ("stop: "+reason)
        CSPWriteText (CyrusPerf.folder+"/stop.request") reason
        for w in #(CyrusPerf.observations,CyrusPerf.operations,CyrusPerf.events,CyrusPerf.corona) where w!=undefined do try(w.Dispose())catch()
        local values=sort (copy CyrusPerf.durations #noMap)
        local med=undefined; local tail=undefined
        if values.count>0 do (
            local mid=(floor(values.count/2.0)) as integer
            med=if mod values.count 2==0 then (values[mid]+values[mid+1])/2.0 else values[mid+1]
            if values.count>=20 do tail=values[(ceil(0.95*values.count)) as integer]
        )
        CSPWriteText (CyrusPerf.folder+"/summary.json") (CSPObject #(
            #("schema_version",1),#("stop_reason",reason),#("successful_measured_operations",values.count),
            #("failed_operations",CyrusPerf.failures),#("median_ms",med),#("p95_ms",tail),
            #("p95_minimum_samples",20),#("resource_summary","sampler-summary.json")))
        CyrusPerf.active=false
        CyrusPerf.status="Saved "+(values.count as string)+" measured rebuilds. "+(if med==undefined then "" else "Median: "+(formattedPrint med format:".1f")+" ms.")
    )
)
fn CSPStart target outputRoot label rendererNote caseId context frozenCopy startSampler:true recordFPS:false traceEdits:false = (
    if CyrusPerf.active do throw "Stop the current recording first."
    if not CSPIsTarget target do throw "Select one Cyrus Scatter controller first."
    if target.baseObject.layerObjects.count==0 do throw "This controller has no layers to measure."
    local proc=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    local tag=(dotNetClass "System.DateTime").UtcNow.ToString "yyyyMMdd-HHmmss"
    local id=((dotNetClass "System.Guid").NewGuid()).ToString "N"
    local dir=(dotNetClass "System.IO.Path").GetFullPath (outputRoot+"/"+tag+"-"+(substring id 1 8))
    (dotNetClass "System.IO.Directory").CreateDirectory dir
    CyrusPerf=CSPRunState target:target folder:dir caseId:caseId context:context fpsEnabled:recordFPS
    local scene=if maxFileName=="" then "" else maxFilePath+maxFileName
    local userScript=(getDir #userScripts)+"/AminScatter/AminScatterObject.ms"
    local viewportInfo=#(try(viewport.getType() as string)catch("unknown"),try(viewport.GetRenderLevel() as string)catch("unknown"),
        try(gw.getWinSizeX())catch(0),try(gw.getWinSizeY())catch(0),try(viewport.getTM() as string)catch("unknown"))
    local manifest=CSPObject #(
        #("schema_version",1),#("tool_version","0.2.2"),#("tool_path",CSPToolPath),#("edit_trace_requested",traceEdits),
        #("cpu_thread_request",try(cyrusScatterCPUThreads())catch(undefined)),
        #("native_source_filter",try(cyrusFilterSourceRows!=undefined)catch(false)),
        #("native_source_transforms",try(cyrusApplySourceTransforms!=undefined)catch(false)),
        #("callback_batch_stats_at_start",try(CyrusScatterLiveBatchStats())catch(undefined)),
        #("started_utc",CSPUtc()),#("pid",proc.Id),#("process_start_utc",(proc.StartTime.ToUniversalTime()).ToString "o"),
        #("build_label",label),#("case_id",caseId),#("context",context),#("renderer_build_note",rendererNote),
        #("scene_path",scene),#("scene_dirty",getSaveRequired()),#("frozen_copy_attested",frozenCopy),
        #("max_version",maxVersion()),#("renderer_class",classof renderers.current as string),
        #("corona_version",try(CoronaRenderer.CoronaFp.getVersionString())catch(undefined)),
        #("controller_name",target.name),#("controller_handle",target.handle),
        #("units",#(units.SystemType as string,units.SystemScale,units.decodeValue "1m")),
        #("frame",currentTime as string),#("viewport",viewportInfo),#("settings",CSPSettings target),
        #("script_candidates",#(userScript,(getDir #userScripts)+"/CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.ms")),#("sampler_requested",startSampler),
        #("trace_tool_path",(getFilenamePath CSPToolPath)+"CyrusEditTrace.ms"),
        #("reported_fps_opt_in",recordFPS),
        #("timing_scope","refreshDisplay call: layer synchronization, preview rebuilds and redraw submission; not completed GPU frames"))
    CSPWriteText (dir+"/manifest.json") manifest
    try (
        CyrusPerf.observations=CSPWriter (dir+"/observations.csv") "utc,elapsed_ms,phase,layer_index,layer_name,enabled,dirty,error,build_count,last_preview_ms,generated,requested,display_count,display_unit,blocker_builds,blocker_hits,density_capped,observed_build_delta,counter_reset,reported_fps,pflow_builds"
        CyrusPerf.operations=CSPWriter (dir+"/operations.csv") "utc,elapsed_ms,operation,phase,iteration,duration_ms,success,error,output_signature,settings_before,settings_after"
        CyrusPerf.events=CSPWriter (dir+"/events.csv") "utc,elapsed_ms,note"
        CyrusPerf.corona=CSPWriter (dir+"/corona.csv") "utc,elapsed_ms,label,scene_parsing_s,geometry_s,rendering_s,passes,noise_percent,note"
        CyrusPerf.clock=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
        CyrusPerf.active=true
        if traceEdits do CSPTraceStart target
        CSPObserve "recording_start"
        if startSampler do (
            local helper=(getFilenamePath CSPToolPath)+"Measure-CyrusProcess.ps1"
            if not doesFileExist helper do throw "Keep Measure-CyrusProcess.ps1 beside this script."
            local startInfo=dotNetObject "System.Diagnostics.ProcessStartInfo"
            startInfo.FileName=((dotNetClass "System.Environment").GetEnvironmentVariable "SystemRoot")+"/System32/WindowsPowerShell/v1.0/powershell.exe"
            startInfo.Arguments="-NoLogo -NoProfile -NonInteractive -File \""+helper+"\" -SessionDir \""+dir+"\""
            startInfo.UseShellExecute=false; startInfo.CreateNoWindow=true
            startInfo.WindowStyle=(dotNetClass "System.Diagnostics.ProcessWindowStyle").Hidden
            CyrusPerf.sampler=(dotNetClass "System.Diagnostics.Process").Start startInfo
        )
        CyrusPerf.status=if startSampler then "Preparing file fingerprints and resource recorder..." else "Recording (resource recorder disabled)."
        dir
    ) catch (
        local reason=getCurrentException(); CSPStop ("start_failed: "+reason); throw()
    )
)
fn CSPResourcesReady = (
    if CyrusPerf.sampler==undefined then true else doesFileExist (CyrusPerf.folder+"/sampler.ready")
)
fn CSPRenderActive = (
    (try(CyrusPFProduction==true or CyrusPFBusy==true)catch(false)) or (try(CoronaRenderer.CoronaFp.getRenderType()!=0)catch(false))
)
fn CSPPreviewStep phase iteration = (
    if not CyrusPerf.active do throw "Start recording first."
    if not CSPResourcesReady() do throw "The resource recorder is still preparing."
    if not CSPIsTarget CyrusPerf.target do throw "The selected Cyrus controller was deleted."
    if CSPRenderActive() do throw "Stop rendering/IR before the controlled rebuild test."
    local before=CSPSnapshot CyrusPerf.target
    if (for r in before where r[3] collect r).count==0 do throw "Enable at least one Cyrus layer."
    local settingsBefore=CSPSettings CyrusPerf.target
    local timer=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
    local error=""
    try(CyrusPerf.target.baseObject.refreshDisplay())catch(error=getCurrentException())
    timer.Stop()
    local duration=timer.Elapsed.TotalMilliseconds
    local after=CSPObserve phase
    local settingsAfter=CSPSettings CyrusPerf.target
    for r in after where r[3] do (
        if r[5]!="" do error+=r[2]+": "+r[5]+"; "
        if r[4] do error+=r[2]+": cache still dirty; "
        if r[6]==0 do error+=r[2]+": preview was not built; "
    )
    if phase=="measured" and settingsBefore!=settingsAfter do error+="Settings changed during the operation. "
    local ok=error==""
    CSPRow CyrusPerf.operations #(CSPUtc(),CSPElapsed(),"controller_refreshDisplay",phase,iteration,duration,ok,error,CSPOutputSignature after,settingsBefore,settingsAfter)
    if phase=="measured" and ok then append CyrusPerf.durations duration
    if not ok do CyrusPerf.failures+=1
    CyrusPerf.status=(if ok then "" else "FAILED: ")+(formattedPrint duration format:".1f")+" ms | "+phase+" "+(iteration as string)+(if ok then "" else " | "+error)
    ok
)
fn CSPQueue warmups repeats = (
    if not CyrusPerf.active do throw "Start recording first."
    if not CSPResourcesReady() do throw "Wait until the resource recorder is ready."
    if warmups<1 or warmups>10 or repeats<1 or repeats>100 do throw "Use 1-10 warmups and 1-100 measured runs."
    if CyrusPerf.context!="idle" do throw "Start a separate idle recording for controlled preview tests."
    if CyrusPerf.queued do throw "A rebuild test is already running."
    if CSPRenderActive() do throw "Stop rendering/IR first."
    CyrusPerf.warmups=warmups; CyrusPerf.repeats=repeats; CyrusPerf.step=0; CyrusPerf.queued=true
    CSPMark ("queued "+(warmups as string)+" warmups and "+(repeats as string)+" measured preview rebuilds")
)
fn CSPTick = (
    if not CyrusPerf.active do return false
    CSPTraceFlush()
    if CSPElapsed()>1800000 or CyrusPerf.rowCount>=60000 do (CSPStop "recording_limit"; return false)
    if not CSPIsTarget CyrusPerf.target do (CSPStop "target_removed_or_scene_changed"; return false)
    if CyrusPerf.sampler!=undefined do (
        if doesFileExist (CyrusPerf.folder+"/sampler-error.txt") do (
            CSPStop "resource_sampler_failed"; CyrusPerf.status="Resource recorder failed. See sampler-error.txt in the results folder."; return false
        )
        if CyrusPerf.sampler.HasExited do (
            CSPStop "resource_sampler_exited"; CyrusPerf.status="Resource recorder stopped. Check sampler-summary.json, or PowerShell policy if it is missing."; return false
        )
        if not CSPResourcesReady() do return true
    )
    if CyrusPerf.queued then (
        CyrusPerf.step+=1
        local phase=if CyrusPerf.step<=CyrusPerf.warmups then "warmup" else "measured"
        local index=if phase=="warmup" then CyrusPerf.step else CyrusPerf.step-CyrusPerf.warmups
        if not CSPPreviewStep phase index do CyrusPerf.queued=false
        if CyrusPerf.step>=CyrusPerf.warmups+CyrusPerf.repeats do (
            CyrusPerf.queued=false; CSPMark "preview test complete"
            CyrusPerf.status+=" | Test complete. Stop & save when finished."
        )
    ) else (
        CSPObserve "passive" fps:CyrusPerf.fpsEnabled
        if matchPattern CyrusPerf.status pattern:"Preparing*" do CyrusPerf.status="Recording. You can run the preview test or edit normally."
    )
    true
)

rollout CyrusPerfPanel "Cyrus Performance - baseline recorder" width:490 height:850 (
    local chosen
    label intro "1. Open a saved test copy and select its Cyrus controller." align:#left
    button choose "Use selected Cyrus controller" width:250 across:2
    label targetLabel "No controller selected" width:210
    edittext buildLabel "Build label:" text:"baseline-current" fieldWidth:360
    edittext caseLabel "Test case:" text:"heavy_preview" fieldWidth:360
    edittext rendererLabel "Renderer/build:" text:(try(CoronaRenderer.CoronaFp.getVersionString())catch("Corona 15 (enter exact build)")) fieldWidth:360
    dropdownlist contextLabel "Activity:" items:#("idle","interactive_rendering","production_rendering") selection:1
    checkbox frozen "Saved test copy matches the current scene settings" checked:false
    checkbox detailed "Detailed edit tracing (requires tracing scripts + Max restart)" checked:true
    edittext outDir "Results:" text:((getFilenamePath CSPToolPath)+"../../build/performance-runs") fieldWidth:380
    button start "2. Start recording" width:220 across:2
    button stop "Stop & save" width:220
    group "Controlled preview test - leave the scene unchanged while running" (
        checkbox safeTest "Test copy open; rendering and IR are stopped" checked:false
        spinner warm "Warmups:" type:#integer range:[1,10,1] fieldWidth:45 across:2
        spinner repeat "Measured runs:" type:#integer range:[1,100,3] fieldWidth:45
        button rebuild "3. Run preview rebuild test" width:280 across:2
        button cancel "Cancel next runs" width:150
        label scope "Times preview building + redraw submission; excludes completed GPU frames." align:#left
        label stopHint "Cancel takes effect between rebuilds. A heavy rebuild can block Max's UI." align:#left
    )
    edittext note "Event note:" fieldWidth:300 across:2
    button mark "Mark" width:55
    edittext editName "Edit name:" text:"corner_move" fieldWidth:350
    button beginEdit "Begin named edit" width:220 across:2
    button resultSeen "Result visible" width:220
    button watchEdit "Watch selected edit object" width:220
    checkbox fps "Record reported FPS (I enabled Statistics and disabled Adaptive Degradation)" checked:false
    label metric "Last preview builds: -" align:#left width:470 height:40
    label resource "Process resources: available after recording starts." align:#left width:470 height:32
    label state "Ready. Recording does not start rendering." align:#left width:470 height:48
    group "Optional Corona VFB Stats - copy values after your own render" (
        edittext parse "Scene parsing (s):" fieldWidth:65 across:2
        edittext geom "Geometry (s):" fieldWidth:65
        edittext rendering "Rendering (s):" fieldWidth:65 across:2
        edittext passes "Passes:" fieldWidth:65
        edittext noise "Noise (%):" fieldWidth:65 across:2
        button saveCorona "Record VFB values" width:210
        label coronaHint "Leave unavailable fields blank. These are whole-scene renderer measurements." align:#left
    )
    button folder "Open results folder" width:220
    timer pulse interval:500 active:true
    fn reportFailure = (state.text=getCurrentException())
    fn updateControls = (
        for control in #(choose,buildLabel,caseLabel,rendererLabel,contextLabel,frozen,detailed,outDir,start,fps) do control.enabled=not CyrusPerf.active
        stop.enabled=CyrusPerf.active
        rebuild.enabled=CyrusPerf.active and not CyrusPerf.queued
        cancel.enabled=CyrusPerf.queued
        beginEdit.enabled=CyrusPerf.active and CSPTrace.active and CSPResourcesReady()
        resultSeen.enabled=beginEdit.enabled
        watchEdit.enabled=beginEdit.enabled
        saveCorona.enabled=CyrusPerf.active
    )
    fn numberOrEmpty text = (
        if text=="" then undefined else (
            local v=(dotNetClass "System.Double").Parse text (dotNetClass "System.Globalization.CultureInfo").InvariantCulture
            if v<0 or (dotNetClass "System.Double").IsNaN v or (dotNetClass "System.Double").IsInfinity v do throw "Enter a finite nonnegative number, or leave it blank."
            v
        )
    )
    on choose pressed do try (
        if CyrusPerf.active do throw "Stop recording before changing controllers."
        if selection.count!=1 or not CSPIsTarget selection[1] do throw "Select exactly one Cyrus Scatter controller."
        chosen=selection[1]; targetLabel.text=chosen.name
    ) catch (reportFailure())
    on start pressed do try (
        CSPStart chosen outDir.text buildLabel.text rendererLabel.text caseLabel.text contextLabel.selected frozen.checked recordFPS:fps.checked traceEdits:detailed.checked
        state.text=CyrusPerf.status
    ) catch (reportFailure())
    on stop pressed do try(CSPStop "user_stopped";state.text=CyrusPerf.status)catch(reportFailure())
    on rebuild pressed do try (
        if not safeTest.checked do throw "Confirm the test-copy/render-stopped checkbox first."
        if contextLabel.selection!=1 do throw "Use an idle recording for the controlled preview test."
        CSPQueue warm.value repeat.value
    ) catch(reportFailure())
    on cancel pressed do (CyrusPerf.queued=false;CSPMark "remaining test runs cancelled";CyrusPerf.status="Cancelled remaining runs; recording continues.")
    on mark pressed do (CSPMark note.text)
    on beginEdit pressed do try(CSPTraceBeginEdit editName.text;state.text="Edit marked. Make one change, wait, then click Result visible.")catch(reportFailure())
    on resultSeen pressed do try(CSPTraceVisible();state.text="Result marked. Ready for the next named edit.")catch(reportFailure())
    on watchEdit pressed do try (
        if not CSPTrace.active do throw "Start detailed tracing first."
        for node in selection do CSPTraceWatch node
        CSPMark ("Watch edit selection: "+CSPText (for n in selection collect n.name))
        state.text="Selected nodes added to the input-event watch list."
    )catch(reportFailure())
    on fps changed checked do (CyrusPerf.fpsEnabled=checked; CSPMark ("reported FPS opt-in: "+checked as string))
    on saveCorona pressed do try (
        if not CyrusPerf.active do throw "Start recording first."
        local values=#(numberOrEmpty parse.text,numberOrEmpty geom.text,numberOrEmpty rendering.text,numberOrEmpty passes.text,numberOrEmpty noise.text)
        if (for v in values where v!=undefined collect v).count==0 do throw "Enter at least one VFB statistic."
        CSPRow CyrusPerf.corona (join #(CSPUtc(),CSPElapsed(),caseLabel.text) (join values #(note.text)))
        CSPMark "manual VFB statistics recorded"; state.text="VFB statistics saved."
    ) catch(reportFailure())
    on folder pressed do (if CyrusPerf.folder!="" do shellLaunch CyrusPerf.folder "")
    on pulse tick do (
        if CyrusPerf.active do try (
            CSPTick(); state.text=CyrusPerf.status
            local lines=""
            for r in CyrusPerf.previous where r[3] do lines+=r[2]+": "+(r[7] as string)+" ms, "+(r[8] as string)+" generated, "+(r[10] as string)+" "+r[11]+"; "
            metric.text=lines
            local live=CyrusPerf.folder+"/live.txt"
            if doesFileExist live do try(resource.text=(dotNetClass "System.IO.File").ReadAllText live)catch()
        ) catch (local reason=getCurrentException();try(CSPStop ("error: "+reason))catch();state.text=reason)
        updateControls()
    )
    on CyrusPerfPanel close do (CSPStop "panel_closed")
)
if CyrusPerfHeadless!=true do createDialog CyrusPerfPanel
