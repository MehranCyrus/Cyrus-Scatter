-- Functions for the real installation-key private Max candidate. No fake clock.
global LNNode,LNSource,LNCamera,LNOutput=#(),LNExpected,LNLog,LNOut,LNBrushExpected
global CyrusLicenseDevelopmentPanel
fn LNCheck value label = (
    if not value do throw label
    format "PASS\t%\n" label to:LNLog;flush LNLog
)
fn LNText path = (local f=openFile path;local value=readLine f;close f;value)
fn LNRows = (
    local state=cyrusOwnedState LNNode.NativeLicenseLab.recipe
    cyrusEditStack #(LNNode.modifiers[1]) (cyrusOwnedEvaluate LNNode.NativeLicenseLab.recipe) 1 ("owned:"+(state[3] as string)) true
)
fn LNHash = (
    local stream=dotNetObject "System.IO.MemoryStream",writer=undefined
    writer=dotNetObject "System.IO.BinaryWriter" stream
    for r in LNRows() do (
        for axis=1 to 4 do for component=1 to 3 do writer.Write (dotNetObject "System.Single" r[1][axis][component])
        writer.Write (dotNetObject "System.Int32" r[2]);writer.Write (r[3] as string)
    )
    writer.Flush()
    local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create()
    local value=(dotNetClass "System.BitConverter").ToString (sha.ComputeHash (stream.ToArray()))
    writer.Dispose();stream.Dispose();sha.Dispose();value
)
fn LNBrushHash = (
    local stream=dotNetObject "System.IO.MemoryStream",writer=undefined
    writer=dotNetObject "System.IO.BinaryWriter" stream
    for r in cyrusBrushRows LNNode.NativeLicenseLab.brush do (
        for axis=1 to 4 do for component=1 to 3 do writer.Write (dotNetObject "System.Single" r[1][axis][component])
        writer.Write (dotNetObject "System.Int32" r[2])
    )
    writer.Flush()
    local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create()
    local value=(dotNetClass "System.BitConverter").ToString (sha.ComputeHash (stream.ToArray()))
    writer.Dispose();stream.Dispose();sha.Dispose();value
)
fn LNRender name = (
    local prepared=LNRows(),next=#()
    undo off for row in prepared do (local n=instance LNSource;n.name="LN_Output";n.transform=row[1];append next n)
    if LNOutput.count>0 do delete LNOutput
    LNOutput=next
    LNCheck (next.count==64) "64_native_owned_render_instances"
    local bitmap=render camera:LNCamera outputwidth:128 outputheight:128 vfb:false
    bitmap.filename=LNOut+name;save bitmap;close bitmap
)
fn LNModules fileName = (
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),stream=createFile fileName
    for i=0 to process.Modules.Count-1 do (local item=process.Modules.Item[i];format "%\t%\n" item.ModuleName item.FileName to:stream)
    close stream
)
fn LNStart output responseFile viaPanel:false = (
    LNOut=output;LNLog=createFile (LNOut+"max-create.tsv")
    LNCheck (cyrusOwnedLabClock==undefined) "synthetic_clock_primitive_absent"
    LNCheck ((cyrusOwnedLabStatus())=="authority_absent") "no_implicit_authority"
    local activation=if viaPanel then CyrusLicenseDevelopmentPanel.applyFile responseFile activation:true else cyrusOwnedLabActivate (LNText responseFile)
    LNCheck (activation=="verified") "Max_authenticated_activation_with_real_installation_key"
    LNCheck ((cyrusOwnedLabStatus())=="allowed") "Max_authority_active"
    resetMaxFile #noPrompt
    local surfaceNode=plane name:"LN_Surface" length:200 width:200 lengthsegs:2 widthsegs:2
    surfaceNode.material=standardMaterial diffuse:(color 100 100 100)
    LNSource=box name:"LN_Source" length:3 width:3 height:12 pos:[1000,0,0]
    LNSource.material=standardMaterial diffuse:(color 30 160 70)
    LNNode=point name:"LN_Owner"
    local ca=attributes NativeLicenseLab attribID:#(0x75302aca,0x561399a2) (parameters data (recipe type:#maxObject;brush type:#maxObject))
    custAttributes.add LNNode ca;addModifier LNNode (CyrusScatterEdit())
    LNNode.NativeLicenseLab.recipe=cyrusOwnedCreate surfaceNode 64 42
    LNCheck ((LNRows()).count==64) "real_grant_admits_native_recipe"
    undo "Licensed CS Edit" on (cyrusEditSelect LNNode.modifiers[1] #(1);cyrusEditCommand LNNode.modifiers[1] 4 (transMatrix [3,4,0]))
    LNExpected=LNHash()
    LNCamera=targetCamera name:"LN_Camera" pos:[260,-320,300] target:(targetObject name:"LN_CameraTarget" pos:[0,0,0])
    renderers.current=Default_Scanline_Renderer()
    LNRender "active.png"
    LNNode.NativeLicenseLab.brush=cyrusBrushCreate surfaceNode
    local brush=LNNode.NativeLicenseLab.brush
    cyrusBrushSettings brush 40 1 0.5 false 1
    LNCheck (cyrusBrushDab brush [0,0,100] [0,0,-1] true) "shared_grant_admits_Brush_stroke"
    LNCheck ((cyrusBrushHistory brush).count==1 and (cyrusBrushRows brush).count>0) "completed_Brush_field_has_population"
    LNBrushExpected=LNBrushHash()
    LNCheck (cyrusBrushDab brush [50,0,100] [0,0,-1] false) "Brush_gesture_admitted_before_expiry"
    LNModules (LNOut+"max-create-modules.tsv")
)
fn LNExpired = (
    LNCheck ((cyrusOwnedLabStatus())=="expired") "Max_expires_during_uptime_without_network"
    local denied=false
    try(cyrusOwnedAuthor LNNode.NativeLicenseLab.recipe 999 999)catch(denied=true)
    LNCheck denied "expired_native_recipe_denied"
    denied=false;try(cyrusEditCommand LNNode.modifiers[1] 4 (transMatrix [90,0,0]))catch(denied=true)
    LNCheck denied "expired_native_edit_denied"
    cyrusOwnedLabSDKMove LNNode.modifiers[1] [90,0,0]
    LNCheck ((LNHash())==LNExpected) "all_matrix_components_source_and_edit_IDs_retained"
    denied=false;try(cyrusOwnedEvaluate LNNode.NativeLicenseLab.recipe 999 true)catch(denied=true)
    LNCheck denied "no_saved_flag_recipe_injection"
    local brush=LNNode.NativeLicenseLab.brush
    LNCheck (not (cyrusOwnedLabBrushEnd brush)) "actual_Painter_commit_denied_at_expiry"
    LNCheck ((cyrusBrushStats brush)[6]==0 and (cyrusBrushHistory brush).count==1) "expired_pending_stroke_cancelled_completed_history_retained"
    LNCheck ((LNBrushHash())==LNBrushExpected) "expired_Brush_population_matches"
    local before=(cyrusBrushOptions brush) as string
    denied=false;try(cyrusBrushSettings brush 99 0.1 0 true 0.1)catch(denied=true)
    LNCheck (denied and ((cyrusBrushOptions brush) as string)==before) "expired_Brush_settings_denied_without_mutation"
    denied=false;try(cyrusBrushFill brush 1)catch(denied=true)
    LNCheck denied "expired_Brush_fill_denied"
    denied=false;try(cyrusBrushStroke brush 1 false 0.2 90)catch(denied=true)
    LNCheck denied "expired_Brush_history_edit_denied"
    denied=false;try(cyrusBrushDeleteStroke brush 1)catch(denied=true)
    LNCheck denied "expired_Brush_history_delete_denied"
    denied=false;try(cyrusBrushDab brush [0,0,100] [0,0,-1] true)catch(denied=true)
    LNCheck denied "expired_direct_Brush_dab_denied"
    denied=false;try(cyrusBrushCreate (getNodeByName "LN_Surface"))catch(denied=true)
    LNCheck denied "expired_Brush_document_creation_denied"
    max undo
    LNCheck ((cyrusBrushHistory brush).count==0) "expired_Brush_Undo_available"
    max redo
    LNCheck ((LNBrushHash())==LNBrushExpected) "expired_Brush_Redo_restores_exact_field"
    cyrusBrushDisplay brush 0 [255,0,0]
    LNCheck ((LNBrushHash())==LNBrushExpected) "expired_Brush_display_does_not_change_field"
    LNRender "expired.png"
    delete LNOutput;LNOutput=#()
    local f=createFile (LNOut+"expected.ms");format "global LNExpected=\"%\"\nglobal LNBrushExpected=\"%\"\n" LNExpected LNBrushExpected to:f;close f
    LNCheck (saveMaxFile (LNOut+"installation-scene.max") quiet:true) "save_expired_scene_without_output_cache"
    format "COMPLETE\n" to:LNLog;close LNLog
)
fn LNReopen output = (
    LNOut=output;LNLog=createFile (LNOut+"max-reopen.tsv")
    LNCheck (cyrusOwnedLabClock==undefined) "reopen_has_no_synthetic_clock"
    LNCheck ((cyrusOwnedLabStatus())=="expired") "second_Max_reads_expired_protected_grant"
    LNCheck (loadMaxFile (LNOut+"installation-scene.max") quiet:true) "native_recipe_reopened"
    LNNode=getNodeByName "LN_Owner";LNSource=getNodeByName "LN_Source";LNCamera=getNodeByName "LN_Camera"
    fileIn (LNOut+"expected.ms")
    LNCheck ((LNHash())==LNExpected) "cold_full_row_identity_matches"
    LNCheck ((LNBrushHash())==LNBrushExpected) "cold_Brush_native_storage_and_field_match"
    LNRender "reopened.png"
    LNSource.height=24;LNRender "source-changed.png"
    LNCheck ((LNHash())==LNExpected) "source_geometry_is_external_dependency"
    LNSource.height=12
    local surfaceNode=getNodeByName "LN_Surface"
    surfaceNode.pos.z=5;LNCheck ((LNHash())!=LNExpected) "external_receiver_evaluates_after_expiry";surfaceNode.pos.z=0
    animate on at time 10 surfaceNode.pos.z=10
    sliderTime=10;LNCheck ((LNHash())!=LNExpected) "dependency_animation_evaluates_after_expiry";sliderTime=0
    LNCheck ((LNHash())==LNExpected) "restored_frame_matches_all_rows"
    LNModules (LNOut+"max-reopen-modules.tsv")
)
fn LNRenew fileName viaPanel:false = (
    local result=if viaPanel then CyrusLicenseDevelopmentPanel.applyFile fileName else cyrusOwnedLabInstall (LNText fileName)
    LNCheck (result=="verified") "Max_imports_verified_renewal"
    LNCheck ((cyrusOwnedLabStatus())=="allowed") "Max_renewal_unlocks_authoring"
    local before=(LNRows())[1][1].row4
    undo "Renewed native edit" on (cyrusEditCommand LNNode.modifiers[1] 4 (transMatrix [2,0,0]))
    LNCheck (distance (LNRows())[1][1].row4 (before+[2,0,0])<0.001) "renewal_edits_retained_scene"
    max undo
    LNCheck ((LNHash())==LNExpected) "renewed_Undo_returns_exact_rows"
    local brush=LNNode.NativeLicenseLab.brush
    cyrusBrushBind brush
    LNCheck (cyrusBrushDab brush [50,0,100] [0,0,-1] true) "shared_renewal_unlocks_Brush_DLL"
    LNCheck ((cyrusBrushHistory brush).count==2) "renewed_Brush_authors_retained_document"
    format "COMPLETE\n" to:LNLog;close LNLog
)
