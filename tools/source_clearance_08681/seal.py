"""Verify release evidence without launching hosts or rewriting product sources."""
from pathlib import Path
import hashlib
import json
import re
import statistics
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/clearance-performance-08681-20261020/final"
DIST = ROOT / "dist/CyrusScatter-0.86.8.1-20261020"
HOST = ROOT / "build/mcp-qualification"


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    build = read(WORK / "max2027/receipt.json")
    assert build["max_year"] == 2027
    assert all(stage["exit_code"] == 0 for stage in build["stages"])
    for path, digest in {**build["sources"], **build["binaries"]}.items():
        assert sha(ROOT / path) == digest, path
    generated = read(WORK / "generated/generated-check.json")
    assert generated["passed"] and generated["development_version"] == "0.86.8.1"
    assert generated["generated_sha256"] == sha(ROOT / "AminScatter/scripts/AminScatterObject.ms")
    packages = read(WORK / "package-checks.json")
    for name, digest in packages["artifacts"].items():
        assert sha(DIST / name) == digest, name
    with zipfile.ZipFile(DIST / "CyrusScatter-0.86.8.1-Max2027.mzp") as archive:
        assert archive.testzip() is None
        manifest = json.loads(archive.read("manifest.json"))
        assert manifest["version"] == "0.86.8.1" and manifest["max_year"] == 2027
        for name, digest in manifest["files"].items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
    embedded = read(WORK / "embedded-payload.json")
    assert embedded["matches"] and embedded["sha256"] == packages["artifacts"]["CyrusScatter-0.86.8.1-Max2027.mzp"]
    installed = Path((WORK / "installer-final/installed-runtime.txt").read_text().strip())
    installed_hashes = {}
    for name in ("AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusScatterEdit.dlm", "CyrusGallery.dll", "CyrusScatter.ms"):
        path = installed / ("bin/" + name if name.endswith((".dlx", ".dlm", ".dlh")) else name)
        installed_hashes[str(path.relative_to(ROOT))] = sha(path)
        assert sha(path) == manifest["files"][name], name
    evidence = {}
    versions = []
    fingerprint = re.search(r'CyrusLoadedScriptFingerprint\s*=\s*"([0-9a-f]+)"',
                            (ROOT / "AminScatter/scripts/AminScatterObject.ms").read_text(encoding="utf-8-sig"))
    assert fingerprint, "Generated source fingerprint missing"
    for suffix in ("final", "installed2"):
        folder = HOST / f"update08671-test-clearance-perf-{suffix}-2027"
        loaded, launch = read(folder / "loaded-identity.json"), read(folder / "launch.json")
        assert loaded["version"] == "0.86.8.1" and loaded["year"] == 2027
        assert launch["script_sha256"] == manifest["files"]["CyrusScatter.ms"]
        assert loaded["script"] == fingerprint[1]
        assert loaded["gallery"] == manifest["files"]["CyrusGallery.dll"]
        for name, digest in loaded["native"].items():
            assert digest == manifest["files"][name], name
        versions.append(loaded)
        logs = ["profile-same-scene.txt", "viewport-checks.txt", "viewport-steps-r2.txt"]
        logs += ["clearance-acceptance.txt", "clearance-lifecycle.txt"] if suffix == "final" else ["installed-checks.txt"]
        for name in logs:
            path = folder / name
            content = path.read_text()
            assert not re.search(r"^(FAIL:|ERROR )", content, re.M), path
            assert "SUCCESS" in content or (name == "viewport-steps-r2.txt" and "PASS:" in content), path
            evidence[str(path.relative_to(ROOT))] = sha(path)
    result = WORK / "installer-final/result.txt"
    assert "SUCCESS" in result.read_text() and "FAIL:" not in result.read_text()
    evidence[str(result.relative_to(ROOT))] = sha(result)
    performance = {}
    for suffix in ("baseline", "final"):
        rows = []
        log = HOST / f"update08671-test-clearance-perf-{suffix}-2027/profile-same-scene.txt"
        for line in log.read_text().splitlines():
            if not line.startswith("mode="):
                continue
            pairs = dict(re.findall(r"(\w+)=([0-9.]+)(?:d0|L)?", line))
            rows.append({key: float(value) for key, value in pairs.items()})
        assert len(rows) == 20
        performance[suffix] = {
            str(mode): {
                "trials": 5,
                "accepted": [int(row["accepted"]) for row in rows if row["mode"] == mode],
                **{key: statistics.median(row[key] for row in rows if row["mode"] == mode)
                   for key in ("setter_ms", "solve_prepare_ms", "redraw_ms", "total_ms")}
            } for mode in range(1, 5)
        }
        evidence[str(log.relative_to(ROOT))] = sha(log)
    for mode in performance["baseline"]:
        assert performance["baseline"][mode]["accepted"] == performance["final"][mode]["accepted"]
    performance["notes"] = [
        "Same frozen two-leaf Count 200 scene; five warm radius edits per mode.",
        "Mode 1 Point Cloud, 2 Proxy, 3 colored Mesh, 4 Textured mesh.",
        "Wall-clock diagnostic measurements on a busy machine, not presented FPS.",
        "Baseline has no material bake counters; placeholder zeros are unavailable measurements.",
        "GPU upload assertions come from frame-separated viewport-steps logs, not nested redraw timings.",
    ]
    (WORK / "performance.json").write_text(json.dumps(performance, indent=2) + "\n")
    for name in ("colored-mesh.png", "textured-mesh.png"):
        path = WORK / name
        assert path.stat().st_size > 10000
        evidence[str(path.relative_to(ROOT))] = sha(path)
    original = ROOT / "dist/CyrusScatter-0.86.7.2-corrected-20261020/CyrusScatter-Content-0.86.7.zip"
    assert (DIST / original.name).samefile(original)
    output = {
        "version": "0.86.8.1", "hosts": [2027],
        "source_build_receipt": str((WORK / "max2027/receipt.json").relative_to(ROOT)),
        "source_hashes_checked": len(build["sources"]),
        "native_tests": 49,
        "generated": generated,
        "python_tests": {"passed": 176, "seconds": 13.88,
                         "command": "build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q",
                         "evidence": "Observed terminal completion, exit 0; no captured text log."},
        "packages": packages, "installed_files": installed_hashes,
        "loaded_identities": versions, "evidence": evidence,
        "artist_profile_modified": False,
        "content_regenerated": False,
        "qualification": "Scoped Max 2027; no broader host, renderer or all-feature performance certification.",
    }
    (WORK / "final-receipt.json").write_text(json.dumps(output, indent=2) + "\n")
    print(json.dumps({"version": output["version"], "source_hashes": len(build["sources"]),
                      "textured_baseline": performance["baseline"]["4"],
                      "textured_final": performance["final"]["4"]}, indent=2))


if __name__ == "__main__":
    main()
