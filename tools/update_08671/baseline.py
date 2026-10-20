"""Freeze the delivered baseline and launch only an isolated Max 2027 probe."""
from pathlib import Path
import hashlib, json, shutil, sys, zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/update-08671-20261020"
WORK.mkdir(exist_ok=True)
runtime = WORK / "baseline-runtime"
runtime.mkdir(exist_ok=False)
package = ROOT / "dist/CyrusScatter-0.86.7-20261020/CyrusScatter-0.86.7-Max2027.mzp"
with zipfile.ZipFile(package) as archive:
    manifest = json.loads(archive.read("manifest.json"))
    for name in ["AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh",
                 "CyrusScatterEdit.dlm", "CyrusScatter.ms", "CyrusGallery.dll"]:
        data = archive.read(name)
        assert hashlib.sha256(data).hexdigest() == manifest["files"][name]
        (runtime / name).write_bytes(data)
paths = ["AminScatter/setup", "AminScatter/tools/ui", "AminScatter/ui",
         "AminScatter/tools/build_gallery.py", "AminScatter/tools/build_installer.py",
         "AminScatter/installer", "tools/build_max.py"]
for relative in paths:
    source, destination = ROOT / relative, WORK / "source-before" / relative
    if source.is_dir():
        shutil.copytree(source, destination)
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
sys.path.insert(0, str(ROOT / "tools/procedural_lab/layer_editor_071"))
from private_host import launch
folder = WORK / "update08671-baseline"
process, metadata = launch(folder, runtime / "CyrusScatter.ms", runtime,
    extra='python.ExecuteFile @"' + (ROOT / "tools/update_08671/probe.py").as_posix() + '"',
    max_year=2027, silent_startup=True, script_assets=("CyrusGallery.dll",))
print(json.dumps({"pid": process.pid, "profile": str(folder)}))
