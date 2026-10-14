"""Stage a script-only candidate with unchanged qualified native inputs and ABI."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import shutil

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--native', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
native, out = args.native.resolve(), args.output.resolve()
assert out.is_relative_to(ROOT / 'build') and not out.exists()
spec = importlib.util.spec_from_file_location('offline_build', ROOT / 'tools/procedural_lab/offline_build.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)
source = json.loads((native / 'receipt.json').read_text())
assert source['project'] == 'scatter' and all(x['exit_code'] == 0 for x in source['stages'])
current = build.source_hashes('AminScatter')
assert current.keys() == source['sources'].keys()
for name, expected in source['sources'].items():
    if name != 'AminScatter/scripts/AminScatterObject.ms':
        assert current[name] == expected, 'Changed native input: ' + name
out.mkdir(parents=True)
binaries = {}
for name, expected in source['binaries'].items():
    path = native / Path(name).name
    assert hashlib.sha256(path.read_bytes()).hexdigest() == expected
    destination = out / path.name
    shutil.copy2(path, destination)
    binaries[destination.relative_to(ROOT).as_posix()] = expected
source.update(sources=current, binaries=binaries, native_receipt=str(native / 'receipt.json'),
              native_abi_unchanged=True, host_launched=False, installed=False,
              qualification='Native stages are reused from native_receipt after verifying every native input. New script is hashed; Max qualification is separate.')
(out / 'receipt.json').write_text(json.dumps(source, indent=2) + '\n')
print(out / 'receipt.json')
