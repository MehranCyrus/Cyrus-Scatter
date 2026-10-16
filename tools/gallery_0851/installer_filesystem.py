"""Exercise installer transactions in owned folders with non-executable payloads."""
from pathlib import Path
import argparse, hashlib, json, subprocess, uuid

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--core', required=True, type=Path)
a = p.parse_args()
core = a.core.resolve()
assert core.is_relative_to(ROOT / 'build') and core.name == 'CyrusInstaller.dll'
out = ROOT / 'build/gallery-0851-20261016-01' / ('installer-files-' + uuid.uuid4().hex)
source = out / 'owned package'
source.mkdir(parents=True)
names = ['AminScatter.dlx', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh', 'CyrusScatterEdit.dlm', 'CyrusScatter.ms',
         'CyrusGallery.dll', 'CyrusInstaller.dll', 'Clipper2-LICENSE.txt', 'nlohmann-json-LICENSE.txt', 'INSTALL.txt',
         'LibraryFiles.ms', 'CyrusScatterStartup.ms', 'CyrusScatter.mcr', 'Uninstall.ms', 'Library/example.csrecipe.json', 'Library/thumbnail.png']
rows = []
for name in names:
    path = source / name
    path.parent.mkdir(parents=True, exist_ok=True)
    value = ('Owned inert fixture: CyrusScatter CyrusScatterCreate ' + name).encode('utf-8')
    path.write_bytes(value)
    rows.append('\t'.join((name, hashlib.sha256(value).hexdigest(), str(len(value)))))
inventory = ('CyrusScatterInstall1\t0.85.1\t2027\t123456abcdef\n' + '\n'.join(rows) + '\n').encode()
(source / 'InstallInventory.txt').write_bytes(inventory)
digest = hashlib.sha256(inventory).hexdigest()
command = ['pwsh', '-NoProfile', '-NonInteractive', '-File', str(ROOT / 'tools/gallery_0851/installer_filesystem.ps1'),
           '-CorePath', str(core), '-PackageDir', str(source), '-InventoryHash', digest, '-OutputDir', str(out)]
result = subprocess.run(command, text=True, capture_output=True, encoding='utf-8')
(out / 'transport.txt').write_text(result.stdout + result.stderr, encoding='utf-8')
(out / 'identity.json').write_text(json.dumps({'core_sha256': hashlib.sha256(core.read_bytes()).hexdigest(),
    'fixture_sha256': hashlib.sha256(Path(command[4]).read_bytes()).hexdigest(), 'exit_code': result.returncode,
    'scope': 'Owned inert payload filesystem tests; no Max installation or loaded-pair qualification.'}, indent=2), encoding='utf-8')
print(out)
print(result.stdout + result.stderr)
if result.returncode: raise SystemExit(result.returncode)
