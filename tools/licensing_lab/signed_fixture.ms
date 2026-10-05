-- Development-only signed-token experiment. No real device/time authority.
(
    if not matchPattern LLRoot pattern:"*/build/licensing-l1-2026-10-04/*/source/" do throw "Refusing non-lab source"
    if not matchPattern LLOut pattern:"*/build/licensing-l1-2026-10-04/*/" do throw "Refusing non-lab output"
    if findItem #("create","reopen") LLStage==0 do throw "Invalid stage"
    global SLLog=createFile (LLOut+LLStage+"/checks.tsv")
    global SLExpected,CyrusScatterObject,CyrusSurfaceAnalyzer,CyrusPFData,CyrusPFClear,CyrusEditStackKey
    fn check value label = (
        if not value do throw label
        format "PASS\t%\n" label to:SLLog;flush SLLog
    )
    fn token name = (
        local stream=openFile (LLOut+"fixtures/"+name+".license")
        local value=readLine stream
        close stream
        value
    )
    fn rowsOf layer = layer.placements (layer.validSources())
    fn fingerprint layer = cyrusEditFingerprint (rowsOf layer) "signed-license-lab"
    fn canAuthor now = (cyrusSignedLabDecide 5 now 0)[1]
    fn moveFirst node delta now = (
        if not canAuthor now do return false
        undo "Signed lab edit" on (
            cyrusEditSelect node.modifiers[1] #(1)
            cyrusEditCommand node.modifiers[1] 4 (transMatrix delta)
        )
        true
    )
    fn renderSaved layer camera path now baseline = (
        check ((fingerprint layer)==baseline) "render_existing_fixture_state"
        -- This is synthetic scene evidence, not a signed scene/provenance check.
        check ((cyrusSignedLabDecide 4 now 1)[1]) "render_continuity_policy"
        local image=render camera:camera outputwidth:128 outputheight:128 vfb:false
        check (image!=undefined) "render_image"
        local count=0
        for data in CyrusPFData do count+=data.count
        check (count==64) "render_population_64"
        image.filename=path;save image;close image
        CyrusPFClear()
    )
    try (
        check ((maxVersion())[1]==29000) "host_2027"
        check ((cyrusSignedLabIdentity())=="Signed license lab 1; NEVER SHIP") "signed_lab_identity"
        fileIn (LLRoot+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
        fileIn (LLRoot+"AminScatter/scripts/AminScatterObject.ms")
        local scene=if LLStage=="create" then "input-scene.max" else "signed-scene.max"
        check (loadMaxFile (LLOut+scene) quiet:true) "disposable_scene_loaded"
        local node=getNodeByName "LL_Scatter",camera=getNodeByName "LL_Camera"
        local root=node.baseObject,layer=(root.layerEntries())[1][2]
        check ((rowsOf layer).count==64) "existing_placements"
        root.layerVisible[1]=true;CyrusEditStackKey root
        cyrusSignedLabReset()
        check (not canAuthor 1800000100) "empty_session_denied"
        check ((cyrusSignedLabInstall (token "tampered"))=="signature") "tampered_grant_rejected"
        check (not canAuthor 1800000100) "tamper_cannot_activate"
        check ((cyrusSignedLabInstall (token "wrong-device"))=="device") "synthetic_wrong_device_rejected"
        check (not canAuthor 1800000100) "wrong_context_cannot_activate"
        check ((cyrusSignedLabInstall (token "active"))=="verified") "signed_grant_imported"
        check (canAuthor 1800000100) "signed_grant_allows_authoring"
        check ((cyrusSignedLabInstall (token "tampered"))=="signature") "bad_replacement_rejected"
        check (canAuthor 1800000100) "bad_replacement_preserves_valid_grant"
        local baseline=fingerprint layer
        if LLStage=="create" then (
            local before=(rowsOf layer)[1][1].row4
            check (moveFirst node [2,0,0] 1800000100) "signed_authoring_admitted"
            check (distance (rowsOf layer)[1][1].row4 (before+[2,0,0])<0.001) "real_native_edit_applied"
            baseline=fingerprint layer
            layer.refreshPreview()
            check (layer.cachedPoints!=undefined and layer.previewError=="") "preview_ready"
            local cache=layer.cachedPoints,builds=layer.previewBuildCount
            check ((cyrusSignedLabDecide 5 1800003600 0)[2]=="expired") "signed_deadline_reached"
            check (not moveFirst node [50,0,0] 1800003600) "expired_wrapper_denied"
            check ((fingerprint layer)==baseline) "expired_denial_preserves_edit"
            check (layer.cachedPoints==cache and layer.previewBuildCount==builds) "expired_denial_preserves_cache"
            check (root.cyrusEnabled and layer.cyrusEnabled) "artist_flags_preserved"
            renderSaved layer camera (LLOut+"signed-active.png") 1800000100 baseline
            renderSaved layer camera (LLOut+"signed-expired.png") 1800003600 baseline
            local direct=aminScatterTransforms (getNodeByName "LL_Surface") 83 42 1 1.0 1.0 [0,0,0] [0,0,0] [0,0,0] true
            check (direct.count==83) "native_boundary_gap_still_observable"
            format "OBSERVED\tdirect_generation_ungated\tSignature validation alone does not enforce product entry points\n" to:SLLog
            SLExpected=#(baseline,layer.layerID,layer.editLayerKey)
            local expectedFile=createFile (LLOut+"signed-expected.ms")
            with printAllElements on format "global SLExpected=%\n" SLExpected to:expectedFile
            close expectedFile
            check (saveMaxFile (LLOut+"signed-scene.max") quiet:true) "save_expired_scene"
        ) else (
            fileIn (LLOut+"signed-expected.ms")
            layer.cachedPoints=undefined;layer.dirty=true
            check ((fingerprint layer)==SLExpected[1]) "cold_saved_edit_retained"
            check (layer.layerID==SLExpected[2] and layer.editLayerKey==SLExpected[3]) "saved_identities_retained"
            check (not canAuthor 1800003700) "reimport_does_not_restart_expired_term"
            renderSaved layer camera (LLOut+"signed-reopened.png") 1800003700 SLExpected[1]
            check ((cyrusSignedLabInstall (token "renewed"))=="verified") "signed_renewal_imported"
            check (canAuthor 1800003700) "signed_renewal_allows_authoring"
            root.layerVisible[1]=true;CyrusEditStackKey root
            local before=(rowsOf layer)[1][1].row4
            check (moveFirst node [5,0,0] 1800003700) "renewed_wrapper_admitted"
            check (distance (rowsOf layer)[1][1].row4 (before+[5,0,0])<0.001) "renewed_native_edit_applied"
            max undo
            check ((fingerprint layer)==SLExpected[1]) "renewed_edit_undo_preserves_scene"
        )
        local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        local modules=createFile (LLOut+LLStage+"/modules.tsv")
        for index=0 to process.Modules.Count-1 do (
            local entry=process.Modules.Item[index]
            format "%\t%\n" entry.ModuleName entry.FileName to:modules
        )
        close modules
        format "COMPLETE\n" to:SLLog;close SLLog
    ) catch (
        format "FAIL\t%\n" (getCurrentException()) to:SLLog;close SLLog
        throw()
    )
)
