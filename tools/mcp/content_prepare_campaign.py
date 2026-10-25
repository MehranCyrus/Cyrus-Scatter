"""Prepare existing installed models in a disposable Max 2027 content-build host."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
from foundation_campaign import ROOT,HERE,qualification,resume,verify_owned,close_owned
from prepared_assets_campaign import launch as launch_native
from compatibility_host import bind_suite

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def clone_content(base):
    original=ROOT/"dist/CyrusScatter-0.86.7-20261020/Content/Library"
    destination=base/"Library";destination.mkdir()
    for path in original.rglob("*"):
        if path.is_symlink():raise ValueError("Original linked content is outside this preparation")
        target=destination/path.relative_to(original)
        if path.is_dir():target.mkdir(exist_ok=True)
        elif path.name=="model-catalog.json":shutil.copy2(path,target)
        else:os.link(path,target)  # Immutable same-volume views; original files are never written.
    assert sha(destination/"model-catalog.json")==sha(original/"model-catalog.json")

def start(base,ids):
    q=qualification(base)
    if not (base/"Library").exists():clone_content(base)
    (base/"Library/PreparedModels").mkdir(exist_ok=True)
    module=base/"fixtures/content_prepare_host.py";shutil.copy2(HERE/"content_prepare_host.py",module)
    bind_suite(q.folder,{"content-prepare-driver":Path(__file__),"content-prepare-module":module,"content-catalog":base/"Library/model-catalog.json"})
    print(json.dumps(q.local("content_prepare_start",root=str(base/"Library"),output=str(base/"Library/PreparedModels"),ids=ids)),flush=True)

def status(base):
    q=qualification(base);verify_owned(q.folder)
    p=q.folder/"content-preparation.json"
    result=json.loads(p.read_text())
    counts={key:sum(row["status"]==key for row in result["entries"]) for key in ("prepared","rejected","deferred","not_requested")}
    print(json.dumps(dict(status=result["status"],remaining=result["remaining"],counts=counts,
                         recent=[{key:row[key] for key in ("entry_id","status")} for row in result["entries"][-3:]])),flush=True)

if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=("launch","resume","prepare","status","close"));p.add_argument("--base",type=Path,required=True)
    p.add_argument("--ids",nargs="*",default=[])
    a=p.parse_args();base=a.base.resolve()
    if a.action=="launch":launch_native(base)
    elif a.action=="resume":resume(base)
    elif a.action=="prepare":start(base,a.ids)
    elif a.action=="status":status(base)
    else:close_owned(base/"host01")
