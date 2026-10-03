"""Error, refinement, persistence and image acceptance through the product API."""
import argparse
import base64
from copy import deepcopy
import json
from pathlib import Path
import uuid
from qualify import Qualification


def run(folder):
    q=Qualification(folder)
    evidence=[]
    q.local("setup")
    context=q.context()
    # Real source is off to the side; radius must be pivot-relative, not its distance from the origin.
    assert abs(context["scope"]["sources"][0]["radius_m"]-.3)<1e-5
    baseline=q.local("snapshot")
    plan=q.plan(context)
    validation=q.call("scatter.validate_plan",plan=plan)
    args={key:validation[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
    refused=q.client.call("scatter.apply_plan",**args,idempotency_key=uuid.uuid4().hex)
    assert refused["error"]["code"]=="APPROVAL_REQUIRED"
    evidence.append({"scenario":"local_approval_required","passed":True})
    for phase in ("controller","layers","preview","replace","publish"):
        q.local("fault",phase=phase)
        failure=q.apply(plan)
        assert failure["state"]=="failed" and failure["error"].get("rollback")=="verified",failure
        after=q.local("snapshot")
        assert after["redraw_disabled"]==baseline["redraw_disabled"]==False,(phase,"Redraw leaked",after)
        assert after["auto_key"]==baseline["auto_key"],(phase,"Auto Key changed")
        assert after["fingerprint"]==baseline["fingerprint"] and after["nodes"]==baseline["nodes"] and after["selected"]==baseline["selected"],(phase,after,baseline)
        evidence.append({"scenario":"create_failure_"+phase,"passed":True,"error":failure["error"]})
        # Deliberately re-enroll after each failure to renew the experiment budget.
        q.local("setup")
        context=q.context();baseline=q.local("snapshot");plan=q.plan(context)
    q.local("fault",phase=None)
    initial=q.apply(plan)
    assert initial["state"]=="succeeded",initial
    context=q.context()
    refined=q.plan(context,count=300,layers=2)
    refined.update(controller_id=initial["result"]["controller_id"],generation_id=initial["result"]["generation_id"])
    before=q.local("snapshot")
    q.local("fault",phase="publish")
    failed=q.apply(refined)
    assert failed["state"]=="failed" and failed["error"].get("rollback")=="verified",failed
    after=q.local("snapshot")
    assert after["redraw_disabled"]==before["redraw_disabled"]==False,after
    assert after["auto_key"]==before["auto_key"],after
    assert before["fingerprint"]==after["fingerprint"] and before["nodes"]==after["nodes"],(before,after)
    (q.folder/"refinement-recovery.json").write_text(json.dumps({"before":before,"after":after},indent=2))
    # Undo may reconstruct the native preview and report its new build duration.
    # Its result, validity and publication counts must still be identical.
    semantic=lambda rows:[{k:v for k,v in row.items() if k!="last_build_ms"} for row in rows]
    assert semantic(before["diagnostics"])==semantic(after["diagnostics"]),"Failed refinement changed the last valid preview result"
    q.local("fault",phase=None)
    evidence.append({"scenario":"refinement_failure_preserves_initial","passed":True})
    successful=q.apply(refined)
    assert successful["state"]=="succeeded",successful
    result=successful["result"]
    assert result["controller_id"]==initial["result"]["controller_id"] and result["generation_id"]!=initial["result"]["generation_id"]
    evidence.append({"scenario":"owned_refinement","passed":True,"emitted":result["emitted"]})
    image=q.call("scene.capture_viewport",scene_epoch=successful["scene_epoch"],scene_revision=successful["scene_revision"],viewport_id=context["viewport_id"],generation_id=result["generation_id"])
    (q.folder/"viewport.png").write_bytes(base64.b64decode(image.pop("image_base64")))
    assert max(image["width"],image["height"])<=1536
    evidence.append({"scenario":"bounded_viewport_capture","passed":True,"metadata":image})
    saved=q.local("save_reopen")
    assert saved["match"] and saved["controllers"]==1 and saved["scope_cleared"],saved
    evidence.append({"scenario":"save_reopen_seeded_parity","passed":True,**saved})
    q.local("setup")
    context=q.context()
    plan=q.plan(context)
    value=q.call("scatter.validate_plan",plan=plan)
    q.local("approve",validation_id=value["validation_id"])
    q.local("edit")
    stale=q.client.call("scatter.apply_plan",**{k:value[k] for k in ("validation_id","digest","scene_epoch","scene_revision")},idempotency_key=uuid.uuid4().hex)
    assert stale["error"]["code"]=="STALE_CONTEXT",stale
    evidence.append({"scenario":"external_artist_edit_invalidates_proposal","passed":True})
    (q.folder/"scenarios.json").write_text(json.dumps(evidence,indent=2))
    print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("folder",type=Path)
    run(parser.parse_args().folder)
