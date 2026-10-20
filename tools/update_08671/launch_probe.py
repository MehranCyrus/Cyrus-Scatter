"""Launch a named, owned panel probe with an explicit matched runtime."""
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/procedural_lab/layer_editor_071"))
from private_host import launch
runtime, label = Path(sys.argv[1]).resolve(), sys.argv[2]
assert label.startswith("update08671-") and "/" not in label and "\\" not in label
folder = ROOT / "build/update-08671-20261020" / label
process, metadata = launch(folder, runtime / "CyrusScatter.ms", runtime,
    extra='python.ExecuteFile @"' + (ROOT / "tools/update_08671/probe.py").as_posix() + '"',
    max_year=2027, silent_startup=True, script_assets=("CyrusGallery.dll",))
print(json.dumps({"pid": process.pid, "profile": str(folder)}))
