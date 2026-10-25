"""Local scene authority and review UI. No model-callable enrollment or approval."""
from pathlib import Path
import traceback
import pymxs
from pymxs import runtime as rt
from PySide6 import QtCore, QtWidgets
import qtmax

from .contracts import Fault
from .max_host import MaxHost
from .service import Journal, Service, uid
from .diagnostics import validate_page, collect_report, save_report
from .transport import Bridge, default_directory, private_directory

PANEL = None


class Panel(QtWidgets.QDialog):
    work_available=QtCore.Signal()

    def __init__(self, directory=None):
        super().__init__(qtmax.GetQMaxMainWindow())
        self.setWindowTitle("Cyrus • Automation")
        self.resize(490,650)
        self.setWindowFlag(QtCore.Qt.Tool,True)
        self.setAttribute(QtCore.Qt.WA_DeleteOnClose)
        # Keep Max's own shortcuts from consuming dialog input (notably Escape).
        # qtmax restores accelerators automatically when focus returns to Max.
        qtmax.DisableMaxAcceleratorsOnFocus(self,True)
        self.directory=private_directory(directory or default_directory())
        self.host=MaxHost()
        self.service=Service(self.host,Journal(self.directory/"operations.json"))
        self.closing=False
        self.dispatching=False
        self.timer=QtCore.QTimer(self)
        self.timer.setSingleShot(True)
        self.timer.timeout.connect(self.tick)
        self.recipe_timer=QtCore.QTimer(self)
        self.recipe_timer.setInterval(250)
        self.recipe_timer.timeout.connect(self.poll_recipe_catalog)
        self.preset_timer=QtCore.QTimer(self)
        self.preset_timer.setInterval(250)
        self.preset_timer.timeout.connect(lambda:self.action(self.poll_preset_catalog))
        self.asset_timer=QtCore.QTimer(self)
        self.asset_timer.setInterval(250)
        self.asset_timer.timeout.connect(lambda:self.action(self.poll_source_package))
        self.work_available.connect(self.schedule,QtCore.Qt.QueuedConnection)
        self.bridge=Bridge(self.directory,wake=self.work_available.emit)
        self.picked={"site":[],"sources":[],"regions":[],"excluded":[]}
        self.callbacks=[]
        self.trace_session=None
        self.trace_identity=None
        self.scene_task_dialog=None
        self.scene_task_signature=None
        self.layout=QtWidgets.QVBoxLayout(self)
        heading=QtWidgets.QLabel("Connect your selected scene to an assistant")
        heading.setStyleSheet("font-size:16px; font-weight:600; padding:6px 0;")
        self.layout.addWidget(heading)
        hint=QtWidgets.QLabel("Select objects in Max, then assign them below. Only this scope is shared. Each proposal needs your approval here.")
        hint.setWordWrap(True)
        self.layout.addWidget(hint)
        row=QtWidgets.QHBoxLayout()
        connect_scene=QtWidgets.QPushButton("Inspect selected scene objects (read-only)")
        connect_scene.clicked.connect(lambda:self.action(self.inspect_scene_selected))
        row.addWidget(connect_scene)
        self.scene_task_button=QtWidgets.QPushButton("Task details…")
        self.scene_task_button.clicked.connect(lambda:self.action(self.open_scene_task))
        row.addWidget(self.scene_task_button)
        self.layout.addLayout(row)
        self.button("Inspect selected Cyrus scatter (read-only)",self.inspect_selected)
        self.picks={}
        for key,title in (("site","Use selected site"),("sources","Use selected assets (1–3)"),("regions","Use selected planting splines (0–3)"),("excluded","Use selected protected splines (optional)")):
            row=QtWidgets.QHBoxLayout()
            button=QtWidgets.QPushButton(title)
            button.clicked.connect(lambda checked=False,k=key:self.action(lambda:self.pick(k)))
            text=QtWidgets.QLabel("None")
            text.setTextFormat(QtCore.Qt.PlainText)
            text.setWordWrap(True)
            row.addWidget(button)
            row.addWidget(text,1)
            self.layout.addLayout(row)
            self.picks[key]=text
        self.share=QtWidgets.QCheckBox("Allow this assistant to receive viewport images")
        self.share.setToolTip("Images can contain every visible object in the active viewport. Your MCP client may send them to its model provider.")
        self.share.toggled.connect(self.capture_permission)
        self.layout.addWidget(self.share)
        self.enroll_button=self.button("Connect selected scope",self.enroll)
        self.scope_label=QtWidgets.QLabel("No scope connected")
        self.scope_label.setTextFormat(QtCore.Qt.PlainText)
        self.scope_label.setWordWrap(True)
        self.layout.addWidget(self.scope_label)
        self.proposals=QtWidgets.QComboBox()
        self.proposals.currentIndexChanged.connect(self.review)
        self.layout.addWidget(self.proposals)
        self.review_text=QtWidgets.QPlainTextEdit()
        self.review_text.setReadOnly(True)
        self.layout.addWidget(self.review_text,1)
        self.approve_button=self.button("Approve displayed proposal",self.approve)
        self.button("Cancel pending proposal / revoke approval",self.cancel)
        self.undo_button=self.button("Undo last result / reject refinement",self.undo)
        self.button("Disconnect scope and continue manually",self.disconnect_scope)
        self.recovery_button=self.button("Review unresolved operation…",self.recover_locally)
        diagnostics=QtWidgets.QGroupBox("Engineering diagnostics • off until started")
        diagnostic_layout=QtWidgets.QVBoxLayout(diagnostics)
        row=QtWidgets.QHBoxLayout()
        for title, callback in (("Start recording",self.start_diagnostics),("Stop",self.stop_diagnostics),("Save report…",self.export_diagnostics)):
            button=QtWidgets.QPushButton(title)
            button.clicked.connect(lambda checked=False,fn=callback:self.action(fn))
            row.addWidget(button)
        diagnostic_layout.addLayout(row)
        self.trace_share=QtWidgets.QCheckBox("Share this recording with the connected assistant")
        self.trace_share.setToolTip("Explicitly shares this process-wide engineering trace, including events for other scatter controllers. No scene names, file paths, images or training labels are recorded by the built-in hooks. Sharing is revoked when the scope or recording changes.")
        self.trace_share.toggled.connect(lambda allowed:self.action(lambda:self.diagnostic_permission(allowed)))
        diagnostic_layout.addWidget(self.trace_share)
        note=QtWidgets.QLabel("At most 10 minutes / 4,096 events / 4 MiB. A new recording replaces the previous ring. Save stops recording and exports locally.")
        note.setWordWrap(True)
        diagnostic_layout.addWidget(note)
        self.layout.addWidget(diagnostics)
        self.status=QtWidgets.QLabel(self.service.last_message)
        self.status.setTextFormat(QtCore.Qt.PlainText)
        self.status.setWordWrap(True)
        self.layout.addWidget(self.status)
        self.setStyleSheet("QDialog {background:#353535; color:#eeeeee; font-family:'Segoe UI'; font-size:12px;} QLabel,QCheckBox {color:#eeeeee;} QPushButton {padding:6px; background:#515151; color:#eeeeee; border:1px solid #686868; border-radius:3px;} QPushButton:hover {background:#606060;} QPushButton:disabled {color:#969696; background:#414141;} QPlainTextEdit,QComboBox {background:#292929; color:#eeeeee; border:1px solid #606060; padding:4px;} QPlainTextEdit {font-family:Consolas;} QLabel {padding:2px;}")
        for event,callback in (("systemPreReset",self.scene_reset),("filePreOpen",self.scene_reset),("systemPreNew",self.scene_reset),("preRender",self.render_start),("postRender",self.render_end)):
            try:
                rt.callbacks.addScript(rt.Name(event),callback,id=rt.Name("CyrusAutomation"))
                self.callbacks.append(callback)
            except Exception:
                self.close()
                raise
        self.known=()
        self.refresh()  # Reflect restart recovery before the first client request.

    def button(self,text,callback):
        button=QtWidgets.QPushButton(text)
        button.clicked.connect(lambda:self.action(callback))
        self.layout.addWidget(button)
        return button

    def action(self,callback):
        try:
            callback()
        except Fault as exc:
            self.service.last_message=exc.code+": "+exc.message
        except Exception as exc:
            self.service.last_message="Action failed: "+str(exc)[:300]
            (self.directory/"host-error.log").write_text(traceback.format_exc(),encoding="utf-8")
        self.refresh()

    def pick(self,key):
        selected=list(rt.selection)
        if key == "site" and len(selected) != 1:
            raise Fault("INVALID_PLAN","Select exactly one site")
        if len(selected)>3:
            raise Fault("BUDGET_EXCEEDED","Choose at most three objects")
        if self.service.scope is not None:
            self.disconnect_scope()
            self.service.last_message="Selection changed. Connect the selected scope before requesting another proposal."
        self.picked[key]=selected
        self.picks[key].setText(", ".join(str(n.name) for n in selected) or "None")

    def capture_permission(self,allowed):
        # Revocation takes effect immediately; it never waits for re-enrollment.
        if self.service.scope is not None:
            self.service.scope["allow_capture"]=bool(allowed)

    def enroll(self):
        if len(self.picked["site"]) != 1:
            raise Fault("INVALID_PLAN","Choose one site first")
        scope=self.service.enroll(self.picked["site"][0],self.picked["sources"],self.picked["regions"],self.picked["excluded"],capture=self.share.isChecked())
        self.revoke_diagnostic_share()
        self.scope_label.setText("Connected: "+scope["site"]["label"]+" • "+str(len(scope["sources"]))+" assets")

    def inspect_selected(self):
        selected=list(rt.selection)
        if len(selected)!=1:
            raise Fault("INVALID_PLAN","Select exactly one Cyrus Scatter controller")
        self.service.observe(selected[0],capture=self.share.isChecked())
        self.revoke_diagnostic_share()
        self.scope_label.setText("Read-only inspection: "+str(selected[0].name))

    def scene_selection(self):
        from .scene import MAX_OBJECTS
        count=len(rt.selection)
        if not 1<=count<=MAX_OBJECTS:
            raise Fault("BUDGET_EXCEEDED","Select 1–32 objects for this scene task")
        return [rt.selection[i] for i in range(count)]

    def inspect_scene_selected(self):
        self.service.inspect_scene(self.scene_selection())
        self.revoke_diagnostic_share()
        self.scope_label.setText("Read-only scene task • "+str(len(self.host.scene_nodes))+" shared objects")
        self.open_scene_task()

    def open_scene_task(self):
        if self.service.task is None or not self.service.scope:
            raise Fault("APPROVAL_REQUIRED","Connect a scene task first")
        if self.service.scope["kind"]=="design":self.service.scope["task_snapshot"]=self.host.scene_snapshot()
        if self.scene_task_dialog is None:
            from .scene import ROLES,MAX_BRIEF
            dialog=QtWidgets.QDialog(self)
            dialog.setWindowTitle("Cyrus • Scene task • read-only")
            dialog.resize(580,540)
            layout=QtWidgets.QVBoxLayout(dialog)
            hint=QtWidgets.QLabel("Describe the result and correct object roles. Roles describe use; they never grant editing permission. Highlight changes Max selection only.")
            hint.setWordWrap(True);layout.addWidget(hint)
            self.task_stage=QtWidgets.QLabel()
            self.task_stage.setWordWrap(True);layout.addWidget(self.task_stage)
            self.task_brief=QtWidgets.QLineEdit()
            self.task_brief.setMaxLength(MAX_BRIEF)
            self.task_brief.setPlaceholderText("Optional brief: a natural meadow here; keep the entrance clear…")
            layout.addWidget(self.task_brief)
            save=QtWidgets.QPushButton("Save task brief")
            save.clicked.connect(lambda:self.action(lambda:self.service.update_scene_brief(self.task_brief.text())))
            layout.addWidget(save)
            tabs=QtWidgets.QTabWidget()
            self.task_tabs=tabs
            layout.addWidget(tabs,1)
            scene_page=QtWidgets.QWidget();content_page=QtWidgets.QWidget()
            content_scroll=QtWidgets.QScrollArea();content_scroll.setWidgetResizable(True);content_scroll.setWidget(content_page)
            tabs.addTab(scene_page,"Scene objects");tabs.addTab(content_scroll,"Shared content")
            layout=QtWidgets.QVBoxLayout(scene_page)
            content_layout=QtWidgets.QVBoxLayout(content_page)
            explanation=QtWidgets.QLabel("Share content explicitly. Names, descriptions, tags, saved role/layer labels and selected typed preset settings may be sent to the assistant. Image pixels and import permission require their own actions.")
            explanation.setWordWrap(True);content_layout.addWidget(explanation)
            self.task_objects=QtWidgets.QTreeWidget()
            self.task_objects.setColumnCount(3)
            self.task_objects.setHeaderLabels(["Shared object","Assigned roles","Status"])
            self.task_objects.setSelectionMode(QtWidgets.QAbstractItemView.ExtendedSelection)
            self.task_objects.setTextElideMode(QtCore.Qt.ElideRight)
            self.task_objects.setHorizontalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOff)
            header=self.task_objects.header()
            header.setStretchLastSection(False)
            header.setSectionResizeMode(0,QtWidgets.QHeaderView.Stretch)
            header.setSectionResizeMode(1,QtWidgets.QHeaderView.Fixed)
            header.setSectionResizeMode(2,QtWidgets.QHeaderView.Fixed)
            header.resizeSection(1,160);header.resizeSection(2,80)
            layout.addWidget(self.task_objects,1)
            row=QtWidgets.QHBoxLayout()
            self.task_role=QtWidgets.QComboBox()
            self.task_role.addItems(ROLES)
            row.addWidget(self.task_role)
            self.task_role_buttons=[]
            for title,callback in (("Assign to Max selection",lambda:self.correct_scene_role(False)),
                                   ("Remove role from table rows",self.remove_table_role)):
                button=QtWidgets.QPushButton(title)
                button.clicked.connect(lambda checked=False,fn=callback:self.action(fn))
                row.addWidget(button)
                self.task_role_buttons.append(button)
            layout.addLayout(row)
            highlight=QtWidgets.QPushButton("Highlight selected table objects in Max")
            highlight.clicked.connect(lambda:self.action(self.highlight_scene_task))
            layout.addWidget(highlight)
            self.task_share_more=QtWidgets.QPushButton("Share selected context objects with this task")
            self.task_share_more.clicked.connect(lambda:self.action(lambda:self.service.extend_scene(self.scene_selection())))
            layout.addWidget(self.task_share_more)
            row=QtWidgets.QHBoxLayout()
            self.catalog_share=QtWidgets.QPushButton("Share / refresh installed plant catalog")
            self.catalog_share.setToolTip("Shares installed model names, categories and hashes only. Reads bounded catalog/previews; never imports. No personal recipes or file paths are shared. Refresh locally after content changes.")
            self.catalog_share.clicked.connect(lambda:self.action(self.service.share_installed_catalog))
            row.addWidget(self.catalog_share)
            self.catalog_revoke=QtWidgets.QPushButton("Revoke catalog sharing")
            self.catalog_revoke.clicked.connect(lambda:self.action(self.service.revoke_installed_catalog))
            row.addWidget(self.catalog_revoke)
            content_layout.addLayout(row)
            self.catalog_status=QtWidgets.QLabel()
            self.catalog_status.setTextFormat(QtCore.Qt.PlainText)
            self.catalog_status.setWordWrap(True);content_layout.addWidget(self.catalog_status)
            row=QtWidgets.QHBoxLayout()
            self.installed_sources_enable=QtWidgets.QPushButton("Enable installed source proposals")
            self.installed_sources_enable.clicked.connect(lambda:self.action(self.service.enable_installed_sources))
            row.addWidget(self.installed_sources_enable)
            self.installed_sources_revoke=QtWidgets.QPushButton("Revoke installed source permission")
            self.installed_sources_revoke.clicked.connect(lambda:self.action(self.service.revoke_installed_sources))
            row.addWidget(self.installed_sources_revoke);content_layout.addLayout(row)
            self.installed_sources_status=QtWidgets.QLabel()
            self.installed_sources_status.setTextFormat(QtCore.Qt.PlainText);self.installed_sources_status.setWordWrap(True)
            content_layout.addWidget(self.installed_sources_status)
            row=QtWidgets.QHBoxLayout()
            self.source_share=QtWidgets.QPushButton("Share prepared source package…")
            self.source_share.clicked.connect(lambda:self.action(self.choose_source_package))
            row.addWidget(self.source_share)
            self.source_revoke=QtWidgets.QPushButton("Revoke prepared sources")
            self.source_revoke.clicked.connect(lambda:self.action(self.service.revoke_source_package))
            row.addWidget(self.source_revoke);content_layout.addLayout(row)
            self.source_status=QtWidgets.QLabel()
            self.source_status.setTextFormat(QtCore.Qt.PlainText);self.source_status.setWordWrap(True)
            content_layout.addWidget(self.source_status)
            note=QtWidgets.QLabel("Share source names, physical dimensions and package revision with the assistant. This separate grant permits proposals to create hidden source copies only. Every import still needs exact approval below. Existing scene objects remain read-only; .max model files are not imported here.")
            note.setWordWrap(True);content_layout.addWidget(note)
            row=QtWidgets.QHBoxLayout()
            self.recipe_personal=QtWidgets.QPushButton("Share My recipes")
            self.recipe_personal.clicked.connect(lambda:self.action(lambda:self.share_recipes("personal_recipes")))
            row.addWidget(self.recipe_personal)
            self.recipe_custom=QtWidgets.QPushButton("Choose recipe folder…")
            self.recipe_custom.clicked.connect(lambda:self.action(self.choose_recipe_folder))
            row.addWidget(self.recipe_custom)
            self.recipe_revoke=QtWidgets.QPushButton("Revoke recipes")
            self.recipe_revoke.clicked.connect(lambda:self.action(self.service.revoke_recipe_catalog))
            row.addWidget(self.recipe_revoke)
            content_layout.addLayout(row)
            self.recipe_status=QtWidgets.QLabel()
            self.recipe_status.setWordWrap(True);self.recipe_status.setTextFormat(QtCore.Qt.PlainText)
            content_layout.addWidget(self.recipe_status)
            note=QtWidgets.QLabel("Scans run in a separate native file worker. Only a completed metadata snapshot becomes searchable; payloads, physical scale and destination compatibility remain unchecked. Refresh locally after content changes.")
            note.setWordWrap(True);content_layout.addWidget(note)
            row=QtWidgets.QHBoxLayout()
            self.preset_personal=QtWidgets.QPushButton("Share My presets")
            self.preset_personal.clicked.connect(lambda:self.action(lambda:self.share_presets("personal_presets")))
            row.addWidget(self.preset_personal)
            self.preset_custom=QtWidgets.QPushButton("Choose preset folder…")
            self.preset_custom.clicked.connect(lambda:self.action(self.choose_preset_folder));row.addWidget(self.preset_custom)
            self.preset_revoke=QtWidgets.QPushButton("Revoke presets")
            self.preset_revoke.clicked.connect(lambda:self.action(self.service.revoke_preset_catalog));row.addWidget(self.preset_revoke)
            content_layout.addLayout(row)
            self.preset_status=QtWidgets.QLabel();self.preset_status.setTextFormat(QtCore.Qt.PlainText);self.preset_status.setWordWrap(True)
            content_layout.addWidget(self.preset_status)
            note=QtWidgets.QLabel("Shares names and selected typed settings from a frozen native snapshot. Settings presets differ from complete planting recipes. No application or scene changes are authorized; refresh after files change.")
            note.setWordWrap(True);content_layout.addWidget(note)
            content_layout.addStretch(1)
            self.task_enable_design=QtWidgets.QPushButton("Enable design proposals…")
            self.task_enable_design.clicked.connect(lambda:self.action(self.prepare_scene_design))
            layout.addWidget(self.task_enable_design)
            note=QtWidgets.QLabel("Measurements are explicit snapshots; metadata does not certify geometry. Unshared neighbors are omitted. The explicit design handoff retains this task; disconnect, scene open/reset or an unrelated enrollment clears its transient memory.")
            note.setWordWrap(True);layout.addWidget(note)
            self.scene_task_dialog=dialog
        self.refresh_scene_task()
        self.scene_task_dialog.show()

    def correct_scene_role(self, remove):
        ids=self.host.scene_selection_ids(self.scene_selection())
        self.service.assign_scene_role(self.task_role.currentText(),ids,remove)

    def remove_table_role(self):
        ids=[item.data(0,QtCore.Qt.UserRole) for item in self.task_objects.selectedItems()]
        self.service.assign_scene_role(self.task_role.currentText(),ids,True)

    def prepare_scene_design(self):
        import json
        review=self.service.prepare_task_design()
        lines=["Enable bounded design proposals for this task?", ""]
        for role,items in review["inputs"].items():
            lines.append(role+": "+(", ".join(item["label"]+" • "+item["object_type"] for item in items) or "None"))
        lines.extend(["", "Area: "+review["region_policy"].replace("_"," "),
                      "Task objects stay read-only. Preserve does not create a canopy setback.",
                      "No nodes are created now. Every later change needs exact local approval.",
                      "Viewport capture remains off until separately enabled locally."])
        box=QtWidgets.QMessageBox(self)
        box.setWindowTitle("Review task design scope")
        box.setTextFormat(QtCore.Qt.PlainText)
        box.setText("\n".join(lines))
        box.setDetailedText(json.dumps(review,indent=2))
        box.setStandardButtons(QtWidgets.QMessageBox.Ok|QtWidgets.QMessageBox.Cancel)
        box.button(QtWidgets.QMessageBox.Ok).setText("Enable proposals")
        box.setDefaultButton(QtWidgets.QMessageBox.Cancel)
        if box.exec()!=QtWidgets.QMessageBox.Ok:
            self.service.task_design_review=None
            self.service.last_message="Design enrollment cancelled; task remains read-only."
            return
        scope=self.service.connect_task_design(review["review_id"],review["digest"])
        self.revoke_diagnostic_share()
        self.share.blockSignals(True);self.share.setChecked(False);self.share.blockSignals(False)
        self.scope_label.setText("Design task connected: "+scope["site"]["label"])

    def highlight_scene_task(self):
        if self.service.task is None or not self.service.scope:
            raise Fault("APPROVAL_REQUIRED","Connect a scene task first")
        ids=[item.data(0,QtCore.Qt.UserRole) for item in self.task_objects.selectedItems()]
        self.host.highlight_scene(ids)

    def refresh_scene_task(self):
        if self.scene_task_dialog is None:return
        source_idle=bool(self.service.scope and self.service.scope["kind"]=="scene_inspection" and self.service.pending is None and not self.service.recovery_required)
        source_supported=self.host.source_asset_adapter().supported()
        self.source_share.setEnabled(source_idle and source_supported)
        self.source_revoke.setEnabled(bool(self.service.asset_grant and self.service.pending is None))
        grant=self.service.asset_grant
        self.source_status.setText(("Prepared sources: "+grant["status"]+(" • "+str(len(grant["entries"]))+" meshes" if grant["status"]=="ready" else "")) if grant else
                                  "Prepared source package is not shared" if source_supported else "Prepared sources need the matching native metadata/tracked-stage build")
        shared=self.service.library_grant
        permission=self.service.installed_source_grant
        linked=sum(row.get("prepared_source",{}).get("status")=="prepared" for row in shared["entries"]) if shared else 0
        self.installed_sources_enable.setEnabled(source_idle and source_supported and self.host.source_asset_adapter().cohort_supported() and linked>0 and permission is None)
        self.installed_sources_revoke.setEnabled(permission is not None and self.service.pending is None)
        self.installed_sources_status.setText(("Installed source proposals enabled • "+str(permission["preparations_remaining"])+" preparations remaining") if permission else
            str(linked)+" models have linked derivatives. Enable to let the assistant prepare up to three selected sources at a time. No scene objects are created until you approve the exact import proposal.")
        self.catalog_status.setText((str(len(shared["entries"]))+" installed model entries shared • frozen metadata; import readiness unchecked") if shared else "Installed catalog is not shared")
        self.catalog_share.setEnabled(bool(self.service.scope and self.service.task is not None and self.service.pending is None))
        self.catalog_revoke.setEnabled(shared is not None)
        recipes=self.service.recipe_grant
        available=self.host.recipe_catalog_version()==1
        idle=bool(self.service.scope and self.service.task is not None and self.service.pending is None)
        self.recipe_personal.setEnabled(idle and available);self.recipe_custom.setEnabled(idle and available)
        self.recipe_revoke.setEnabled(recipes is not None)
        presets=self.service.preset_grant;preset_available=self.host.preset_catalog_version()==1
        self.preset_personal.setEnabled(idle and preset_available);self.preset_custom.setEnabled(idle and preset_available)
        self.preset_revoke.setEnabled(presets is not None)
        if presets is None:self.preset_status.setText("Settings presets are not shared" if preset_available else "Settings preset discovery needs the matching native catalog build")
        elif presets["status"]=="failed":self.preset_status.setText("Settings preset scan failed; review the folder and refresh locally")
        else:self.preset_status.setText(("Scanning settings presets" if presets["status"]=="scanning" else "Settings preset snapshot ready")+
            " • "+str(presets["entry_count"])+" valid; "+str(presets["invalid"])+" invalid"+(" • catalog limit reached" if presets["limited"] else ""))
        if recipes is None:self.recipe_status.setText("Recipe folder is not shared" if available else "Recipe discovery needs the matching native catalog API build")
        elif recipes["status"]=="failed":self.recipe_status.setText("Recipe scan failed • review the folder and refresh locally")
        else:self.recipe_status.setText(("Scanning recipes" if recipes["status"]=="scanning" else "Recipe snapshot ready")+
            " • "+str(recipes["entry_count"])+" valid; "+str(recipes["invalid"])+" invalid"+(" • catalog limit reached" if recipes["limited"] else ""))
        from .contracts import digest
        connected=bool(self.service.task is not None and self.service.scope)
        inspection=connected and self.service.scope["kind"]=="scene_inspection"
        self.scene_task_dialog.setEnabled(connected)
        for control in [self.task_role,*self.task_role_buttons,self.task_share_more,self.task_enable_design]:control.setEnabled(bool(inspection))
        self.task_stage.setText("Read-only inspection • roles never grant editing permission" if inspection else "Design connected • bindings are locked; each write requires exact local approval" if connected else "No scene task connected")
        data=(self.service.task,self.service.scope["snapshot"] if inspection else self.service.scope["task_snapshot"]) if connected else None
        signature=digest(data)
        if signature==self.scene_task_signature:return
        self.scene_task_signature=signature
        self.task_objects.clear()
        if not connected:
            self.task_brief.clear()
            return
        if not self.task_brief.hasFocus():self.task_brief.setText(self.service.task["brief"])
        for card in data[1]["objects"]:
            roles=self.service.task["roles"].get(card["object_id"],[])
            label=card.get("label","Missing object")+" • "+card.get("object_type","missing")
            item=QtWidgets.QTreeWidgetItem([label,", ".join(roles) or "Unassigned",card["status"]])
            item.setData(0,QtCore.Qt.UserRole,card["object_id"])
            item.setToolTip(0,card["object_id"]+" • "+card.get("object_type","missing"))
            item.setToolTip(1,", ".join(roles) or "Unassigned")
            self.task_objects.addTopLevelItem(item)

    def review(self):
        vid=self.proposals.currentData()
        proposal=self.service.validations.get(vid)
        if not proposal:
            self.review_text.setPlainText("Waiting for an assistant proposal.")
            return
        if "asset_use" in proposal:
            value=proposal["asset_use"]
            lines=[value["name"],"",value["effects_summary"],"", "Prepared revision: "+value["package_revision"]]
            for entry in value["sources"]:
                geometry=entry["geometry"]
                lines.append(entry["name"]+": "+" × ".join(format(v,".5g") for v in geometry["local_aabb_m"]["size"])+" m • "+str(geometry["triangles"])+" triangles")
            lines.extend(["",str(value["resources"]["file_bytes"])+" prepared payload bytes; "+str(value["resources"]["image_pixels"])+" image pixels (package resource upper bounds).",
                          value["undo"],"No placements are calculated. Enabling planting proposals is a separate local step.",
                          "Approval applies to these exact source copies and expires in five minutes."])
            self.review_text.setPlainText("\n".join(lines));return
        plan=proposal["plan"]
        if "change" in proposal:
            import json
            lines=[plan["name"], "", proposal["effect"].replace("_", " "),
                   "Publication: "+proposal["publication_effect"].replace("_", " "),
                   "Layer identities and unmentioned settings are preserved.", ""]
            for item in proposal["changes"]:
                lines.append(item["name"]+": "+item["field"]+" "+str(item["before"])+" → "+str(item["after"]))
            lines.extend(["", "Authored candidate total: "+str(proposal["requested_instances"]),
                          "Count is a candidate budget; accepted output may be lower.",
                          "Approval applies to this exact operation; expires in five minutes."])
            self.review_text.setPlainText("\n".join(lines))
            return
        regions={r["region_id"]:r["label"] for r in self.service.scope["regions"]}
        sources={s["source_id"]:s["label"] for s in self.service.scope["sources"]}
        lines=[plan["name"],"",proposal["effect"].replace("_"," "),"Derived mask shapes: "+str(proposal["derived_masks"]),""]
        for layer in plan["layers"]:
            lines.extend([layer["name"]+" on "+regions[layer["region_id"]],f"  {layer['count']} requested • seed {layer['seed']}","  Assets: "+", ".join(sources[s["source_id"]]+" ("+str(s["weight"])+")" for s in layer["sources"]),f"  Scale {layer['scale']} • yaw {layer['yaw_degrees']}°",f"  Underfill: {layer['underfill']}",""])
            import json
            lines.extend(["  Layer settings: "+json.dumps(layer["settings"],sort_keys=True),"  Exclusions: "+str(layer["exclude_region_ids"]),"  Asset settings: "+json.dumps([s["settings"] for s in layer["sources"]],sort_keys=True)])
        lines.extend(["Display: "+json.dumps(plan["display"],sort_keys=True),"Layer pair rules: "+json.dumps(plan["pair_rules"],sort_keys=True)])
        lines.extend(["Clearance: "+str(plan.get("clearance_m",0))+" metres","Existing site, assets and authored regions stay read-only.","Approval applies to this exact proposal; expires in five minutes."])
        self.review_text.setPlainText("\n".join(lines))

    def approve(self):
        self.service.approve(self.proposals.currentData())

    def cancel(self):
        self.service.cancel()
        if not self.service.recovery_required:
            self.service.last_message="Pending proposal cancelled; approvals revoked. A finished result can be undone below."

    def recover_locally(self):
        records=self.service.unresolved_operations()
        if not records:
            raise Fault("UNKNOWN_REFERENCE","No unresolved operation to review")
        labels=[r["operation_id"]+" • "+str(r["effects"])+" • "+str(r["state"]) for r in records]
        index=0
        if len(records)>1:
            chosen,accepted=QtWidgets.QInputDialog.getItem(self,"Review recovery","Operation",labels,0,False)
            if not accepted:return
            index=labels.index(chosen)
        review=self.service.prepare_local_recovery(records[index]["operation_id"],list(rt.selection))
        evidence=review["evidence"]
        node=evidence.get("selected_controller")
        box=QtWidgets.QMessageBox(self)
        box.setWindowTitle("Keep scene and retire operation")
        box.setIcon(QtWidgets.QMessageBox.Warning)
        box.setTextFormat(QtCore.Qt.PlainText)
        box.setText("Recorded effects: "+review["effects"]+".\nKeep the current scene and retire this operation without replay?")
        summary=("Selected setup: "+str(node.get("owner_id") or "unassigned")+"\nCached accepted plants: "+str(node.get("accepted_count","unavailable"))) if node else "No setup selected. The operation target has not been verified."
        box.setInformativeText(summary+"\n\n"+evidence["comparison"]+"\n\nInspect the scene manually first. Unknown effects remain unknown. This does not Undo changes or authorize another task; fresh enrollment and proposal approval are required.")
        import json
        box.setDetailedText(json.dumps(review,indent=2,sort_keys=True))
        box.setStandardButtons(QtWidgets.QMessageBox.Yes|QtWidgets.QMessageBox.No)
        box.button(QtWidgets.QMessageBox.Yes).setText("Retire operation")
        box.setDefaultButton(QtWidgets.QMessageBox.No)
        if box.exec()==QtWidgets.QMessageBox.Yes:
            self.service.confirm_local_recovery(review["review_id"],review["digest"])
            self.revoke_diagnostic_share()
            self.scope_label.setText("Recovery reviewed locally; no scope connected")

    def undo(self):
        self.service.undo()
        if self.service.scope is None:
            self.revoke_diagnostic_share()
            self.scope_label.setText("No scope connected")
        elif self.service.recovery_required:
            self.scope_label.setText("Undo needs local review; further changes are blocked")

    def disconnect_scope(self):
        self.service.reset()
        self.revoke_diagnostic_share()
        self.service.last_message="Scope disconnected. The procedural result remains editable in Cyrus."
        self.scope_label.setText("No scope connected")

    def choose_source_package(self):
        path=QtWidgets.QFileDialog.getExistingDirectory(self,"Share a prepared source package; enable import proposals")
        if path:self.share_source_package(path)

    def share_source_package(self,path):
        self.service.share_source_package(path)
        self.asset_timer.start()

    def poll_source_package(self):
        if not self.service.poll_source_package():self.asset_timer.stop()

    def share_recipes(self,kind,root=None):
        self.service.share_recipe_catalog(kind,root)
        self.recipe_timer.start()

    def choose_recipe_folder(self):
        path=QtWidgets.QFileDialog.getExistingDirectory(self,"Share recipe metadata from this folder")
        if path:self.share_recipes("custom_recipes",path)

    def share_presets(self,kind,root=None):
        self.service.share_preset_catalog(kind,root);self.preset_timer.start()

    def choose_preset_folder(self):
        path=QtWidgets.QFileDialog.getExistingDirectory(self,"Share settings preset metadata and selected frozen settings")
        if path:self.share_presets("custom_presets",path)

    def poll_preset_catalog(self):
        self.service.poll_preset_catalog()
        if not self.service.preset_grant or self.service.preset_grant["status"]!="scanning":self.preset_timer.stop()

    def poll_recipe_catalog(self):
        if self.closing or self.bridge.closed:
            self.recipe_timer.stop();self.service.revoke_recipe_catalog();return
        if self.dispatching:return
        grant=self.service.recipe_grant
        if grant is None or grant["status"]!="scanning":self.recipe_timer.stop();return
        if self.host.busy():return
        self.service.poll_recipe_catalog()
        self.refresh()

    def scene_reset(self):
        try:
            self.stop_diagnostics()
        except Exception:
            pass
        self.service.reset()
        self.revoke_diagnostic_share()
        self.host.nodes,self.host.controllers,self.host.masks={},{},{}
        self.picked={"site":[],"sources":[],"regions":[],"excluded":[]}
        for text in self.picks.values():
            text.setText("None")
        self.scope_label.setText("Scene changed; choose a new scope")
        self.service.last_message=("Scene changed. An operation still needs local recovery review." if self.service.recovery_required
                                   else "Scene changed; choose a new scope.")
        self.refresh()  # Revoke task controls immediately, before another client request.

    def revoke_diagnostic_share(self):
        self.service.diagnostic_session=None
        self.trace_share.blockSignals(True)
        self.trace_share.setChecked(False)
        self.trace_share.blockSignals(False)

    def start_diagnostics(self):
        session=uid("trace")
        identity=self.host.version()
        self.host.diagnostic_start(session)
        self.trace_session,self.trace_identity=session,identity
        self.revoke_diagnostic_share()
        self.service.last_message="Recording engineering events locally: "+session

    def stop_diagnostics(self):
        if self.trace_session is None:
            return
        validate_page(self.host.diagnostic_page(0,1),self.trace_session,0,1)
        self.host.diagnostic_stop()
        self.service.last_message="Recording stopped. The bounded history is available to save."

    def diagnostic_permission(self,allowed):
        if not allowed:
            self.service.diagnostic_session=None
            return
        if self.trace_session is None or self.service.scope is None:
            self.revoke_diagnostic_share()
            raise Fault("APPROVAL_REQUIRED","Start a recording and connect a scope before sharing it")
        validate_page(self.host.diagnostic_page(0,1),self.trace_session,0,1)
        self.service.diagnostic_session=self.trace_session
        self.service.last_message="Shared engineering session: "+self.trace_session

    def export_diagnostics(self):
        if self.trace_session is None:
            raise Fault("UNKNOWN_REFERENCE","Start a recording first")
        path,_=QtWidgets.QFileDialog.getSaveFileName(self,"Save Cyrus diagnostic report",self.trace_session+".json","JSON report (*.json)")
        if not path:
            return
        self.stop_diagnostics()
        report=collect_report(self.host.diagnostic_page,self.trace_session,
                              {"at_start":self.trace_identity,"at_export":self.host.version()})
        save_report(path,report)
        health=report["recording"]["health"]
        self.service.last_message=f"Report saved: {health['retained']} events; evicted {health['evicted']}, lock drops {health['lock_drops']}, failures {health['failures']}, truncated {health['truncated']}."

    def render_start(self):
        self.host.blocked=True

    def render_end(self):
        self.host.blocked=False

    def refresh(self):
        self.refresh_scene_task()
        self.scene_task_button.setEnabled(bool(self.service.scope and self.service.task is not None))
        known=tuple(self.service.validations)
        if known != self.known:
            self.known=known
            self.proposals.blockSignals(True)
            self.proposals.clear()
            for vid,record in self.service.validations.items():
                self.proposals.addItem(record["asset_use"]["name"] if "asset_use" in record else record["plan"]["name"],vid)
            self.proposals.setCurrentIndex(self.proposals.count()-1)
            self.proposals.blockSignals(False)
            self.review()
        if self.status.text()!=self.service.last_message:
            self.status.setText(self.service.last_message)
        enabled=bool(self.proposals.currentData()) and self.service.pending is None and not self.service.recovery_required and not (self.service.scope or {}).get("stale")
        if self.approve_button.isEnabled()!=enabled:
            self.approve_button.setEnabled(enabled)
        self.recovery_button.setEnabled(bool(self.service.unresolved_operations()) and self.service.pending is None)
        self.enroll_button.setEnabled(not self.service.recovery_required)
        self.undo_button.setEnabled(bool(self.service.last_undo) and self.service.pending is None
                                    and not self.service.recovery_required and not (self.service.scope or {}).get("stale"))

    @QtCore.Slot()
    def schedule(self):
        if not self.closing and not self.dispatching and not self.bridge.closed and not self.timer.isActive():
            self.timer.start(0)

    def tick(self):
        if self.closing or self.dispatching or self.bridge.closed:
            return
        self.dispatching=True
        try:
            # A queued apply receives its response before execution on a later UI tick.
            if self.service.pending and not self.host.busy():
                self.service.step()
            self.bridge.drain_one(self.service)
            if self.service.asset_grant and self.service.asset_grant["status"]=="preparing" and not self.asset_timer.isActive():self.asset_timer.start()
            self.refresh()
            if self.service.pending or not self.bridge.queue.empty():
                self.timer.start(100)
        except Exception:
            self.timer.stop()
            self.recipe_timer.stop()
            self.preset_timer.stop()
            self.asset_timer.stop()
            self.service.cancel()
            self.service.revoke_source_package()
            self.service.revoke_recipe_catalog()
            self.service.revoke_preset_catalog()
            self.bridge.close()
            self.service.last_message="Automation stopped after a host error. Inspect the scene before reconnecting."
            (self.directory/"host-error.log").write_text(traceback.format_exc(),encoding="utf-8")
            self.status.setText(self.service.last_message)
        finally:
            self.dispatching=False

    def closeEvent(self,event):
        global PANEL
        self.closing=True
        self.timer.stop()
        self.recipe_timer.stop()
        self.preset_timer.stop()
        self.asset_timer.stop()
        try:
            self.stop_diagnostics()
        except Exception:
            pass
        try:
            self.service.cancel()
            self.service.revoke_source_package()
            self.service.revoke_recipe_catalog()
            self.service.revoke_preset_catalog()
        finally:
            try:
                self.host.clear_scene_selection()
                self.service.task=None
                self.service.task_design_review=None
                self.service.library_grant=None
                self.service.installed_source_grant=None
                self.service.source_preparations.clear()
                rt.callbacks.removeScripts(id=rt.Name("CyrusAutomation"))
            finally:
                self.bridge.close()
                PANEL=None
                event.accept()

    def reject(self):
        # QDialog's default Escape behavior only hides it; our connection and
        # dispatch timer must actually close when the artist dismisses the UI.
        self.close()


def start(directory=None):
    global PANEL
    if PANEL is not None:
        PANEL.show()
        PANEL.raise_()
        return PANEL
    PANEL=Panel(directory)
    PANEL.show()
    return PANEL
