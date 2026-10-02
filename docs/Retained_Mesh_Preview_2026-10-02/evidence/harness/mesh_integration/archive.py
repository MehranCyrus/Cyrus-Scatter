"""Curate accepted Mesh evidence without copying scenes, DLLs or SDK files."""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import hashlib
import json
import shutil
import subprocess
from build import ROOT, BASE


def fingerprint(path):
    return {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run", required=True)
    args = parser.parse_args()
    run = (BASE / args.run).resolve()
    if run.parent != BASE.resolve() or args.run == "run01":
        raise SystemExit("Choose a valid, accepted private run; run01 is rejected")
    destination = ROOT / "docs/Retained_Mesh_Preview_2026-10-02/evidence"
    manifest_path = destination / "manifest.json"
    if manifest_path.exists() and json.loads(manifest_path.read_text())["run"] != args.run:
        raise SystemExit("Existing evidence belongs to another run")

    receipts = ["analysis.json", "identity.json", "ready.json", "launch.json",
                "environment.json", "protection.json", "mesh-smoke.json",
                "mesh-lifecycle.json", "lifecycle.json", "hardening.json",
                "mesh-parity.json", "mesh-memory.json", "shutdown.json",
                "artist-mesh-initial.json"]
    for name in receipts:
        json.loads((run / name).read_text(encoding="utf-8-sig"))
    protection = json.loads((run / "protection.json").read_text(encoding="utf-8-sig"))
    if not (protection["scene_hash_unchanged"] and protection["artist_process_running"]
            and protection["private_processes_exited"]):
        raise SystemExit("Protection receipt did not pass")

    def copy(source, relative):
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)

    for name in receipts:
        copy(run / name, name)
    for pattern in ["*-frames.csv", "*-trials.json", "*-metadata.json"]:
        for path in sorted(run.glob(pattern)):
            copy(path, path.name)
    for path in sorted(run.glob("*.png")):
        copy(path, Path("images") / path.name)
    for path in sorted(run.glob("recipe-*.ms")):
        copy(path, Path("executed-recipes") / path.name)
    for name in ["start.ms", "plugins.ini"]:
        copy(run / name, Path("host") / name)
    copy(BASE / "packages.json", "packages.json")
    for year in [2026, 2027]:
        folder = BASE / f"max{year}"
        for name in ["build-0.log", "build-1.log", "build-2.log", "identity.json"]:
            copy(folder / name, Path(f"build-max{year}") / name)
        copy(folder / "Testing/Temporary/LastTest.log", Path(f"build-max{year}/LastTest.log"))

    # Freeze helper versions used by recipes that fileIn repository sources.
    for path in sorted(Path(__file__).parent.iterdir()):
        if path.suffix in {".py", ".ms"} or path.name == "README.md":
            copy(path, Path("harness/mesh_integration") / path.name)
    for name in ["build.py", "launch.py", "request.py", "bootstrap.ms",
                 "transport.ms", "lifecycle.ms", "hardening.ms"]:
        copy(ROOT / "tools/performance/retained_integration" / name,
             Path("harness/retained_integration") / name)
    copy(ROOT / "tools/performance/CyrusPerformanceMonitor.ms", "harness/CyrusPerformanceMonitor.ms")

    source_files = {ROOT / "AminScatter/CMakeLists.txt", ROOT / "tools/build_max.py",
                    ROOT / "AminScatter/scripts/AminScatterObject.ms",
                    ROOT / "CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms"}
    for directory in ["AminScatter/src", "AminScatter/include", "AminScatter/tools/ui"]:
        source_files.update(p for p in (ROOT / directory).rglob("*") if p.is_file())
    sources = {p.relative_to(ROOT).as_posix(): fingerprint(p) for p in sorted(source_files)}
    (destination / "source-hashes.json").write_text(json.dumps({
        "scope": "Completion-time fingerprints of implementation/generator inputs; not a clean-commit claim",
        "git_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "files": sources,
    }, indent=2) + "\n", encoding="utf-8")
    (destination / "README.md").write_text(
        "# Accepted Mesh evidence\n\n"
        f"Curated from isolated `{args.run}`. The report explains the measurement limits. "
        "`run01` artist timings are rejected and are not included.\n\n"
        "- `analysis.json`, timing CSVs and trial/metadata JSON: raw scripted redraw evidence.\n"
        "- `images/`: original, unedited captures, including legacy/retained pairs and the 61.7M-triangle stress view.\n"
        "- Runtime receipt JSON: lifecycle, transform, Point regression and deliberate memory-limit tests.\n"
        "- `identity.json`, `ready.json`, `packages.json`: tested files, loaded module paths and package identities.\n"
        "- `environment.json`, `protection.json`: hardware/version and post-test scene/process checks.\n"
        "- `build-max*/`: incremental build, CTest summary and per-suite logs. Both SDK builds passed nine suites.\n"
        "- `executed-recipes/`: copies submitted to Max; two memory recipes show the initial process-cap probe "
        "and the expanded final test. `mesh-memory.json` is the final expanded test's receipt.\n"
        "- `harness/`: frozen helper/recipe versions for audit. Use the active repository harness to reproduce, "
        "not these copies: their imports and paths expect the repository layout.\n"
        "- `source-hashes.json`: completion-time production/generator fingerprints. The working tree includes "
        "pre-existing work; its base Git commit alone does not identify this candidate.\n\n"
        "`manifest.json` hashes every other file here. No scene, mesh asset, native DLL or SDK file is included. "
        "Paths and process IDs describe this local test machine, not portable installation instructions.\n",
        encoding="utf-8")
    entries = {p.relative_to(destination).as_posix(): fingerprint(p)
               for p in sorted(destination.rglob("*")) if p.is_file() and p != manifest_path}
    manifest_path.write_text(json.dumps({"run": args.run,
        "created_utc": datetime.now(timezone.utc).isoformat(), "files": entries}, indent=2) + "\n",
        encoding="utf-8")
    print(json.dumps({"destination": str(destination), "files": len(entries),
                      "bytes": sum(item["bytes"] for item in entries.values())}, indent=2))


if __name__ == "__main__":
    main()
