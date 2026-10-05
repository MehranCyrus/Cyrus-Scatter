-- NEVER SHIP: native count/seed ownership, real CS Edit, disposable rendering.
(
    if not matchPattern LLRoot pattern:"*/build/licensing-native-20261005/*/source/" do throw "Refusing non-lab source"
    if not matchPattern LLOut pattern:"*/build/licensing-native-20261005/*/" do throw "Refusing non-lab output"
    global NLLog=createFile (LLOut+LLStage+"/checks.tsv")
    global NLNode,NLSource,NLCamera,NLOutput=#(),NLExpected
    fn check value label = (
        if not value do throw label
        format "PASS\t%\n" label to:NLLog;flush NLLog
    )
    fn token name = (local f=openFile (LLOut+"fixtures/"+name+".license");local s=readLine f;close f;s)
    fn rows = (
        local state=cyrusOwnedState NLNode.NativeLicenseLab.recipe
        cyrusEditStack #(NLNode.modifiers[1]) (cyrusOwnedEvaluate NLNode.NativeLicenseLab.recipe) 1 ("owned:"+(state[3] as string)) true
    )
    fn fingerprint = (
        -- Diagnostic only: compare every float component/source/identity, not
        -- just position. This is never used as authorization evidence.
        local stream=dotNetObject "System.IO.MemoryStream"
        local writer=dotNetObject "System.IO.BinaryWriter" stream
        for r in rows() do (
            for axis=1 to 4 do for component=1 to 3 do writer.Write (dotNetObject "System.Single" r[1][axis][component])
            writer.Write (dotNetObject "System.Int32" r[2]);writer.Write (r[3] as string)
        )
        writer.Flush()
        local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create()
        local signature=(dotNetClass "System.BitConverter").ToString (sha.ComputeHash (stream.ToArray()))
        writer.Dispose();stream.Dispose();sha.Dispose();signature
    )
    fn renderRows path = (
        local prepared=rows() -- Resolve before touching previously completed output.
        local next=#()
        undo off for r in prepared do (local n=instance NLSource;n.name="NL_Output";n.transform=r[1];n.isHidden=false;append next n)
        if NLOutput.count>0 do delete NLOutput
        NLOutput=next
        local image=render camera:NLCamera outputwidth:128 outputheight:128 vfb:false
        check (image!=undefined and NLOutput.count==64) "render_64_native_owned_rows"
        image.filename=path;save image;close image
    )
    try (
        check ((maxVersion())[1]==29000) "Max_2027"
        if LLStage=="create" then (
            resetMaxFile #noPrompt
            local surfaceNode=plane name:"NL_Surface" length:200 width:200 lengthsegs:2 widthsegs:2
            surfaceNode.material=standardMaterial diffuse:(color 100 100 100)
            NLSource=box name:"NL_Source" length:3 width:3 height:12 pos:[1000,0,0]
            NLSource.material=standardMaterial diffuse:(color 30 160 70)
            NLNode=point name:"NL_Owner"
            local ca=attributes NativeLicenseLab attribID:#(0x75302aca,0x561399a2) (parameters data (recipe type:#maxObject))
            custAttributes.add NLNode ca
            addModifier NLNode (CyrusScatterEdit())
            local denied=false
            try(cyrusOwnedCreate surfaceNode 64 42)catch(denied=true)
            check denied "absent_native_create_denied"
            check ((cyrusOwnedLabInstall (token "tampered"))=="signature") "invalid_signature_rejected"
            check ((cyrusOwnedLabInstall (token "active"))=="verified") "authentic_development_activation"
            cyrusOwnedLabClock 1800000100
            NLNode.NativeLicenseLab.recipe=cyrusOwnedCreate surfaceNode 64 42
            check ((rows()).count==64) "native_recipe_evaluates"
            cyrusOwnedAuthor NLNode.NativeLicenseLab.recipe 80 17
            check ((cyrusOwnedState NLNode.NativeLicenseLab.recipe)[1]==80) "native_count_seed_admitted"
            max undo
            check ((rows()).count==64) "native_recipe_undo"
            max redo
            check ((cyrusOwnedState NLNode.NativeLicenseLab.recipe)[1]==80) "native_recipe_redo"
            max undo
            local before=(rows())[1][1].row4
            undo "Native licensed edit" on (
                cyrusEditSelect NLNode.modifiers[1] #(1)
                cyrusEditCommand NLNode.modifiers[1] 4 (transMatrix [3,4,0])
            )
            check (distance (rows())[1][1].row4 (before+[3,4,0])<0.001) "real_CS_Edit_mutation"
            NLExpected=fingerprint()
            cyrusOwnedLabClock 1800003600
            max undo
            check (distance (rows())[1][1].row4 before<0.001) "CS_Edit_Undo_after_expiry"
            max redo
            check ((fingerprint())==NLExpected) "CS_Edit_Redo_after_expiry"
            cyrusOwnedLabClock 1800000100
            NLCamera=targetCamera name:"NL_Camera" pos:[260,-320,300] target:(targetObject name:"NL_CameraTarget" pos:[0,0,0])
            renderers.current=Default_Scanline_Renderer()
            renderRows (LLOut+"owned-active.png")
            cyrusOwnedLabClock 1800003600
            for command in #(0,2,3,4) do (
                denied=false;try(cyrusEditCommand NLNode.modifiers[1] command (transMatrix [90,0,0]))catch(denied=true)
                check denied ("direct_CS_Edit_denied_"+(command as string))
            )
            denied=false;try(cyrusEditTransform NLNode.modifiers[1] 0 [90,0,0] (matrix3 1) false)catch(denied=true)
            check denied "direct_transform_denied"
            cyrusOwnedLabSDKMove NLNode.modifiers[1] [90,0,0]
            check ((fingerprint())==NLExpected) "SDK_Move_callback_denied_before_mutation"
            denied=false;try(cyrusOwnedAuthor NLNode.NativeLicenseLab.recipe 999 999)catch(denied=true)
            check denied "direct_recipe_mutation_denied"
            denied=false;try(cyrusOwnedEvaluate NLNode.NativeLicenseLab.recipe 999 true)catch(denied=true)
            check denied "caller_saved_evaluation_flag_cannot_supply_recipe"
            denied=false;try(aminScatterTransforms surfaceNode 83 42 1 1.0 1.0 [0,0,0] [0,0,0] [0,0,0] true)catch(denied=true)
            check denied "raw_simple_generator_denied"
            check ((fingerprint())==NLExpected and NLOutput.count==64) "denial_retains_revision_edit_and_output"
            check ((cyrusOwnedLabInstall (token "wrong-device"))=="device") "wrong_context_rejected"
            check ((cyrusOwnedLabStatus())=="expired") "bad_import_does_not_change_deadline"
            renderRows (LLOut+"owned-expired.png")
            delete NLOutput;NLOutput=#()
            local f=createFile (LLOut+"owned-expected.ms");format "global NLExpected=\"%\"\n" NLExpected to:f;close f
            check (saveMaxFile (LLOut+"owned-scene.max") quiet:true) "save_without_output_cache_after_expiry"
        ) else (
            check (loadMaxFile (LLOut+"owned-scene.max") quiet:true) "saved_recipe_loaded"
            NLNode=getNodeByName "NL_Owner";NLSource=getNodeByName "NL_Source";NLCamera=getNodeByName "NL_Camera"
            fileIn (LLOut+"owned-expected.ms")
            check ((cyrusOwnedLabStatus())=="authority_absent") "fresh_process_has_no_authority"
            check ((fingerprint())==NLExpected) "cold_native_recipe_and_edit_evaluation"
            renderRows (LLOut+"owned-reopened.png")
            local baseline=fingerprint()
            NLSource.height=24
            renderRows (LLOut+"owned-source-changed.png")
            check ((fingerprint())==baseline) "external_source_geometry_not_authored_recipe"
            NLSource.height=12
            local surfaceNode=getNodeByName "NL_Surface"
            surfaceNode.pos.z=5
            check ((fingerprint())!=baseline) "external_receiver_change_affects_evaluation"
            surfaceNode.pos.z=0
            animate on at time 10 surfaceNode.pos.z=10
            sliderTime=10
            check ((fingerprint())!=baseline) "saved_dependency_animation_evaluates"
            sliderTime=0
            check ((fingerprint())==baseline) "return_frame_retains_recipe"
            check ((cyrusOwnedLabInstall (token "renewed"))=="verified") "verified_renewal_import"
            cyrusOwnedLabClock 1800003700
            local before=(rows())[1][1].row4
            undo "Renewed edit" on (cyrusEditCommand NLNode.modifiers[1] 4 (transMatrix [2,0,0]))
            check (distance (rows())[1][1].row4 (before+[2,0,0])<0.001) "renewal_restores_editing_retained_scene"
            max undo
            check ((fingerprint())==NLExpected) "renewed_Undo_preserves_original_scene"
        )
        local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        local modules=createFile (LLOut+LLStage+"/modules.tsv")
        for i=0 to process.Modules.Count-1 do (local m=process.Modules.Item[i];format "%\t%\n" m.ModuleName m.FileName to:modules)
        close modules
        format "COMPLETE\n" to:NLLog;close NLLog
    ) catch (format "FAIL\t%\n" (getCurrentException()) to:NLLog;close NLLog;throw())
)
