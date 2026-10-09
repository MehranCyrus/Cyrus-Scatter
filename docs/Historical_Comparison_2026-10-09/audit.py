"""Read saved sources/evidence; write this comparison's receipt. Does not run Max."""
import csv
import hashlib
import json
import statistics
import subprocess
import zipfile
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


receipt = {"date": "2026-10-09", "scope": "Source inspection and reanalysis of archived measurements; no new host benchmark", "head": git("rev-parse", "HEAD").decode().strip(), "sources": {}, "packages": {}, "timings": {}}
old_path = ROOT / "_local/archives/Cyrus Scatter.zip"
receipt["original_archive_sha256"] = digest(old_path.read_bytes())
with zipfile.ZipFile(old_path) as archive:
    for name in ["AminScatter/scripts/AminScatterObject.ms", "AminScatter/src/scatter.cpp", "AminScatter/src/preview.cpp"]:
        versions = {"0.59_archive": archive.read(name), "0.64_first_git": git("show", "b757b0f:" + name), "0.74_current": (ROOT / name).read_bytes()}
        receipt["sources"][name] = {version: {"sha256": digest(data), "lines": len(data.splitlines())} for version, data in versions.items()}

for relative in ["dist/CyrusScatter-0.59-Max2027.mzp", "dist/CyrusScatter-0.59-PrePerformance-Max2027.mzp", "dist/retained-mesh-0.64/CyrusScatter-0.64-Max2027.mzp", "dist/Layer_Paint_Areas_0.74_2026-10-09/Max2027/CyrusScatter-0.74.0-Max2027.mzp"]:
    path = ROOT / relative
    with zipfile.ZipFile(path) as archive:
        name = next(n for n in archive.namelist() if n.endswith(("AminScatterObject.ms", "CyrusScatter.ms")))
        receipt["packages"][relative] = {"sha256": digest(path.read_bytes()), "script_entry": name, "script_sha256": digest(archive.read(name))}

for folder, files in [
    ("docs/Retained_Mesh_Preview_2026-10-02/evidence", ["artist-mesh-200k-frames.csv", "artist-mesh-2m-frames.csv"]),
    ("docs/Retained_Point_Preview_2026-10-02/evidence", ["run04/artist-maximized-frames.csv"]),
]:
    manifest = json.loads((ROOT / folder / "manifest.json").read_text())["files"]
    if isinstance(manifest, list):
        manifest = {entry["path"]: entry for entry in manifest}
    for relative in files:
        path = ROOT / folder / relative
        actual = digest(path.read_bytes())
        assert actual == manifest[relative]["sha256"], path
        groups = defaultdict(list)
        with path.open(newline="", encoding="utf-8-sig") as stream:
            for row in csv.DictReader(stream):
                groups[row["arm"]].append(float(row["step_ms"]))
        receipt["timings"][folder + "/" + relative] = {"sha256_verified": actual, "arms": {arm: {"samples": len(values), "median_ms": statistics.median(values)} for arm, values in groups.items()}}

cpu = json.loads((ROOT / "docs/Performance_Evidence_2026-10-01.json").read_text())["saved_scene_benchmark"]
raw_cpu = Path(cpu["artifact"])
receipt["cpu_reference"] = {"receipt": "docs/Performance_Evidence_2026-10-01.json", "raw_result_exists": raw_cpu.exists(), "raw_result_sha256_matches": raw_cpu.exists() and digest(raw_cpu.read_bytes()) == cpu["artifact_sha256"], "reference_script_sha256": next(value for key, value in cpu["report"]["measured_files"]["reference"].items() if key.endswith("AminScatterObject.ms"))}
(OUT / "EVIDENCE.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"head": receipt["head"], "verified_timing_files": len(receipt["timings"]), "cpu_reference": receipt["cpu_reference"], "timings": receipt["timings"]}, indent=2))
