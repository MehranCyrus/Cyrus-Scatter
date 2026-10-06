"""Collect small receipts for the frozen playback candidate; no host or install."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
LAB = ROOT / "build/playback-20261006"
DEST = ROOT / "docs/Playback_Performance_2026-10-06/evidence"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    final_native = {}
    for folder in ("max2026", "max2027", "analyzer-max2026", "analyzer-max2027"):
        receipt = LAB / folder / "receipt.json"
        data = json.loads(receipt.read_text())
        assert data.get("status") != "pending" and all(s["exit_code"] == 0 for s in data["stages"])
        assert all(sha(ROOT / name) == digest for name, digest in data["sources"].items()), folder
        assert all(sha(ROOT / name) == digest for name, digest in data["binaries"].items()), folder
        if data["max_year"] == 2027:
            final_native.update({Path(name).name: digest for name, digest in data["binaries"].items()})
        shutil.copy2(receipt, DEST / (folder + "-build.json"))
        shutil.copy2(LAB / folder / "tests.log", DEST / (folder + "-tests.txt"))
    runtime = json.loads((LAB / "run19/receipt.json").read_text())
    assert runtime["passed"] and runtime["loaded_native_matches"] and runtime["artist_profile_unchanged"]
    assert "SUCCESS 1312 assertions" in runtime["report"]
    assert set(final_native) == set(runtime["loaded_native"])
    assert all(runtime["loaded_native"][name]["sha256"] == digest for name, digest in final_native.items())
    for name, relative in {"AminScatterObject.ms": "AminScatter/scripts/AminScatterObject.ms",
                           "CyrusSurfaceAnalyzer.ms": "CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms",
                           "fixture.ms": "tools/procedural_lab/Max_Playback_Regression.ms",
                           "analyzer-fixture.ms": "tools/procedural_lab/Max_Analyzer_Playback_Regression.ms"}.items():
        assert sha(ROOT/relative) == runtime["sources_and_binaries"][name], relative
    shutil.copy2(LAB / "run19/receipt.json", DEST / "max2027-headless.json")
    shutil.copy2(LAB / "run19/result.txt", DEST / "max2027-result.txt")
    shutil.copy2(LAB / "python-tests.xml", DEST / "python-tests.xml")
    shutil.copy2(ROOT / "build/procedural-07/generated-check.json", DEST / "generated-check.json")
    # One failure receipt preserves the distinction between counters and queue state.
    shutil.copy2(LAB / "run16/receipt.json", DEST / "intermediate-deferred-release-failure.json")
    paths = subprocess.check_output(["git", "ls-files", "--modified", "--others", "--exclude-standard", "-z"], cwd=ROOT).decode().split("\0")
    suffixes = {".cpp", ".h", ".ms", ".cjs", ".py"}
    sources = {name: sha(ROOT/name) for name in sorted(set(paths)) if name and
               (Path(name).suffix in suffixes or Path(name).name == "CMakeLists.txt")}
    evidence = {p.name: {"sha256": sha(p), "bytes": p.stat().st_size}
                for p in sorted(DEST.iterdir()) if p.is_file() and p.name != "index.json"}
    index = {"recorded_at_utc": datetime.now(timezone.utc).isoformat(),
             "branch": subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip(),
             "baseline": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
             "computer_use": False, "installed": False, "packaged": False,
             "qualification": "Code-only candidate: SDK/native executables and private headless Max 2027; no presented FPS/UI/IR qualification.",
             "changed_source_sha256": sources, "evidence": evidence}
    (DEST / "index.json").write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    print(f"Collected {len(evidence)} receipts and {len(sources)} changed source fingerprints.")


if __name__ == "__main__":
    main()
