"""Run existing assertions in explicitly authorized installed 2024/2026 fixtures."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/clearance-performance-08681-20261020/final"
sys.path.insert(0, str(ROOT / "tools/procedural_lab/layer_editor_071"))
from private_host import launch
sys.path.insert(0, str(ROOT / "tools/native_placement"))
from run_generation import ready, send


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("year", type=int, choices=(2024, 2026))
    parser.add_argument("action", choices=("launch", "acceptance", "lifecycle", "viewport", "steps", "identity", "close"))
    parser.add_argument("phases", nargs="*")
    args = parser.parse_args()
    folder = ROOT / f"build/mcp-qualification/update08671-test-clearance-compat-{args.year}"
    if args.action == "launch":
        installed = Path((WORK / f"installer-three-hosts/{args.year}/installed-runtime.txt").read_text().strip())
        native = WORK / f"installed-load{args.year}"
        native.mkdir(exist_ok=False)
        for source in [*(installed / "bin").iterdir(), installed / "CyrusGallery.dll", installed / "LibraryBinding.txt"]:
            shutil.copy2(source, native / source.name)
            assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256((native / source.name).read_bytes()).digest()
        process, metadata = launch(folder, installed / "CyrusScatter.ms", native, transport=True,
            max_year=args.year, silent_startup=True, script_assets=("CyrusGallery.dll", "LibraryBinding.txt"))
        shutil.copytree(ROOT / "AminScatter/patterns", folder / "scripts/Patterns")
        print(json.dumps({"pid": process.pid, "folder": str(folder)}), flush=True)
        ready(folder)
        print("Owned installed host ready", flush=True)
        return
    ready(folder)
    files = {
        "acceptance": "tools/source_clearance_0868/host_acceptance.ms",
        "lifecycle": "tools/source_clearance_0868/host_lifecycle.ms",
        "viewport": "tools/source_clearance_08681/compatibility_fixture.ms",
        "steps": "tools/source_clearance_08681/viewport_steps.ms",
        "identity": "tools/source_clearance_08681/identity.ms",
        "close": "build/clearance-performance-08681-20261020/close-owned.ms",
    }
    text = (ROOT / files[args.action]).read_text(encoding="utf-8-sig")
    for pattern in ("*/update08671-test-clearance-*-2027/", "*/update08671-test-clearance-perf-*-2027/"):
        text = text.replace(pattern, f"*/update08671-test-clearance-compat-{args.year}/")
    if args.action == "steps":
        text = text.replace(".opacityLevel", ".opacity").replace(".baseTexmap", ".diffuseMap")
    if args.action == "lifecycle":
        # The original regression fixture was saved in Max 2027. Use the
        # preserved schema-58 scene actually saved by Max 2024 for older hosts.
        original = 'loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/update08671-test-clearance-baseline-2027/schema58.max" quiet:true'
        compatible = 'check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/update08671-test-final4-2024/texture-persistence.max" quiet:true) "Compatible schema 58 fixture loads successfully" log'
        assert original in text
        text = text.replace(original, compatible)
    script = folder / f"qualified-{args.action}.ms"
    script.write_text(text, encoding="utf-8-sig")
    for phase in args.phases or [args.action]:
        send(folder, script, phase)
        time.sleep(.3)
    logs = {"acceptance": "clearance-acceptance.txt", "lifecycle": "clearance-lifecycle.txt",
            "viewport": "compatibility-viewport.txt", "steps": "viewport-steps-r2.txt"}
    if args.action in logs:
        text = (folder / logs[args.action]).read_text()
        assert not any(line.startswith(("FAIL:", "ERROR ")) for line in text.splitlines()), text
        assert "PASS:" in text, text


if __name__ == "__main__":
    main()
