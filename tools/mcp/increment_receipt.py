"""Freeze source/runtime and actually loaded native identity for an owned increment."""
import argparse
import hashlib
import json
from pathlib import Path
from foundation_campaign import qualification,ROOT,verify_owned

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def run(base):
    q=qualification(base);meta=verify_owned(q.folder)
    connection=q.call("connection.get_status")
    files={}
    for path in sorted((base/"source/cyrus_mcp").rglob("*")):
        if path.suffix not in (".py",".json") or "__pycache__" in path.parts:continue
        current=ROOT/"CyrusMCP"/path.relative_to(base/"source")
        frozen=sha(path);assert frozen==sha(current),str(current)
        files[current.relative_to(ROOT).as_posix()]=frozen
    modules=connection["host"]["loaded_modules"]
    assert len(modules)==5
    for module in modules:
        assert module["loaded"] and module["loaded_file_sha256"]==meta["hashes"][module["module"]],module
    result=dict(status="passed",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],
                runtime_files=files,host=connection["host"],qualification="Owned loaded identity and frozen runtime/source equality; not package or broad workflow qualification.")
    (q.folder/"increment-receipt.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(dict(status="passed",pid=meta["pid"],runtime_files=len(files),loaded_native_modules=len(modules),artifact_id=meta["artifact_id"])),flush=True)

if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("--base",type=Path,required=True);run(p.parse_args().base.resolve())
