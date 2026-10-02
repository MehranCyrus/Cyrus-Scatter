"""Measure a saved artist scene in isolated Max processes and compare exact rows.

No installation, interaction with the open Max session, or save over the source.
The fixed edge recipe measures synchronous calculations + preview preparation;
it does not measure GPU frame completion or automatic UI scheduling.
"""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import statistics
import subprocess
import shutil
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]


def fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scene", type=Path, default=ROOT / "Test Scene/SaveSelect 2.max")
    parser.add_argument("--reference", type=Path, default=ROOT / "build/performance-reference/20261001-cpu-v1")
    parser.add_argument("--output", type=Path, default=ROOT / "build/scene-benchmark-v1")
    parser.add_argument("--engines", nargs="+", choices=("reference", "candidate", "script_only"), default=["reference", "candidate"])
    parser.add_argument("--threads", type=int, default=0)
    parser.add_argument("--trials", type=int, default=3)
    parser.add_argument("--reuse-reference", type=Path, help="Reuse a verified reference from an earlier run of the same saved scene/recipe")
    args = parser.parse_args()
    if not 1 <= args.trials <= 30 or not 0 <= args.threads <= 64:
        parser.error("trials must be 1..30; threads must be 0..64")
    scene = args.scene.resolve()
    original_hash = hashlib.sha256(scene.read_bytes()).hexdigest()
    reference = args.reference.resolve()
    manifest = json.loads((reference / "manifest.json").read_text())
    for name, expected in manifest["files"].items():
        if hashlib.sha256((reference / name).read_bytes()).hexdigest() != expected:
            raise SystemExit(f"Frozen reference changed: {name}")
    output = args.output.resolve()
    summaries = {}
    identities = {}
    started = datetime.now(timezone.utc).isoformat()
    earlier = None
    if args.reuse_reference:
        previous = args.reuse_reference.resolve()
        if "reference" not in args.engines or previous == output:
            parser.error("reference must be included; the new output must differ from the reused run")
        earlier = json.loads((previous / "results.json").read_text())
        harness = ROOT / "tools/tests/scene_compute_benchmark.ms"
        if (earlier["scene_sha256"] != original_hash or earlier["trials"] != args.trials or
            earlier.get("harness_files", {}).get(str(harness)) != fingerprint(harness)):
            raise SystemExit("Cannot reuse reference: scene, trials or geometry harness differs")
    for engine in args.engines:
        source = reference if engine == "reference" else ROOT
        native = (reference if engine == "script_only" else source) / "build/max2027-release"
        measured_files = [native / "AminScatter/AminScatter.dlx", native / "AminScatter/CyrusScatterEdit.dlm",
                          native / "CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.dlx",
                          source / "AminScatter/scripts/AminScatterObject.ms",
                          source / "CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms"]
        identities[engine] = {str(path): fingerprint(path) for path in measured_files}
        destination = output / engine
        destination.mkdir(parents=True, exist_ok=True)
        plugins = destination / "plugins.ini"
        plugins.write_text("[Directories]\nCyrusScatterTest=" + str(native / "AminScatter") +
                           "\nCyrusAnalyzerTest=" + str(native / "CyrusSurfaceAnalyzer") + "\n")
        ini = destination / "max.ini"
        if not ini.exists(): ini.write_text("[Directories]\n")
        result = destination / "result.txt"
        values = [str(source / "CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms"),
                  str(source / "AminScatter/scripts/AminScatterObject.ms"), destination.as_posix()+"/", scene.as_posix()]
        # MAXScript uses forward slashes for paths; JSON quotes are not shell code.
        entry = destination / "entry.ms"
        entry.write_text("global CyrusBench=#(" + ",".join(json.dumps(v.replace("\\", "/")) for v in values) +
                         f",{args.threads},{args.trials})\nfileIn " +
                         json.dumps((ROOT / "tools/tests/scene_compute_benchmark.ms").as_posix()) + "\n")
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
        command = ["C:/Program Files/Autodesk/3ds Max 2027/3dsmaxbatch.exe", str(entry), "-i", str(ini), "-p", str(plugins),
                   "-listenerlog", str(destination / "listener.log"), "-log", str(destination / "session.log")]
        returncode = 0
        if engine == "reference" and earlier is not None:
            if identities[engine] != earlier.get("measured_files", {}).get(engine):
                raise SystemExit("Cannot reuse reference: native binaries or scripts differ")
            old = args.reuse_reference.resolve() / engine
            for path in list(old.glob("*.bin")) + [old / name for name in ("result.txt", "recipe.txt", "timings.csv")]:
                shutil.copyfile(path, destination / path.name)
                if fingerprint(path) != fingerprint(destination / path.name):
                    raise SystemExit("Reused reference copy verification failed")
            print(f"Reusing preserved reference measurements: {old}", flush=True)
        else:
            result.write_text("PENDING\n")
            print(f"Running {engine} in a separate Max batch process...", flush=True)
            with (destination / "stdout.log").open("wb") as out, (destination / "stderr.log").open("wb") as err:
                completed = subprocess.run(command, cwd=ROOT, stdout=out, stderr=err, startupinfo=startup, timeout=600)
                returncode = completed.returncode
        report = result.read_text(encoding="utf-8-sig")
        if returncode or "SUCCESS" not in report:
            raise SystemExit(f"Scene test failed ({engine}): {report}; inspect {destination}")
        if any(fingerprint(path) != identities[engine][str(path)] for path in measured_files):
            raise SystemExit(f"Measured engine files changed during {engine}")
        with (destination / "timings.csv").open(encoding="utf-8-sig", newline="") as stream:
            rows = list(csv.DictReader(stream))
        grouped = {}
        for row in rows:
            key = "|".join(row[k] for k in ("phase", "kind", "layer"))
            grouped.setdefault(key, []).append(float(row["elapsed_ms"].lower().replace("d", "e")))
        summaries[engine] = {key: dict(median_ms=statistics.median(values), samples_ms=values) for key, values in grouped.items()}
        print(f"PASS {engine}: {len(rows)} timings, 5 defined geometry states", flush=True)
    if {"reference", "candidate"} <= set(summaries):
        if (output / "reference/recipe.txt").read_bytes() != (output / "candidate/recipe.txt").read_bytes():
            raise SystemExit("Geometry recipe differs")
        reference_files = sorted((output / "reference").glob("*.bin"))
        candidate_files = sorted((output / "candidate").glob("*.bin"))
        if [p.name for p in reference_files] != [p.name for p in candidate_files]:
            raise SystemExit("Output fixture set differs")
        for path in candidate_files:
            if path.read_bytes() != (output / "reference" / path.name).read_bytes():
                raise SystemExit(f"Ordered transforms or source assignment changed: {path.name}")
        for key, result in summaries["candidate"].items():
            result["speedup_vs_reference"] = summaries["reference"][key]["median_ms"] / result["median_ms"]
        print(f"PASS exact bytes of all transforms/source IDs in {len(candidate_files)} scene outputs", flush=True)
    if "script_only" in summaries and "reference" in summaries:
        for path in (output / "reference").glob("*.bin"):
            if path.read_bytes() != (output / "script_only" / path.name).read_bytes():
                raise SystemExit(f"Older native engine/script fallback changed rows: {path.name}")
        print("PASS script fallback with the preserved older native engine", flush=True)
    if hashlib.sha256(scene.read_bytes()).hexdigest() != original_hash:
        raise SystemExit("Original scene changed")
    report = dict(scene=str(scene), scene_sha256=original_hash, trials=args.trials, threads=args.threads,
                  started_utc=started, measured_files=identities,
                  reference_reused_from=str(args.reuse_reference.resolve()) if earlier is not None else None,
                  reference_started_utc=earlier["started_utc"] if earlier is not None else started,
                  harness_files={str(path): fingerprint(path) for path in
                                 [Path(__file__), ROOT / "tools/tests/scene_compute_benchmark.ms"]},
                  scope="synchronous CPU calculations and preview preparation; excludes automatic UI scheduling/GPU frames",
                  compute_stats_scope="most recent native scatter call on the calling thread; may describe a dependent layer",
                  output_sha256={engine: {path.name: fingerprint(path) for path in sorted((output / engine).glob("*.bin"))}
                                 for engine in summaries},
                  summaries=summaries)
    (output / "results.json").write_text(json.dumps(report, indent=2) + "\n")
    for engine, values in summaries.items():
        for key, result in values.items():
            if "controller_refresh" in key or key.endswith("placements|3"):
                print(engine, key, f'{result["median_ms"]:.2f} ms', flush=True)


if __name__ == "__main__":
    main()
