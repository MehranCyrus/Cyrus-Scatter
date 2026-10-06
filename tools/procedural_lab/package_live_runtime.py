"""Package the exact Max 2027 pair qualified by the 6 October runtime campaign."""
from pathlib import Path
from types import SimpleNamespace
import hashlib
import json
import shutil
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from build_max import package, scatter_version


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    qualified = ROOT / "build/mcp-qualification/procedural07-ui-071-live-runtime-final03"
    frozen = ROOT / "build/live-runtime-20261006/final03"
    staging = ROOT / "build/live-runtime-20261006/package01/payload"
    output = ROOT / "dist/live-runtime-0.7.1-20261006"
    identity = json.loads((qualified / "launch.json").read_text())
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    assert scatter_version() == "0.7.1"
    assert digest(script) == identity["script_sha256"] == digest(frozen / "CyrusScatter.ms")
    analyzer = ROOT / "CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms"
    assert digest(analyzer) == digest(frozen / "CyrusSurfaceAnalyzer.ms")
    assert json.loads((qualified / "idle-qualification.json").read_text())["passed"]
    assert json.loads((qualified / "courtyard-runtime.json").read_text())["scheduling_passed"]
    native_sources = json.loads((ROOT / "build/offline-implementation-20261005/max2027/receipt.json").read_text())
    for name, expected in native_sources["sources"].items():
        if name.endswith((".cpp", ".h", ".inc")) or name == "AminScatter/CMakeLists.txt":
            assert digest(ROOT / name) == expected, name
    for name, expected in identity["binaries"].items():
        source = qualified / "bin" / name
        assert digest(source) == expected, name
        project = "CyrusSurfaceAnalyzer" if name == "CyrusSurfaceAnalyzer.dlx" else "AminScatter"
        target = staging / project / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    args = SimpleNamespace(max_year=2027, tools_version="14.38.33130", windows_sdk="10.0.19041.0", output=output)
    names = ["AminScatter.dlx", "CyrusScatterEdit.dlm", "CyrusBrush.dlx", "CyrusBrushStorage.dlh"]
    package("AminScatter", "Cyrus Scatter", "0.7.1", names, "AminScatterObject.ms", args, staging)
    package("CyrusSurfaceAnalyzer", "Cyrus Surface Analyzer", "0.14", ["CyrusSurfaceAnalyzer.dlx"], "CyrusSurfaceAnalyzer.ms", args, staging)
    packages = {}
    for path in sorted(output.glob("*.mzp")):
        with zipfile.ZipFile(path) as archive:
            manifest = json.loads(archive.read("manifest.json"))
            for name, expected in identity["binaries"].items():
                if name in manifest["files"]:
                    assert manifest["files"][name] == expected, name
            if "CyrusScatter.ms" in manifest["files"]:
                assert manifest["files"]["CyrusScatter.ms"] == identity["script_sha256"]
            assert not any(b"__VERSION__" in archive.read(name) or b"__NATIVE_ID__" in archive.read(name)
                           for name in archive.namelist() if name.endswith((".ms", ".mcr")))
            packages[path.name] = {"sha256": digest(path), "bytes": path.stat().st_size, "manifest": manifest}
    receipt = {"max_year": 2027, "qualification": "Live_Runtime_2026-10-06/final03",
               "script_sha256": identity["script_sha256"], "native_binaries_rebuilt": False,
               "normal_profile_installed": False, "packages": packages,
               "scope": "Scatter 0.7.1 and matching Analyzer dependency; Automation/MCP is separate."}
    (output / "BUILD.json").write_text(json.dumps(receipt, indent=2) + "\n")
    (output / "START_HERE.txt").write_text(
        "Cyrus Scatter 0.7.1 - Max 2027 development build - 6 October 2026\n\n"
        "1. Save your current work and use an empty Max 2027 scene for installation.\n"
        "2. Scripting > Run Script: select CyrusScatter-0.7.1-Max2027.mzp.\n"
        "3. For the supplied courtyard/Analyzer features, also run CyrusSurfaceAnalyzer-0.14-Max2027.mzp.\n"
        "4. Close and restart Max, then reopen a copy of the courtyard scene.\n"
        "5. Select Cyrus Scatter. Modify > Layer Manager > select a layer > Edit layer...\n\n"
        "The floating editor contains Assets, Population, Paint, Transform, Spacing and Statistics.\n"
        "Spacing fields save automatically. In Manual mode, use Update setup to publish changes.\n"
        "The installer copies a matching script/native pair and registers it for the next startup.\n"
        "It does not reload the new script into the current session's older native DLLs.\n"
        "The latest files remain labeled 0.7.1; BUILD.json records their exact identities.\n\n"
        "This package contains the final03 Live/Manual scheduling, IR recovery and native diagnostics fixes.\n"
        "MCP/Automation is separately installed and is not upgraded by these MZPs.\n"
        "Max 2026, successful docked IR and tiny-coordinate Brush serialization remain separate qualification work.\n"
        "See docs/Live_Runtime_2026-10-06/RESULTS.md in the repository for the complete evidence and limits.\n",
        encoding="utf-8")
    print(json.dumps({"output": str(output), "packages": {n: p["sha256"] for n, p in packages.items()}}, indent=2))


if __name__ == "__main__":
    main()
