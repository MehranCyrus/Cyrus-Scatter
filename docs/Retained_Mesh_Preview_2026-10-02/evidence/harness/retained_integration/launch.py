"""Open an isolated, visible Max 2027 candidate session for viewport verification."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from build import ROOT, BASE

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run', required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+', args.run):
        raise SystemExit('Use a short lowercase run name')
    output = BASE / args.run
    output.mkdir(parents=True, exist_ok=False)
    for name in ['startup', 'plugcfg', 'temp', 'bin']:
        (output / name).mkdir()
    for name in ['AminScatter.dlx', 'CyrusScatterEdit.dlm']:
        shutil.copy2(BASE / 'max2027' / name, output / 'bin' / name)
    shutil.copy2(ROOT / 'AminScatter/scripts/AminScatterObject.ms', output / 'AminScatterObject.ms')
    config = (ROOT / 'build/viewport-round2-2026-10-01/desktop.ini').read_text(encoding='utf-16')
    for key, target in {'Additional Startup Scripts': output / 'startup', 'PlugCFG': output / 'plugcfg', 'Temp': output / 'temp', 'Page File': output / 'temp'}.items():
        config = re.sub(rf'(?m)^{re.escape(key)}=.*$', lambda _: key + '=' + str(target), config)
    (output / 'desktop.ini').write_text(config, encoding='utf-16')
    paths = [output / 'bin', ROOT / 'build/max2027-release/CyrusSurfaceAnalyzer']
    (output / 'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns/\n' + ''.join(f'CyrusPrivate{i}={p}\n' for i, p in enumerate(paths)) + '[Help]\n')
    start = output / 'start.ms'
    start.write_text(f'global RIRoot="{ROOT.as_posix()}/",RIDir="{output.as_posix()}/"\nfileIn (RIRoot+"tools/performance/retained_integration/transport.ms")\n', encoding='utf-8')
    files = [*list((output / 'bin').glob('*')), output / 'AminScatterObject.ms', ROOT / 'Test Scene/SaveSelect 2.max']
    (output / 'identity.json').write_text(json.dumps({str(p): {'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size} for p in files}, indent=2))
    command = ['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe', '-q', '-i', str(output / 'desktop.ini'), '-p', str(output / 'plugins.ini'), '-U', 'MAXScript', str(start), '-listenerlog', str(output / 'listener.log')]
    process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    result = {'pid': process.pid, 'command': command, 'output': str(output)}
    (output / 'launch.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
