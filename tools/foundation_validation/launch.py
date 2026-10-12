"""Launch a fresh, isolated Max host for foundation regressions; never install."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/procedural_lab/layer_editor_071'))
from private_host import launch


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native-build', type=Path, required=True)
    parser.add_argument('--name', required=True)
    parser.add_argument('--script', type=Path, default=ROOT / 'AminScatter/scripts/AminScatterObject.ms')
    args = parser.parse_args()
    if Path(args.name).name != args.name or not args.name.startswith('foundation-'):
        raise ValueError('Use an owned foundation- profile name')
    receipt = json.loads((args.native_build / 'receipt.json').read_text())
    year = receipt['max_year']
    if year not in (2026, 2027) or any(row['exit_code'] for row in receipt['stages']):
        raise ValueError('A successfully built supported SDK is required')
    # The separately hashed script is interpreted at startup, not compiled into DLLs.
    for rel, expected in receipt['sources'].items():
        if rel.endswith('.ms'):
            continue
        if hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() != expected:
            raise ValueError('Compiled source changed: ' + rel)
    binaries = [ROOT / rel for rel in receipt['binaries']]
    for path in binaries:
        if hashlib.sha256(path.read_bytes()).hexdigest() != receipt['binaries'][path.relative_to(ROOT).as_posix()]:
            raise ValueError('Compiled binary changed: ' + str(path))
    directories = {path.parent for path in binaries if path.name == 'AminScatter.dlx'}
    if len(directories) != 1:
        raise ValueError('Expected one native binary directory')
    folder = ROOT / 'build/mcp-qualification' / args.name
    process, metadata = launch(folder, args.script, directories.pop(), transport=True,
                               max_year=year, silent_startup=True)
    print(json.dumps(metadata), flush=True)
    deadline = time.monotonic() + 240
    while time.monotonic() < deadline:
        if (folder / 'startup-error.txt').exists():
            raise RuntimeError((folder / 'startup-error.txt').read_text(encoding='utf-8-sig'))
        if (folder / 'ready.json').exists():
            print('Owned foundation host ready', flush=True)
            return
        if process.poll() is not None:
            raise RuntimeError('Owned host exited before readiness')
        time.sleep(.5)
    raise TimeoutError('Inspect this owned process before sending requests or retrying')


if __name__ == '__main__':
    main()
