"""Verify frozen sources, loaded pairs, installed bytes and final artifacts."""
from pathlib import Path
import hashlib
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/source-clearance-0868-20261020/final"
DIST = ROOT / "dist/CyrusScatter-0.86.8-20261020"


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    record = dict(version="0.86.8", hosts=[2027], status="passed",
                  artist_profiles_modified=False, content_regenerated=False,
                  evidence={}, artifacts={})

    def receipt(path):
        text = path.read_text(encoding="utf-8-sig")
        assert "SUCCESS" in text and not re.search(r"^(ERROR|FAIL:)", text, re.M), path
        record["evidence"][path.relative_to(ROOT).as_posix()] = sha(path)

    native = read(WORK / "max2027-r2/receipt.json")
    assert native["max_year"] == 2027 and all(s["exit_code"] == 0 for s in native["stages"])
    for path, digest in native["sources"].items():
        assert sha(ROOT / path) == digest, path
    record["evidence"]["build/source-clearance-0868-20261020/final/max2027-r2/receipt.json"] = sha(WORK / "max2027-r2/receipt.json")
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    fingerprint = re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"', script.read_text())[1]
    generated = read(WORK / "generated-r2/generated-check.json")
    assert generated["passed"] and generated["generated_sha256"] == sha(script)
    assert read(WORK / "python-tests.json")["exit_code"] == 0
    mzp = DIST / "CyrusScatter-0.86.8-Max2027.mzp"
    with zipfile.ZipFile(mzp) as archive:
        assert archive.testzip() is None
        manifest = json.loads(archive.read("manifest.json"))
        assert manifest["version"] == "0.86.8" and manifest["max_year"] == 2027
        for name, digest in manifest["files"].items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
        assert manifest["files"]["CyrusScatter.ms"] == sha(script)
        assert b"29000" in archive.read("install.ms")
    for name in ("final2", "installed3"):
        host = ROOT / f"build/mcp-qualification/update08671-test-clearance-{name}-2027"
        launch = read(host / "launch.json")
        loaded = read(host / "loaded-identity.json")
        assert launch["script_sha256"] == sha(script)
        assert loaded["script"] == fingerprint and loaded["version"] == "0.86.8"
        assert loaded["recipe"] == 8 and loaded["publication"] == 4 and loaded["year"] == 2027
        assert loaded["gallery"] == manifest["files"]["CyrusGallery.dll"]
        assert len(loaded["native"]) == 4
        for module, digest in loaded["native"].items():
            assert digest == launch["binaries"][module] == manifest["files"][module] == sha(WORK / "max2027-r2" / module)
        for log in ("clearance-acceptance.txt", "real-models.txt"):
            receipt(host / log)
        if name == "final2":
            receipt(host / "clearance-lifecycle.txt")
        record["evidence"][(host / "loaded-identity.json").relative_to(ROOT).as_posix()] = sha(host / "loaded-identity.json")
    receipt(ROOT / "build/mcp-qualification/update08671-test-clearance-old-reader-2027/old-reader.txt")
    receipt(WORK / "installer-final-r2/result.txt")
    for name, entry in read(WORK / "installed-load-r2.json").items():
        assert sha(Path(entry["installed"])) == entry["sha256"]
        if name in manifest["files"]:
            assert entry["sha256"] == manifest["files"][name]
    exe = DIST / "CyrusScatter-0.86.8-Setup.exe"
    build = read(WORK / "CyrusScatter-0.86.8-Setup.build.json")
    assert sha(exe) == build["artifact_sha256"]
    assert build["max_years"] == [2027] and build["packages"][0]["package_sha256"] == sha(mzp)
    for path, digest in build["sources"].items():
        assert sha(ROOT / path) == digest, path
    resources = read(WORK / "exe-resources.json")
    assert resources["Cyrus.Payload.2027.mzp"] == sha(mzp)
    content = DIST / "CyrusScatter-Content-0.86.7.zip"
    original = ROOT / "dist/CyrusScatter-0.86.7.2-corrected-20261020" / content.name
    assert content.samefile(original)
    for path in (exe, mzp, content):
        record["artifacts"][path.name] = sha(path)
    record["script_sha256"] = sha(script)
    record["loaded_script_fingerprint"] = fingerprint
    record["content_hardlink"] = True
    (WORK / "final-receipt.json").write_text(json.dumps(record, indent=2) + "\n")
    (DIST / "SHA256SUMS.txt").write_text("".join(f"{digest}  {name}\n" for name, digest in record["artifacts"].items()))
    print(json.dumps(record, indent=2))


if __name__ == "__main__":
    main()
