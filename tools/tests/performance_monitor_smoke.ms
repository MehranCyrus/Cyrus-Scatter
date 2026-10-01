-- Disposable fixture in a SEPARATE batch process. Never run in an artist's scene.
(
    global AminScatterObject, CyrusSurfaceAnalyzer, CyrusPerfHeadless, AminScatterLayerFields
    global CyrusPerf, CyrusPerfPanel, CSPSettings, CSPSnapshot, CSPStart, CSPStop, CSPObserve, CSPMark, CSPResourcesReady, CSPPreviewStep, CSPQueue, CSPTick
    global CSPTrace,CSPTraceBeginEdit,CSPTraceVisible,CyrusPerfTraceInput,CyrusPerfTraceBegin,CyrusPerfTraceEnd
    global CSPTraceInstallerHeadless,CSPTraceInstaller,CSPInstallTracing,CSPInstallHash
    global CSPText,CSPWriteText
    local root=(dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName()))+"../../")
    local destination=root+"build/performance-monitor-test/"
    makeDir destination all:true
    local log=createFile (destination+"result.txt")
    fn require value reason = (if not value do throw reason)
    try (
        require ((maxVersion())[1]==29000) "Expected Max 2027"
        fileIn (root+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
        fileIn (root+"AminScatter/scripts/AminScatterObject.ms")
        CyrusPerfHeadless=true
        fileIn (root+"tools/performance/CyrusPerformanceMonitor.ms")
        format "PASS monitor compiles\n" to:log;flush log
        local surfaceNode=plane length:1000 width:1000 lengthsegs:2 widthsegs:2
        local sourceNode=box length:10 width:10 height:30 pos:[1500,0,0]
        local controller=AminScatterObject name:"Perf_Smoke_Controller"
        controller.surfaceNodes=#(surfaceNode);controller.updateMode=1
        controller.newLayer()
        local layer=controller.layerObjects[1]
        layer.sources=#(sourceNode);layer.amount=200
        controller.syncLayerSurface layer
        controller.layerNames[1]="Layer, \"quoted\""
        local fieldCount=AminScatterLayerFields.count
        local settingsBefore=CSPSettings controller
        local originalState=layer.cacheSnapshot()
        local rows=CSPSnapshot controller
        require ((CSPSettings controller)==settingsBefore) "Observer changed settings"
        require (AminScatterLayerFields.count==fieldCount) "Observer changed the global field list"
        local observed=layer.cacheSnapshot()
        require (originalState[3]==observed[3] and originalState[6]==observed[6]) "Observer rebuilt or invalidated the preview"
        require (saveMaxFile (destination+"fixture.max") quiet:true) "Could not save test fixture"
        local run=CSPStart controller (destination+"runs") "batch-smoke" "No renderer test" "synthetic_200" "idle" true
        format "RUN %\n" run to:log;flush log
        local readyClock=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
        while not CSPResourcesReady() and readyClock.Elapsed.TotalSeconds<90 do (
            if doesFileExist (run+"/sampler-error.txt") do throw ((dotNetClass "System.IO.File").ReadAllText (run+"/sampler-error.txt"))
            if CyrusPerf.sampler.HasExited do throw "Resource sampler exited before ready"
            sleep 0.2
        )
        require (CSPResourcesReady()) "Resource sampler timeout"
        local nodeCount=objects.count
        CSPQueue 1 3
        while CyrusPerf.queued do (CSPTick();sleep 0.1)
        require (CyrusPerf.durations.count==3 and CyrusPerf.failures==0) CyrusPerf.status
        require ((CSPSnapshot controller)[1][8]==200) "Wrong generated count"
        require (objects.count==nodeCount) "Benchmark created scene nodes"
        local builds=(layer.previewStats())[1]
        CSPObserve "passive"
        require ((layer.previewStats())[1]==builds) "Passive observer rebuilt the preview"
        layer.forcePreviewUpdate()
        CSPObserve "counter_reset"
        require (CyrusPerf.previous[1][6]==0) "Reset was not observed"
        CSPMark "quote \" comma, newline\nUnicode: فارسی"
        sleep 1.2
        CSPStop "smoke_complete"
        local stopClock=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
        while not CyrusPerf.sampler.HasExited and stopClock.Elapsed.TotalSeconds<10 do sleep 0.1
        require (doesFileExist (run+"/sampler-summary.json")) "Sampler did not finish"
        -- Trace synchronous work without a UI timer tick between builds.
        local analyzer=CyrusSurfaceAnalyzer name:"Perf_Trace_Analyzer"
        analyzer.surface=surfaceNode;analyzer.pointRadius=100
        layer.fallAnalyzer=analyzer
        layer.refreshPreview()
        local parity=layer.cacheSnapshot()
        local parityPoints=CSPText (aminScatterPreviewPoints parity[1])
        local traceRun=CSPStart controller (destination+"runs") "trace-smoke" "No renderer test" "synthetic_edit" "idle" false startSampler:false traceEdits:true
        format "TRACE_RUN %\n" traceRun to:log;flush log
        CSPTraceBeginEdit "corner_move"
        require(CSPTrace.edit==1) "First edit ID must be 1"
        CyrusPerfTraceInput "scatter_input_received" #geometryChanged #(getHandleByAnim surfaceNode)
        analyzer.runAnalysis()
        layer.externalChanged #(surfaceNode)
        layer.refreshPreview();layer.refreshPreview()
        local afterTrace=layer.cacheSnapshot()
        require(parity[5]==afterTrace[5] and parity[2]==afterTrace[2]) "Trace changed generated/displayed counts"
        require(parityPoints==CSPText (aminScatterPreviewPoints afterTrace[1])) "Trace changed preview point positions"
        require(findItem CSPTrace.watched sourceNode>0) "Source tab references missing from watch list"
        require(CSPTrace.sequence>=6) "Missing traced nested stages or Analyzer"
        require(CSPTrace.stack.count==0 and CSPTrace.errors==0) "Trace stack/collector error"
        CSPTraceVisible()
        require(CSPTrace.edit==0) "Result visible must close the active edit"
        -- Reusing a label must still produce a distinct ID and report window.
        CSPTraceBeginEdit "corner_move"
        require(CSPTrace.edit==2) "Second edit reused the first ID"
        layer.refreshPreview()
        CSPTraceVisible()
        CSPTraceBeginEdit "undo_extension"
        require(CSPTrace.edit==3) "Third edit ID did not advance"
        layer.refreshPreview()
        CSPTraceVisible()
        -- Work after Result visible belongs to no artist edit.
        layer.refreshPreview()
        CSPStop "smoke_complete"
        require(CyrusPerfTraceBegin==undefined and CyrusPerfTraceEnd==undefined and CyrusPerfTraceInput==undefined) "Trace sinks leaked after stop"
        format "PASS nested trace spans, consecutive builds, input hook, Analyzer, three edit IDs, repeated labels and marker cleanup\n" to:log;flush log
        -- Failure is a measured failure, not a fast successful empty preview.
        layer.surfaceNodes=#();layer.surface=undefined;controller.surfaceNodes=#()
        local failureRun=CSPStart controller (destination+"runs") "failure-smoke" "No renderer test" "missing_surface" "idle" false startSampler:false traceEdits:true
        format "FAILURE_TRACE_RUN %\n" failureRun to:log;flush log
        require (not CSPPreviewStep "measured" 1) "Missing surface was accepted as success"
        require (CyrusPerf.failures==1 and CyrusPerf.durations.count==0) "Failed timing entered successful distribution"
        CSPStop "failure_case_complete"
        createDialog CyrusPerfPanel
        require ((CyrusPerfPanel.numberOrEmpty "1.25")==1.25) "VFB decimal parsing failed"
        require ((CyrusPerfPanel.numberOrEmpty "")==undefined) "Blank VFB value must be unavailable"
        local invalidRejected=false
        try(CyrusPerfPanel.numberOrEmpty "-1")catch(invalidRejected=true)
        require invalidRejected "Negative VFB duration was accepted"
        destroyDialog CyrusPerfPanel
        -- Installer is exercised only against copies under the test folder.
        CSPTraceInstallerHeadless=true
        fileIn(root+"tools/performance/Install-CyrusPerformanceTracing.ms")
        local installRoot=destination+"install-fixture/"
        makeDir (installRoot+"AminScatter") all:true
        makeDir (installRoot+"CyrusSurfaceAnalyzer") all:true
        (dotNetClass "System.IO.File").Copy (root+"build/performance-trace-originals/AminScatterObject.ms") (installRoot+"AminScatter/AminScatterObject.ms") true
        (dotNetClass "System.IO.File").Copy (root+"build/performance-trace-originals/CyrusSurfaceAnalyzer.ms") (installRoot+"CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.ms") true
        local installed=CSPInstallTracing root installRoot
        require(matchPattern installed pattern:"*RESTART MAX*") "Installer did not install fixture"
        require(CSPInstallHash (installRoot+"AminScatter/AminScatterObject.ms")==CSPInstallHash (root+"AminScatter/scripts/AminScatterObject.ms")) "Installer copied wrong Scatter"
        require(matchPattern (CSPInstallTracing root installRoot) pattern:"*already match*") "Installer is not idempotent"
        local scatterHash=CSPInstallHash (installRoot+"AminScatter/AminScatterObject.ms")
        CSPWriteText (installRoot+"CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.ms") "unknown version"
        local rejected=false
        try(CSPInstallTracing root installRoot)catch(rejected=true)
        require(rejected and scatterHash==CSPInstallHash (installRoot+"AminScatter/AminScatterObject.ms")) "Installer did not preflight both files"
        createDialog CSPTraceInstaller
        destroyDialog CSPTraceInstaller
        format "PASS installer backup/copy, idempotence, unknown-version guard and dialog\n" to:log;flush log
        format "PASS passive reads, explicit preview, count parity, reset, failure, exports, sampler and dialog creation\nSUCCESS\n" to:log
        close log
    ) catch (
        local reason=getCurrentException()
        try(CSPStop "smoke_failed")catch()
        format "FAILED: %\n" reason to:log;close log
        throw()
    )
)
