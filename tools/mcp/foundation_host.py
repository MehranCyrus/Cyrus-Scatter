"""Owned M00/M01 fixture. Never shipped or registered as an MCP tool."""
from pathlib import Path
import json
import traceback

import host_fixture as base
from pymxs import runtime as rt
from PySide6 import QtCore

ORIGINAL_COMMAND = base.command
ORIGINAL_FINGERPRINT = None
ORIGINAL_GENERATE = None
ORIGINAL_CHANGE = None
OBSERVED = {}
SENTINEL = None


def command(data):
    panel = base.PANEL
    action = data["action"]
    if action == "setup":
        OBSERVED.clear()
    if action=="content_prepare_start":
        import content_prepare_host
        return content_prepare_host.start(data["root"],data["output"],data.get("ids",[]))
    if action.startswith("destination_step_"):
        import destination_settings_host
        return destination_settings_host.command(data)
    if action.startswith("preset_apply_"):
        import preset_application_host
        return preset_application_host.command(data)
    if action=="prepared_source_task":
        rt.select(rt.Array(panel.picked["site"][0],panel.picked["regions"][0]))
        panel.inspect_scene_selected();panel.scene_task_dialog.hide()
        return panel.service.context(panel.service.scope["scope_id"])
    if action=="installed_source_enable":
        panel.refresh()
        assert panel.installed_sources_enable.isEnabled()
        panel.installed_sources_enable.click();panel.refresh()
        assert panel.service.installed_source_grant is not None
        return dict(permission=panel.service.installed_source_grant,text=panel.installed_sources_status.text())
    if action=="installed_source_revoke":
        panel.installed_sources_revoke.click();panel.refresh()
        assert panel.service.installed_source_grant is None
        return dict(revoked=True)
    if action=="prepared_source_revoke":
        panel.source_revoke.click();panel.refresh()
        assert panel.service.asset_grant is None
        return dict(revoked=True)
    if action=="prepared_source_share":
        panel.share_source_package(data["directory"]);panel.refresh()
        return dict(status=panel.service.asset_grant["status"],share_enabled=panel.source_share.isEnabled())
    if action=="prepared_source_approve":
        index=panel.proposals.findData(data["validation_id"])
        assert index>=0
        panel.proposals.setCurrentIndex(index);panel.review();panel.refresh()
        text=panel.review_text.toPlainText()
        assert "hidden" in text and "source" in text and "No placements" in text
        panel.approve_button.click()
        assert data["validation_id"] in panel.service.approved
        return dict(approved=True,review=text)
    if action=="prepared_source_state":
        from cyrus_mcp.max_host import frozen
        return dict(nodes=len(rt.objects),selected=[int(rt.getHandleByAnim(n)) for n in rt.selection],
                    undo=[str(v) for v in rt.theHold.GetUndoNames()],scope=panel.host.source_asset_adapter().scope_state() if panel.host.scene_nodes else None,
                    source_handles=[int(rt.getHandleByAnim(n)) for n in panel.host.scene_nodes.values() if rt.isValidNode(n)],
                    asset_token=panel.host.source_asset_adapter().token is not None,grant=panel.service.asset_grant,
                    asset_tokens=sum(part["token"] is not None for part in panel.host.source_asset_adapter().parts),
                    retained_native_packages=int(rt.cyrusAssetPackageRetainedCount()) if panel.host.source_asset_adapter().cohort_supported() else None,
                    applications=panel.service.applications,auto_key=bool(rt.animButtonState),time=str(rt.sliderTime))
    if action=="prepared_source_auto_key":
        rt.sliderTime=160;rt.animButtonState=bool(data["enabled"])
        return dict(auto_key=bool(rt.animButtonState),time=str(rt.sliderTime))
    if action=="prepared_source_receipt_check":
        result=[]
        for row in data["sources"]:
            node=rt.getAnimByHandle(row["node_handle"])
            assert node is not None and rt.isValidNode(node) and node.isHidden and not node.renderable
            assert str(rt.getUserProp(node,"CyrusAutomationAssetRef"))==row["asset_ref"]
            assert panel.host.source_descriptor(node)==row["geometry"]
            result.append(dict(asset_ref=row["asset_ref"],valid=True,geometry_matches=True))
        return dict(sources=result)
    if action=="prepared_source_unsupported":
        from cyrus_mcp.contracts import Fault
        assert not panel.source_share.isEnabled() and not panel.host.source_asset_adapter().supported()
        before=command(dict(action="prepared_source_state"))
        try:panel.service.share_source_package(data["directory"])
        except Fault as exc:assert exc.code=="UNSUPPORTED_CAPABILITY"
        else:raise AssertionError("Old pair admitted source package use")
        assert command(dict(action="prepared_source_state"))==before
        return dict(status="passed",share_disabled=True,native_admission_denied=True,scene_preserved=True)
    if action == "planting_sources_fixture":
        import runpy,pymxs
        with pymxs.undo(False):
            return runpy.run_path(str(base.OUTPUT/"planting_source_setup.py"))["result"]
    if action == "portable_sources_probe":
        import runpy,pymxs
        with pymxs.undo(False):
            return runpy.run_path(str(base.OUTPUT/"portable_source_probe.py"))["result"]
    if action.startswith("portable_step_"):
        import portable_source_host
        return portable_source_host.command(data)
    if action == "show_panel":
        import os
        panel.setWindowTitle("Cyrus Automation | owned MCP qualification | PID "+str(os.getpid()))
        panel.refresh()
        panel.show()
        return {"title": panel.windowTitle(), "pid": os.getpid()}
    if action == "scene_fixture":
        site=panel.picked["site"][0]
        source=panel.picked["sources"][0]
        region=panel.picked["regions"][0]
        site.name="Flowers";source.name="Flowers"
        parent=rt.Point(name="Unshared hierarchy parent")
        source.parent=parent
        box=rt.box(name="Untrusted scene text "+"花"*200,width=2,length=3,height=4,pos=rt.Point3(20,20,0))
        rt.select(rt.Array(site,source,region,box))
        panel.inspect_scene_selected()
        panel.scene_task_dialog.hide()
        return {"scope_id":panel.service.scope["scope_id"],"objects":panel.service.scope["snapshot"]["objects"]}
    if action == "recipe_catalog_native":
        import recipe_catalog_host
        return recipe_catalog_host.start(panel,base.OUTPUT,data["roots"],lambda:command({"action":"scene_state"}))
    if action.startswith("source_use_"):
        import source_use_host
        if action=="source_use_fixture":return source_use_host.high_fixture()
        if action=="source_use_edit":return source_use_host.edit_vertex()
        if action=="source_use_zero_offset":return source_use_host.transform_identity_offset()
        if action=="source_use_move":return source_use_host.move()
        if action=="source_use_restore":source_use_host.restore_guard();return {"restored":True}
        if action=="source_use_import":return source_use_host.import_probe(data["root"],data["entry_id"])
        raise ValueError("Unsupported source qualification action")
    if action == "task_extend_fixture":
        extra=rt.box(name="Neighbor context",width=1,length=2,height=3,pos=rt.Point3(18,0,0))
        excluded=base.shape("Keep entrance clear",[(-2,-2),(2,-2),(2,2),(-2,2)])
        point=rt.Point(name="Unsupported mesh prototype")
        before=command({"action":"scene_state"})
        rt.select(rt.Array(extra,excluded,point))
        selected=command({"action":"scene_state"})
        panel.task_share_more.click()
        after=command({"action":"scene_state"})
        for key in ("nodes","selected","save_required","undo"):
            assert selected[key]==after[key],"Scope extension changed native state: "+key
        assert all(item in after["objects"] for item in selected["objects"])
        return {"objects":panel.service.scope["snapshot"]["objects"],"before":before,"after":after}
    if action == "task_source_transform":
        source=panel.picked["sources"][0]
        source.objectOffsetPos=rt.Point3(.1,0,0)
        source.rotation=rt.quat(37,rt.Point3(0,0,1))
        return {"transformed":True}
    if action == "task_prepare_grant":
        return panel.service.prepare_task_design()
    if action == "task_connect_grant":
        panel.service.connect_task_design(data["review_id"],data["digest"])
        panel.refresh()
        return {"scope_kind":panel.service.scope["kind"],"task":panel.service.task}
    if action == "task_grant_dialog":
        from PySide6 import QtWidgets
        seen={}
        def cancel():
            box=next(w for w in QtWidgets.QApplication.topLevelWidgets() if isinstance(w,QtWidgets.QMessageBox) and w.isVisible())
            seen.update(default=box.defaultButton().text(),text=box.text())
            box.done(QtWidgets.QMessageBox.Ok if data.get("confirm",False) else QtWidgets.QMessageBox.Cancel)
        QtCore.QTimer.singleShot(50,cancel)
        panel.task_enable_design.click()
        assert seen.get("default")=="Cancel" and panel.service.task_design_review is None
        return {"dialog":seen,"scope_kind":panel.service.scope["kind"]}
    if action == "task_connect_expect_stale":
        from cyrus_mcp.contracts import Fault
        try:panel.service.connect_task_design(data["review_id"],data["digest"])
        except Fault as exc:
            assert exc.code=="STALE_CONTEXT" and panel.service.scope["kind"]=="scene_inspection"
            return {"code":exc.code,"scope_retained":True}
        raise AssertionError("Stale review enabled design scope")
    if action == "task_connect_expected_failure":
        from cyrus_mcp.contracts import Fault
        before=panel.service.scope["scope_id"]
        review=panel.service.prepare_task_design()
        try:panel.service.connect_task_design(review["review_id"],review["digest"])
        except Fault as exc:
            assert panel.service.scope["scope_id"]==before and panel.service.scope["kind"]=="scene_inspection"
            return {"code":exc.code,"message":exc.message,"scope_retained":True}
        raise AssertionError("Unsupported task was granted design scope")
    if action == "scene_role":
        nodes=[panel.host.scene_nodes[oid] for oid in data["object_ids"]]
        rt.select(rt.Array(*nodes))
        panel.task_role.setCurrentText(data["role"])
        panel.correct_scene_role(data.get("remove",False));panel.refresh()
        return panel.service.task
    if action == "catalog_fixture":
        import hashlib
        root=Path(data["root"]).resolve()
        runtime=Path(str(rt.CyrusRecipeScriptDirectory)).resolve()
        assert runtime.is_relative_to(base.OUTPUT.resolve()),"Only owned profile binding may be written"
        catalog=root/"model-catalog.json"
        assert catalog.is_file() and catalog.stat().st_size<=2*1024*1024
        sha=hashlib.sha256(catalog.read_bytes()).hexdigest()
        binding=runtime/"LibraryBinding.txt"
        binding.write_text("CyrusLibraryBinding1\n"+str(base.OUTPUT/"owned-library-selection.txt")+"\n"+
                           "\n".join([str(root),"mcp-owned-test",sha,"0"*64,"2024","","cyrus-plants"])+"\n",encoding="utf-8")
        return {"owned_binding":str(binding),"catalog_sha256":sha}
    if action == "catalog_share":
        panel.catalog_share.click()
        panel.refresh()
        assert panel.service.library_grant is not None,panel.service.last_message
        return {"grant":panel.service.connection()["installed_catalog"],"status":panel.catalog_status.text(),
                "load_duration_ms":panel.service.library_grant["load_duration_ms"],"revoke_enabled":panel.catalog_revoke.isEnabled()}
    if action == "catalog_revoke":
        panel.catalog_revoke.click();panel.refresh()
        return {"grant":panel.service.connection()["installed_catalog"],"status":panel.catalog_status.text(),
                "revoke_enabled":panel.catalog_revoke.isEnabled()}
    if action == "recipe_share":
        from PySide6 import QtWidgets
        kind=data.get("kind","custom_recipes")
        if kind=="custom_recipes":
            previous=QtWidgets.QFileDialog.getExistingDirectory
            try:
                QtWidgets.QFileDialog.getExistingDirectory=lambda *args,**kwargs:data["root"]
                panel.recipe_custom.click()
            finally:QtWidgets.QFileDialog.getExistingDirectory=previous
        else:
            # Owned personal-folder fixture only; never scan the artist's real Documents.
            previous=rt.CyrusRecipeDirectory
            try:
                rt.CyrusMCPRecipeFixturePath=data["root"]
                rt.CyrusRecipeDirectory=rt.execute("fn CyrusMCPRecipeFixtureDirectory = CyrusMCPRecipeFixturePath")
                panel.recipe_personal.click()
            finally:
                rt.CyrusRecipeDirectory=previous;rt.CyrusMCPRecipeFixturePath=None
        if data.get("pause",False):panel.recipe_timer.stop()
        panel.refresh()
        assert panel.service.recipe_grant is not None,panel.service.last_message
        return command({"action":"recipe_ui"})
    if action=="preset_share":
        from PySide6 import QtWidgets
        kind=data.get("kind","custom_presets")
        if kind=="custom_presets":
            previous=QtWidgets.QFileDialog.getExistingDirectory
            try:
                QtWidgets.QFileDialog.getExistingDirectory=lambda *args,**kwargs:data["root"]
                panel.preset_custom.click()
            finally:QtWidgets.QFileDialog.getExistingDirectory=previous
        else:
            previous=rt.CyrusPresetDirectory
            try:
                rt.CyrusMCPPresetFixturePath=data["root"]
                rt.CyrusPresetDirectory=rt.execute("fn CyrusMCPPresetFixtureDirectory = CyrusMCPPresetFixturePath")
                panel.preset_personal.click()
            finally:rt.CyrusPresetDirectory=previous;rt.CyrusMCPPresetFixturePath=None
        if data.get("pause",False):panel.preset_timer.stop()
        panel.refresh();assert panel.service.preset_grant is not None,panel.service.last_message
        return command(dict(action="preset_ui"))
    if action=="preset_resume":
        panel.preset_timer.start();return dict(timer=panel.preset_timer.isActive())
    if action=="preset_revoke":
        panel.preset_revoke.click();panel.refresh();return command(dict(action="preset_ui"))
    if action=="preset_ui":
        return dict(catalog=panel.service.connection()["preset_catalog"],status=panel.preset_status.text(),
            personal_enabled=panel.preset_personal.isEnabled(),custom_enabled=panel.preset_custom.isEnabled(),
            revoke_enabled=panel.preset_revoke.isEnabled(),native_reader=panel.host.preset_reader is not None,
            timer=panel.preset_timer.isActive())
    if action=="preset_unsupported":
        from cyrus_mcp.contracts import Fault
        panel.refresh();assert panel.host.preset_catalog_version() is None and not panel.preset_custom.isEnabled() and not panel.preset_personal.isEnabled()
        try:panel.service.share_preset_catalog("custom_presets",data["root"])
        except Fault as exc:assert exc.code=="UNSUPPORTED_CAPABILITY"
        else:raise AssertionError("Preset scan started without native support")
        return command(dict(action="preset_ui"))
    if action=="preset_denied":
        from cyrus_mcp.contracts import Fault
        try:panel.service.share_preset_catalog("custom_presets",data["root"])
        except Fault as exc:return dict(code=exc.code,catalog=panel.service.connection()["preset_catalog"])
        raise AssertionError("Unconfined settings preset root was admitted")
    if action == "recipe_resume":
        panel.recipe_timer.start();return {"timer":panel.recipe_timer.isActive()}
    if action == "recipe_revoke":
        panel.recipe_revoke.click();panel.refresh();return command({"action":"recipe_ui"})
    if action == "recipe_ui":
        return {"catalog":panel.service.connection()["recipe_catalog"],"status":panel.recipe_status.text(),
                "personal_enabled":panel.recipe_personal.isEnabled(),"custom_enabled":panel.recipe_custom.isEnabled(),
                "revoke_enabled":panel.recipe_revoke.isEnabled(),"native_reader":panel.host.recipe_reader is not None,
                "tabs":[panel.task_tabs.tabText(i) for i in range(panel.task_tabs.count())]}
    if action == "recipe_gallery_start":
        OBSERVED["recipe_gallery_token"]=int(rt.cyrusRecipeLibraryStart(rt.Array(data["root"])))
        return {"started":True}
    if action == "recipe_gallery_snapshot":
        from cyrus_mcp.max_host import frozen
        from cyrus_mcp.contracts import digest
        page=frozen(rt.cyrusRecipeLibraryPage(OBSERVED["recipe_gallery_token"],"","",1))
        return {"state":page[0],"count":page[2],"digest":digest(page)}
    if action == "recipe_unsupported":
        from cyrus_mcp.contracts import Fault
        assert panel.host.recipe_catalog_version() is None
        try:panel.service.share_recipe_catalog("custom_recipes",data["root"])
        except Fault as exc:assert exc.code=="UNSUPPORTED_CAPABILITY"
        else:raise AssertionError("Recipe scan started without native support")
        return command({"action":"recipe_ui"})
    if action == "scene_brief":
        panel.task_brief.setText(data["brief"])
        panel.service.update_scene_brief(panel.task_brief.text());panel.refresh()
        return panel.service.task
    if action == "scene_ui":
        panel.refresh()
        return {"brief":panel.task_brief.text(),"enabled":panel.scene_task_dialog.isEnabled(),
                "details_enabled":panel.scene_task_button.isEnabled(),
                "share_more_enabled":panel.task_share_more.isEnabled(),"grant_enabled":panel.task_enable_design.isEnabled(),
                "roles_enabled":panel.task_role.isEnabled(),"stage":panel.task_stage.text(),
                "rows":[{"object_id":panel.task_objects.topLevelItem(i).data(0,QtCore.Qt.UserRole),
                         "label":panel.task_objects.topLevelItem(i).text(0),
                         "roles":panel.task_objects.topLevelItem(i).text(1),
                         "status":panel.task_objects.topLevelItem(i).text(2)} for i in range(panel.task_objects.topLevelItemCount())]}
    if action == "scene_edit":
        node=panel.host.scene_nodes[data["object_id"]]
        if data["kind"]=="rename":node.name="Now renamed"
        elif data["kind"]=="height":node.height=float(node.height)+.5
        elif data["kind"]=="delete_replace":
            name=str(node.name);rt.delete(node)
            rt.box(name=name,width=1,length=1,height=1)
        elif data["kind"]=="units":rt.units.SystemType=rt.Name("Centimeters")
        else:raise ValueError("Unknown scene edit")
        return {"edited":True}
    if action == "scene_over_budget":
        from cyrus_mcp.contracts import Fault
        scope=panel.service.scope["scope_id"]
        points=[rt.Point(name="Owned admission probe") for _ in range(33)]
        try:
            rt.select(rt.Array(*points))
            try:panel.inspect_scene_selected()
            except Fault as exc:
                assert exc.code=="BUDGET_EXCEEDED"
            else:raise AssertionError("Oversized selection admitted")
            assert panel.service.scope["scope_id"]==scope
        finally:rt.delete(rt.Array(*points))
        return {"rejected":True,"scope_retained":True}
    if action == "scene_highlight":
        ids=data["object_ids"]
        for i in range(panel.task_objects.topLevelItemCount()):
            item=panel.task_objects.topLevelItem(i)
            item.setSelected(item.data(0,QtCore.Qt.UserRole) in ids)
        panel.highlight_scene_task()
        return {"selected_ids":panel.host.scene_selection_ids([rt.selection[i] for i in range(len(rt.selection))])}
    if action == "scene_state":
        from cyrus_mcp.max_host import frozen
        return {"nodes":len(rt.objects),"selected":[int(rt.getHandleByAnim(rt.selection[i])) for i in range(len(rt.selection))],
                "save_required":bool(rt.getSaveRequired()),"undo":[str(v) for v in rt.theHold.GetUndoNames()],
                "objects":[{"object_id":oid,"valid":bool(rt.isValidNode(node)),
                            "transform":frozen(node.transform) if rt.isValidNode(node) else None}
                           for oid,node in panel.host.scene_nodes.items()]}
    if action == "scene_reopen_task":
        panel.scene_task_dialog.close()
        panel.scene_task_button.click()
        visible=panel.scene_task_dialog.isVisible()
        panel.scene_task_dialog.hide()
        return {"visible":visible,"task":panel.service.task}
    if action == "scene_disconnect":
        panel.disconnect_scope();panel.refresh()
        return {"scope":panel.service.scope,"task":panel.service.task,
                "retained_references":len(panel.host.scene_nodes),"details_enabled":panel.scene_task_button.isEnabled(),
                "dialog_enabled":panel.scene_task_dialog.isEnabled()}
    if action == "scene_event_reset":
        rt.resetMaxFile(rt.Name("noPrompt"))
        # Inspect before any request/call to panel.refresh can conceal stale UI.
        return {"scope":panel.service.scope,"task":panel.service.task,"references":len(panel.host.scene_nodes),
                "details_enabled":panel.scene_task_button.isEnabled(),"dialog_enabled":panel.scene_task_dialog.isEnabled(),
                "table_rows":panel.task_objects.topLevelItemCount(),"brief":panel.task_brief.text(),"status":panel.status.text()}
    if action == "scene_panel_close":
        host,service=panel.host,panel.service
        panel.close()
        return {"references":len(host.scene_nodes),"task":service.task,"bridge_closed":panel.bridge.closed}
    if action == "ui_state":
        from PySide6 import QtWidgets
        boxes = [widget for widget in QtWidgets.QApplication.topLevelWidgets()
                 if isinstance(widget, QtWidgets.QMessageBox) and widget.isVisible()]
        return {"review": panel.review_text.toPlainText(), "status": panel.status.text(),
                "approved": sorted(panel.service.approved), "scope": panel.service.scope is not None,
                "recovery_required": panel.service.recovery_required,
                "dialogs": [{"title": box.windowTitle(), "text": box.text(), "information": box.informativeText(),
                             "default": box.defaultButton().text() if box.defaultButton() else None} for box in boxes]}
    if action == "select_owned":
        rt.select(panel.host.controllers[data["controller_id"]])
        return {"selected": True}
    if action == "recovery_read_budgets":
        from cyrus_mcp.contracts import Fault
        probe = rt.execute("(struct CyrusMCPRecoveryProbe (value=undefined); CyrusMCPRecoveryProbe())")
        outcomes = []
        def denied(name, value):
            probe.value = value
            try:
                panel.host.recovery_reader()(probe, "value")
            except Fault as exc:
                outcomes.append({"case": name, "code": exc.code})
            else:
                raise AssertionError("Oversized native metadata was admitted: "+name)
        denied("array", rt.Array(*range(4097)))
        denied("text", "x"*262145)
        nested = 1
        for _ in range(10):
            nested = rt.Array(nested)
        denied("depth", nested)
        probe.value = rt.Array(*range(4096))
        read = panel.host.recovery_reader()
        for _ in range(3):
            assert len(read(probe, "value")) == 4096
        try:
            read(probe, "value")
        except Fault as exc:
            outcomes.append({"case": "aggregate", "code": exc.code})
        else:
            raise AssertionError("Aggregate native metadata budget was bypassed")
        assert all(item["code"] == "BUDGET_EXCEEDED" for item in outcomes)
        return {"cases": outcomes, "boundary_array_accepted": 4096}
    if action == "sentinel_create":
        global SENTINEL
        SENTINEL = rt.box(name="Unrelated artist object", width=1.7, length=2.3, height=3.1,
                          pos=rt.Point3(40, 12, 5))
        return {"created": True}
    if action == "sentinel_snapshot":
        from cyrus_mcp.max_host import frozen
        return {"handle": int(rt.getHandleByAnim(SENTINEL)), "transform": frozen(SENTINEL.transform),
                "dimensions": [float(SENTINEL.width), float(SENTINEL.length), float(SENTINEL.height)]}
    if action == "sentinel_edit":
        import pymxs
        with pymxs.undo(True, "Unrelated sentinel edit"):
            SENTINEL.height=float(SENTINEL.height)+1
        return {"edited": True}
    if action == "undo_receipt":
        if data.get("panel",False):
            panel.undo();panel.refresh()
            return {"operation":list(panel.service.journal.records.values())[-1],"scope_label":panel.scope_label.text(),
                    "undo_enabled":panel.undo_button.isEnabled(),"shared_checkbox":panel.trace_share.isChecked()}
        return panel.service.undo()
    if action == "redo":
        import pymxs
        pymxs.run_redo()
        return {"redone": True}
    if action == "publication_snapshot":
        from cyrus_mcp.max_host import frozen
        from cyrus_mcp.publication import manifest, page
        from cyrus_mcp.contracts import digest, require
        cid = data["controller_id"]
        node = panel.host.controllers.get(cid, OBSERVED.get(cid))
        require(node is not None and rt.isValidNode(node), "Observed fixture controller unavailable")
        OBSERVED[cid] = node
        rt.completeRedraw()
        published = manifest(frozen(node.procPublicationInfo()))
        require(published["count"] <= 2000, "Fixture readback budget exceeded")
        rows = []
        for offset in range(0, published["count"], 500):
            raw = frozen(node.procPublicationPage(published["publication_id"], offset, 500))
            rows.extend(page(raw, published, offset, 500)["rows"])
        authored = panel.host.controller_state(node)
        retained_owner=rt.CyrusPointOwner(node)
        native_retained=None
        if retained_owner and rt.isValidNode(retained_owner):
            stats=rt.cyrusRetainedStats(retained_owner)
            native_retained={key:int(stats[index]) for key,index in
                             (("revision",2),("prepares",3),("node_updates",4),("uploads",5),("upload_bytes",6),("state",11))}
        return {"manifest": published, "rows_sha256": digest(rows), "rows": rows, "authored": authored,
                "authored_sha256": digest(authored),
                "generation_id": str(rt.getUserProp(node, "CyrusAutomationGeneration")),
                "configuration_id": str(rt.getUserProp(node, "CyrusAutomationConfiguration")),
                "cache_builds": [int(layer.cacheSnapshot()[5]) for layer in node.layerObjects],
                "pending_flags": [bool(layer.cacheSnapshot()[2]) for layer in node.layerObjects],
                "retained": panel.host.retained_diagnostics(),
                "native_retained":native_retained,
                "root_layer_id": str(node.layerID),
                "layer_ids": [str(layer.layerID) for layer in node.layerObjects], "nodes": len(list(rt.objects))}
    if action == "time":
        rt.sliderTime = int(data["value"])
        return {"time": str(rt.sliderTime)}
    if action == "post_commit_fault":
        kind = data.get("kind", "generate")
        original = ORIGINAL_CHANGE if kind == "change" else ORIGINAL_GENERATE
        def finalize(*args):
            result = original(*args)
            def unavailable():
                from cyrus_mcp.contracts import Fault
                raise Fault("HOST_ERROR", "Private post-commit fingerprint fault")
            panel.host.fingerprint = unavailable
            return result
        setattr(panel.host, kind, finalize)
        return {"armed": True}
    if action == "clear_post_commit_fault":
        panel.host.fingerprint = ORIGINAL_FINGERPRINT
        panel.host.generate = ORIGINAL_GENERATE
        panel.host.change = ORIGINAL_CHANGE
        return {"cleared": True}
    if action == "review_recovery":
        record = panel.service.journal.records[data["operation_id"]]
        cid = record.get("commit_identity", {}).get("controller_id")
        node = panel.host.controllers.get(cid, OBSERVED.get(cid))
        selected = [node] if node is not None and rt.isValidNode(node) else []
        rt.select(rt.Array(*selected)) if selected else rt.clearSelection()
        return panel.service.prepare_local_recovery(data["operation_id"], selected)
    if action == "confirm_recovery":
        return panel.service.confirm_local_recovery(data["review_id"], data["digest"])
    if action == "publication":
        cid = data["controller_id"]
        return panel.host.publication_manifest(cid)
    return ORIGINAL_COMMAND(data)


def start(output, connection_dir=None):
    global ORIGINAL_FINGERPRINT, ORIGINAL_GENERATE, ORIGINAL_CHANGE
    base.OUTPUT = Path(output)
    try:
        from cyrus_mcp.panel import Panel
        base.PANEL = Panel(connection_dir or base.OUTPUT / "connection")
        base.PANEL.hide()
        ORIGINAL_FINGERPRINT = base.PANEL.host.fingerprint
        ORIGINAL_GENERATE = base.PANEL.host.generate
        ORIGINAL_CHANGE = base.PANEL.host.change
        base.command = command
        connection = base.PANEL.service.connection() if base.PANEL.service.recovery_required else base.setup()
        base.TIMER = QtCore.QTimer(base.PANEL)
        base.TIMER.timeout.connect(base.tick)
        base.TIMER.start(100)
        (base.OUTPUT / "foundation-ready.json").write_text(json.dumps(connection, indent=2), encoding="utf-8")
    except Exception:
        (base.OUTPUT / "foundation-error.txt").write_text(traceback.format_exc(), encoding="utf-8")
