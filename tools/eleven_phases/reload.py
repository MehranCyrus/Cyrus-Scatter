"""Reload a script-only successor in a verified disposable host; retain all receipts."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import shutil
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
p.add_argument('--native', required=True, type=Path)
a = p.parse_args()
folder, native = a.folder.resolve(), a.native.resolve()
assert folder.parent == ROOT / 'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-')
metadata = json.loads((folder / 'launch.json').read_text())
assert Path(metadata['output']).resolve() == folder and metadata['development_transport']
pid = int(metadata['pid'])
command = subprocess.check_output(['powershell', '-NoProfile', '-Command',
    f'(Get-CimInstance Win32_Process -Filter "ProcessId = {pid}").CommandLine'], text=True).strip()
assert str(folder / 'start.ms') in command and str(folder / 'max.ini') in command
spec = importlib.util.spec_from_file_location('offline_build', ROOT / 'tools/procedural_lab/offline_build.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)
receipt = json.loads((native / 'receipt.json').read_text())
assert receipt['max_year'] == metadata['max_year'] and all(x['exit_code'] == 0 for x in receipt['stages'])
current = build.source_hashes('AminScatter')
script_name = 'AminScatter/scripts/AminScatterObject.ms'
assert current.keys() == receipt['sources'].keys()
for name, expected in receipt['sources'].items():
    if name != script_name:
        assert current[name] == expected, 'Native input changed: ' + name
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
for name, expected in metadata['binaries'].items():
    assert digest(folder / 'bin' / name) == digest(native / name) == expected
loaded = (folder / 'loaded.tsv').read_text(encoding='utf-8-sig')
for name in metadata['binaries']:
    assert str(folder / 'bin' / name).lower() in loaded.lower()
pending = folder / 'dev-request.txt'
if pending.exists():
    previous = pending.read_text(encoding='utf-8-sig')
    done = (folder / 'dev-result.txt').read_text(encoding='utf-8-sig')
    assert done == 'SUCCESS ' + previous or (done.startswith('ERROR ') and previous in done)
token = uuid.uuid4().hex
snapshot = folder / 'scripts' / ('successor-' + token + '.ms')
shutil.copy2(ROOT / script_name, snapshot)
manifest = dict(native_receipt=str(native / 'receipt.json'), native_abi_unchanged=True,
                sources=current, script=str(snapshot), script_sha256=digest(snapshot), binaries=metadata['binaries'])
receipt_path = folder / ('script-successor-' + token + '.json')
receipt_path.write_text(json.dumps(manifest, indent=2) + '\n')
request = folder / ('reload-' + token + '.ms')
request.write_text('''if CyrusPresetBrowser!=undefined do try(destroyDialog CyrusPresetBrowser)catch()
if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
resetMaxFile #noPrompt
fileIn @"''' + snapshot.as_posix() + '''"
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.json") "{}"
''', encoding='utf-8-sig')
if (folder / 'ready.json').exists():
    (folder / 'ready.json').unlink()
pending.write_text(request.as_posix(), encoding='utf-8-sig')
print('Submitted verified script successor ' + str(receipt_path), flush=True)
deadline = time.monotonic() + 60
while time.monotonic() < deadline:
    result = folder / 'dev-result.txt'
    value = result.read_text(encoding='utf-8-sig') if result.exists() else ''
    if value == 'SUCCESS ' + request.as_posix():
        manifest['status'] = 'loaded'
        receipt_path.write_text(json.dumps(manifest, indent=2) + '\n')
        (folder / 'runtime.json').write_text(json.dumps(manifest, indent=2) + '\n')
        print(value, flush=True)
        break
    if value.startswith('ERROR ') and request.as_posix() in value:
        raise RuntimeError(value)
    time.sleep(.25)
else:
    raise TimeoutError('Inspect this outstanding request before retrying; it was not cancelled')
