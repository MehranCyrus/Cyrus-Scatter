"""Owned host driver for clearance layout and Relax acceptance."""
from pathlib import Path
import argparse
import json
import hashlib
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/clearance-relax-08682-20261021"
sys.path.insert(0, str(ROOT / "tools/procedural_lab/layer_editor_071"))
from private_host import launch
sys.path.insert(0, str(ROOT / "tools/native_placement"))
from run_generation import ready, send


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("year", type=int, choices=(2024, 2026, 2027))
    parser.add_argument("stage")
    parser.add_argument("action")
    args = parser.parse_args()
    assert args.stage in ("baseline", "dev", "final", "installed")
    folder = ROOT / f"build/mcp-qualification/clearance-relax-08682-{args.stage}-{args.year}"
    if args.action == "launch":
        native = (ROOT / "build/clearance-performance-08681-20261020/final" if args.stage == "dev" else WORK) / f"max{args.year}"
        script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
        if args.stage == "installed":
            installed = Path((WORK / f"installer-three-hosts/{args.year}/installed-runtime.txt").read_text().strip())
            assert installed.is_relative_to(WORK), "Owned installed runtime required"
            native = WORK / f"installed-host-payload{args.year}"
            native.mkdir(exist_ok=False)
            for name in ("AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusScatterEdit.dlm", "CyrusGallery.dll"):
                source = installed / (name if name.endswith('.dll') else 'bin/' + name)
                assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256((WORK / f'max{args.year}' / name).read_bytes()).digest()
                shutil.copy2(source, native / name)
            script = installed / "CyrusScatter.ms"
        process, _ = launch(folder, script,
                            native, transport=True, max_year=args.year,
                            silent_startup=True, script_assets=("CyrusGallery.dll",))
        print(json.dumps({"pid": process.pid, "folder": str(folder)}), flush=True)
    ready(folder)
    if args.action != "launch":
        send(folder, Path(__file__).with_name("identity.ms" if args.action == "identity" else "checks.ms"), args.action)
        log = folder / f"{args.action}.txt"
        if log.exists():
            text = log.read_text(encoding="utf-8-sig")
            print(text)
            assert "ERROR" not in text and "FAIL:" not in text


if __name__ == "__main__":
    main()
