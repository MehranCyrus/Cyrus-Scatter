"""Owned native lifecycle witness before UI refresh can conceal stale preset refs."""
import json
from pymxs import runtime as rt
import host_fixture
OLD=None
BEFORE=None

def capture():
    global OLD,BEFORE
    panel=host_fixture.PANEL;OLD=panel.host.preset_reader
    assert OLD is not None and panel.service.preset_grant["status"]=="scanning"
    BEFORE=dict(adapter_status="scanning",native_status=json.loads(str(rt.cyrusPresetCatalogPage(OLD,1)))["state"])

def verify(reason):
    panel=host_fixture.PANEL;closed=False
    try:rt.cyrusPresetCatalogPage(OLD,1)
    except RuntimeError:closed=True
    checks=[panel.service.preset_grant is None,panel.host.preset_reader is None,closed,
            panel.service.task is None and not panel.host.scene_nodes,
            (panel.bridge.closed and not panel.preset_timer.isActive()) if reason=="close" else panel.service.scope is None]
    rt.CyrusMCPPresetLifecycleChecks=rt.Array(*checks)
    result=dict(status="passed" if all(checks) else "failed",case=reason,before=BEFORE,checks=checks,
        qualification="Immediate grant/handle revocation before snapshot publication; worker file IO may already be terminal. Not a mid-IO cancellation guarantee.")
    (host_fixture.OUTPUT/("presets-lifecycle-"+reason+".json")).write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
