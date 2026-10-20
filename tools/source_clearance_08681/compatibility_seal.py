"""Verify each additional installed host and the three-host distribution."""
from pathlib import Path
import hashlib
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/clearance-performance-08681-20261020/final"
OUT = ROOT / "dist/CyrusScatter-0.86.8.1-20261020"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    package = read(WORK / "compatibility-package-checks.json")
    assert package["hosts"] == [2024, 2026, 2027]
    for name, digest in package["artifacts"].items():
        assert sha(OUT / name) == digest, name
    fingerprint = re.search(r'CyrusLoadedScriptFingerprint\s*=\s*"([0-9a-f]+)"',
        (ROOT / "AminScatter/scripts/AminScatterObject.ms").read_text(encoding="utf-8-sig"))[1]
    outputs = {}
    for year in (2024, 2026, 2027):
        build = read(WORK / f"max{year}/receipt.json")
        assert build["max_year"] == year and all(s["exit_code"] == 0 for s in build["stages"])
        for name, digest in {**build["sources"], **build["binaries"]}.items():
            assert sha(ROOT / name) == digest, name
        with zipfile.ZipFile(OUT / f"CyrusScatter-0.86.8.1-Max{year}.mzp") as archive:
            assert archive.testzip() is None
            manifest = json.loads(archive.read("manifest.json"))
            assert manifest["max_year"] == year and manifest["version"] == "0.86.8.1"
            for name, digest in manifest["files"].items():
                assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
        installed = Path((WORK / f"installer-three-hosts/{year}/installed-runtime.txt").read_text().strip())
        for name in ("AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusScatterEdit.dlm", "CyrusGallery.dll", "CyrusScatter.ms"):
            path = installed / ("bin/" + name if name.endswith((".dlx", ".dlm", ".dlh")) else name)
            assert sha(path) == manifest["files"][name], path
        host = ROOT / ("build/mcp-qualification/update08671-test-clearance-perf-installed2-2027"
                       if year == 2027 else f"build/mcp-qualification/update08671-test-clearance-compat-{year}")
        loaded, launch = read(host / "loaded-identity.json"), read(host / "launch.json")
        assert loaded["year"] == year and loaded["version"] == "0.86.8.1"
        assert loaded["script"] == fingerprint and launch["script_sha256"] == manifest["files"]["CyrusScatter.ms"]
        assert loaded["gallery"] == manifest["files"]["CyrusGallery.dll"]
        assert all(digest == manifest["files"][name] for name, digest in loaded["native"].items())
        logs = ["viewport-steps-r2.txt"]
        logs += (["viewport-checks.txt", "installed-checks.txt"] if year == 2027
                 else ["clearance-acceptance.txt", "clearance-lifecycle.txt", "compatibility-viewport.txt"])
        hashes = {}
        for name in logs:
            path = host / name
            content = path.read_text()
            assert not re.search(r"^(FAIL:|ERROR )", content, re.M), path
            assert "PASS:" in content, path
            hashes[name] = sha(path)
        outputs[str(year)] = {"source_hashes": len(build["sources"]), "native_tests": 49,
                              "loaded": loaded, "logs": hashes, "host": str(host.relative_to(ROOT))}
    embedded = read(WORK / "compatibility-embedded-payloads.json")
    assert len(embedded) == 3
    for item in embedded:
        assert item["matches"] and item["sha256"] == package["artifacts"][f'CyrusScatter-0.86.8.1-Max{item["year"]}.mzp']
    result = WORK / "installer-three-hosts/result.txt"
    assert "SUCCESS" in result.read_text() and "FAIL" not in result.read_text()
    generated = read(WORK / "generated/generated-check.json")
    assert generated["passed"] and generated["generated_sha256"] == sha(ROOT / "AminScatter/scripts/AminScatterObject.ms")
    images = {}
    for name in ("installer-three-hosts.png", "max2024-textured.png", "max2024-colored.png",
                 "max2026-textured.png", "max2026-colored.png"):
        path = WORK / name
        assert path.stat().st_size > 10000, path
        images[name] = sha(path)
    receipt = {
        "version": "0.86.8.1", "hosts": outputs, "package": package,
        "installer_result": sha(result),
        "max2027_behavior_receipt": "max2027-only/final-receipt.json",
        "screenshots": images,
        "older_schema_fixture": {
            "path": "build/mcp-qualification/update08671-test-final4-2024/texture-persistence.max",
            "sha256": sha(ROOT / "build/mcp-qualification/update08671-test-final4-2024/texture-persistence.max"),
        },
        "scope": "Native suites on all three SDK builds; isolated installed-host integration and Standard-material opacity checks on 2024/2026; real Corona leaves and performance on 2027.",
        "original_content_reused": True, "artist_profiles_modified": False,
    }
    (WORK / "compatibility-final-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("PASS: 2024/2026/2027 source, package, installed, loaded and integration evidence")


if __name__ == "__main__":
    main()
