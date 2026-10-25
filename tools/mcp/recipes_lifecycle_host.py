"""Private lifecycle witnesses on the actual panel/native reader, before refresh."""
import json
from pymxs import runtime as rt
import host_fixture

OLD=None
BEFORE=None


def capture():
    global OLD,BEFORE
    panel=host_fixture.PANEL
    OLD=panel.host.recipe_reader
    assert OLD is not None and panel.service.recipe_grant["status"]=="scanning"
    BEFORE=dict(adapter_status="scanning",native_status=str(rt.cyrusRecipeCatalogPage(OLD,"","",1)[0]))


def verify(reason):
    panel=host_fixture.PANEL
    closed=False
    try:rt.cyrusRecipeCatalogPage(OLD,"","",1)
    except RuntimeError:closed=True
    checks=[panel.service.recipe_grant is None,panel.host.recipe_reader is None,closed,
            panel.service.task is None and not panel.host.scene_nodes,
            (panel.bridge.closed and not panel.recipe_timer.isActive()) if reason=="close" else panel.service.scope is None]
    rt.CyrusMCPRecipeLifecycleChecks=rt.Array(*checks)
    result=dict(status="passed" if all(checks) else "failed",case=reason,before=BEFORE,checks=checks,
                qualification="Handle revocation before metadata publication; native worker may already have completed file IO. Not a mid-IO cancellation guarantee.")
    (host_fixture.OUTPUT/("recipes-lifecycle-"+reason+".json")).write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
