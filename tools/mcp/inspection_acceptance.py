"""Observe a pre-existing layout without granting mutation authority."""
import argparse
import json
from pathlib import Path
from qualify import Qualification


def run(folder):
    q=Qualification(folder)
    q.local("setup")
    initial=q.context()
    result=q.apply(q.plan(initial,layers=3))
    assert result["state"]=="succeeded",result
    connection=q.local("boundary",kind="inspect")
    before=q.local("snapshot")
    context=q.context()
    observed=next(iter(context["observed_controllers"].values()))
    assert len(observed["layers"])==3 and not context["owned_controllers"]
    q.call("scatter.get_diagnostics",scene_epoch=connection["scene_epoch"])
    q.call("scatter.get_status",scene_epoch=connection["scene_epoch"],controller_id=observed["controller_id"])
    plan=q.plan(initial);plan["context_id"]=context["context_id"]
    rejected=q.client.call("scatter.validate_plan",plan=plan)
    assert rejected["error"]["code"]=="UNSUPPORTED_CAPABILITY",rejected
    after=q.local("snapshot")
    assert before==after,(before,after)
    capture=q.call("scene.capture_viewport",scene_epoch=connection["scene_epoch"],scene_revision=context["scene_revision"],viewport_id=context["viewport_id"],generation_id=observed["generation_id"])
    capture.pop("image_base64")
    host=q.call("connection.get_status")["host"]
    assert all(m["loaded"] and len(m["loaded_file_sha256"])==64 for m in host["loaded_modules"]),host
    evidence={"three_existing_layers":observed,"inspection_is_pure":True,"mutation_rejected":True,"capture":capture,"verified_build_identity":host}
    (q.folder/"inspection.json").write_text(json.dumps(evidence,indent=2))
    print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("folder",type=Path)
    run(parser.parse_args().folder)
