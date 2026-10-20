"""Seal the script-only Hide surface correction against fresh owned-host receipts."""
from pathlib import Path
import hashlib, json, re, zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/hide-surface-08672-20261020"
DIST = ROOT / "dist/CyrusScatter-0.86.7.2-corrected-20261020"
COMPILED = ROOT / "build/final-08672-20261020"

def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))

record = {"version": "0.86.7.2", "status": "passed", "native_rebuilt": False,
          "artist_profiles_modified": False, "assets_regenerated": False,
          "artifacts": {}, "evidence": {}}

def receipt(path):
    text = path.read_text(encoding="utf-8-sig")
    assert "SUCCESS" in text and "FAIL:" not in text and not re.search(r"^ERROR", text, re.M), path
    record["evidence"][str(path.relative_to(ROOT))] = sha(path)

script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
fingerprint = re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"', script.read_text(encoding="utf-8-sig"))[1]
assert read(WORK / "generated/generated-check.json")["generated_sha256"] == sha(script)
exe = DIST / "CyrusScatter-0.86.7.2-Setup.exe"
buildfile = exe.with_suffix(".build.json")
if not buildfile.exists():
    buildfile = WORK / "artifact-build" / buildfile.name
build = read(buildfile)
assert sha(exe) == build["artifact_sha256"]
for path, digest in build["sources"].items():
    assert sha(ROOT / path) == digest, path
assert sha(COMPILED / "CyrusInstaller.dll") == build["core_sha256"]
resources = read(WORK / "exe-resource-hashes.json")
record["artifacts"][exe.name] = sha(exe)
for year in (2024, 2026, 2027):
    host = ROOT / f"build/mcp-qualification/update08671-test-hide-fixed-{year}"
    loaded, launch = read(host / "loaded-identity.json"), read(host / "launch.json")
    assert loaded["year"] == year and loaded["script"] == fingerprint
    package = DIST / f"CyrusScatter-0.86.7.2-Max{year}.mzp"
    with zipfile.ZipFile(package) as archive:
        assert archive.testzip() is None
        manifest = json.loads(archive.read("manifest.json"))
        assert manifest["version"] == "0.86.7.2" and manifest["max_year"] == year
        assert set(archive.namelist()) == set(manifest["files"]) | {"manifest.json"}
        for name, digest in manifest["files"].items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
        assert manifest["files"]["CyrusScatter.ms"] == launch["script_sha256"] == sha(script)
        assert manifest["files"]["CyrusGallery.dll"] == loaded["gallery"] == sha(COMPILED / f"max{year}/CyrusGallery.dll")
        assert manifest["files"]["CyrusInstaller.dll"] == build["core_sha256"]
        assert len(loaded["native"]) == 4
        for name, digest in loaded["native"].items():
            assert manifest["files"][name] == digest == launch["binaries"][name] == sha(COMPILED / f"max{year}" / name)
        assert str((year - 1998) * 1000).encode() in archive.read("install.ms")
    embedded = next(row for row in build["packages"] if row["year"] == str(year))
    assert embedded["package_sha256"] == resources[embedded["resource"]] == sha(package)
    record["artifacts"][package.name] = sha(package)
    receipt(host / "hide-acceptance.txt")
    record["evidence"][str((host / "loaded-identity.json").relative_to(ROOT))] = sha(host / "loaded-identity.json")
host2027 = ROOT / "build/mcp-qualification/update08671-test-hide-fixed-2027"
for name in ("viewport-08672.txt", "brush-ui-08672.txt", "surface-08672.txt"):
    receipt(host2027 / name)
installer = COMPILED / "exe-ui-hide-correction"
receipt(installer / "result.txt")
assert (installer / "exe-sha256.txt").read_text(encoding="utf-8-sig").strip() == sha(exe)
original = read(COMPILED / "final-receipt.json")
content = DIST / "CyrusScatter-Content-0.86.7.zip"
assert sha(content) == original["artifacts"][content.name]
record["artifacts"][content.name] = sha(content)
record["content_storage"] = "NTFS hard link to original content ZIP; no new asset/archive bytes"
record["script_sha256"] = sha(script)
record["loaded_script_fingerprint"] = fingerprint
record["source_sha256"] = sha(ROOT / "AminScatter/tools/ui/templates/unified-core.ms")
record["prior_delivery"] = str((COMPILED / "final-receipt.json").relative_to(ROOT))
(WORK / "correction-receipt.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
(DIST / "SHA256SUMS.txt").write_text("".join(f"{digest}  {name}\n" for name, digest in record["artifacts"].items()), encoding="utf-8")
# Keep developer sidecars outside the artist-facing delivery folder.
sidecars = WORK / "artifact-build"
sidecars.mkdir(exist_ok=True)
for path in DIST.iterdir():
    if path.name.endswith((".build.json", ".build.log", ".identity.cs", ".sha256")):
        destination = sidecars / path.name
        assert not destination.exists()
        path.rename(destination)
print(json.dumps(record, indent=2))
