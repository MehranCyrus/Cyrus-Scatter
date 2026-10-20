"""Extend the qualified 0.86.8.1 distribution with explicitly requested hosts."""
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
sys.path.insert(0, str(ROOT / "tools"))
import build_max
sys.path.insert(0, str(ROOT / "AminScatter/tools"))
import build_installer


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    history = WORK / "max2027-only"
    history.mkdir(exist_ok=False)
    for name in ("package-checks.json", "embedded-payload.json", "final-receipt.json"):
        shutil.copy2(WORK / name, history / name)
    shutil.copy2(OUT / "CyrusScatter-0.86.8.1-Setup.exe", history)
    names = ["AminScatter.dlx", "CyrusScatterEdit.dlm", "CyrusBrush.dlx", "CyrusBrushStorage.dlh"]
    for year in (2024, 2026):
        native = WORK / f"max{year}"
        receipt = json.loads((native / "receipt.json").read_text())
        assert receipt["max_year"] == year and all(s["exit_code"] == 0 for s in receipt["stages"])
        for name, digest in {**receipt["sources"], **receipt["binaries"]}.items():
            assert sha(ROOT / name) == digest, name
        stage = WORK / f"package{year}"
        runtime = stage / "AminScatter"
        runtime.mkdir(parents=True, exist_ok=False)
        for name in names + ["CyrusGallery.dll"]:
            shutil.copy2(native / name, runtime / name)
        for name in ["CyrusInstaller.dll", "CyrusInstaller.build.json"]:
            shutil.copy2(WORK / name, runtime / name)
        args = SimpleNamespace(max_year=year, tools_version="14.38.33130",
            windows_sdk="10.0.19041.0", output=OUT,
            team_trust_header=ROOT / "CyrusLicensing/team/team_public_key.h",
            content_dir=ROOT / "dist/CyrusScatter-0.86.7-20261020/Content")
        build_max.package("AminScatter", "Cyrus Scatter", "0.86.8.1", names,
                          "AminScatterObject.ms", args, stage)
        with zipfile.ZipFile(OUT / f"CyrusScatter-0.86.8.1-Max{year}.mzp") as archive:
            assert archive.testzip() is None
            manifest = json.loads(archive.read("manifest.json"))
            assert manifest["version"] == "0.86.8.1" and manifest["max_year"] == year
            assert set(archive.namelist()) == set(manifest["files"]) | {"manifest.json"}
            for name, digest in manifest["files"].items():
                assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
                assert not Path(name).is_absolute() and ".." not in Path(name).parts
            for name in names + ["CyrusGallery.dll"]:
                assert manifest["files"][name] == sha(native / name)
            assert manifest["files"]["CyrusScatter.ms"] == sha(ROOT / "AminScatter/scripts/AminScatterObject.ms")
            assert str((year - 1998) * 1000).encode() in archive.read("install.ms")
            assert not any(name.startswith("Library/") or name.endswith(".max") for name in archive.namelist())
            archive.extractall(WORK / f"payload{year}")
    mzps = [OUT / f"CyrusScatter-0.86.8.1-Max{year}.mzp" for year in (2024, 2026, 2027)]
    exe = OUT / "CyrusScatter-0.86.8.1-Setup.exe"
    build_installer.build_exe(exe, mzps, WORK / "CyrusInstaller.dll")
    content = OUT / "CyrusScatter-Content-0.86.7.zip"
    assert content.samefile(ROOT / "dist/CyrusScatter-0.86.7.2-corrected-20261020" / content.name)
    hashes = {p.name: sha(p) for p in [exe, *mzps, content]}
    (OUT / "SHA256SUMS.txt").write_text("".join(f"{h}  {n}\n" for n, h in hashes.items()))
    (WORK / "compatibility-package-checks.json").write_text(json.dumps({
        "hosts": [2024, 2026, 2027], "artifacts": hashes, "content_hardlink": True,
        "checks": ["matched SDK payloads", "frozen sources", "CRC", "every payload hash",
                   "script/native/Gallery correspondence", "host guards", "no content in MZPs"]
    }, indent=2) + "\n")
    for suffix in (".build.json", ".build.log", ".identity.cs"):
        sidecar = exe.with_suffix(suffix)
        shutil.copy2(sidecar, WORK / ("compatibility-" + sidecar.name))
        sidecar.unlink()
    print(json.dumps(hashes, indent=2))


if __name__ == "__main__":
    main()
