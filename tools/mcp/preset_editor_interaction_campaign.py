"""Record real owned-editor interaction; gestures remain native UI actions.

Run begin, physically drag the middle density point and close the editor, then
verify, undo, redo and release. Never replay an uncertain phase. A private
scripted model check is not a substitute for the required mouse gesture.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from foundation_campaign import ROOT,qualification,verify_owned


def run(base,action):
    base=base.resolve()
    if not base.is_relative_to(ROOT/"build"):raise ValueError("Owned build profile required")
    q=qualification(base);meta=verify_owned(q.folder)
    path=q.folder/"physical-editor-campaign.json"
    if action=="begin":
        if path.exists():raise FileExistsError("Observe the original physical request; do not replay")
        source=json.loads((q.folder/"preset-application.json").read_text())
        assert source["status"]=="passed" and len(source["cases"])==16
        driver=base/"fixtures/preset_editor_interaction_campaign.py"
        if driver.exists():raise FileExistsError(driver)
        shutil.copy2(Path(__file__),driver)
        record=dict(status="running",phase="before_begin",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],
                    controller_id=source["creation"]["result"]["controller_id"],
                    driver_sha256=hashlib.sha256(driver.read_bytes()).hexdigest(),
                    qualification="Native physical mouse drag/close plus private exact model/Undo/Redo/lifetime checks; not public preset-write or complete artist acceptance.")
    else:
        record=json.loads(path.read_text())
        assert record["status"]=="running" and record["artifact_id"]==meta["artifact_id"] and record["run_id"]==meta["run_id"]
    expected=dict(verify="awaiting_physical_gesture_and_close",undo="verify_verified",redo="undo_verified",release="redo_verified")
    if action!="begin":assert record["phase"]==expected[action],"Observe the original request/result before another action"
    def save():path.write_text(json.dumps(record,indent=2)+"\n",encoding="utf-8")
    record["phase"]="before_"+action;save()
    try:
        native="preset_apply_curve_lifetime_release" if action=="release" else "preset_apply_physical_"+action
        result=q.local(native,controller_id=record["controller_id"])
        record[action]=result
        record["phase"]="awaiting_physical_gesture_and_close" if action=="begin" else action+"_verified"
        if action=="release":record["status"]="passed"
        save();print(json.dumps(dict(status=record["status"],phase=record["phase"],result=result)),flush=True)
    except Exception as exc:
        record.update(status="failed",effects="unknown",error=repr(exc));save();raise


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("action",choices=("begin","verify","undo","redo","release"))
    p.add_argument("--base",type=Path,required=True)
    args=p.parse_args();run(args.base,args.action)
