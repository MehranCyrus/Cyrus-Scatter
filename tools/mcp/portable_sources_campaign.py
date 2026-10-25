"""Actual native staging and prior-history preservation, separate host callbacks."""
import argparse
import json
from pathlib import Path
import shutil
import time
from foundation_campaign import qualification,HERE,verify_owned
from compatibility_host import bind_suite

def run(base,source,resume=False):
    q=qualification(base)
    destination=base/"prepared-package"
    if not resume:
        assert not destination.exists(),"Use a fresh campaign; do not replay uncertain staging"
        shutil.copytree(source,destination)
    module=base/"fixtures/portable_source_host.py";shutil.copy2(HERE/"portable_source_host.py",module)
    inputs={"portable-driver":Path(__file__),"portable-module":module}
    inputs.update({"portable-package-"+str(i):p for i,p in enumerate(destination.rglob("*")) if p.is_file()})
    meta=bind_suite(q.folder,inputs)
    receipt=q.folder/"portable-sources.json"
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],steps=[],
                qualification="Owned native API proof; no MCP asset import/apply contract, artist consent or complete M03 qualification.")
    if resume:
        previous=json.loads((q.folder/"portable-sources-attempt01.json").read_text())
        assert previous["status"]=="failed" and [s["step"] for s in previous["steps"]][-2:]==["stage","state"]
        result["steps"]=previous["steps"]
        result["parent_receipt"]="portable-sources-attempt01.json"
    def step(name,**args):
        value=q.local("portable_step_"+name,**args)
        result["steps"].append(dict(step=name,artifact_id=verify_owned(q.folder)["artifact_id"],result=value));save();return value
    def save():receipt.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    try:
        if resume:
            before=next(s["result"] for s in previous["steps"] if s["step"]=="state")
            staged=previous["steps"][-1]["result"]
            assert step("state")==staged,"Live state changed; inspect before continuing"
        else:
            step("prepare",directory=str(destination));deadline=time.monotonic()+30
            while True:
                polled=step("poll")
                if polled["state"]!="preparing":break
                assert time.monotonic()<deadline,"Observe original native worker before replay"
                time.sleep(.2)
            assert polled["state"]=="ready",polled
            step("prior");before=step("state")
            assert before["undo"]==["Owned prior portable edit"] and before["sentinel_x"]==7,before
            step("stage");staged=step("state")
        assert staged["undo"]==["Owned portable source import"]+before["undo"],staged
        assert len(staged["nodes"])==len(before["nodes"])+2 and all(staged["created_valid"])
        step("release")
        moved=base/"prepared-package-unavailable"
        assert destination.resolve().is_relative_to(base) and moved.resolve().is_relative_to(base) and not moved.exists()
        destination.rename(moved)
        rebound={key:(moved/path.relative_to(destination) if path.is_relative_to(destination) else path) for key,path in inputs.items()}
        bind_suite(q.folder,rebound)
        try:
            assert not destination.exists()
            step("undo");undone=step("state")
            assert undone["nodes"]==before["nodes"] and undone["undo"]==before["undo"]
            assert not any(undone["created_valid"]) and undone["sentinel_x"]==7
            step("undo");prior_undone=step("state")
            assert abs(prior_undone["sentinel_x"])<1e-6
            step("redo");step("redo");redone=step("state")
            assert redone==staged
            result["undo_redo_without_package_or_prepared_handle"]=True
        finally:
            assert moved.resolve().is_relative_to(base) and destination.resolve().is_relative_to(base) and not destination.exists()
            moved.rename(destination)
            bind_suite(q.folder,inputs)
        step("prepare",directory=str(destination));deadline=time.monotonic()+30
        while True:
            polled=step("poll")
            if polled["state"]!="preparing":break
            assert time.monotonic()<deadline,"Observe original native worker before replay"
            time.sleep(.2)
        assert polled["state"]=="ready",polled
        step("failure");failed=step("state")
        assert failed==staged,"Failed successor changed nodes, previous geometry/materials, sentinel or history"
        step("release")
        result.update(status="passed",prior_history_preserved=True,import_undo_removed_only_owned_nodes=True,
                      redo_restored_exact_geometry=True,post_staging_failure_retained_previous_state=True)
        save()
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise
    print(json.dumps(dict(status="passed",artifact_id=meta["artifact_id"],steps=len(result["steps"]))),flush=True)

if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("--base",type=Path,required=True);p.add_argument("--source",type=Path,required=True)
    p.add_argument("--resume-after-stage",action="store_true",help="Resume the exact observed staged fixture after the preserved history-order assertion failure")
    a=p.parse_args();run(a.base.resolve(),a.source.resolve(),a.resume_after_stage)
