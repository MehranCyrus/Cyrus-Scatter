"""Prepare a copied Max 2027 scene and publish a validated, self-contained GLB."""
from pathlib import Path
import argparse
import copy
import datetime
import json
import os
import shutil
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
APP = HERE.parents[1]
sys.path.insert(0, str(HERE / 'scene-preparation'))
from recipe import digest, make_plan, max_string, VERSION


def ms_value(value):
    if isinstance(value, str): return max_string(value)
    if isinstance(value, bool): return 'true' if value else 'false'
    if isinstance(value, (int, float)): return repr(value)
    if isinstance(value, list): return '#(' + ','.join(ms_value(v) for v in value) + ')'
    raise ValueError('Unsupported generated MAXScript value')


def native_request(plan, source_copy, staging, delivery):
    recipe = plan['recipe']
    material_rules = [[[key, value] for key, value in row.items()] for row in recipe['materials']['rules']]
    config = [str(source_copy), str(Path(plan['source']).parent), staging.as_posix() + '/', delivery.as_posix() + '/', recipe['bakeFrame']]
    text = 'global CyrusPrepareNative,CyrusPrepareGeometry,CyrusPrepareMaterials,CyrusPrepareJsonString,CyrusPrepareJsonNumber\n'
    for filename in ['geometry.ms', 'materials.ms', 'export-materials.ms', 'native.ms']:
        text += 'fileIn ' + max_string(str(HERE / 'scene-preparation' / filename)) + '\n'
    translation = '[' + ','.join(repr(v) for v in recipe['translationMetres']) + ']'
    values = [ms_value(v) for v in config] + [translation, ms_value(recipe['nativeReduction']['minimumFaces']), ms_value([[r['layer'], r['percent'], r['keepUV']] for r in recipe['nativeReduction']['layers']]), ms_value(recipe['protectedLayers']), ms_value(recipe['materials']['mode']), ms_value(material_rules)]
    return text + 'CyrusPrepareNative #(' + ','.join(values) + ')\n'


def write_json(path, data):
    temporary = path.with_suffix(path.suffix + '.next')
    temporary.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
    temporary.replace(path)


def process_state(metadata):
    if os.name != 'nt': raise RuntimeError('3ds Max preparation requires Windows')
    command = f'Get-CimInstance Win32_Process -Filter "ProcessId = {int(metadata["pid"])}" | Select-Object ProcessId,ExecutablePath,CommandLine,CreationDate | ConvertTo-Json -Compress'
    result = subprocess.run(['powershell', '-NoProfile', '-Command', command], capture_output=True, text=True, encoding='utf-8', errors='replace', creationflags=subprocess.CREATE_NO_WINDOW, check=True)
    if not result.stdout.strip(): return None
    actual = json.loads(result.stdout)
    if actual['ProcessId'] != metadata['pid'] or Path(actual['ExecutablePath']).resolve() != Path(metadata['command'][0]).resolve() or str(Path(metadata['run']) / 'max.ini').casefold() not in actual['CommandLine'].casefold():
        raise RuntimeError('PID no longer identifies this owned Max host; refusing to attach or restart')
    if metadata.get('creationDate') and actual['CreationDate'] != metadata['creationDate']:
        raise RuntimeError('Owned Max process identity changed')
    return actual


def wait_native(state, timeout):
    session = Path(state['host']['run']); began = time.monotonic(); last_message = -30
    while True:
        actual = process_state(state['host'])
        result_path = session / 'dev-result.txt'
        result = result_path.read_text(encoding='utf-8-sig').strip() if result_path.exists() else ''
        request = str(Path(state['request']).as_posix())
        if result == 'SUCCESS ' + request: return
        if result.startswith('ERROR ') and 'REQUEST: ' + request in result:
            raise RuntimeError('Owned Max request failed; inspect ' + str(result_path) + '\n' + result[:2000])
        if actual is None: raise RuntimeError('Owned Max process ended before this request completed; inspect diagnostics, do not restart blindly')
        if state['phase'] == 'launching' and (session / 'ready.txt').exists():
            if not (session / 'ready.txt').read_text(encoding='utf-8-sig').startswith('#(29000,'): raise RuntimeError('Unexpected Max host version')
            next_request = session / 'dev-request.next'; next_request.write_text(request, encoding='utf-8'); next_request.replace(session / 'dev-request.txt')
            state['phase'] = 'native-running'; write_json(Path(state['output']) / 'run.json', state)
        elapsed = time.monotonic() - began
        if elapsed - last_message >= 30:
            print(json.dumps({'phase': state['phase'], 'ownedPid': state['host']['pid'], 'waitSeconds': round(elapsed), 'session': str(session)}), flush=True); last_message = elapsed
        if elapsed > timeout: raise TimeoutError('Owned Max remains active. Keep its session; resume this output after inspecting its exact request/result. No restart was attempted.')
        time.sleep(3)


def finish(state):
    output = Path(state['output']); staging = output / 'delivery.partial'; delivery = output / 'delivery'; plan = state['plan']
    if digest(Path(plan['source'])) != plan['sourceSha256']: raise RuntimeError('Original source changed during preparation; output will not publish')
    if not (staging / 'native-complete.json').exists() or not (staging / 'native.glb').exists() or not (staging / 'prepared.max').exists(): raise RuntimeError('Native completion artifacts are incomplete')
    was_closing = state['phase'] == 'closing-native'
    state['phase'] = 'native-complete'; write_json(output / 'run.json', state)
    if not was_closing and process_state(state['host']):
        session = Path(state['host']['run']); quit_request = session / 'preparation-close.ms'; quit_request.write_text('quitMAX #noPrompt\n', encoding='utf-8-sig')
        pending = session / 'dev-request.next'; pending.write_text(quit_request.as_posix(), encoding='utf-8'); pending.replace(session / 'dev-request.txt')
    state['phase'] = 'closing-native'; write_json(output / 'run.json', state)
    # Max's current scene directory can keep the whole staging directory locked on Windows.
    closing = time.monotonic(); last_message = -30
    while process_state(state['host']) is not None:
        elapsed = time.monotonic() - closing
        if elapsed - last_message >= 30:
            print(json.dumps({'phase': 'closing-owned-Max', 'ownedPid': state['host']['pid'], 'waitSeconds': round(elapsed)}), flush=True); last_message = elapsed
        if elapsed > 120: raise TimeoutError('Owned Max has not finished closing. Preserve this run and resume it; no forced termination or replacement host was used.')
        time.sleep(3)
    state['phase'] = 'post-running'; write_json(output / 'run.json', state)
    subprocess.run(['node', '--import', 'tsx', str(HERE / 'scene-preparation/post.mjs'), str(staging)], cwd=APP, check=True)
    post = json.loads((staging / 'post-report.json').read_text(encoding='utf-8'))
    if digest(staging / 'optimized.glb') != post['outputSha256']: raise RuntimeError('Prepared GLB hash differs from its validated result')
    # Retain a portable recipe pointing to the texture copies beside prepared.max.
    portable = copy.deepcopy(plan['recipe']); texture_rows = [json.loads(line) for line in (staging / 'prepared-textures.jsonl').read_text(encoding='utf-8-sig').splitlines() if line]
    texture_paths = {str(Path(row['source']).resolve()).casefold(): row['path'] for row in texture_rows}
    for rule in portable['materials']['rules']:
        for field in ['baseColorTexture', 'opacityTexture']:
            if field in rule:
                key = str(Path(rule[field]).resolve()).casefold()
                if key not in texture_paths: raise RuntimeError('A recipe texture is absent from the prepared bundle')
                rule[field] = texture_paths[key]
    write_json(staging / 'recipe.json', portable)
    report = {'tool': 'Cyrus scene preparation', 'toolVersion': VERSION, 'source': plan['source'], 'sourceSha256': plan['sourceSha256'], 'sourceBytes': plan['sourceBytes'], 'recipeSha256': plan['recipeSha256'], 'originalPreserved': digest(Path(plan['source'])) == plan['sourceSha256'], 'normalProfilePreserved': digest(Path(state['host']['normal_profile_path'])) == state['host']['normal_profile_sha256'], 'native': json.loads((staging / 'native-complete.json').read_text()), 'geometry': json.loads((staging / 'geometry-summary.json').read_text()), 'post': post, 'toolHashes': state['toolHashes'], 'files': {p.relative_to(staging).as_posix(): {'bytes': p.stat().st_size, 'sha256': digest(p)} for p in staging.rglob('*') if p.is_file()}, 'maxTexturePaths': 'Prepared Max references this final delivery/textures directory; re-path textures if moving the Max scene. The portable recipe uses relative texture paths.', 'scope': 'Static preparation at the selected frame; artistic scalar conversion is not renderer equivalence. Visual/performance acceptance remains scene-specific.'}
    if not report['originalPreserved'] or not report['normalProfilePreserved']: raise RuntimeError('Source/profile preservation failed; output will not publish')
    write_json(staging / 'report.json', report)
    if delivery.exists(): raise RuntimeError('Final destination already exists; previous result retained')
    if staging.resolve().parent != output.resolve() or delivery.resolve().parent != output.resolve(): raise RuntimeError('Publication paths escaped the explicitly selected output directory')
    staging.rename(delivery); state['phase'] = 'complete'; state['completedAt'] = datetime.datetime.now(datetime.timezone.utc).isoformat(); write_json(output / 'run.json', state)
    print(json.dumps({'phase': 'complete', 'delivery': str(delivery), 'glbBytes': post['outputBytes'], 'triangles': post['submittedTriangles'], 'sha256': post['outputSha256']}, indent=2), flush=True)


def run(args):
    if args.resume:
        output = Path(args.resume).resolve(); state = json.loads((output / 'run.json').read_text(encoding='utf-8'))
        if state['phase'] not in ['launching', 'native-running', 'native-complete', 'closing-native']: raise RuntimeError('Resume supports the existing native request only; inspect failed/post/complete runs before taking further action')
        if str(output) != state['output']: raise RuntimeError('Output identity differs from its record')
        for path, expected in state['toolHashes'].items():
            if digest(Path(path)) != expected: raise RuntimeError('Tool changed since launch; do not resume an unqualified mixed run')
    else:
        if not args.source or not args.output: raise ValueError('Provide source.max and a fresh output directory')
        plan = make_plan(args.source, args.output, args.recipe)
        if args.plan: print(json.dumps(plan, indent=2)); return
        if os.name != 'nt': raise RuntimeError('Native preparation requires Windows and 3ds Max 2027')
        output = Path(plan['output']); output.mkdir(parents=True, exist_ok=False); working = output / 'working'; working.mkdir(); staging = output / 'delivery.partial'; staging.mkdir(); (staging / 'textures').mkdir()
        source_copy = working / 'source.max'; shutil.copy2(plan['source'], source_copy)
        if digest(source_copy) != plan['sourceSha256']: raise RuntimeError('Source copy differs from the original')
        for rule in plan['recipe']['materials']['rules']:
            for field in ['baseColorTexture', 'opacityTexture']:
                if field in rule:
                    original = Path(rule[field]); key = str(original); expected = plan['textures'][key]
                    if digest(original) != expected: raise RuntimeError('Texture changed after planning')
                    copied = working / (expected[:20] + original.suffix.lower())
                    if not copied.exists(): shutil.copy2(original, copied)
                    rule[field] = str(copied)
        write_json(staging / 'plan.json', plan)
        tool_paths = [Path(__file__).resolve(), HERE / 'host-workflow.py'] + [p for p in (HERE / 'scene-preparation').iterdir() if p.suffix in ['.py', '.ms', '.mjs']]
        launched = subprocess.run([sys.executable, str(HERE / 'host-workflow.py'), 'launch'], capture_output=True, text=True, encoding='utf-8', check=True)
        host = json.loads(launched.stdout); host['creationDate'] = process_state(host)['CreationDate']
        request = Path(host['run']) / 'prepare-scene.ms'; request.write_text(native_request(plan, source_copy, staging, output / 'delivery'), encoding='utf-8-sig')
        state = {'output': str(output), 'phase': 'launching', 'plan': plan, 'host': host, 'request': str(request), 'toolHashes': {str(p): digest(p) for p in tool_paths}}
        write_json(output / 'run.json', state); print(json.dumps({'phase': 'launched', 'ownedPid': host['pid'], 'output': str(output)}), flush=True)
    try:
        if state['phase'] in ['launching', 'native-running']: wait_native(state, args.timeout)
        finish(state)
    except BaseException as error:
        write_json(output / 'failure.json', {'phase': state['phase'], 'error': str(error), 'ownedHost': state['host'], 'request': state['request'], 'finalPublished': (output / 'delivery').exists()})
        raise


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', nargs='?'); parser.add_argument('output', nargs='?')
    parser.add_argument('--recipe', type=Path, default=HERE / 'scene-preparation/recipes/conservative.json')
    parser.add_argument('--plan', action='store_true', help='Validate and print a plan without starting Max or writing output')
    parser.add_argument('--resume', type=Path, help='Wait for the same recorded native request; never launches a replacement host')
    parser.add_argument('--timeout', type=int, default=3600)
    arguments = parser.parse_args()
    if not 30 <= arguments.timeout <= 7200: parser.error('Timeout must be 30–7200 seconds; expiry never restarts Max')
    run(arguments)
