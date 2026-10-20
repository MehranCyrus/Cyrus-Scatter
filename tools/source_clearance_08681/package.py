"""Package the frozen Max 2027 pair; hard-link unchanged optional content."""
from pathlib import Path
from types import SimpleNamespace
import hashlib
import json
import shutil
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/clearance-performance-08681-20261020/final"
OUT = ROOT / "dist/CyrusScatter-0.86.8.1-20261020"
NATIVE = WORK / "max2027"
sys.path.insert(0, str(ROOT / "tools"))
import build_max
sys.path.insert(0, str(ROOT / "AminScatter/tools"))
import build_installer


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    receipt = json.loads((NATIVE / "receipt.json").read_text())
    assert receipt["max_year"] == 2027 and all(s["exit_code"] == 0 for s in receipt["stages"])
    for name, digest in receipt["sources"].items():
        assert sha(ROOT / name) == digest, name
    for name, digest in receipt["binaries"].items():
        assert sha(ROOT / name) == digest, name
    build_installer.build(WORK / "CyrusInstaller.dll")
    stage = WORK / "package2027"
    runtime = stage / "AminScatter"
    runtime.mkdir(parents=True, exist_ok=True)
    names = ["AminScatter.dlx", "CyrusScatterEdit.dlm", "CyrusBrush.dlx", "CyrusBrushStorage.dlh"]
    for name in names + ["CyrusGallery.dll"]:
        shutil.copy2(NATIVE / name, runtime / name)
    for name in ["CyrusInstaller.dll", "CyrusInstaller.build.json"]:
        shutil.copy2(WORK / name, runtime / name)
    args = SimpleNamespace(max_year=2027, tools_version="14.38.33130",
        windows_sdk="10.0.19041.0", output=OUT,
        team_trust_header=ROOT / "CyrusLicensing/team/team_public_key.h",
        content_dir=ROOT / "dist/CyrusScatter-0.86.7-20261020/Content")
    build_max.package("AminScatter", "Cyrus Scatter", "0.86.8.1", names,
                      "AminScatterObject.ms", args, stage)
    mzp = OUT / "CyrusScatter-0.86.8.1-Max2027.mzp"
    with zipfile.ZipFile(mzp) as archive:
        assert archive.testzip() is None
        manifest = json.loads(archive.read("manifest.json"))
        assert manifest["version"] == "0.86.8.1" and manifest["max_year"] == 2027
        assert set(archive.namelist()) == set(manifest["files"]) | {"manifest.json"}
        for name, digest in manifest["files"].items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
        for name in names + ["CyrusGallery.dll"]:
            assert manifest["files"][name] == sha(NATIVE / name)
        assert manifest["files"]["CyrusScatter.ms"] == sha(ROOT / "AminScatter/scripts/AminScatterObject.ms")
        assert b"29000" in archive.read("install.ms")
        assert not any(name.startswith("Library/") or name.endswith(".max") for name in archive.namelist())
        payload = WORK / "payload2027"
        payload.mkdir(exist_ok=True)
        for name in archive.namelist():
            assert not Path(name).is_absolute() and ".." not in Path(name).parts
        archive.extractall(payload)
    exe = OUT / "CyrusScatter-0.86.8.1-Setup.exe"
    build_installer.build_exe(exe, [mzp], WORK / "CyrusInstaller.dll")
    original = ROOT / "dist/CyrusScatter-0.86.7.2-corrected-20261020/CyrusScatter-Content-0.86.7.zip"
    content = OUT / original.name
    if not content.exists():
        content.hardlink_to(original)
    assert content.samefile(original), "Content must reuse the existing archive allocation"
    hashes = {p.name: sha(p) for p in [exe, mzp, content]}
    (OUT / "SHA256SUMS.txt").write_text("".join(f"{h}  {n}\n" for n, h in hashes.items()))
    (WORK / "package-checks.json").write_text(json.dumps({
        "hosts": [2027], "artifacts": hashes, "content_hardlink": True,
        "checks": ["frozen source hashes", "archive CRC", "every payload hash",
                   "exact native/script/Gallery pair", "host guard", "content excluded from MZP"]
    }, indent=2) + "\n")
    for suffix in (".build.json", ".build.log", ".identity.cs"):
        sidecar = exe.with_suffix(suffix)
        shutil.move(str(sidecar), str(WORK / sidecar.name))
    print(OUT)


if __name__ == "__main__":
    main()
