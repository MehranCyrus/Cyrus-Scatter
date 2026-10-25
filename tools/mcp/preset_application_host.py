"""Owned native preset transaction/evaluator probes; never a model-callable API."""
import json
import sys
from copy import deepcopy
import pymxs
from pymxs import runtime as rt
import host_fixture as base
from cyrus_mcp.contracts import digest
from cyrus_mcp.max_host import frozen


def native_state(cid):
    root=base.PANEL.host.controllers[cid]
    owners=[root.baseObject,*list(root.layerObjects)]
    return dict(parameters=[{str(key):frozen(rt.getProperty(owner,key)) for key in rt.AminScatterLayerFields} for owner in owners],
        counters=[dict(prepare=int(owner.procPreparedBuilds),preview=int(owner.previewBuildCount),density=int(owner.procDensityBakes)) for owner in owners],
        solves=int(root.groupBuilds),
        publication=base.PANEL.host.publication_identity(root),
        ids=[str(layer.layerID) for layer in root.layerObjects],
        nodes=len(rt.objects),selected=[int(rt.getHandleByAnim(n)) for n in rt.selection],
        undo=[str(v) for v in rt.theHold.GetUndoNames()],save_required=bool(rt.getSaveRequired()),
        auto_key=bool(rt.animButtonState),frame=str(rt.sliderTime))


def command(data):
    action=data["action"]
    if action=="preset_apply_parity":
        assert int(rt.cyrusPresetCurveVersion())==1
        assert int(rt.CyrusPresetTransactionVersion())==1
        assert list(rt.cyrusPresetCurveUndoInfo())==[0,0]
        rt.fileIn(str(base.OUTPUT.parent/"fixtures/preset_curve_probe.ms"),quiet=True)
        traces=[str(v) for v in rt.CyrusMCPPresetCurveProbe()]
        results=[]
        for encoded in traces:
            source=json.loads(encoded)
            normalized=json.loads(str(rt.cyrusPresetPrepareCurve(encoded,source["category"]=="scale_curve")))
            assert normalized["values"]["samples"]==source["values"]["samples"],(source,normalized)
            assert normalized["values"]["graph"]==source["values"]["graph"],(source,normalized)
            results.append(dict(category=source["category"],graph_points=len(source["values"]["graph"]),samples=257,
                original_sha256=digest(source),normalized_sha256=digest(normalized),exact_artist_evaluator_parity=True))
        packed=rt.Array(*[v for point in json.loads(traces[3])["values"]["graph"] for v in point])
        assert rt.CyrusFallValidPackedGraph(packed)
        for bad in (rt.Array(0.),rt.Array(*([0.]*16)),rt.Array(*([0.]*2057))):assert not rt.CyrusFallValidPackedGraph(bad)
        return dict(cases=results,host_python=sys.version)
    cid=data["controller_id"];root=base.PANEL.host.controllers[cid];leaf=list(root.layerObjects)[0]
    if action=="preset_apply_physical_begin":
        path=base.OUTPUT/"physical-editor-before.json"
        assert not path.exists(),"Observe the original physical probe before replay"
        before=native_state(cid);path.write_text(json.dumps(before,indent=2)+"\n")
        rt.CyrusOpenFalloffGraph(leaf,rt.undefined,True)
        return dict(opened=True,layer_id=str(leaf.layerID),undo_lifetime_before=list(rt.cyrusPresetCurveUndoInfo()))
    if action=="preset_apply_physical_verify":
        assert rt.CyrusFalloffGraph is None,"Close the editor through its UI before checking the model"
        before=json.loads((base.OUTPUT/"physical-editor-before.json").read_text())
        after=native_state(cid)
        (base.OUTPUT/"physical-editor-after.json").write_text(json.dumps(after,indent=2)+"\n")
        assert after["parameters"][1]["fallDensityCurve"]!=before["parameters"][1]["fallDensityCurve"]
        allowed={"fallDensityCurve","fallDensityGraph"}
        for i,(old,new) in enumerate(zip(before["parameters"],after["parameters"])):
            assert {k:v for k,v in old.items() if i!=1 or k not in allowed}=={k:v for k,v in new.items() if i!=1 or k not in allowed}
        assert after["publication"]==before["publication"] and after["solves"]==before["solves"]
        lifetime=list(rt.cyrusPresetCurveUndoInfo())
        start=json.loads((base.OUTPUT/"physical-editor-campaign.json").read_text())["begin"]["undo_lifetime_before"]
        assert lifetime==[start[0]+2,0],"One selection and one drag must retain exactly one control per hold"
        return dict(actual_density_edit=True,other_settings_preserved=True,manual_publication_preserved=True,undo=after["undo"],undo_lifetime_after=lifetime)
    if action in ("preset_apply_physical_undo","preset_apply_physical_redo"):
        undo=action.endswith("_undo")
        stage=base.OUTPUT/"physical-editor-history.json"
        stage.write_text(json.dumps(dict(phase="before_undo" if undo else "before_redo"))+"\n")
        if undo:pymxs.run_undo()
        else:pymxs.run_redo()
        expected=json.loads((base.OUTPUT/("physical-editor-before.json" if undo else "physical-editor-after.json")).read_text())
        actual=native_state(cid)
        assert actual["parameters"]==expected["parameters"] and actual["publication"]==expected["publication"]
        stage.write_text(json.dumps(dict(phase="undo_verified" if undo else "redo_verified"))+"\n")
        lifetime=list(rt.cyrusPresetCurveUndoInfo());assert lifetime[0]>=2 and lifetime[1]==0
        return dict(undo=undo,exact_model_and_publication_restoration=True,undo_lifetime=lifetime)
    if action=="preset_apply_curve_lifetime_release":
        before=list(rt.cyrusPresetCurveUndoInfo());assert before[0]>=2 and before[1]==0
        # Reset only this owned disposable scene after its Undo/Redo witness.
        # This tests normal history retirement; it cannot conceal a failed Undo.
        assert json.loads((base.OUTPUT/"physical-editor-history.json").read_text())["phase"]=="redo_verified"
        rt.resetMaxFile(rt.Name("noPrompt"))
        after=list(rt.cyrusPresetCurveUndoInfo());assert after==[0,0],(before,after)
        return dict(before=before,after=after,owned_reset_released_history_references=True)
    if action=="preset_apply_caller_guards":
        binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,"population")
        values=rt.CyrusPresetCapture(binding)
        schema=[str(row[0]) for row in rt.cyrusPresetSchema("population")]
        values[schema.index("amount")]=int(leaf.amount)+1
        document=rt.cyrusPresetDecode(rt.cyrusPresetEncode("population","Caller guards",values))
        before=native_state(cid)
        try:rt.CyrusPresetApply(binding,document,transaction=rt.Name("caller"))
        except RuntimeError:pass
        else:raise AssertionError("Caller transaction accepted without a hold")
        assert native_state(cid)==before
        rt.theHold.Begin()
        try:
            for options in ({},{"transaction":rt.Name("caller")}):
                try:rt.CyrusPresetApply(binding,document,**options)
                except RuntimeError:pass
                else:raise AssertionError("Nested owned or unsuspended caller operation accepted")
                assert rt.theHold.Holding() and native_state(cid)==before
            root.setLayerTransfer(True);leaf.setLayerTransfer(True)
            try:rt.CyrusPresetApply(binding,document,transaction=rt.Name("caller"),seedPolicy=rt.Name("new"))
            except RuntimeError:pass
            else:raise AssertionError("Caller generated an unreviewed random seed")
            assert rt.theHold.Holding() and native_state(cid)==before
        finally:
            rt.theHold.Cancel();root.setLayerTransfer(False);leaf.setLayerTransfer(False)
        assert native_state(cid)==before
        return dict(no_hold_denied=True,nested_owned_denied=True,unsuspended_owners_denied=True,unreviewed_seed_denied=True,caller_hold_and_history_preserved=True)
    if action=="preset_apply_caller_commit":
        # Share one supported static controller with an untouched layer. Preset
        # detachment must preserve that owner's stored value and controller.
        other=list(root.layerObjects)[1]
        shared=rt.Bezier_Float();shared.value=-.5
        with pymxs.undo(True,"Owned shared preset controller"),pymxs.animate(False):
            rt.setPropertyController(leaf,rt.Name("movXMinWU"),shared)
            rt.setPropertyController(other,rt.Name("movXMinWU"),shared)
        shared_id=int(rt.getHandleByAnim(shared))
        documents=[]
        for category in ("population","transforms","spacing","density_curve","scale_curve"):
            binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,category)
            if category in ("density_curve","scale_curve"):
                values=rt.Array(rt.Array(1.,.4,.8),rt.Array(),category=="scale_curve")
            else:
                values=rt.CyrusPresetCapture(binding)
                if category=="population":
                    schema=[str(row[0]) for row in rt.cyrusPresetSchema(category)]
                    values[schema.index("amount")]=int(leaf.amount)+7
                elif category=="transforms":
                    schema=[str(row[0]) for row in rt.cyrusPresetSchema(category)]
                    values[schema.index("movXMinWU")]=-.02
                else:values=rt.Array(True,1.7,.35,False)
            documents.append((binding,rt.cyrusPresetDecode(rt.cyrusPresetEncode(category,"Composed preset",values))))
        before=native_state(cid);old_config=str(rt.getUserProp(root,"CyrusAutomationConfiguration"))
        allowed=set()
        for category in ("population","transforms"):allowed.update(str(row[0]) for row in rt.cyrusPresetSchema(category))
        allowed.update(("procSelfEnabled","procSelfMultiplier","procSelfGap","procSelfPlanar","procSelfOverride","fallDensityCurve","fallDensityGraph","fallScaleCurve","fallScaleGraph"))
        with pymxs.undo(True,"Owned composed preset command"),pymxs.animate(False):
            rt.cyrusPresetTrackPublication(rt.Array(root.baseObject,*list(root.layerObjects)))
            root.setLayerTransfer(True);leaf.setLayerTransfer(True)
            try:
                for binding,document in documents:
                    assert rt.CyrusPresetApply(binding,document,transaction=rt.Name("caller"))
                    assert rt.theHold.Holding() and root.getLayerTransfer() and leaf.getLayerTransfer()
                    interim=native_state(cid)
                    assert not rt.CyrusPresetApply(binding,document,transaction=rt.Name("caller"))
                    assert native_state(cid)==interim,"An identical composed apply changed authored state"
                rt.setUserProp(root,"CyrusAutomationConfiguration","owned_composed_preset_configuration")
            finally:root.setLayerTransfer(False);leaf.setLayerTransfer(False)
        after=native_state(cid)
        assert len(after["undo"])==len(before["undo"])+1 and after["undo"][1:]==before["undo"]
        assert after["parameters"][0]==before["parameters"][0] and after["parameters"][2]==before["parameters"][2]
        assert {k:v for k,v in after["parameters"][1].items() if k not in allowed}=={k:v for k,v in before["parameters"][1].items() if k not in allowed}
        for key in ("counters","solves","ids","nodes","selected","auto_key","frame"):assert after[key]==before[key],key
        assert int(rt.getHandleByAnim(rt.getPropertyController(other,rt.Name("movXMinWU"))))==shared_id
        assert int(rt.getHandleByAnim(rt.getPropertyController(leaf,rt.Name("movXMinWU"))))!=shared_id
        pymxs.run_undo();undone=native_state(cid)
        assert undone["parameters"]==before["parameters"] and undone["publication"]==before["publication"]
        assert str(rt.getUserProp(root,"CyrusAutomationConfiguration"))==old_config
        assert int(rt.getHandleByAnim(rt.getPropertyController(leaf,rt.Name("movXMinWU"))))==shared_id
        pymxs.run_redo();redone=native_state(cid)
        assert redone["parameters"]==after["parameters"] and redone["publication"]==after["publication"]
        return dict(categories=5,one_authored_hold=True,configuration_tag_in_same_undo=True,shared_controller_other_owner_preserved=True,identical_apply_passive=True,manual_publication_preserved=True,undo_redo=True)
    if action=="preset_apply_caller_rollback":
        binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,"population")
        values=rt.CyrusPresetCapture(binding)
        schema=[str(row[0]) for row in rt.cyrusPresetSchema("population")]
        values[schema.index("amount")]=int(leaf.amount)+11
        document=rt.cyrusPresetDecode(rt.cyrusPresetEncode("population","Before rejected successor",values))
        curve_binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,"density_curve")
        bad=rt.cyrusPresetDecode(rt.cyrusPresetEncode("density_curve","Inconsistent graph",rt.Array(rt.Array(0.,1.),rt.Array(0.,100.,0.,0.,0.,0.,0.,1.,1.,0.,0.,0.,0.,0.,0.,1.),False)))
        before=native_state(cid)
        rt.theHold.Begin()
        try:
            rt.cyrusPresetTrackPublication(rt.Array(root.baseObject,*list(root.layerObjects)))
            root.setLayerTransfer(True);leaf.setLayerTransfer(True)
            assert rt.CyrusPresetApply(binding,document,transaction=rt.Name("caller"))
            staged=native_state(cid)
            try:rt.CyrusPresetApply(curve_binding,bad,transaction=rt.Name("caller"))
            except RuntimeError:pass
            else:raise AssertionError("Composed command accepted inconsistent curve")
            assert rt.theHold.Holding() and native_state(cid)==staged,"Rejected successor consumed the caller hold or rolled back its prior work"
        finally:
            rt.theHold.Cancel();root.setLayerTransfer(False);leaf.setLayerTransfer(False)
        restored=native_state(cid)
        for key in ("parameters","publication","undo","ids","nodes","selected","counters","solves"):assert restored[key]==before[key],key
        return dict(failed_successor_preserves_caller_ownership=True,caller_cancel_restores_all_authored_state_and_publication=True,prior_history_retained=True)
    if action=="preset_apply_passive":
        encoded=str(rt.cyrusPresetEncode("density_curve","Passive ramp",rt.Array(rt.Array(0.,1.),rt.Array(),False)))
        previous_key=bool(rt.animButtonState);previous_time=rt.sliderTime
        rt.animButtonState=True;rt.sliderTime=160
        try:
            before=native_state(cid)
            assert not before["save_required"],"Owned passive-preparation checkpoint must start clean"
            for _ in range(32):assert len(json.loads(str(rt.cyrusPresetPrepareCurve(encoded,False)))["values"]["samples"])==257
            largest=str(rt.cyrusPresetEncode("density_curve","Bounded 257-point ramp",rt.Array(rt.Array(*[i/256 for i in range(257)]),rt.Array(),False)))
            assert len(json.loads(str(rt.cyrusPresetPrepareCurve(largest,False)))["values"]["graph"])==257
            bad=json.loads(encoded);bad["values"]["graph"]=[[0,100,0,0,0,0,0,1],[1,0,0,0,0,0,0,1]]
            oversized=json.loads(encoded);oversized["values"]["samples"]=[0.]*258
            for text,multiplier in ((json.dumps(bad),False),(encoded,True),(json.dumps(oversized),False),(encoded,0)):
                try:rt.cyrusPresetPrepareCurve(text,multiplier)
                except RuntimeError:pass
                else:raise AssertionError("Incompatible curve preparation succeeded")
            assert native_state(cid)==before
            # A transient prepare, including a rejected one, cannot swallow the
            # caller's existing authored hold or add entries to it.
            with pymxs.undo(True,"Owned curve preparation outer hold"),pymxs.animate(False):
                prior=float(leaf.procSelfGap);leaf.procSelfGap=prior+1
                assert rt.theHold.Holding()
                rt.cyrusPresetPrepareCurve(encoded,False)
                try:rt.cyrusPresetPrepareCurve(json.dumps(bad),False)
                except RuntimeError:pass
                else:raise AssertionError("Mismatched graph succeeded inside a hold")
                assert rt.theHold.Holding()
            assert len(native_state(cid)["undo"])==len(before["undo"])+1
            pymxs.run_undo();assert float(leaf.procSelfGap)==prior
        finally:rt.animButtonState=previous_key;rt.sliderTime=previous_time
        return dict(repeats=32,clean_scene_and_history_preserved=True,auto_key_frame_preserved=True,outer_hold_survived=True)
    if action=="preset_apply_category":
        category=data["category"];binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,category)
        if category in ("density_curve","scale_curve"):
            values=rt.Array(rt.Array(*([0.,.25,1.] if category=="density_curve" else [.5,2.,1.])),rt.Array(),category=="scale_curve")
            changed_fields={"fallDensityCurve","fallDensityGraph"} if category=="density_curve" else {"fallScaleCurve","fallScaleGraph"}
        else:
            schema=[str(row[0]) for row in rt.cyrusPresetSchema(category)]
            values=rt.CyrusPresetCapture(binding)
            if category=="population":values[schema.index("amount")]=125;values[schema.index("randomSeed")]=407
            elif category=="transforms":
                values[schema.index("advancedAxes")]=True;values[schema.index("movXMinWU")]=-.15;values[schema.index("movXMaxWU")]=.35
            else:values=rt.Array(True,1.5,.25,False)
            changed_fields=set(schema) if category!="spacing" else {"procSelfEnabled","procSelfMultiplier","procSelfGap","procSelfPlanar","procSelfOverride"}
        encoded=str(rt.cyrusPresetEncode(category,"Owned native application",values));document=rt.cyrusPresetDecode(encoded)
        before=native_state(cid)
        assert rt.CyrusPresetApply(binding,document)
        after=native_state(cid)
        assert after["publication"]==before["publication"] and after["ids"]==before["ids"]
        assert after["counters"]==before["counters"] and after["solves"]==before["solves"],"Manual preset apply performed calculation/preparation"
        assert after["nodes"]==before["nodes"] and after["selected"]==before["selected"]
        assert len(after["undo"])==len(before["undo"])+1 and after["undo"][1:]==before["undo"]
        for i,(old,new) in enumerate(zip(before["parameters"],after["parameters"])):
            allowed=changed_fields if i==1 else set()
            assert {k:v for k,v in old.items() if k not in allowed}=={k:v for k,v in new.items() if k not in allowed},(category,i)
        assert not rt.CyrusPresetApply(binding,document) and native_state(cid)==after
        captured=json.loads(str(rt.cyrusPresetEncode(category,"Captured native destination",rt.CyrusPresetCapture(binding))))
        if category in ("density_curve","scale_curve"):assert len(captured["values"]["samples"])==257 and captured["values"]["graph"]
        pymxs.run_undo();undone=native_state(cid)
        assert undone["parameters"]==before["parameters"] and undone["publication"]==before["publication"],category
        pymxs.run_redo();redone=native_state(cid)
        assert redone["parameters"]==after["parameters"] and redone["publication"]==after["publication"],category
        return dict(category=category,layer_id=str(leaf.layerID),document=json.loads(encoded),changed=True,
            identical_apply_passive=True,untouched_parameters_and_other_layer_preserved=True,publication_preserved=True,undo_redo=True)
    if action=="preset_apply_reject":
        binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,"density_curve")
        malformed=rt.cyrusPresetEncode("density_curve","Wrong handles",rt.Array(rt.Array(0.,1.),rt.Array(0.,100.,0.,0.,0.,0.,0.,1.,1.,0.,0.,0.,0.,0.,0.,1.),False))
        before=native_state(cid)
        try:rt.CyrusPresetApply(binding,rt.cyrusPresetDecode(malformed))
        except RuntimeError:pass
        else:raise AssertionError("Incompatible global curve mutated the scene")
        assert native_state(cid)==before
        return dict(incompatible_graph_rejected_before_mutation=True)
    if action=="preset_apply_editor_restore":
        # Five uneven points falsify sequential restoration against the SDK's
        # as-yet-unloaded neighbors; also verify the ordinary editor stays usable.
        encoded=list(rt.CyrusMCPPresetCurveProbe())[3]
        binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,"density_curve")
        assert rt.CyrusPresetApply(binding,rt.cyrusPresetDecode(encoded))
        destination=base.OUTPUT/"preset-editor-clean.max"
        assert not destination.exists() and rt.saveMaxFile(str(destination),quiet=True)
        before=native_state(cid);assert not before["save_required"]
        try:
            editor=rt.CyrusOpenFalloffGraph(leaf,rt.undefined,True)
            actual=json.loads(str(rt.cyrusPresetEncode("density_curve","Editor readback",editor.presetValues())))
            expected=json.loads(str(rt.cyrusPresetEncode("density_curve","Current",rt.CyrusPresetCapture(binding))))
            assert actual["values"]==expected["values"],(actual,expected)
        finally:
            if rt.CyrusFalloffGraph is not None:rt.destroyDialog(rt.CyrusFalloffGraph)
        assert native_state(cid)==before,"Opening/closing an unchanged stored graph changed the clean scene or history"
        return dict(graph_points=5,exact_restoration=True,unchanged_open_close_passive=True)
    if action=="preset_apply_precision_roundtrip":
        cases=[]
        for encoded in list(rt.CyrusMCPPresetCurveProbe())[4:]:
            category=json.loads(str(encoded))["category"]
            binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,category)
            assert rt.CyrusPresetApply(binding,rt.cyrusPresetDecode(encoded))
            captured=str(rt.cyrusPresetEncode(category,"Captured curve",rt.CyrusPresetCapture(binding)))
            before=native_state(cid)
            changed=bool(rt.CyrusPresetApply(binding,rt.cyrusPresetDecode(captured)))
            after=native_state(cid)
            cases.append(dict(category=category,changed=changed,state_and_history_unchanged=before==after,captured=json.loads(captured)))
            (base.OUTPUT/"precision-roundtrip.json").write_text(json.dumps(cases,indent=2)+"\n")
            assert not changed and before==after,"Captured native curve failed its exact-storage no-op roundtrip"
        return dict(cases=cases)
    if action=="preset_apply_legacy_browse":
        pack=rt.execute('''(fn legacyCurveText values = (local s=stringStream "";for i=1 to values.count do format "% %" (formattedPrint values[i] format:".6g" userLocale:false) (if i<values.count then "," else "") to:s;s as string))''')
        with pymxs.undo(True,"Owned older graph encoding"):
            leaf.fallDensityGraph=pack(rt.CyrusFallUnpack(leaf.fallDensityGraph))
        checkpoint=base.OUTPUT/"legacy-editor-clean.max"
        assert not checkpoint.exists() and rt.saveMaxFile(str(checkpoint),quiet=True)
        before=native_state(cid);assert not before["save_required"]
        editor=rt.CyrusOpenFalloffGraph(leaf,rt.undefined,True)
        rt.destroyDialog(editor);after=native_state(cid)
        (base.OUTPUT/"legacy-browse-state.json").write_text(json.dumps(dict(before=before,after=after),indent=2)+"\n")
        assert after==before,"Browsing an older graph encoding rewrote saved samples/graph or forced presentation"
        return dict(legacy_six_digit_graph_preserved=True,unchanged_open_close_passive=True)
    if action=="preset_apply_editor_edit":
        def mark(phase):
            (base.OUTPUT/"editor-edit-progress.json").write_text(json.dumps(dict(phase=phase,holding=bool(rt.theHold.Holding())))+"\n")
        mark("before_open")
        before=native_state(cid)
        editor=rt.CyrusOpenFalloffGraph(leaf,rt.undefined,True)
        mark("editor_opened")
        prepare=rt.execute('''(fn ownedCurvePrepare editor = (local c=editor.graph.curves[1],p=c.points[2];p.value=[p.value.x,p.value.y+5];true))''')
        try:
            # The temporary SDK controller is a view, not persistent scene
            # data. Match presetPrepare: construct its changed view with Undo
            # disabled and callbacks suppressed, then author only PB2 state in
            # the scene hold. Putting the UI controller in that hold leaves SDK
            # restore records referring to a retired control after close.
            editor.loading=True
            try:
                with pymxs.undo(False),pymxs.animate(False):
                    assert prepare(editor)
            finally:editor.loading=False
            mark("view_prepared_without_scene_undo")
            assert native_state(cid)==before,"Preparing the transient view authored scene state"
            with pymxs.undo(True,"Owned ordinary curve edit"),pymxs.animate(False):
                mark("before_edit")
                editor.queueCurve()
                assert editor.storeCurve()
                mark("edit_returned")
            mark("hold_accepted")
            assert not rt.theHold.Holding(),"Finish the edit hold before retiring its transient control"
            rt.destroyDialog(editor)
            mark("editor_closed")
        finally:
            if rt.CyrusFalloffGraph is not None and not rt.theHold.Holding():rt.destroyDialog(rt.CyrusFalloffGraph)
        after=native_state(cid)
        assert after["parameters"][1]["fallDensityCurve"]!=before["parameters"][1]["fallDensityCurve"]
        for i,(old,new) in enumerate(zip(before["parameters"],after["parameters"])):
            allowed={"fallDensityCurve","fallDensityGraph"} if i==1 else set()
            assert {k:v for k,v in old.items() if k not in allowed}=={k:v for k,v in new.items() if k not in allowed}
        assert after["publication"]==before["publication"] and after["solves"]==before["solves"]
        mark("before_undo");pymxs.run_undo();mark("undo_returned");assert native_state(cid)["parameters"]==before["parameters"]
        mark("before_redo");pymxs.run_redo();mark("redo_returned");assert native_state(cid)["parameters"]==after["parameters"]
        mark("complete")
        return dict(actual_edit_updates_curve=True,other_parameters_preserved=True,manual_publication_preserved=True,undo_redo=True)
    if action=="preset_apply_editor_preset":
        encoded=list(rt.CyrusMCPPresetCurveProbe())[1]
        before=native_state(cid)
        editor=rt.CyrusOpenFalloffGraph(leaf,rt.undefined,True)
        binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,"density_curve",editor=editor)
        try:
            assert rt.CyrusPresetApply(binding,rt.cyrusPresetDecode(encoded))
            after=native_state(cid)
            assert after["parameters"][1]["fallDensityCurve"]!=before["parameters"][1]["fallDensityCurve"]
            assert not rt.CyrusPresetApply(binding,rt.cyrusPresetDecode(encoded)) and native_state(cid)==after
            prior_view=str(rt.cyrusPresetEncode("density_curve","Rollback view",editor.presetValues()))
            bad=rt.cyrusPresetEncode("density_curve","Wrong UI handles",rt.Array(rt.Array(0.,1.),rt.Array(0.,100.,0.,0.,0.,0.,0.,1.,1.,0.,0.,0.,0.,0.,0.,1.),False))
            try:rt.CyrusPresetApply(binding,rt.cyrusPresetDecode(bad))
            except RuntimeError:pass
            else:raise AssertionError("UI preset accepted inconsistent handles")
            assert str(rt.cyrusPresetEncode("density_curve","Rollback view",editor.presetValues()))==prior_view
            assert native_state(cid)==after,"Failed UI preparation changed authoring or history"
        finally:
            if rt.CyrusFalloffGraph is not None:rt.destroyDialog(rt.CyrusFalloffGraph)
        assert native_state(cid)==after
        pymxs.run_undo();assert native_state(cid)["parameters"]==before["parameters"]
        pymxs.run_redo();assert native_state(cid)["parameters"]==after["parameters"]
        return dict(ui_preset_applied=True,identical_apply_passive=True,failed_prepare_restores_view_and_edit_intent=True,undo_redo=True)
    raise ValueError("Unknown owned preset application probe")
