"""Owned, visible 0.73 qualification host. Never attaches to an artist process."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/procedural_lab/layer_editor_071'))
from private_host import launch


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def verify(directory, project):
    receipt = json.loads((directory / 'receipt.json').read_text())
    if receipt.get('status') == 'pending' or receipt['project'] != project or receipt['max_year'] != 2027 or any(s['exit_code'] for s in receipt['stages']):
        raise RuntimeError('Passing Max 2027 build receipt required')
    for name, expected in {**receipt['sources'], **receipt['binaries']}.items():
        if sha(ROOT / name) != expected:
            raise RuntimeError('Source/binary changed since build: ' + name)
    return receipt


def profile_snapshot():
    base = Path(os.environ['LOCALAPPDATA']) / 'Autodesk/3dsMax/2027 - 64bit/ENU'
    paths = [base / 'scripts/CyrusScatter', base / 'scripts/CyrusSurfaceAnalyzer',
             base / 'scripts/Startup/CyrusScatterStartup.ms', base / 'scripts/Startup/CyrusSurfaceAnalyzerStartup.ms']
    paths += [base / 'plugins' / n for n in ('AminScatter.dlx', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh', 'CyrusScatterEdit.dlm', 'CyrusSurfaceAnalyzer.dlx')]
    paths += [base / 'usermacros' / n for n in ('CyrusScatter-CyrusScatter.mcr', 'CyrusSurfaceAnalyzer-CyrusSurfaceAnalyzer.mcr')]
    result = {}
    for path in paths:
        if path.is_dir():
            for file in sorted(path.rglob('*')):
                if file.is_file(): result[str(file)] = sha(file)
        else:
            result[str(path)] = sha(path) if path.is_file() else None
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('start', 'stop'))
    parser.add_argument('--name', required=True)
    parser.add_argument('--scene', type=Path)
    parser.add_argument('--native', type=Path, default=ROOT / 'build/approved-layout-073-20261006/native-max2027')
    parser.add_argument('--analyzer', type=Path, default=ROOT / 'build/unified-073-20261006/analyzer-max2027')
    args = parser.parse_args()
    if not args.name or Path(args.name).name != args.name or not all(c.isalnum() or c in '-_' for c in args.name):
        raise ValueError('A simple private campaign name is required')
    folder = ROOT / 'build/mcp-qualification' / args.name
    if args.action == 'stop':
        record = json.loads((folder / 'protection.json').read_text())
        metadata = json.loads((folder / 'launch.json').read_text())
        # The PID alone is insufficient: validate the owned profile in its command line.
        code = '$p=Get-CimInstance Win32_Process -Filter "ProcessId=' + str(metadata['pid']) + '";if($p){$p.CommandLine}'
        command = subprocess.check_output(['powershell', '-NoProfile', '-Command', code], text=True).strip()
        if command:
            if str(folder / 'max.ini').lower() not in command.lower():
                raise RuntimeError('PID no longer belongs to this private host')
            subprocess.run(['taskkill', '/PID', str(metadata['pid']), '/F'], check=True, capture_output=True)
        record['owned_process_stopped'] = True
        record['normal_profile_after'] = profile_snapshot()
        record['installed_product_files_unchanged'] = record['normal_profile_before'] == record['normal_profile_after']
        record['original_scene_unchanged'] = sha(record['original_scene']['path']) == record['original_scene']['sha256']
        (folder / 'protection.json').write_text(json.dumps(record, indent=2) + '\n')
        print(json.dumps({k: record[k] for k in ('owned_process_stopped', 'installed_product_files_unchanged', 'original_scene_unchanged')}))
        return
    verify(args.native, 'scatter'); verify(args.analyzer, 'analyzer')
    if not args.scene or not args.scene.is_file():
        raise ValueError('An existing source scene is required')
    source = args.scene.resolve()
    protection = {'original_scene': {'path': str(source), 'sha256': sha(source), 'bytes': source.stat().st_size},
                  'normal_profile_before': profile_snapshot(), 'owned_process_stopped': False}
    payload = ROOT / 'build/full-qualification-073-20261007/payload' / args.name
    payload.mkdir(parents=True, exist_ok=False)
    for name in ('AminScatter.dlx', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh', 'CyrusScatterEdit.dlm'):
        shutil.copy2(args.native / name, payload / name)
    shutil.copy2(args.analyzer / 'CyrusSurfaceAnalyzer.dlx', payload / 'CyrusSurfaceAnalyzer.dlx')
    extra = 'fileIn @"' + (ROOT / 'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms').as_posix() + '"\n'
    extra += 'fileIn @"' + (ROOT / 'tools/performance/CyrusPerformanceMonitor.ms').as_posix() + '"\n'
    # Copy/load happens only after the matching script and modules have been verified.
    copy = folder / ('project/INPUT_PRIVATE_' + source.name)
    extra += 'copyFile @"' + source.as_posix() + '" @"' + copy.as_posix() + '"\n'
    extra += 'loadMaxFile @"' + copy.as_posix() + '" quiet:true useFileUnits:true\n'
    extra += 'CyrusPerfHeadless=false\n'
    process, metadata = launch(folder, ROOT / 'AminScatter/scripts/AminScatterObject.ms', payload,
                               extra=extra, transport=True, visible=True, extra_modules=('CyrusSurfaceAnalyzer.dlx',))
    (folder / 'protection.json').write_text(json.dumps(protection, indent=2) + '\n')
    deadline = time.monotonic() + 360
    while not (folder / 'ready.json').exists():
        if (folder / 'startup-error.txt').exists(): raise RuntimeError((folder / 'startup-error.txt').read_text())
        if process.poll() is not None: raise RuntimeError('Private host exited during startup')
        if time.monotonic() > deadline: raise TimeoutError('Private host startup timed out; inspect owned host before stopping it')
        time.sleep(.5)
    protection['input_copy_sha256'] = sha(copy)
    (folder / 'protection.json').write_text(json.dumps(protection, indent=2) + '\n')
    print(json.dumps({'ready': True, 'pid': metadata['pid'], 'folder': str(folder), 'script_sha256': metadata['script_sha256']}, indent=2))


if __name__ == '__main__':
    main()
