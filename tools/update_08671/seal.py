"""Verify the delivered bytes against source, installed runtimes and host receipts."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/update-08671-20261020"
DIST = ROOT / "dist/CyrusScatter-0.86.7.1-20261020"


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


record = {"version": "0.86.7.1", "status": "passed", "artifacts": {}, "evidence": {},
          "content_revision": "0.86.7", "artist_profiles_modified": False}
exe = DIST / "CyrusScatter-0.86.7.1-Setup.exe"
build = read(exe.with_suffix(".build.json"))
assert sha(exe) == build["artifact_sha256"]
for path, fingerprint in build["sources"].items():
    assert sha(ROOT / path) == fingerprint, path
record["artifacts"][exe.name] = sha(exe)
real = read(WORK / "real-installer-final/result.json")
assert real["status"] == "passed" and len(real["checks"]) == 20
for year in (2024, 2026, 2027):
    mzp = DIST / f"CyrusScatter-0.86.7.1-Max{year}.mzp"
    host = ROOT / f"build/mcp-qualification/update08671-test-final-{year}"
    launch = read(host / "launch.json")
    gallery = read(WORK / f"max{year}/CyrusGallery.build.json")
    assert gallery["source_sha256"] == sha(ROOT / "AminScatter/ui/LibraryGallery.cs")
    assert gallery["shared_source_sha256"] == sha(ROOT / "AminScatter/shared/LibraryLocation.cs")
    with zipfile.ZipFile(mzp) as archive:
        assert archive.testzip() is None
        manifest = json.loads(archive.read("manifest.json"))
        assert manifest["version"] == "0.86.7.1" and manifest["max_year"] == year
        for name, fingerprint in manifest["files"].items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == fingerprint, name
        assert manifest["files"]["CyrusScatter.ms"] == launch["script_sha256"]
        assert launch["script_sha256"] == sha(ROOT / "AminScatter/scripts/AminScatterObject.ms")
        for name, fingerprint in launch["binaries"].items():
            assert manifest["files"][name] == fingerprint
            assert sha(Path(real["releases"][str(year)]) / "bin" / name) == fingerprint
        assert manifest["files"]["CyrusGallery.dll"] == launch["script_assets"]["CyrusGallery.dll"]
        assert manifest["files"]["CyrusGallery.dll"] == gallery["artifact_sha256"]
        assert manifest["files"]["CyrusInstaller.dll"] == build["core_sha256"]
        # The plugin includes small built-in density-pattern PNGs, not plants.
        assert not any(name.lower().endswith(".max") or name.startswith("Library/")
                       for name in archive.namelist())
    embedded = next(p for p in build["packages"] if int(p["year"]) == year)
    assert embedded["package_sha256"] == sha(mzp)
    record["artifacts"][mzp.name] = sha(mzp)
    for name in ("texture-acceptance", "source-controls", "panel-acceptance",
                 "gallery-host", "library-binding", "installer-host"):
        path = host / (name + ".txt")
        text = path.read_text()
        assert "SUCCESS" in text and "FAIL:" not in text and "ERROR" not in text, path
        record["evidence"][str(path.relative_to(ROOT))] = sha(path)

for name, scale in (("final", 1), ("dpi150b", 1.5), ("dpi200b", 2)):
    host = ROOT / f"build/mcp-qualification/update08671-test-{name}-2027"
    path = host / ("layout-settled2.json" if scale == 1 else "layout-settled.json")
    data = read(path)
    assert data["status"] == "passed" and data["max_scale"] == scale
    assert len(data["pages"]) == 12 and data["clipped_count"] == data["overlap_count"] == 0
    record["evidence"][str(path.relative_to(ROOT))] = sha(path)

for name in ("leaf-acceptance", "managed-leaf-acceptance"):
    path = ROOT / f"build/mcp-qualification/update08671-test-final-2027/{name}.txt"
    assert "SUCCESS" in path.read_text()
    record["evidence"][str(path.relative_to(ROOT))] = sha(path)
for relative in ("real-installer-final/result.json", "real-managed/result.json",
                 "installer-3be9278fde/result.json", "generated-qualified/generated-check.json",
                 "package-checks.json", "panel-comparison.json"):
    path = WORK / relative
    record["evidence"][str(path.relative_to(ROOT))] = sha(path)
content = ROOT / "dist/CyrusScatter-0.86.7-20261020/Content/content-manifest.json"
assert sha(content) == real["content_manifest_sha256"]
record["content_manifest_sha256"] = sha(content)
assert not (DIST / "Content").exists()
(WORK / "final-receipt.json").write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps({"status": "passed", "artifacts": len(record["artifacts"]),
                  "evidence_receipts": len(record["evidence"])}))
