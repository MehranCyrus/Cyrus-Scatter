"""Run current spline regressions in one explicitly owned, matched Max host."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/procedural_lab"))
from runtime_driver import run_script


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("profile", type=Path)
    parser.add_argument("--scope", choices=("full", "authoring"), default="full")
    parser.add_argument("--performance", action="store_true", help="Include the bounded host workload ladder in the full campaign")
    args = parser.parse_args()
    if args.performance and args.scope != "full":
        parser.error("--performance requires --scope full")
    folder = args.profile.resolve()
    if folder.parent != ROOT / "build/mcp-qualification" or not folder.name.startswith("foundation-spline-"):
        raise ValueError("An explicitly owned spline host is required")
    report = {"launch": json.loads((folder / "launch.json").read_text()), "scope": args.scope, "performance": args.performance, "steps": [], "passed": False}
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    report["script_sha256"] = hashlib.sha256(script.read_bytes()).hexdigest()
    if report["script_sha256"] != report["launch"]["script_sha256"]:
        raise ValueError("The script differs from this host's startup identity")
    receipt = folder / ("qualification-" + uuid.uuid4().hex + ".json")

    def run(label, code, fixture):
        step = {"label": label, "fixture": str(fixture.relative_to(ROOT)),
                "fixture_sha256": hashlib.sha256(fixture.read_bytes()).hexdigest()}
        report["steps"].append(step)
        receipt.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        start = time.monotonic()
        try:
            step["result"] = run_script(folder, code, timeout=240 if fixture.name == "performance_host.py" else 180)
            step["passed"] = step["result"].startswith("SUCCESS ")
        except Exception as error:
            step["error"] = repr(error)
            step["passed"] = False
        step["seconds"] = time.monotonic() - start
        receipt.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(label, "PASS" if step["passed"] else step, flush=True)
        if not step["passed"]:
            raise RuntimeError("Host qualification failed; inspect " + str(receipt))

    # Native Undo events precede Python to avoid a pymxs enclosing hold.
    native = Path(__file__).with_name("authoring_ui_undo.ms")
    for phase in ("prepare", "convert", "undo-convert", "redo-convert", "reorder", "undo-reorder",
                  "redo-reorder", "curve-open", "curve-unchanged-close", "curve-reopen", "curve-edit", "undo-curve", "redo-curve",
                  "curve-close", "undo-after-close"):
        run("Undo " + phase, 'global BandUIPhase="' + phase + '"\n' + native.read_text(encoding="utf-8"), native)
    if args.scope == "authoring":
        fixture = ROOT / "tools/spline_bands/authoring_ui_host.py"
        run(fixture.stem, 'python.ExecuteFile @"' + fixture.as_posix() + '"', fixture)
        report["passed"] = True
        receipt.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(receipt, flush=True)
        return
    native = Path(__file__).with_name("auto_radius_undo.ms")
    for phase in ("prepare","auto","undo-auto","redo-auto","manual","undo-manual","redo-manual"):
        run("Radius Undo " + phase, 'global RadiusUndoPhase="' + phase + '"\n' + native.read_text(encoding="utf-8"), native)
    native = Path(__file__).with_name("field_ui_undo.ms")
    for phase in ("prepare","falloff","undo-falloff","redo-falloff","boundaries","undo-boundaries","redo-boundaries",
                  "samples","undo-samples","redo-samples","combined","undo-combined","redo-combined"):
        run("Field Undo " + phase, 'global FieldUndoPhase="' + phase + '"\n' + native.read_text(encoding="utf-8"), native)
    for rel in ("tools/spline_bands/field_host.py", "tools/spline_bands/geometry_host.py",
                "tools/spline_bands/authored_host.py", "tools/spline_bands/transport_host.py",
                "tools/spline_bands/authoring_ui_host.py", "tools/spline_bands/palette_host.py",
                "tools/spline_bands/source_revision_host.py", "tools/spline_bands/geometry_units_host.py",
                "tools/spline_bands/auto_radius_host.py", "tools/spline_bands/auto_radius_lifecycle_host.py", "tools/spline_bands/auto_radius_sources_host.py",
                "tools/spline_bands/overlay_host.py", "tools/spline_bands/field_ui_host.py", "tools/spline_bands/field_capture_host.py",
                "tools/spline_bands/palette_capture_host.py", "tools/foundation_validation/publication.py",
                "tools/foundation_validation/retained.py", "tools/spline_bands/render_host.py",
                *(("tools/spline_bands/performance_host.py",) if args.performance else ()),
                "tools/spline_bands/retired_scene_host.py"):
        fixture = ROOT / rel
        run(fixture.stem, 'python.ExecuteFile @"' + fixture.as_posix() + '"', fixture)
        if fixture.name in ('palette_capture_host.py','field_capture_host.py','render_host.py'):
            kind='palette' if fixture.name=='palette_capture_host.py' else ('field' if fixture.name=='field_capture_host.py' else 'render')
            captures=[p for p in folder.glob(kind+('-*.json' if kind=='render' else '-images-*.json')) if not p.stem.endswith('-verified')]
            if len(captures)!=1:raise RuntimeError('Qualification requires exactly one fresh image capture')
            verifier=ROOT/('tools/spline_bands/verify_'+kind+'_images.py')
            step={'label':'actual image verification','fixture':str(verifier.relative_to(ROOT)),
                  'fixture_sha256':hashlib.sha256(verifier.read_bytes()).hexdigest()}
            report['steps'].append(step)
            completed=subprocess.run([sys.executable,str(verifier),str(captures[0])],capture_output=True,text=True)
            step.update(passed=completed.returncode==0,exit_code=completed.returncode,stdout=completed.stdout,stderr=completed.stderr)
            receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
            if not step['passed']:raise RuntimeError('Actual image verification failed; inspect '+str(receipt))
            print('actual image verification PASS',flush=True)
    report["passed"] = True
    receipt.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(receipt, flush=True)


if __name__ == "__main__":
    main()
