"""Build/test/package the native plugins with the matching Autodesk SDK.

Uses the pinned MSVC compiler directly with NMake, including installations where
Visual Studio COM discovery or Developer Command Prompt scripts are unavailable.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
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


def scatter_version():
    script = (ROOT / 'AminScatter/scripts/AminScatterObject.ms').read_text(encoding='utf-8')
    versions = re.findall(r'fn uiVersion\s*=\s*"(\d+\.\d+\.\d+)"', script)
    if len(versions) != 1:
        raise ValueError('Generate one SemVer-versioned Scatter script before packaging.')
    return versions[0]


def package(project, name, version, native_names, script_name, args, build_dir):
    if project == 'AminScatter' and version != scatter_version():
        raise ValueError('Requested Scatter version differs from generated source. Use a frozen checkout for historical versions.')
    payload = {}
    for filename in native_names:
        payload[filename] = (build_dir / project / filename).read_bytes()
    native_id = sha(b''.join(payload[n] for n in sorted(payload)))[:12]
    for path in sorted((ROOT / project / 'installer').iterdir()):
        if path.is_file():
            text = path.read_text(encoding='utf-8-sig')
            if project == 'AminScatter':
                if path.name == 'install.ms' and '__MAX_VERSION__' not in text:
                    raise RuntimeError('Missing Scatter installer host guard')
                for token, value in {'__MAX_YEAR__': args.max_year,
                                     '__MAX_VERSION__': (args.max_year - 1998) * 1000,
                                     '__NATIVE_ID__': native_id, '__VERSION__': version}.items():
                    text = text.replace(token, str(value))
            else:
                if path.name == 'install.ms' and ('28000' not in text or '2026' not in text):
                    raise RuntimeError('Analyzer installer host guard changed')
                text = text.replace('2026', str(args.max_year)).replace('28000', str((args.max_year - 1998) * 1000))
                text = text.replace('bin05', f'bin-max{args.max_year}-{native_id}')
            if path.name == 'mzp.run':
                # MZP uses a numeric version; retain full SemVer in its name,
                # filename and manifest, rather than emitting 1.0.0 syntax.
                mzp_version='.'.join(version.split('.')[:2])
                text = f'name "{name} {version} for 3ds Max {args.max_year}"\nversion {mzp_version}\nrun "install.ms"\n'
            payload[path.name] = text.encode('utf-8')
    payload['CyrusScatter.ms' if project == 'AminScatter' else script_name] = (ROOT / project / 'scripts' / script_name).read_bytes()
    payload['INSTALL.txt'] = (
        f'{name} {version} - 3ds Max {args.max_year} x64\n'
        'Run this MZP through Scripting > Run Script, then restart Max.\n'
        + ('Native Max plant-group editor with a shared receiver, placement/display statistics and separate viewport visibility.\n'
           'Coverage / Brush: Paint/Erase the selected group, edit stroke history, Fill/Empty and Undo.\n'
           'Group spacing uses accepted final plants, pair gaps and priority; conflicting manual overrides are preserved and reported.\n'
           'Flat and curved static surfaces are supported. Topology changes require target validation; strokes are preserved.\n'
           'Manual mode updates the mask immediately and publishes plants when Update is pressed.\n'
           'Painted coverage pauses point Relax. Shared groups pause Boundary Relax. Stored settings are preserved.\n'
           'Existing scenes retain legacy spacing. Explicit conversion is undoable; setups with CS Edit remain legacy.\n'
           'Randomize XYZ has separate Undoable rotation, scale, whole-scale and movement resets.\n'
           'Brush with unprojected random movement remains outside this release.\n'
           'Retained Nitrous point-cloud buffers, GPU-instanced Mesh preview, bounded proxy batches and deferred synchronization during held input.\n'
           'Point Cloud and Mesh reuse GPU buffers during navigation. Existing preview limits still apply; no automatic camera LOD.\n'
           'Includes native source filtering/transforms, batched edit notifications, and bounded clustered queries.\n'
           'Automatic clustered calculations use at most 4 total CPU participants. GPU compute is not enabled.\n'
           if project == 'AminScatter' else 'The Analyzer algorithm is unchanged in this performance iteration.\n') +
        'Create > Geometry > Cyrus, then select the tool and use Modify.\n'
        'Use saved test scene copies to compare performance and verify output.\n'
        + ('Max 2027 runtime qualification is recorded in the planting-groups report. Max 2026 is SDK-built/tested and still needs host testing.\n'
           'Cyrus Automation/MCP is a separate optional installation; Brush is not exposed as an MCP tool in schema 1.0.\n'
           if project == 'AminScatter' else '')
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
    package('AminScatter', 'Cyrus Scatter', scatter_version(), ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh'],
            'AminScatterObject.ms', args, base)
    package('CyrusSurfaceAnalyzer', 'Cyrus Surface Analyzer', '0.14', ['CyrusSurfaceAnalyzer.dlx'],
            'CyrusSurfaceAnalyzer.ms', args, base)


if __name__ == '__main__':
    main()
