"""Build and run a synthetic licensing boundary experiment in disposable Max.

No installation, product gate, account, issuer key or artist scene is changed.
Each run retains its own immutable source copy, binaries, profiles and logs.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import psutil

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
from build_max import compiler_environment


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2), encoding='utf-8')


def run_command(command, output, env, timeout=300):
    started = time.monotonic()
    command = list(map(str, command))
    print('Running ' + output.stem, flush=True)
    # Direct files avoid waiting for pipe EOF when a compiler helper inherits
    # stdout, and retain diagnostics even if the command reaches its timeout.
    timed_out = False
    with output.with_suffix('.log').open('wb') as log:
        process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log,
                                   stderr=subprocess.STDOUT)
        try:
            return_code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            try:
                children = psutil.Process(process.pid).children(recursive=True)
            except psutil.NoSuchProcess:
                children = []
            for child in reversed(children):
                try:
                    child.kill()
                except psutil.NoSuchProcess:
                    pass
            process.kill()
            return_code = process.wait(timeout=15)
    write_json(output.with_suffix('.json'), {
        'command': command, 'exit_code': return_code, 'timeout': timed_out,
        'elapsed_seconds': time.monotonic() - started,
    })
    print(output.with_suffix('.log').read_text(encoding='utf-8', errors='replace')[-2000:],
          flush=True)
    if timed_out:
        raise subprocess.TimeoutExpired(command, timeout)
    if return_code:
        raise subprocess.CalledProcessError(return_code, command)


def snapshot(output, product_baseline=None):
    prefixes = ['AminScatter', 'CyrusSurfaceAnalyzer', 'CyrusLicensing', 'cmake',
                'tools/licensing_lab', 'tools/build_max.py', 'tools/procedural_lab',
                'tools/performance', 'tools/mcp', 'CyrusMCP']
    names = subprocess.check_output(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', *prefixes],
        cwd=ROOT, text=True).splitlines()
    frozen = {}
    if product_baseline is not None:
        frozen = {row['path']: row for row in json.loads(
            (product_baseline / 'source.json').read_text(encoding='utf-8'))['files']
            if row['path'].startswith(('AminScatter/', 'CyrusSurfaceAnalyzer/', 'cmake/'))}
        names = [name for name in names if not name.startswith(
            ('AminScatter/', 'CyrusSurfaceAnalyzer/', 'cmake/'))] + list(frozen)
    source = output / 'source'
    records = []
    for name in sorted(set(names)):
        origin = (product_baseline / 'source').resolve() if name in frozen else ROOT
        original = (origin / name).resolve()
        if not original.is_relative_to(origin) or not original.is_file():
            raise RuntimeError('Invalid snapshot source: ' + name)
        if name in frozen and digest(original) != frozen[name]['sha256']:
            raise RuntimeError('Frozen baseline source changed: ' + name)
        target = source / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(original, target)
        records.append({'path': name, 'bytes': original.stat().st_size, 'sha256': digest(target)})
    write_json(output / 'source.json', {
        'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'scope': 'Current licensing/lab code plus frozen product baseline' if frozen else
                 'Working-tree snapshot, including uncommitted lab code; HEAD alone is insufficient',
        'product_baseline': str(product_baseline) if frozen else None,
        'files': records,
    })
    declarations = []
    for directory in ['AminScatter/src', 'CyrusSurfaceAnalyzer/src']:
        for path in sorted((source / directory).rglob('*')):
            if path.suffix not in ('.cpp', '.inc', '.h') or not path.is_file():
                continue
            for number, line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(), 1):
                for match in re.finditer(r'def_visible_primitive\(\s*(\w+)\s*,\s*"([^"]+)"', line):
                    declarations.append({'symbol': match[1], 'script_name': match[2],
                                         'path': path.relative_to(source).as_posix(), 'line': number})
    write_json(output / 'native_inventory.json', {
        'scope': 'Declarations only; SDK callbacks, script/MCP entry points need separate coverage',
        'count': len(declarations), 'declarations': declarations,
    })
    return source


def build(source, output, env):
    native = output / 'bin'
    native.mkdir()
    for year in (2026, 2027):
        sdk = ROOT / f'build/tooling/max{year}-sdk/Program Files/Autodesk/3ds Max {year} SDK/maxsdk'
        target = output / f'lab-{year}'
        run_command(['cmake', '-S', source / 'tools/licensing_lab', '-B', target,
                     '-G', 'NMake Makefiles', '-DCMAKE_BUILD_TYPE=Release',
                     '-DCYRUS_BUILD_LICENSING_LAB=ON', f'-DCYRUS_MAX_YEAR={year}',
                     f'-DMAXSDK_ROOT={sdk}'], output / f'lab-{year}-configure', env)
        run_command(['cmake', '--build', target], output / f'lab-{year}-build', env)
        run_command(['ctest', '--test-dir', target, '--output-on-failure', '-V'],
                    output / f'lab-{year}-tests', env)
    shutil.copy2(output / 'lab-2027/CyrusLicenseLab.dlx', native)
    sdk = ROOT / 'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
    for product, targets in [
        ('AminScatter', ['AminScatter', 'CyrusScatterEdit', 'CyrusBrush', 'CyrusBrushStorage']),
        ('CyrusSurfaceAnalyzer', ['CyrusSurfaceAnalyzer']),
    ]:
        target = output / product
        run_command(['cmake', '-S', source / product, '-B', target, '-G', 'NMake Makefiles',
                     '-DCMAKE_BUILD_TYPE=Release', '-DCYRUS_MAX_YEAR=2027', f'-DMAXSDK_ROOT={sdk}'],
                    output / f'{product}-configure', env)
        run_command(['cmake', '--build', target, '--target', *targets],
                    output / f'{product}-build', env)
        for path in target.glob('*.dl?'):
            shutil.copy2(path, native)
    write_json(output / 'binaries.json', {path.name: digest(path) for path in native.glob('*.dl?')})


def reuse_binaries(previous, output):
    # Script-only fixture repair: reuse exact binaries only if every native
    # source/build input matches. Preserve provenance instead of silently
    # substituting whatever happens to be installed on the artist's machine.
    def native_inputs(folder):
        files = json.loads((folder / 'source.json').read_text())['files']
        return {row['path']: row['sha256'] for row in files
                if Path(row['path']).suffix not in ('.ms', '.md', '.py', '.json')
                or row['path'] == 'tools/build_max.py'}
    if native_inputs(previous) != native_inputs(output):
        raise RuntimeError('Native/build inputs changed; run without --reuse-binaries-from')
    expected = json.loads((previous / 'binaries.json').read_text())
    (output / 'bin').mkdir()
    for name, sha in expected.items():
        path = previous / 'bin' / name
        if digest(path) != sha:
            raise RuntimeError('Reused binary fingerprint mismatch: ' + name)
        shutil.copy2(path, output / 'bin' / name)
    shutil.copy2(previous / 'binaries.json', output / 'binaries.json')
    write_json(output / 'reused_build.json', {
        'from': str(previous), 'native_inputs_equal': True,
        'note': 'Build/test results belong to original build; only Max fixture is rerun here',
    })
    print('Reusing verified unchanged native build from ' + str(previous), flush=True)


def host(source, output, stage, max_dir, fixture='fixture.ms'):
    profile = output / stage
    profile.mkdir()
    for name in ('startup', 'scripts', 'macros', 'plugcfg', 'temp', 'autoback'):
        (profile / name).mkdir()
    original = Path(os.environ['LOCALAPPDATA']) / 'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
    config = original.read_text(encoding='utf-16')
    for key, directory in {'Additional Scripts': 'scripts', 'Additional Macros': 'macros',
                           'Additional Startup Scripts': 'startup', 'PlugCFG': 'plugcfg',
                           'Temp': 'temp', 'Page File': 'temp', 'AutoBackup': 'autoback'}.items():
        config, count = re.subn(rf'(?m)^{re.escape(key)}=.*$',
                                lambda _: key + '=' + str(profile / directory), config)
        if count != 1:
            raise RuntimeError('Expected one isolated INI entry: ' + key)
    ini = profile / 'max.ini'
    ini.write_text(config, encoding='utf-16')
    plugins = profile / 'plugins.ini'
    plugins.write_text('[Directories]\nAdditional MAX plug-ins=' + str(max_dir / 'PlugIns') +
                       '\nCyrusLicenseLab=' + str(output / 'bin') + '\n[Help]\n', encoding='utf-8')
    script = profile / 'start.ms'
    script.write_text(
        f'global LLRoot="{source.as_posix()}/",LLOut="{output.as_posix()}/",'
        f'LLStage="{stage}"\nfileIn (LLRoot+"tools/licensing_lab/{fixture}")\n', encoding='utf-8')
    command = [str(max_dir / '3dsmaxbatch.exe'), str(script), '-i', str(ini), '-p', str(plugins),
               '-listenerlog', str(profile / 'listener.log'), '-log', str(profile / 'session.log')]
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    print('Running isolated Max 2027 ' + stage, flush=True)
    with (profile / 'stdout.log').open('wb') as out, (profile / 'stderr.log').open('wb') as err:
        process = subprocess.Popen(command, cwd=ROOT, stdout=out, stderr=err, startupinfo=startup)
        try:
            return_code = process.wait(timeout=300)
        except subprocess.TimeoutExpired:
            # Stop only this runner's process tree, never an artist Max session.
            try:
                children = psutil.Process(process.pid).children(recursive=True)
            except psutil.NoSuchProcess:
                children = []
            for child in reversed(children):
                try:
                    child.kill()
                except psutil.NoSuchProcess:
                    pass
            process.kill()
            process.wait(timeout=15)
            write_json(profile / 'launch.json', {'command': command, 'timeout': True})
            raise
    write_json(profile / 'launch.json', {'command': command, 'exit_code': return_code})
    checks = (profile / 'checks.tsv').read_text(encoding='utf-8-sig')
    print(checks[-4000:], flush=True)
    if return_code != 0 or not checks.rstrip().endswith('COMPLETE') or any(
            line.startswith('FAIL\t') for line in checks.splitlines()):
        raise RuntimeError('Fixture failed: ' + str(profile))
    expected = json.loads((output / 'binaries.json').read_text())
    loaded = {}
    for line in (profile / 'modules.tsv').read_text(encoding='utf-8-sig').splitlines():
        name, location = line.split('\t', 1)
        if name in expected:
            path = Path(location).resolve()
            if path != (output / 'bin' / name).resolve() or digest(path) != expected[name]:
                raise RuntimeError('Wrong loaded binary: ' + line)
            loaded[name] = {'path': str(path), 'sha256': digest(path)}
    if set(loaded) != set(expected):
        raise RuntimeError('Missing module identities: ' + str(set(expected) - set(loaded)))
    write_json(profile / 'verified_modules.json', loaded)
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', required=True)
    parser.add_argument('--reuse-binaries-from', help='Existing run name with identical native inputs')
    parser.add_argument('--max-dir', type=Path, default=Path('C:/Program Files/Autodesk/3ds Max 2027'))
    args = parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+', args.run):
        raise SystemExit('Use a lowercase alphanumeric/hyphen run name')
    output = ROOT / 'build/licensing-l0-2026-10-04' / args.run
    output.mkdir(parents=True, exist_ok=False)
    source = snapshot(output)
    env = compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),
                               '14.38.33130', '10.0.19041.0')
    if args.reuse_binaries_from:
        if not re.fullmatch(r'[a-z0-9-]+', args.reuse_binaries_from):
            raise SystemExit('Invalid previous run name')
        reuse_binaries(output.parent / args.reuse_binaries_from, output)
    else:
        build(source, output, env)
    results = {stage: host(source, output, stage, args.max_dir) for stage in ('create', 'reopen')}
    from PIL import Image, ImageChops
    with Image.open(output / 'active.png') as active:
        if active.size != (128, 128):
            raise RuntimeError('Unexpected render dimensions')
        for filename in ('expired-create.png', 'expired.png'):
            with Image.open(output / filename) as expired:
                if expired.size != active.size:
                    raise RuntimeError('Unexpected expired render dimensions')
                if ImageChops.difference(active.convert('RGB'), expired.convert('RGB')).getbbox() is not None:
                    raise RuntimeError('Expired fixture render differs from active control: ' + filename)
        if len(active.convert('RGB').getcolors(16385) or []) < 4:
            raise RuntimeError('Fixture render appears blank')
        with Image.open(output / 'expired-source-changed.png') as changed:
            if ImageChops.difference(active.convert('RGB'), changed.convert('RGB')).getbbox() is None:
                raise RuntimeError('Dependency counterexample did not alter the rendered geometry')
    write_json(output / 'result.json', {
        'status': 'PASS', 'scope': 'Synthetic policy and wrapper feasibility only; no production enforcement',
        'sdk_builds': [2026, 2027], 'runtime': 'Max 2027 batch, Default Scanline only',
        'render_pixels_equal': True, 'checks': results,
        'changed_source_render_differs': True,
        'open_boundary': 'Product direct calls and edited parameters remain ungated; see escape observations',
    })
    print('PASS isolated licensing L0 experiment: ' + str(output), flush=True)


if __name__ == '__main__':
    main()
