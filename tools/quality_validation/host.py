"""Owned Max 2027 runner. Timeouts are observed, never replayed."""
from pathlib import Path
import argparse
import json
import os
import sys
import subprocess
import hashlib
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/procedural_lab/layer_editor_071'))
from private_host import launch
sys.path.insert(0, str(Path(__file__).parent))
from results import Expected, artifact_identity, read_result


def wait_ready(folder, timeout=120):
    deadline = time.monotonic() + timeout
    while not (folder / 'ready.json').exists():
        failure = folder / 'startup-error.txt'
        if failure.exists():
            raise RuntimeError(failure.read_text(encoding='utf-8-sig'))
        if time.monotonic() >= deadline:
            raise TimeoutError('Owned startup remains unresolved; observe its PID before another launch')
        time.sleep(.15)


def bind_suite(folder: Path):
    """Freeze a successor test revision without changing the loaded product pair."""
    path=folder/'qualification.json'
    metadata=json.loads(path.read_text(encoding='utf-8'))
    pointer,response=folder/'dev-request.txt',folder/'dev-result.txt'
    if pointer.exists():
        state=response.read_text(encoding='utf-8-sig') if response.exists() else ''
        if pointer.read_text(encoding='utf-8-sig') not in state or not state.startswith(('SUCCESS','ERROR')):
            raise RuntimeError('Prior mutation is unresolved; observe it before rebinding the suite')
    paths={name:Path(source) for name,source in metadata['paths'].items() if not name.startswith('fixture:') and name!='scenario_manifest' and not name.startswith('driver:')}
    # Bind to the bytes actually staged/loaded by this process. Repository edits
    # do not alter an already loaded candidate; final delivery separately seals
    # that candidate against its producing build's current-source receipt.
    for name in list(paths):
        staged=folder/('scripts/CyrusScatter.ms' if name=='Scatter' else 'scripts/CyrusSurfaceAnalyzer.ms' if name=='AnalyzerScript' else 'scripts/'+name if name=='CyrusGallery.dll' else 'bin/'+name)
        if staged.is_file() and hashlib.sha256(staged.read_bytes()).hexdigest()==metadata['hashes'][name]:paths[name]=staged
    for name,source in paths.items():
        if hashlib.sha256(source.read_bytes()).hexdigest()!=metadata['hashes'][name]:
            raise RuntimeError('Loaded product source changed: '+name)
    for fixture in sorted(Path(__file__).parent.iterdir()):
        if fixture.suffix not in ('.ms','.py','.cs','.ps1','.cpp') or fixture.name in ('host.py','results.py'):continue
        paths['fixture:'+fixture.name]=fixture.resolve()
    for helper in ('RolloutOrderFixture.dll','OwnedRolloutSdk.dll'):
        if (folder.parent/helper).is_file():paths['fixture:'+helper]=(folder.parent/helper).resolve()
    paths['scenario_manifest']=Path(__file__).with_name('scenarios.json').resolve()
    for name in ('host.py','results.py'):
        paths['driver:'+name]=Path(__file__).with_name(name).resolve()
    identity,hashes=artifact_identity(paths)
    archive=folder/('qualification-'+metadata['run_id']+'.json')
    archive.write_bytes(path.read_bytes())
    metadata.update(parent_run_id=metadata['run_id'],run_id=uuid.uuid4().hex,artifact_id=identity,hashes=hashes,paths={n:str(p) for n,p in paths.items()})
    path.write_text(json.dumps(metadata,indent=2),encoding='utf-8')
    return metadata


def run(folder: Path, scenario: dict, timeout=120):
    """Publish once; preserve all late-result evidence on an uncertain timeout."""
    metadata = json.loads((folder / 'qualification.json').read_text(encoding='utf-8'))
    pid = int(metadata['pid'])
    command = subprocess.check_output(['powershell', '-NoProfile', '-Command',
        f'(Get-CimInstance Win32_Process -Filter "ProcessId={pid}").CommandLine'], text=True).strip()
    profile=Path(metadata.get('profile_ini',folder/'max.ini')).resolve()
    if (not profile.is_relative_to(ROOT/'build') or str(profile).lower() not in command.lower() or '3dsmax.exe' not in command.lower()
            or ('command' in metadata and subprocess.list2cmdline(metadata['command']).lower()!=command.lower())):
        raise RuntimeError('Owned Max profile/process identity no longer matches')
    for name, source in metadata.get('paths', {}).items():
        if hashlib.sha256(Path(source).read_bytes()).hexdigest() != metadata['hashes'][name]:
            raise RuntimeError('Qualification source changed after launch: ' + name)
    pointer, response = folder / 'dev-request.txt', folder / 'dev-result.txt'
    if pointer.exists():
        previous = pointer.read_text(encoding='utf-8-sig')
        state = response.read_text(encoding='utf-8-sig') if response.exists() else ''
        if previous not in state or not state.startswith(('SUCCESS', 'ERROR')):
            raise RuntimeError('Prior mutation is unresolved; observe it before publishing another request')
    request_id = uuid.uuid4().hex
    expected = Expected(metadata['run_id'], request_id, scenario['id'], metadata['artifact_id'], tuple(scenario['assertions']))
    fixture = ROOT / scenario['fixture']
    if not fixture.resolve().is_relative_to(ROOT / 'tools/quality_validation'):
        raise ValueError('Fixture must belong to the maintained private suite')
    # Only controlled identifiers and verified local paths enter this script.
    for value in (expected.run_id, request_id, scenario['id'], expected.artifact_id):
        if not value or any(c not in '0123456789abcdefABCDEFGHIJKLMNOPQRSTUVWXYZ-_' for c in value):
            raise ValueError('Unsafe scenario identity')
    request = folder / ('scenario-' + request_id + '.ms')
    result = folder / ('result-' + request_id + '.json')
    prefix = 'global QRunID="%s",QRequestID="%s",QScenarioID="%s",QArtifactID="%s"\n' % (expected.run_id, request_id, scenario['id'], expected.artifact_id)
    request.write_text(prefix + 'fileIn @"' + (Path(__file__).parent / 'protocol.ms').as_posix() + '"\n' +
                       'QExecute @"' + fixture.as_posix() + '" @"' + result.as_posix() + '"\n', encoding='utf-8-sig')
    (folder / ('request-' + request_id + '.json')).write_text(json.dumps(expected.__dict__, indent=2), encoding='utf-8')
    temporary = folder / ('pointer-' + request_id + '.tmp')
    temporary.write_text(request.as_posix(), encoding='utf-8-sig')
    publish_deadline = time.monotonic() + 5
    while True:
        try:
            os.replace(temporary, pointer)
            break
        except PermissionError:
            if not temporary.exists() or time.monotonic() > publish_deadline:
                raise
            time.sleep(.05)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            state = response.read_text(encoding='utf-8-sig') if response.exists() else ''
        except PermissionError:
            time.sleep(.1)
            continue
        if request.as_posix() in state:
            if not state.startswith('SUCCESS'):
                raise RuntimeError(state)
            outcome = read_result(result, expected)
            for name, source in metadata.get('paths', {}).items():
                if hashlib.sha256(Path(source).read_bytes()).hexdigest() != metadata['hashes'][name]:
                    raise RuntimeError('Qualification source changed during scenario: ' + name)
            return outcome
        time.sleep(.15)
    raise TimeoutError('Observe original request without replay: ' + str(request))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('launch', 'run', 'observe', 'bind-suite'))
    parser.add_argument('--folder', type=Path, required=True)
    parser.add_argument('--native', type=Path)
    parser.add_argument('--scenario')
    parser.add_argument('--timeout',type=int,default=120)
    parser.add_argument('--visible', action='store_true', help='Show only this owned qualification window')
    parser.add_argument('--interactive-startup', action='store_true', help='Keep Max startup dialogs visible in the owned profile')
    args = parser.parse_args()
    folder = args.folder.resolve()
    if not folder.is_relative_to(ROOT / 'build'):
        raise ValueError('An owned build directory is required')
    if args.action == 'launch':
        if args.native is None:
            parser.error('--native must contain the matched staged modules')
        native = args.native.resolve()
        paths = {'Scatter': ROOT / 'AminScatter/scripts/AminScatterObject.ms',
                 'AnalyzerScript': native / 'CyrusSurfaceAnalyzer.ms'}
        for name in ('AminScatter.dlx', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh', 'CyrusScatterEdit.dlm', 'CyrusSurfaceAnalyzer.dlx', 'CyrusGallery.dll'):
            paths[name] = native / name
        for fixture in sorted(Path(__file__).parent.iterdir()):
            if fixture.suffix not in ('.ms','.py','.cs','.ps1','.cpp') or fixture.name in ('host.py','results.py'):continue
            paths['fixture:' + fixture.name] = fixture.resolve()
        for helper in ('RolloutOrderFixture.dll','OwnedRolloutSdk.dll'):
            if (folder.parent/helper).is_file():paths['fixture:'+helper]=(folder.parent/helper).resolve()
        for name in ('host.py','results.py'):
            paths['driver:'+name]=Path(__file__).with_name(name).resolve()
        paths['scenario_manifest'] = Path(__file__).with_name('scenarios.json').resolve()
        identity, hashes = artifact_identity(paths)
        process, _ = launch(folder, paths['Scatter'], native, transport=True, max_year=2027,
                            visible=args.visible,
                            silent_startup=not args.interactive_startup, extra_modules=('CyrusSurfaceAnalyzer.dlx',),
                            script_assets=('CyrusGallery.dll', 'CyrusSurfaceAnalyzer.ms'),
                            extra='if cyrusBandShapeKey==undefined do throw "Incomplete Bands native payload"\nfileIn (MCPFixtureDir+"scripts/CyrusSurfaceAnalyzer.ms")')
        origins={name:str(path) for name,path in paths.items()}
        for name in ('Scatter','AnalyzerScript','CyrusGallery.dll','AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusSurfaceAnalyzer.dlx'):
            paths[name]=folder/('scripts/CyrusScatter.ms' if name=='Scatter' else 'scripts/CyrusSurfaceAnalyzer.ms' if name=='AnalyzerScript' else 'scripts/'+name if name=='CyrusGallery.dll' else 'bin/'+name)
            if hashlib.sha256(paths[name].read_bytes()).hexdigest()!=hashes[name]:raise RuntimeError('Staged payload differs: '+name)
        (folder / 'qualification.json').write_text(json.dumps({'run_id': uuid.uuid4().hex, 'artifact_id': identity, 'hashes': hashes, 'paths': {n:str(p) for n,p in paths.items()}, 'origins':origins, 'pid': process.pid}, indent=2), encoding='utf-8')
        print(json.dumps({'pid': process.pid, 'folder': str(folder)}), flush=True)
        wait_ready(folder)
    elif args.action == 'bind-suite':
        metadata=bind_suite(folder)
        print(json.dumps({'run_id':metadata['run_id'],'artifact_id':metadata['artifact_id']}))
    elif args.action == 'observe':
        for name in ('startup-error.txt', 'dev-result.txt'):
            path = folder / name
            if path.exists():
                print(path.read_text(encoding='utf-8-sig'))
    else:
        wait_ready(folder)
        manifest = json.loads(Path(__file__).with_name('scenarios.json').read_text(encoding='utf-8'))
        scenario = next(s for s in manifest['scenarios'] if s['id'] == args.scenario)
        if not 1<=args.timeout<=600:parser.error('--timeout must be 1..600 seconds')
        print(json.dumps(run(folder, scenario,timeout=args.timeout), indent=2))


if __name__ == '__main__':
    main()
