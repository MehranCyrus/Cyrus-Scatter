"""Supported-scope rejection, host-busy and local permission checks in real Max."""
import argparse
import json
from pathlib import Path
import time
from qualify import Qualification


def run(folder):
    q=Qualification(folder)
    evidence=[]
    q.local("setup")
    # Playback is tested through the real Play control. Calling playAnimation()
    # synchronously from the fixture's Python timer blocks that timer's return.
    for mode in ("render_callback","undo_hold","modal"):
        try:
            busy=q.local("boundary",kind="busy",mode=mode,enabled=True)
            assert busy["busy"],(mode,busy)
            result=q.client.call("connection.get_status")
            assert result["error"]["code"]=="HOST_BUSY",(mode,result)
        finally:
            q.local("boundary",kind="busy",mode=mode,enabled=False)
        evidence.append({"scenario":"busy_"+mode,"passed":True})
    for kind in ("tilted_site","animated_source","outside_region","concave_region"):
        q.local("setup")
        rejected=q.local("boundary",kind=kind)
        assert not rejected.get("ok",True),rejected
        evidence.append({"scenario":"reject_"+kind,"passed":True,"error":rejected["error"]})
    for kind in ("protected_region","huge_asset"):
        q.local("setup")
        assert q.local("boundary",kind=kind)["enrolled"]
        context=q.context()
        result=q.client.call("scatter.validate_plan",plan=q.plan(context))
        assert not result["ok"] and result["error"]["code"]=="GEOMETRY_CONSTRAINT",result
        evidence.append({"scenario":"reject_"+kind,"passed":True,"error":result["error"]})
    for group in ("sources","regions"):
        q.local("setup")
        q.local("boundary",kind="delete_input",group=group)
        result=q.client.call("scene.get_context",scope_id=q.call("connection.get_status")["scope_id"])
        assert result["error"]["code"]=="STALE_CONTEXT",result
        evidence.append({"scenario":"deleted_"+group,"passed":True})
    q.local("setup")
    context=q.context();operation=q.apply(q.plan(context))
    assert operation["state"]=="succeeded",operation
    assert not q.local("boundary",kind="capture_permission",enabled=False)["allowed"]
    result=q.client.call("scene.capture_viewport",scene_epoch=operation["scene_epoch"],scene_revision=operation["scene_revision"],viewport_id=context["viewport_id"],generation_id=operation["result"]["generation_id"])
    assert result["error"]["code"]=="APPROVAL_REQUIRED",result
    evidence.append({"scenario":"capture_revocation_immediate","passed":True})
    before=q.local("boundary",kind="other_edit")
    result=q.local("boundary",kind="guarded_undo")
    assert result["error"]["code"]=="STALE_CONTEXT",result
    assert q.local("snapshot")["nodes"]==before["nodes"]
    evidence.append({"scenario":"unrelated_artist_edit_not_undone","passed":True})
    assert q.local("boundary",kind="repick")["scope_cleared"]
    evidence.append({"scenario":"scope_repick_revokes_previous_enrollment","passed":True})
    # The old 100k-triangle envelope took 25s and is intentionally rejected.
    q.local("setup")
    rejected=q.local("boundary",kind="complexity",x=200,y=250)
    assert rejected["error"]["code"]=="BUDGET_EXCEEDED",rejected
    evidence.append({"scenario":"oversized_mesh_rejected_before_extraction","passed":True,"measurement":rejected})
    q.local("setup")
    measured=q.local("boundary",kind="complexity",x=50,y=90)
    assert measured["enrolled"],measured
    started=time.perf_counter();q.context()
    measured["context_wall_ms"]=(time.perf_counter()-started)*1000
    assert measured["context_wall_ms"]<5000,measured
    evidence.append({"scenario":"geometry_boundary_measurement","measurement":measured})
    (q.folder/"boundaries.json").write_text(json.dumps(evidence,indent=2))
    print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("folder",type=Path)
    run(parser.parse_args().folder)
