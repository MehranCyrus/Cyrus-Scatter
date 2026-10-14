"""Launch a source-matched roadmap candidate in an owned disposable Max host."""
from pathlib import Path
import argparse
import hashlib
import json
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('name')
parser.add_argument('--native', type=Path, required=True)
parser.add_argument('--year', type=int, choices=[2026, 2027], required=True)
parser.add_argument('--visible', action='store_true')
args = parser.parse_args()
assert args.name.startswith('foundation-roadmap-') and Path(args.name).name == args.name
native = args.native.resolve()
receipt = json.loads((native / 'receipt.json').read_text())
assert receipt['max_year'] == args.year

def digest(path):
    value = hashlib.sha256()
    with Path(path).open('rb') as source:
        for block in iter(lambda: source.read(8 * 1024 * 1024), b''):
            value.update(block)
    return value.hexdigest()

for name, expected in receipt['sources'].items():
    assert digest(ROOT / name) == expected, name
for name, expected in receipt['binaries'].items():
    assert digest(native / Path(name).name) == expected, name
sys.path.insert(0, str(ROOT / 'tools/procedural_lab/layer_editor_071'))
from private_host import launch
folder = ROOT / 'build/mcp-qualification' / args.name
process, metadata = launch(folder, ROOT / 'AminScatter/scripts/AminScatterObject.ms', native,
                           transport=True, max_year=args.year, silent_startup=True,
                           visible=args.visible)
print(json.dumps(metadata), flush=True)
deadline = time.monotonic() + 180
while time.monotonic() < deadline:
    if (folder / 'startup-error.txt').exists():
        raise RuntimeError((folder / 'startup-error.txt').read_text(encoding='utf-8-sig'))
    if (folder / 'ready.json').exists():
        print('Owned roadmap host ready', flush=True)
        break
    if process.poll() is not None:
        raise RuntimeError('Host exited before readiness')
    time.sleep(.5)
else:
    raise TimeoutError('Inspect this owned host before retrying')
