"""Native fault boundaries in an owned disposable Max process only."""
from pathlib import Path
import json
import os
import time
import traceback
from pymxs import runtime as rt
import foundation_host as foundation

ORIGINAL_COMMAND = foundation.command
CASE = None


def write(path, value):
    temporary = path.with_suffix(".tmp")
    with temporary.open("w", encoding="utf-8") as stream:
        json.dump(value, stream, indent=2)
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)


def scene_state():
    nodes = list(rt.objects)
    if len(nodes) > 64:
        raise ValueError("Owned synthetic scene budget exceeded")
    roots = [node for node in nodes if rt.classOf(node.baseObject) == rt.AminScatterObject]
    values = []
    for node in roots:
        record = dict(owner=str(rt.getUserProp(node,"CyrusAutomationOwner")),
                      generation=str(rt.getUserProp(node,"CyrusAutomationGeneration")),
                      configuration=str(rt.getUserProp(node,"CyrusAutomationConfiguration")),
                      layers=[dict(id=str(layer.layerID), count=int(layer.amount), seed=int(layer.randomSeed),
                                   update_mode=int(layer.updateMode)) for layer in node.layerObjects],
                      root_update_mode=int(node.updateMode))
        try:
            from cyrus_mcp.max_host import frozen
            from cyrus_mcp.publication import manifest
            record["publication"] = manifest(frozen(node.procPublicationInfo()))
        except Exception as exc:
            record["publication_unavailable"] = str(exc)[:200]
        values.append(record)
    return {"roots": values, "nodes":len(nodes)}


def save_checkpoint():
    path = CASE/"checkpoint.max"
    if not rt.saveMaxFile(str(path), quiet=True):
        raise RuntimeError("Owned checkpoint save failed")
    return scene_state()


def wait_for_termination(stage, result):
    write(CASE/"loss-boundary.json", dict(stage=stage, pid=os.getpid(), result=result,
          scene=scene_state(), checkpoint=str(CASE/"checkpoint.max")))
    # A bounded private fault barrier. The external verified process handle must
    # terminate this process; expiry is a failed test, never a claimed crash.
    deadline=time.monotonic()+45
    while time.monotonic()<deadline:
        time.sleep(.05)
    raise RuntimeError("Owned process-loss barrier expired without termination")


def command(data):
    panel=foundation.base.PANEL
    action=data["action"]
    if action=="loss_checkpoint":
        return save_checkpoint()
    if action=="loss_arm":
        stage=data["stage"]
        if stage not in ("queued","host_return","journal_commit"):
            raise ValueError("Unsupported owned boundary")
        if (CASE/"loss-boundary.json").exists():
            raise ValueError("Never replay an already observed loss boundary")
        if stage=="queued":
            original_apply=panel.service.apply
            def apply(*args,**kwargs):
                result=original_apply(*args,**kwargs)
                panel.host.blocked=True  # Busy begins only after durable admission.
                return result
            panel.service.apply=apply
        else:
            original=foundation.ORIGINAL_CHANGE
            def change(*args):
                result=original(*args)
                save_checkpoint()
                if stage=="host_return":
                    wait_for_termination(stage,result)
                else:
                    def fingerprint():
                        wait_for_termination(stage,result)
                    panel.host.fingerprint=fingerprint
                return result
            panel.host.change=change
        return {"armed":stage}
    if action=="loss_state":
        return scene_state()
    if action=="loss_select":
        roots=[node for node in rt.objects if rt.classOf(node.baseObject)==rt.AminScatterObject
               and str(rt.getUserProp(node,"CyrusAutomationOwner"))==data["controller_id"]]
        if len(roots)!=1:
            raise ValueError("Owned recovery selection is not unique")
        rt.select(roots[0])
        return {"selected":True}
    if action=="loss_review":
        return panel.service.prepare_local_recovery(data["operation_id"],list(rt.selection))
    return ORIGINAL_COMMAND(data)


def start(output, connection, restore=False):
    global CASE
    output=Path(output)
    CASE=output.parent
    try:
        if restore:
            rt.loadMaxFile(str(CASE/"checkpoint.max"),quiet=True)
        foundation.start(output, Path(connection))
        if foundation.base.PANEL is None or not (output/"foundation-ready.json").exists():
            return
        foundation.base.command=command
        rt.completeRedraw()  # Explicit fixture startup presentation, not a read-tool solve.
        panel=foundation.base.PANEL
        write(output/"loss-startup.json", dict(pid=os.getpid(),restored_scene=restore,
              recovery_required=panel.service.recovery_required,scope=panel.service.scope is not None,
              message=panel.status.text(),enroll_enabled=panel.enroll_button.isEnabled(),
              approve_enabled=panel.approve_button.isEnabled(),review_enabled=panel.recovery_button.isEnabled(),
              scene=scene_state()))
    except Exception:
        (output/"foundation-error.txt").write_text(traceback.format_exc(),encoding="utf-8")
