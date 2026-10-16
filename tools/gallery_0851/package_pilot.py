"""Build an owned installer pilot, never a delivery/host qualification claim."""
from pathlib import Path
from types import SimpleNamespace
import argparse, hashlib, json, shutil, sys, uuid, zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import build_max

p = argparse.ArgumentParser()
p.add_argument('--native', required=True, type=Path)
p.add_argument('--core', required=True, type=Path)
p.add_argument('--host', required=True, type=Path)
p.add_argument('--candidate', action='store_true', help='Keep the exact source library inventory for final recipient qualification; still not a delivery claim.')
a = p.parse_args()
native, core = a.native.resolve(), a.core.resolve()
assert native.is_relative_to(ROOT / 'build') and core.is_relative_to(ROOT / 'build')
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
receipt = json.loads((native / 'receipt.json').read_text(encoding='utf-8'))
assert receipt['max_year'] == 2027 and all(stage['exit_code'] == 0 for stage in receipt['stages'])
for name, digest in receipt['sources'].items():
    if name != 'AminScatter/scripts/AminScatterObject.ms': assert sha(ROOT / name) == digest, name
host = a.host.resolve()
assert host.parent == ROOT / 'build/mcp-qualification' and host.name.startswith('foundation-roadmap-gallery0851-')
loaded = json.loads((host / 'launch.json').read_text(encoding='utf-8'))
assert (host / 'ready.json').exists()
runtime = json.loads((host / 'runtime.json').read_text(encoding='utf-8')) if (host / 'runtime.json').exists() else loaded
loaded_script = Path(runtime.get('script', host / 'scripts/CyrusScatter.ms'))
assert loaded_script.resolve().is_relative_to(host) and sha(loaded_script) == runtime['script_sha256'] == sha(ROOT / 'AminScatter/scripts/AminScatterObject.ms')
for name in ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh']:
    assert sha(native / name) == sha(host / 'bin' / name) == loaded['binaries'][name]
out = ROOT / 'build/gallery-0851-20261016-01' / ('package-pilot-' + uuid.uuid4().hex)
stage = out / 'staging/AminScatter'
stage.mkdir(parents=True)
names = ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh']
for name in names + ['CyrusGallery.dll']:
    shutil.copy2(native / name, stage / name)
shutil.copy2(core, stage / core.name)
shutil.copy2(core.with_suffix('.build.json'), stage / core.with_suffix('.build.json').name)
library = out / 'library'
original = ROOT / 'AminScatter/library'
inventory = json.loads((original / 'inventory.json').read_text(encoding='utf-8'))
for name, digest in inventory['files'].items():
    assert sha(original / name) == digest
    (library / name).parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(original / name, library / name)
if not a.candidate:
    inventory['previous_qualification_version'] = inventory['version']
    inventory['version'] = build_max.scatter_version()
    inventory['pilot_scope'] = 'Installer exercise only; original example hashes retained. Final content qualification pending.'
else:
    assert inventory['version'] == build_max.scatter_version()
if a.candidate:
    shutil.copy2(original / 'inventory.json', library / 'inventory.json')
else:
    (library / 'inventory.json').write_text(json.dumps(inventory, indent=2), encoding='utf-8')
args = SimpleNamespace(max_year=2027, tools_version='14.38.33130', windows_sdk='10.0.19041.0', output=out,
                       team_trust_header=ROOT / 'CyrusLicensing/team/team_public_key.h', library_dir=library)
build_max.package('AminScatter', 'Cyrus Scatter', build_max.scatter_version(), names, 'AminScatterObject.ms', args, out / 'staging')
package = out / 'CyrusScatter-0.85.1-Max2027.mzp'
with zipfile.ZipFile(package) as archive:
    assert archive.testzip() is None
    manifest = json.loads(archive.read('manifest.json'))
    assert set(archive.namelist()) == set(manifest['files']) | {'manifest.json'}
    for name, digest in manifest['files'].items(): assert hashlib.sha256(archive.read(name)).hexdigest() == digest
    assert b'__INSTALL_HASH__' not in archive.read('install.ms')
    # These builder-owned names are already validated by the package builder.
    archive.extractall(out / 'payload')
result = {'state': 'candidate; not delivered or host-qualified' if a.candidate else 'pilot; not delivered or host-qualified', 'package': str(package), 'sha256': sha(package),
          'native_receipt_sha256': sha(native / 'receipt.json'), 'installer_core_sha256': sha(core),
          'script_sha256': sha(ROOT / 'AminScatter/scripts/AminScatterObject.ms'),
          'inventory_sha256': sha(out / 'payload/InstallInventory.txt'), 'installed': False}
(out / 'pilot.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(out)
