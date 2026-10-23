"""Explicit NEVER_SHIP Max2027 host. Never stages or packages a product payload."""
from pathlib import Path
import argparse
import json
import uuid
from compatibility_host import (ROOT, HERE, private_launch, suite_paths, artifact_identity,
                                wait_ready, verify_owned, run_case)
import sys
sys.path.insert(0, str(ROOT / "tools"))
import build_inputs

ASSERTIONS = ["E4_gpu_initial", "E4_gpu_cpu_successor", "E4_gpu_feedback_retained",
              "E4_gpu_authoring_guard", "E4_gpu_recovery"]

def launch(folder, native):
    native = native.resolve()
    receipt_path = native / "receipt.json"
    receipt = json.loads(receipt_path.read_text())
    if (receipt.get("status") != "complete" or receipt.get("preview_fault_lab") is not True
            or receipt.get("max_year") != 2027 or receipt.get("project") != "scatter"):
        raise ValueError("A completed separate NEVER_SHIP Max2027 build is required")
    build_inputs.verify_frozen(receipt["input_manifest"], ROOT)
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    paths = {n: native / n for n in ("AminScatter.dlx", "CyrusScatterEdit.dlm", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusGallery.dll")}
    for source in paths.values():
        if build_inputs.digest(source) != receipt["binaries"][source.relative_to(ROOT).as_posix()]:
            raise ValueError("Private compiled binary differs from its producer receipt")
    paths["CyrusScatter.ms"] = script
    paths["native_receipt"] = receipt_path
    paths.update(suite_paths())
    identity, hashes = artifact_identity(paths)
    process, metadata = private_launch(folder, script, native, transport=True, max_year=2027,
        silent_startup=True, preview_fault_lab=True, script_assets=("CyrusGallery.dll",),
        extra='if cyrusOwnedPreviewFault==undefined or cyrusEditVersion()!=2 do throw "Incorrect private Edit qualification module"')
    origins = {n: str(p) for n, p in paths.items()}
    for name in ("AminScatter.dlx", "CyrusScatterEdit.dlm", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusGallery.dll", "CyrusScatter.ms"):
        paths[name] = folder / ("scripts" if name in ("CyrusGallery.dll", "CyrusScatter.ms") else "bin") / name
        if build_inputs.digest(paths[name]) != hashes[name]:
            raise ValueError("Loaded private copy differs")
    (folder / "qualification.json").write_text(json.dumps({
        "schema": "cyrus.edit-host/1", "run_id": uuid.uuid4().hex, "artifact_id": identity,
        "pid": process.pid, "max_year": 2027, "command": metadata["command"], "version": "0.86.9",
        "never_ship": True, "hashes": hashes, "paths": {n: str(p) for n, p in paths.items()},
        "origins": origins, "artist_profile_modified": False}, indent=2) + "\n")
    print(json.dumps({"pid": process.pid, "folder": str(folder)}), flush=True)
    wait_ready(folder)
    return verify_owned(folder)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("launch", "run"))
    parser.add_argument("--folder", type=Path, required=True)
    parser.add_argument("--native", type=Path)
    args = parser.parse_args()
    folder = args.folder.resolve()
    if args.action == "launch":
        result = launch(folder, args.native)
    else:
        result = run_case(folder, HERE / "feedback_failure.ms", "late_failure", ASSERTIONS,
                          timeout=180, entrypoint="EWFailureRun")
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
