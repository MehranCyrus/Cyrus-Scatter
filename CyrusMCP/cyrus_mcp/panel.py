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
        self.work_available.connect(self.schedule,QtCore.Qt.QueuedConnection)
        self.bridge=Bridge(self.directory,wake=self.work_available.emit)
        self.picked={"site":[],"sources":[],"regions":[],"excluded":[]}
        self.callbacks=[]
        self.trace_session=None
        self.trace_identity=None
        self.layout=QtWidgets.QVBoxLayout(self)
        heading=QtWidgets.QLabel("Connect your selected scene to an assistant")
        heading.setStyleSheet("font-size:16px; font-weight:600; padding:6px 0;")
        self.layout.addWidget(heading)
        hint=QtWidgets.QLabel("Select objects in Max, then assign them below. Only this scope is shared. Each proposal needs your approval here.")
        hint.setWordWrap(True)
        self.layout.addWidget(hint)
        self.button("Inspect selected Cyrus scatter (read-only)",self.inspect_selected)
        self.picks={}
        for key,title in (("site","Use selected site"),("sources","Use selected assets (1–3)"),("regions","Use selected planting splines (1–3)"),("excluded","Use selected protected splines (optional)")):
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
        self.button("Undo last result / reject refinement",self.undo)
        self.button("Disconnect scope and continue manually",self.disconnect_scope)
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

    def review(self):
        vid=self.proposals.currentData()
        proposal=self.service.validations.get(vid)
        if not proposal:
            self.review_text.setPlainText("Waiting for an assistant proposal.")
            return
        plan=proposal["plan"]
        regions={r["region_id"]:r["label"] for r in self.service.scope["regions"]}
        sources={s["source_id"]:s["label"] for s in self.service.scope["sources"]}
        lines=[plan["name"],"",proposal["effect"].replace("_"," "),"Derived mask shapes: "+str(proposal["derived_masks"]),""]
        for layer in plan["layers"]:
            lines.extend([layer["name"]+" on "+regions[layer["region_id"]],f"  {layer['count']} requested • seed {layer['seed']}","  Assets: "+", ".join(sources[s["source_id"]]+" ("+str(s["weight"])+")" for s in layer["sources"]),f"  Scale {layer['scale']} • yaw {layer['yaw_degrees']}°",f"  Underfill: {layer['underfill']}",""])
            if plan["schema_version"]=="2.0":
                import json
                lines.extend(["  Layer settings: "+json.dumps(layer["settings"],sort_keys=True),"  Exclusions: "+str(layer["exclude_region_ids"]),"  Asset settings: "+json.dumps([s["settings"] for s in layer["sources"]],sort_keys=True)])
        if plan["schema_version"]=="2.0":lines.extend(["Display: "+json.dumps(plan["display"],sort_keys=True),"Layer pair rules: "+json.dumps(plan["pair_rules"],sort_keys=True)])
        lines.extend(["Clearance: "+str(plan.get("clearance_m",0))+" metres","Existing site, assets and authored regions stay read-only.","Approval applies to this exact proposal; expires in five minutes."])
        self.review_text.setPlainText("\n".join(lines))

    def approve(self):
        self.service.approve(self.proposals.currentData())

    def cancel(self):
        self.service.cancel()
        self.service.last_message="Pending proposal cancelled; approvals revoked. A finished result can be undone below."

    def undo(self):
        self.service.undo()
        self.scope_label.setText("No scope connected")

    def disconnect_scope(self):
        self.service.reset()
        self.revoke_diagnostic_share()
        self.service.last_message="Scope disconnected. The procedural result remains editable in Cyrus."
        self.scope_label.setText("No scope connected")

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
        known=tuple(self.service.validations)
        if known != self.known:
            self.known=known
            self.proposals.blockSignals(True)
            self.proposals.clear()
            for vid,record in self.service.validations.items():
                self.proposals.addItem(record["plan"]["name"],vid)
            self.proposals.setCurrentIndex(self.proposals.count()-1)
            self.proposals.blockSignals(False)
            self.review()
        if self.status.text()!=self.service.last_message:
            self.status.setText(self.service.last_message)
        enabled=bool(self.proposals.currentData()) and self.service.pending is None
        if self.approve_button.isEnabled()!=enabled:
            self.approve_button.setEnabled(enabled)

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
            self.refresh()
            if self.service.pending or not self.bridge.queue.empty():
                self.timer.start(100)
        except Exception:
            self.timer.stop()
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
        try:
            self.stop_diagnostics()
        except Exception:
            pass
        try:
            self.service.cancel()
        finally:
            try:
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
