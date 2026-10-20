"""Runs inside an owned Max host; measure actual queued panel mounting."""
from pathlib import Path
import json, os, time, traceback
from pymxs import runtime as rt
from PySide6.QtCore import QTimer

H = Path(str(rt.MCPFixtureDir)).resolve()
assert H.name.startswith("update08671-")
R = {"status": "running", "version": str(rt.CyrusLibraryVersion()), "pid": os.getpid(),
     "scope": "Empty controller, Manual; ten repetitions per open-state condition; observed readiness includes event-loop scheduling.", "samples": []}
cases = [(f"two-{i}", False) for i in range(10)] + [(f"all-{i}", True) for i in range(10)]
phase = index = ticks = 0
start = select_ms = first_ready = 0.
root = node = None

def save():
    (H / "panel-probe.json").write_text(json.dumps(R, indent=2), encoding="utf-8")

def snap():
    return json.loads(str(rt.cyrusDiagnosticSnapshot(0, 500)))

def tick():
    global phase, index, start, select_ms, ticks, root, node, first_ready
    timer.stop()
    try:
        if phase == 0:
            rt.execute('global PanelResearchNode=AminScatterObject name:"Panel owned"; global PanelResearchRoot=PanelResearchNode.baseObject')
            node, root = rt.PanelResearchNode, rt.PanelResearchRoot
            root.newLayer()
            root.updateMode = 1
            rt.clearSelection()
            rt.execute("max modify mode")
            phase = 1
            timer.start(500)
            return
        if phase == 1:
            label, all_open = cases[index]
            rt.execute("PanelResearchRoot.uiPresentationState=for i=1 to 12 collect #(" +
                       ("true" if all_open else "(i==1 or i==2)") + ",undefined,undefined)")
            rt.cyrusDiagnosticStart(label, 4096, 4194304, 60000)
            start = time.perf_counter()
            rt.select(node)
            select_ms = (time.perf_counter() - start) * 1000
            ticks, phase = 0, 2
            first_ready=0.
            timer.start(10)
            return
        ticks += 1
        if not bool(rt.execute("PanelResearchRoot.mainUI.controlsReady")):
            if ticks > 300:
                raise RuntimeError("Panel never became ready")
            timer.start(10)
            return
        if first_ready==0.:first_ready=(time.perf_counter()-start)*1000
        expected=12 if cases[index][1] else 2
        mounted=int(rt.execute("(for p in PanelResearchRoot.mainUI.editors where p.isDisplayed collect p).count"))
        if mounted<expected:
            if ticks>1000:raise RuntimeError("Queued sections did not finish mounting")
            timer.start(10)
            return
        sample = {"case": cases[index][0], "select_call_ms": select_ms,
                  "first_interactive_observed_ms":first_ready,
                  "ready_observed_ms": (time.perf_counter() - start) * 1000,
                  "mounted_pages": int(rt.execute("(for p in PanelResearchRoot.mainUI.editors where p.isDisplayed collect p).count")),
                  "epoch": int(root.procEpoch), "native_diagnostics": snap()}
        rt.cyrusDiagnosticStop()
        rt.cyrusDiagnosticStart(cases[index][0] + "-bind", 4096, 4194304, 60000)
        before = time.perf_counter()
        root.bindNativeUI()
        sample["warm_bind_ms"] = (time.perf_counter() - before) * 1000
        sample["warm_diagnostics"] = snap()
        rt.cyrusDiagnosticStop()
        sample["epoch_after_bind"] = int(root.procEpoch)
        assert sample["epoch"] == sample["epoch_after_bind"]
        R["samples"].append(sample)
        save()
        rt.clearSelection()
        index += 1
        if index == len(cases):
            R["status"] = "complete"
            save()
            rt.execute("quitMAX #noPrompt")
            return
        phase = 1
        timer.start(500)
    except Exception:
        R.update(status="failed", error=traceback.format_exc())
        save()
        rt.execute("quitMAX #noPrompt")

timer = QTimer()
timer.timeout.connect(tick)
timer.start(500)
save()
