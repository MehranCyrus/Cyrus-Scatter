-- Definitions for the owned visible real-asset qualification host only.
-- Original artist scene/profile must never be modified by this fixture.
global Real073Node,Real073Root,Real073Plants,Real073Parents,Real073Out
global Real073StressNode,Real073StressRoot,Real073StressLeaf,Real073ResourceRows=#()
global Real073Find,Real073Sample,Real073Raise,Real073Stress,Real073Navigate,Real073Car
fn Real073Find = (
    if findString MCPFixtureDir "/real073-"==undefined do throw "Owned real-asset host required"
    Real073Node=getNodeByName "CYRUS 0.73 | Heavy garden - unified workflow"
    if not isValidNode Real073Node do throw "Fresh unified garden not loaded"
    Real073Root=Real073Node.baseObject
    Real073Parents=Real073Root.logicalLayers()
    Real073Out=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/Cyrus_073_Qualification/"
    Real073Plants=for name in #("crp_MT_PM_V33_Myrtle_01_003","crp_MT_PM_Rosa_rugosa_01_02","crp_MT_PM_Sambucus_nigra_02_01","MT_PM_V41_Arthropodium_01_01","MT_PM_V41_Arthropodium_01_04","crp_Lavander_01","crp_Lavander_05","crp_MT_PM_V33_Glossy_abelia_01_006","MT_PM_V41_Geranium_robertianum_01_04","MT_PM_V41_Lamium_maculatum_01_04","MT_PM_V41_Phlox_stolonifera_01_01","MT_PM_V41_Viola_sororia_01_05","clover_pack_004","grass_bush","grass_small") collect getNodeByName name
    for model in Real073Plants where not isValidNode model do throw "Plant source missing"
    true
)
fn Real073Sample node label durationMs:0.0 = (
    local root=node.baseObject,view=CyrusPointOwner node,process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    process.Refresh()
    local slots=#()
    for i=1 to root.layerObjects.count do (
        local leaf=root.layerObjects[i],sources=if i<=root.procPublishedSources.count then root.procPublishedSources[i] else #(),counts=for source in sources collect 0
        if i<=root.groupSnapshotRows.count do for row in root.groupSnapshotRows[i] do counts[row[2]]+=1
        append slots #(leaf.layerID,leaf.paintSetName,for j=1 to sources.count collect #(sources[j].name,counts[j]))
    )
    local row=#(#("label",label),#("duration_ms",durationMs),#("epoch",root.procEpoch),#("calculation_model",root.calculationModel()),#("requested_layers",for parent in root.logicalLayers() collect parent.amount),#("accepted",for leaf in root.layerObjects collect leaf.generatedCount),#("shown",for leaf in root.layerObjects collect leaf.cachedPointCount),#("shown_unit",if root.viewportMode==1 then "points" else "instances"),#("prepared_builds",for leaf in root.layerObjects collect leaf.procPreparedBuilds),#("preview_builds",for leaf in root.layerObjects collect leaf.previewBuildCount),#("sources",slots),#("container_counters",for leaf in root.layerObjects collect #(leaf.containerScans,leaf.containerTests,leaf.containerMembershipBuilds)),#("retained",if isValidNode view then cyrusRetainedStats view else #()),#("retained_mesh",if isValidNode view then cyrusRetainedMeshStats view else #()),#("host_private_bytes",process.PrivateMemorySize64),#("host_working_bytes",process.WorkingSet64),#("host_peak_working_bytes",process.PeakWorkingSet64),#("errors",for leaf in root.layerObjects collect leaf.previewError))
    append Real073ResourceRows row
    local stream=stringStream "["
    for i=1 to Real073ResourceRows.count do format "% %" (if i>1 then "," else "") (CSPObject Real073ResourceRows[i]) to:stream
    format "]" to:stream
    CSPWriteText (MCPFixtureDir+"real-load-stages.json") (stream as string)
    CSPWriteText (MCPFixtureDir+label+".json") (CSPObject row)
    true
)
fn Real073Raise population = (
    Real073Find()
    local root=Real073Root,parent=Real073Parents[5],timer=dotNetObject "System.Diagnostics.Stopwatch"
    root.updateMode=1;parent.amount=population;Real073Parents[4].amount=30000
    timer.Start();root.refreshAll();timer.Stop()
    for leaf in root.layerObjects where leaf.previewError!="" do throw leaf.previewError
    Real073Sample Real073Node ("garden_"+population as string) durationMs:timer.Elapsed.TotalMilliseconds
    true
)
fn Real073Stress population = (
    Real073Find()
    if not isValidNode Real073StressNode do (
        local receiver=plane name:"QUALIFICATION | 100 metre stress field" width:10000 length:10000 widthsegs:4 lengthsegs:4 pos:[-12500,0,0]
        Real073StressNode=AminScatterObject name:"CYRUS 0.73 | 100k real-plant stress field" pos:[-17700,-5100,0]
        Real073StressRoot=Real073StressNode.baseObject
        local root=Real073StressRoot
        root.autoRender=false;root.updateMode=1;root.surfaceNodes=#(receiver);root.pointsPerPlant=3;root.previewBudget=300000
        root.viewportInstances=100000;root.viewportFaces=20000000;root.viewportMode=1
        root.newLayer();Real073StressLeaf=root.selectedLayer();root.layerNames=#("100k plants | deliberately bounded viewport")
        Real073StressLeaf.sources=Real073Plants as array
        -- Every supplied plant participates. Higher ground-cover share makes
        -- this a realistic mixed planting; report exact source counts.
        Real073StressLeaf.sourceScales=for source in Real073Plants collect 1.0
        Real073StressLeaf.paintEnabled=false;Real073StressLeaf.randomSeed=7307
        Real073StressLeaf.procSelfOverride=true;Real073StressLeaf.procSelfEnabled=false
        hide Real073Node
        viewport.setType #view_persp_user
        local eye=[-4200,-6400,6100],target=[-12500,0,0],look=normalize(target-eye),right=normalize(cross look [0,0,1]),up=cross right look
        viewport.setTM (inverse(matrix3 right up (-look) eye))
        clearSelection();max create mode
    )
    -- Source shares use the public 0..1 domain. Normalize relative weights,
    -- preserving their intended ratio without bypassing the native validator.
    Real073StressRoot.viewportFaces=20000000
    Real073StressLeaf.sourceWeights=for share in #(.3,.3,.3,.6,.6,.4,.4,.3,1,1,1,1,12,20,30) collect share/30.0
    local timer=dotNetObject "System.Diagnostics.Stopwatch"
    Real073StressLeaf.amount=population;timer.Start();Real073StressRoot.refreshAll();timer.Stop()
    Real073Sample Real073StressNode ("stress_"+population as string) durationMs:timer.Elapsed.TotalMilliseconds
    if Real073StressLeaf.generatedCount!=population or Real073StressLeaf.previewError!="" do throw ("Stress field did not publish the complete requested population: "+Real073StressLeaf.generatedCount as string+" / "+population as string+"; "+Real073StressLeaf.previewError)
    true
)
fn Real073Navigate node label frames:40 modes:#(0,1,2,3,4) = (
    local root=node.baseObject,baseTM=viewport.getTM(),timer=dotNetObject "System.Diagnostics.Stopwatch",trials=#()
    root.updateMode=2
    timer.Start()
    for mode in modes do (
        root.showPoints=(mode!=0)
        if mode==0 do root.groupCenters=false
        if mode!=0 do root.setGroupDisplay mode
        root.refreshDisplay()
        CyrusViewportRedraw()
        for warm=1 to 8 do (completeRedraw();windows.processPostedMessages())
        for leaf in root.layerObjects where leaf.previewError!="" do throw leaf.previewError
        local before=#(root.procEpoch,for leaf in root.layerObjects collect #(leaf.procPreparedBuilds,leaf.previewBuildCount,leaf.containerScans,leaf.containerTests,leaf.containerMembershipBuilds))
        local owner=CyrusPointOwner node,retained=if isValidNode owner then cyrusRetainedStats owner else #(),mesh=if isValidNode owner then cyrusRetainedMeshStats owner else #()
        local timings=#(),beginQpc=(dotNetClass "System.Diagnostics.Stopwatch").GetTimestamp() as double/(dotNetClass "System.Diagnostics.Stopwatch").Frequency*1000.0
        for frame=1 to frames do (
            local start=timer.Elapsed.TotalMilliseconds
            viewport.setTM ((rotateZMatrix (3.0*sin(frame*7.0)))*baseTM)
            completeRedraw();windows.processPostedMessages()
            append timings (timer.Elapsed.TotalMilliseconds-start)
        )
        local endQpc=(dotNetClass "System.Diagnostics.Stopwatch").GetTimestamp() as double/(dotNetClass "System.Diagnostics.Stopwatch").Frequency*1000.0
        local after=#(root.procEpoch,for leaf in root.layerObjects collect #(leaf.procPreparedBuilds,leaf.previewBuildCount,leaf.containerScans,leaf.containerTests,leaf.containerMembershipBuilds))
        local now=if isValidNode owner then cyrusRetainedStats owner else #()
        if after as string!=before as string do throw "Navigation rebuilt placements, preview or container membership"
        if retained.count>0 do for k in #(3,4,5,6,7,9) where retained[k]!=now[k] do throw "Navigation rebuilt or uploaded unchanged retained buffers"
        append trials #(#("mode",mode),#("actual_layer_modes",for leaf in root.layerObjects collect leaf.uiPreviewMode),#("preview_faces",for leaf in root.layerObjects collect cyrusPreviewFaces leaf.cachedPoints),#("errors",for leaf in root.layerObjects collect leaf.previewError),#("begin_qpc_ms",beginQpc),#("end_qpc_ms",endQpc),#("step_ms",timings),#("accepted",for leaf in root.layerObjects collect leaf.generatedCount),#("shown",for leaf in root.layerObjects collect leaf.cachedPointCount),#("retained_before",retained),#("retained_after",now),#("mesh",mesh),#("unchanged_placement_preview_membership_upload",true))
        -- Pair arrays keep native values without embedding escaped JSON text.
        CSPWriteText (MCPFixtureDir+label+"-navigation.json") (CSPObject #(#("label",label),#("metric","synchronous viewport.setTM / completeRedraw / posted messages; not presented FPS"),#("viewport",#(gw.getWinSizeX(),gw.getWinSizeY())),#("trials",trials)))
    )
    timer.Stop();viewport.setTM baseTM
    true
)
fn Real073Car = (
    local car=getNodeByName "QUALIFICATION | unrelated animated car"
    if not isValidNode car do (
        car=box name:"QUALIFICATION | unrelated animated car" width:160 length:350 height:125 pos:[2000,-1700,65] wirecolor:(color 160 30 20)
        with animate on (at time 0 car.pos=[2000,-1700,65];at time 100 car.pos=[2000,1700,65])
    )
    car
)
Real073Find()
