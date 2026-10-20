"""Verify exact standalone 0.2.1 artifacts and completed owned host receipts."""
from pathlib import Path
import hashlib, json, subprocess, zipfile

ROOT = Path(__file__).resolve().parents[3]
DOCS = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build/physics-collider-021-20261019-01"
NATIVE = BUILD / "native"
DIST = ROOT / "dist/CyrusPhysicsLab-0.2.1-20261019-02"

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return json.loads(p.read_text(encoding="utf-8-sig"))
def txt(p): return p.read_text(encoding="utf-8-sig").strip()

receipt = read(NATIVE / "receipt.json")
assert receipt["version"] == "0.2.1" and receipt["max_year"] == 2027 and not receipt["faults"]
for name, value in receipt["source_hashes"].items(): assert sha(ROOT / "CyrusPhysicsLab" / name) == value, name
for name, value in receipt["shared_source_hashes"].items(): assert sha(ROOT / name) == value, name
for name, value in receipt["binaries"].items(): assert sha(NATIVE / name) == value, name
assert "100% tests passed, 0 tests failed out of 8" in txt(NATIVE / "tests.log")
exact = read(BUILD / "exact-artist-result.json")
assert exact["pass"] and exact["artist_colliders"][0]["cooked_triangles"] == 84672
assert exact["artist_colliders"][0]["input_triangles"] == 84672
assert exact["platform"]["sleeping"]
grip = read(BUILD / "small-grip.json")
assert grip["pass"] and grip["cases"][1]["sleeping"]

def host(name, restart=False, expected_failures=False):
    folder = ROOT / "build" / name
    prefix = "restart-" if restart else ""
    assert (folder / (prefix + "completed.json")).exists(), folder
    assert not (folder / (prefix + "error.txt")).exists(), folder
    diag = folder / (prefix + "diagnostics")
    exits = [read(p) for p in diag.glob("*/process-exit.json")]
    assert exits and all(x["exit_code"] == 0 and x["exception_notifications"] == 0 for x in exits), exits
    launch = read(folder / "launch.json")
    assert launch["script_sha256"] == receipt["source_hashes"]["scripts/CyrusPhysicsLab.ms"]
    for name, value in launch["binaries"].items(): assert receipt["binaries"][name] == value
    errors = []; commits = []; ready = []; scales = set()
    for path in diag.glob("*/events-*.jsonl"):
        for line in path.read_text(encoding="utf-8").splitlines():
            event = json.loads(line); kind = event["event"]; data = event["data"]
            if kind == "bake.commit": commits.append(data)
            if kind == "bake.collider.ready": ready.append(data)
            if kind == "prepare.exit": scales.add(data.get("solver_length_scale"))
            if kind in ("live.worker.error", "live.commit.error", "live.step.error", "paint.error", "collision.display.error", "source.cook.error", "scene.notification.error"):
                message = data.get("message", data.get("error", ""))
                allowed = (message.startswith("Finish wall-time limit")
                           or message == "Finish limit reached. Freeze the preview or resume brushing."
                           or message.startswith("Bake collider exceeds 200,000"))
                if expected_failures: allowed |= message in ("Static collider 1: Collider has no non-degenerate triangles", "Collider has no triangles")
                assert allowed, (folder, event)
                errors.append({"event": kind, "message": message})
    return {"profile": str(folder.relative_to(ROOT)), "launch": launch, "exits": exits,
            "bake_commits": len(commits), "bake_cook_checks": len(ready), "solver_length_scales": sorted(scales),
            "expected_rejections_or_settle_limits": errors, "unexpected_errors": 0}

installed = ROOT / "build/physics-lab-collider-021-installed-03"
transitions = captured = installed
profiles = [host(installed.name, restart=True, expected_failures=True)]
assert txt(transitions / "transition-summary.txt").startswith("7 cases; 195 checks;")
assert txt(captured / "captured-count.txt") == "22"
assert txt(captured / "failure-count.txt") == "18"
assert txt(installed / "workflow-count.txt") == "56"
assert txt(installed / "stack-count.txt") == "69"
assert txt(installed / "recovery-count.txt") == "12"
assert txt(installed / "mountain-count.txt").startswith("9 cases;")

package = DIST / "CyrusPhysicsLab-0.2.1-Max2027.mzp"
with zipfile.ZipFile(package) as archive:
    assert archive.testzip() is None
    manifest = json.loads(archive.read("manifest.json"))
    assert manifest["version"] == "0.2.1" and manifest["max_year"] == 2027
    for name, value in manifest["payload"].items(): assert hashlib.sha256(archive.read(name)).hexdigest() == value, name
    assert not any("Probe" in p or p.endswith(".pdb") for p in archive.namelist())
    assert b"29000" in archive.read("install.ms")
    for name in ("CyrusPhysicsLab.dlx", "CyrusPhysicsStorage.dlh"):
        assert hashlib.sha256(archive.read("native/" + name)).hexdigest() == receipt["binaries"][name]
installer = read(installed / "installer-receipt.json")
assert installer["pass"] and installer["package_sha256"] == sha(package)
original = ROOT / "Test Scene/Mountain Scene Brush Test.max"
assert sha(original) == "99ee36fd84f34995ca565aa27ad6292a5b83b46a24ea7cfbe92a7ab87315b28e"

evidence = {"pass": True, "date": "2026-10-19", "version": "0.2.1", "max_year": 2027,
    "computer_use": False, "artist_profile_installation": False, "scatter_integration": False,
    "source_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
    "build": str(NATIVE.relative_to(ROOT)), "receipt": receipt, "native_suites": 8,
    "artist_capture": read(BUILD / "artist-capture/capture.json"), "old_pair_reproduction": txt(BUILD / "baseline.txt"),
    "exact_artist_native_replay": exact, "small_object_grip": grip,
    "private_grip_binary_sha256": sha(BUILD / "small-grip.exe"),
    "linked_core_library_sha256": sha(NATIVE / "cpl_core.lib"),
    "profiles": profiles, "installer": installer,
    "package": {"path": str(package.relative_to(ROOT)), "sha256": sha(package), "bytes": package.stat().st_size},
    "transitions": txt(transitions / "transition-summary.txt"), "captured_host_assertions": 22,
    "failure_host_assertions": 18, "installed_workflow_assertions": 56,
    "installed_workflow_stack_assertions": 69, "recovery_assertions": 12,
    "mountain": txt(installed / "mountain-count.txt"), "stack_height_m": txt(installed / "stack-height.txt"),
    "original_mountain_sha256": sha(original),
    "preserved_failed_candidates": [
        "Cook-only candidate passed captured cooking but the 2 mm dynamic platform test lost contact; fixed by solver length scaling, not accepted as a pass.",
        "installed-01 budget fixture emitted 193536 triangles below the 200000 bound; fixture corrected to assert a genuinely oversized batch. Product/package bytes unchanged.",
        "installed-02 passed workflow, stack and recovery but the owned parent timed out at 600 seconds during mountain case 8. Its incomplete run is not a qualification pass; installed-03 reruns the full suite against the final guarded binary with a 1200-second allowance."],
    "fixture_hashes": {p.name: sha(p) for p in Path(__file__).resolve().parent.iterdir() if p.is_file()}}
(DOCS / "COLLIDER_COOK_021_EVIDENCE.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
print("PASS current sources, eight suites, exact capture, host transitions/failures/mountain and installed MZP")
