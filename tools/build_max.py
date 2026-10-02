"""Build/test/package the native plugins with the matching Autodesk SDK.

Uses the pinned MSVC compiler directly with NMake, including installations where
Visual Studio COM discovery or Developer Command Prompt scripts are unavailable.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def run(args, env):
    print('+ ' + subprocess.list2cmdline([str(x) for x in args]), flush=True)
    subprocess.run([str(x) for x in args], cwd=ROOT, env=env, check=True)


def compiler_environment(vs_root, tools_version, windows_sdk):
    vc = vs_root / 'VC/Tools/MSVC' / tools_version
    kits = Path(os.environ.get('ProgramFiles(x86)', 'C:/Program Files (x86)')) / 'Windows Kits/10'
    bindirs = [vc / 'bin/Hostx64/x64', kits / 'bin' / windows_sdk / 'x64']
    includes = [vc / 'include', vc / 'atlmfc/include'] + [
        kits / 'Include' / windows_sdk / part for part in ('ucrt', 'shared', 'um', 'winrt', 'cppwinrt')]
    libs = [vc / 'lib/x64', vc / 'atlmfc/lib/x64'] + [
        kits / 'Lib' / windows_sdk / part / 'x64' for part in ('ucrt', 'um')]
    for path in [bindirs[0] / 'cl.exe', bindirs[0] / 'nmake.exe', bindirs[1] / 'rc.exe'] + includes + libs:
        if not path.exists():
            raise SystemExit(f'Missing build prerequisite: {path}')
    env = os.environ.copy()
    env['PATH'] = os.pathsep.join(map(str, bindirs)) + os.pathsep + env['PATH']
    env['INCLUDE'] = os.pathsep.join(map(str, includes))
    env['LIB'] = os.pathsep.join(map(str, libs))
    return env


def sha(data):
    return hashlib.sha256(data).hexdigest()


def package(project, name, version, native_names, script_name, args, build_dir):
    payload = {}
    for filename in native_names:
        payload[filename] = (build_dir / project / filename).read_bytes()
    native_id = sha(b''.join(payload[n] for n in sorted(payload)))[:12]
    for path in sorted((ROOT / project / 'installer').iterdir()):
        if path.is_file():
            text = path.read_text(encoding='utf-8-sig')
            # These are host-specific staging substitutions; source installers
            # remain the legacy 2026 installers. Guard against template drift.
            if path.name == 'install.ms' and ('28000' not in text or '2026' not in text):
                raise RuntimeError('Installer template changed: review host-year substitutions')
            text = text.replace('2026', str(args.max_year)).replace('28000', str((args.max_year - 1998) * 1000))
            if project == 'AminScatter':
                text = text.replace('0.59', version)
            text = text.replace('bin55', f'bin-max{args.max_year}-{native_id}')
            text = text.replace('bin05', f'bin-max{args.max_year}-{native_id}')
            if path.name == 'mzp.run':
                text = f'name "{name} {version} for 3ds Max {args.max_year}"\nversion {version}\nrun "install.ms"\n'
            payload[path.name] = text.encode('utf-8')
    payload[script_name] = (ROOT / project / 'scripts' / script_name).read_bytes()
    payload['INSTALL.txt'] = (
        f'{name} {version} - 3ds Max {args.max_year} x64\n'
        'Run this MZP through Scripting > Run Script, then restart Max.\n'
        + ('Viewport performance candidate: retained Nitrous point-cloud buffers, GPU-instanced Mesh preview, bounded proxy batches and deferred synchronization during held input.\n'
           'Point Cloud and Mesh reuse GPU buffers during navigation. Existing preview limits still apply; no automatic camera LOD.\n'
           'Includes native source filtering/transforms, batched edit notifications, and bounded clustered queries.\n'
           'Automatic clustered calculations use at most 4 total CPU participants. GPU compute is not enabled.\n'
           if project == 'AminScatter' else 'The Analyzer algorithm is unchanged in this performance iteration.\n') +
        'Create > Geometry > Cyrus, then select the tool and use Modify.\n'
        'Use saved test scene copies to compare performance and verify output.\n'
    ).encode('utf-8')
    manifest = dict(product=name, version=version, max_year=args.max_year,
                    toolset=args.tools_version, windows_sdk=args.windows_sdk,
                    configuration='Release', native_id=native_id,
                    files={n: sha(data) for n, data in sorted(payload.items())})
    payload['manifest.json'] = (json.dumps(manifest, indent=2) + '\n').encode('utf-8')
    args.output.mkdir(parents=True, exist_ok=True)
    target = args.output / f'{name.replace(" ", "")}-{version}-Max{args.max_year}.mzp'
    # Deterministic ZIP metadata. No SDK headers/libraries go into the installer.
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as z:
        for n, data in sorted(payload.items()):
            info = zipfile.ZipInfo(n, date_time=(2026, 9, 28, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, data)
    with zipfile.ZipFile(target) as z:
        if z.testzip() is not None:
            raise RuntimeError('Package ZIP integrity check failed')
        for n, expected in manifest['files'].items():
            if sha(z.read(n)) != expected:
                raise RuntimeError(f'Package verification failed: {n}')
    target.with_suffix('.sha256').write_text(sha(target.read_bytes()) + '  ' + target.name + '\n')
    print(f'Package: {target}', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--max-year', type=int, choices=(2026, 2027), required=True)
    parser.add_argument('--sdk-root', type=Path, required=True)
    parser.add_argument('--vs-root', type=Path, default=Path('C:/Program Files/Microsoft Visual Studio/2022/Community'))
    parser.add_argument('--tools-version', default='14.38.33130')
    parser.add_argument('--windows-sdk', default='10.0.19041.0')
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    parser.add_argument('--node', default='node', help='Node.js executable for regenerating the owned Scatter script')
    args = parser.parse_args()
    env = compiler_environment(args.vs_root, args.tools_version, args.windows_sdk)
    node = shutil.which(args.node, path=env['PATH'])
    if node is None:
        raise SystemExit('Node.js is required to generate the Scatter script; install it or pass --node with its executable path')
    print('Regenerating the Scatter script from its UI source...', flush=True)
    subprocess.run([node, 'tools/ui/generate.cjs'], cwd=ROOT / 'AminScatter', env=env, check=True)
    base = ROOT / 'build' / f'max{args.max_year}-release'
    for project in ('AminScatter', 'CyrusSurfaceAnalyzer'):
        dest = base / project
        run(['cmake', '-S', ROOT / project, '-B', dest, '-G', 'NMake Makefiles',
             '-DCMAKE_BUILD_TYPE=Release', f'-DCYRUS_MAX_YEAR={args.max_year}',
             f'-DMAXSDK_ROOT={args.sdk_root.resolve()}'], env)
        run(['cmake', '--build', dest], env)
        run(['ctest', '--test-dir', dest, '--output-on-failure'], env)
    package('AminScatter', 'Cyrus Scatter', '0.64', ['AminScatter.dlx', 'CyrusScatterEdit.dlm'],
            'AminScatterObject.ms', args, base)
    package('CyrusSurfaceAnalyzer', 'Cyrus Surface Analyzer', '0.14', ['CyrusSurfaceAnalyzer.dlx'],
            'CyrusSurfaceAnalyzer.ms', args, base)


if __name__ == '__main__':
    main()
