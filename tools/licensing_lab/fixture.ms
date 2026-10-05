-- LAB ONLY. Run through run.py in a disposable 3dsmaxbatch process.
-- Script-controlled synthetic policy inputs are NOT a security boundary.
(
    if LLRoot==undefined or LLOut==undefined or LLStage==undefined do throw "Missing isolated lab paths"
    if not matchPattern LLRoot pattern:"*/build/licensing-l0-2026-10-04/*/source/" do throw "Refusing non-lab source"
    if not matchPattern LLOut pattern:"*/build/licensing-l0-2026-10-04/*/" do throw "Refusing non-lab output"
    if findItem #("create","reopen") LLStage==0 do throw "Invalid lab stage"
    global LLLog=createFile (LLOut+LLStage+"/checks.tsv")
    global LLExpected
    global CyrusScatterObject,CyrusSurfaceAnalyzer,CyrusPFData,CyrusPFClear,CyrusEditStackKey
    fn check condition label detail:"" = (
        if not condition do throw (label+": "+detail)
        format "PASS\t%\t%\n" label detail to:LLLog;flush LLLog
    )
    fn observed label detail = (format "OBSERVED\t%\t%\n" label detail to:LLLog;flush LLLog)
    fn permitted operation scenario now state:0 = (cyrusLicenseLabDecide operation scenario now state)[1]
    fn rowsOf layer = layer.placements (layer.validSources())
    fn fingerprint rows = cyrusEditFingerprint rows "licensing-l0"
    -- Checks precede property changes, Undo transactions, cache disposal and
    -- destructive native work. No production methods are replaced here.
    fn setAmount layer value scenario now = (
        if not permitted 5 scenario now do return false
        undo "Lab amount" on (layer.amount=value)
        true
    )
    fn moveFirst modifier delta scenario now = (
        if not permitted 5 scenario now do return false
        undo "Lab CS Edit" on (
            cyrusEditSelect modifier #(1)
            cyrusEditCommand modifier 4 (transMatrix delta)
        )
        true
    )
    fn fillBrush document value scenario now = (
        if not permitted 5 scenario now do return false
        cyrusBrushFill document value
        true
    )
    fn analyze node scenario now = (
        if not permitted 6 scenario now do return false
        node.runAnalysis()
        true
    )
    fn refresh layer scenario now = (
        if not permitted 5 scenario now do return false
        layer.refreshPreview()
        true
    )
    fn renderExisting layer camera filename scenario now baseline = (
        -- Only an assertion about THIS controlled fixture. A hash computed
        -- from public rows is not proof that real scene authoring was licensed.
        local current=rowsOf layer
        check ((fingerprint current)==baseline) "render_fixture_baseline"
        check (permitted 4 scenario now state:1) "render_policy"
        local image=render camera:camera outputwidth:128 outputheight:128 vfb:false
        check (image!=undefined) "render_returned_image"
        local rendered=0
        for data in CyrusPFData do rendered+=data.count
        check (rendered==64) "render_population" detail:(rendered as string)
        image.filename=filename;save image;close image
        CyrusPFClear()
    )
    try (
        local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        local pidFile=createFile (LLOut+LLStage+"/pid.txt")
        format "%" process.Id to:pidFile;close pidFile
        check ((maxVersion())[1]==29000) "host_version" detail:((maxVersion()) as string)
        check ((cyrusLicenseLabIdentity())=="L0 synthetic policy probe 1; NEVER SHIP") "lab_identity"
        check (permitted 5 1 150) "active_policy"
        check (not permitted 5 1 200) "expiry_boundary_policy"
        check (not permitted 5 1 250) "expired_policy"
        check (permitted 5 3 250) "renewed_policy"
        check (not permitted 4 1 250) "unproven_render_rejected"
        check (not permitted 256 1 150 state:1) "unknown_operation_rejected"
        fileIn (LLRoot+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
        fileIn (LLRoot+"AminScatter/scripts/AminScatterObject.ms")
        local node,root,layer,source,surfaceNode,camera,modifier,analyzer
        if LLStage=="create" then (
            resetMaxFile #noPrompt
            surfaceNode=plane name:"LL_Surface" length:200 width:200 lengthsegs:2 widthsegs:2
            surfaceNode.material=standardMaterial diffuse:(color 100 100 100)
            source=box name:"LL_Source" length:3 width:3 height:12 pos:[1000,0,0]
            source.material=standardMaterial diffuse:(color 30 160 70)
            node=CyrusScatterObject name:"LL_Scatter";root=node.baseObject
            root.surfaceNodes=#(surfaceNode);root.updateMode=2;root.viewportMode=1;root.autoRender=false
            root.newLayer();layer=root.layerObjects[1]
            layer.sources=#(source);layer.amount=64;layer.updateMode=2;layer.viewportMode=1
            root.syncLayerSurface layer
            check ((rowsOf layer).count==64) "fixture_population"
            check (setAmount layer 80 1 150) "active_parameter_edit"
            check ((rowsOf layer).count==80) "active_parameter_result"
            max undo
            check (layer.amount==64 and (rowsOf layer).count==64) "parameter_undo"
            modifier=CyrusScatterEdit();addModifier node modifier
            local initial=rowsOf layer
            local initialPosition=initial[1][1].row4
            check (moveFirst modifier [3,4,0] 1 150) "active_native_edit"
            local edited=rowsOf layer
            check (distance edited[1][1].row4 (initialPosition+[3,4,0])<0.001) "native_edit_result"
            max undo
            check (distance (rowsOf layer)[1][1].row4 initialPosition<0.001) "native_edit_undo"
            max redo
            check ((fingerprint(rowsOf layer))==(fingerprint edited)) "native_edit_redo"
            local baseline=fingerprint(rowsOf layer)
            local layerID=layer.layerID,key=layer.editLayerKey
            check (not setAmount layer 128 1 250) "expired_parameter_denied"
            check (not moveFirst modifier [20,0,0] 1 250) "expired_native_edit_denied"
            check (layer.amount==64 and (fingerprint(rowsOf layer))==baseline) "denial_preserves_state"
            check (layer.layerID==layerID and layer.editLayerKey==key) "denial_preserves_identity"
            check (refresh layer 1 150) "active_preview"
            check (layer.previewError=="" and layer.cachedPoints!=undefined) "preview_built"
            local cached=layer.cachedPoints,buildCount=layer.previewBuildCount
            check (not refresh layer 1 250) "expired_refresh_denied"
            check (layer.cachedPoints==cached and layer.previewBuildCount==buildCount) "denial_precedes_cache_cleanup"
            check (root.cyrusEnabled and layer.cyrusEnabled) "artist_enable_unchanged"

            local document=cyrusBrushCreate surfaceNode
            check (fillBrush document 1.0 1 150) "active_brush_fill"
            check (not fillBrush document 0.0 1 250) "expired_brush_denied"
            check ((cyrusBrushStats document)[17]==1.0) "brush_preserved"
            cyrusBrushFill document 0.0
            check ((cyrusBrushStats document)[17]==0.0) "brush_direct_change_observed"
            observed "brush_direct_entry_ungated" "Public native fill bypasses the lab wrapper"
            max undo
            check ((cyrusBrushStats document)[17]==1.0) "brush_undo_while_expired"

            analyzer=CyrusSurfaceAnalyzer name:"LL_Analyzer"
            analyzer.surface=surfaceNode;analyzer.fitRadius=1;analyzer.pointRadius=25
            check (analyze analyzer 1 150) "active_analyzer"
            local runs=analyzer.getAnalysisRuns()
            check (runs>0) "analyzer_calculated"
            check (not analyze analyzer 1 250) "expired_analyzer_denied"
            check (analyzer.getAnalysisRuns()==runs) "analyzer_denial_preserves_runs"
            hide analyzer

            -- Counterexamples: public product entry points have no licensing
            -- integration. Passing these observations proves the wrapper is
            -- insufficient, not that the product is protected.
            local probeSurface=plane name:"LL_ProbeSurface" length:200 width:200 lengthsegs:2 widthsegs:2 pos:[500,0,0]
            probeSurface.renderable=false
            local probeNode=CyrusScatterObject name:"LL_ProbeScatter"
            local probeRoot=probeNode.baseObject
            probeRoot.surfaceNodes=#(probeSurface);probeRoot.autoRender=false;probeRoot.updateMode=2;probeRoot.newLayer()
            local probeLayer=probeRoot.layerObjects[1]
            probeLayer.sources=#(source);probeLayer.amount=64;probeLayer.autoRender=false
            probeRoot.syncLayerSurface probeLayer
            local probeBaseline=fingerprint(rowsOf probeLayer)
            probeLayer.amount=81
            check ((rowsOf probeLayer).count==81) "parameter_escape_observed"
            observed "parameter_entry_ungated" "Changing the parameter then evaluating produces new work"
            probeLayer.amount=64
            local direct=aminScatterTransforms surfaceNode 83 42 1 1.0 1.0 [0,0,0] [0,0,0] [0,0,0] true
            check (direct.count==83) "native_generation_escape_observed"
            observed "generation_entry_ungated" "The native generator cannot infer authoring versus saved evaluation"
            -- Re-evaluate the original base layout before checking its edits.
            check ((fingerprint(rowsOf layer))==baseline) "baseline_after_escape_probes"
            local oldPosition=probeSurface.pos
            probeSurface.pos=oldPosition+[0,0,10]
            local dependent=fingerprint(rowsOf probeLayer)
            observed "surface_dependency" ("layout_changed="+((dependent!=probeBaseline) as string))
            probeSurface.pos=oldPosition
            check ((fingerprint(rowsOf layer))==baseline) "restored_surface_baseline"

            renderers.current=Default_Scanline_Renderer()
            camera=targetCamera name:"LL_Camera" pos:[240,-300,260] target:(targetObject name:"LL_CameraTarget" pos:[0,0,0])
            root.autoRender=true;layer.autoRender=true
            root.layerVisible[1]=false
            renderExisting layer camera (LLOut+"active.png") 1 150 baseline
            renderExisting layer camera (LLOut+"expired-create.png") 1 250 baseline
            LLExpected=#(baseline,layerID,key,64,source.height)
            local expectedFile=createFile (LLOut+"expected.ms")
            with printAllElements on format "global LLExpected=%\n" LLExpected to:expectedFile
            close expectedFile
            check (permitted 2 1 250) "save_policy_while_expired"
            check (saveMaxFile (LLOut+"lab-scene.max") quiet:true) "save_while_expired"
        ) else (
            fileIn (LLOut+"expected.ms")
            check (loadMaxFile (LLOut+"lab-scene.max") quiet:true) "reopen_while_expired"
            node=getNodeByName "LL_Scatter";root=node.baseObject
            layer=(root.layerEntries())[1][2]
            camera=getNodeByName "LL_Camera";source=getNodeByName "LL_Source"
            check (node.modifiers.count==1) "modifier_persisted"
            check (layer.amount==LLExpected[4]) "parameters_persisted"
            check (layer.layerID==LLExpected[2] and layer.editLayerKey==LLExpected[3]) "identities_persisted"
            layer.cachedPoints=undefined;layer.dirty=true
            check ((fingerprint(rowsOf layer))==LLExpected[1]) "cold_evaluation_restores_edits"
            renderExisting layer camera (LLOut+"expired.png") 1 250 LLExpected[1]
            check (not setAmount layer 128 1 250) "reopened_expired_edit_denied"
            -- Hidden layers deliberately cannot be selected by CS Edit.
            -- Restore the ordinary visible editing context before renewal.
            root.layerVisible[1]=true
            CyrusEditStackKey root
            check ((cyrusEditVisibleCount node.modifiers[1])>0) "renewal_visible_edit_context"
            local position=(rowsOf layer)[1][1].row4
            check (moveFirst node.modifiers[1] [5,0,0] 3 250) "renewal_resumes_editing"
            check (distance (rowsOf layer)[1][1].row4 (position+[5,0,0])<0.001) "renewed_result"
            max undo
            check ((fingerprint(rowsOf layer))==LLExpected[1]) "renewal_undo_restores_prior_work"
            -- Dependency semantics need a product decision. Unchanged Cyrus
            -- parameters do not freeze source geometry or animation.
            source.height=LLExpected[5]*2
            check ((fingerprint(rowsOf layer))==LLExpected[1]) "source_edit_keeps_placement_positions"
            observed "source_geometry" "Source height changed while placement fingerprint stayed unchanged"
            renderExisting layer camera (LLOut+"expired-source-changed.png") 1 250 LLExpected[1]
            source.height=LLExpected[5]
        )
        local moduleFile=createFile (LLOut+LLStage+"/modules.tsv")
        for index=0 to process.Modules.Count-1 do (
            local entry=process.Modules.Item[index]
            format "%\t%\n" entry.ModuleName entry.FileName to:moduleFile
        )
        close moduleFile
        format "COMPLETE\n" to:LLLog;close LLLog
    ) catch (
        format "FAIL\t%\n" (getCurrentException()) to:LLLog;close LLLog
        throw()
    )
)
