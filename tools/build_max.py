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
import sys
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
    versions = re.findall(r'fn uiVersion\s*=\s*"(\d+\.\d+(?:\.\d+){0,2})"', script)
    if len(versions) != 1:
        raise ValueError('Generate one development-versioned Scatter script before packaging.')
    version = versions[0] + '.0' if versions[0].count('.') == 1 else versions[0]
    cmake = (ROOT / 'AminScatter/CMakeLists.txt').read_text(encoding='utf-8')
    if re.findall(r'project\(CyrusScatter VERSION ([0-9.]+) LANGUAGES CXX\)', cmake) != [version]:
        raise ValueError('Scatter native/package metadata differs from the displayed development version.')
    return version


def reject_development_binary(filename, data, *, allow_owned_preview=False):
    for marker in ('CYRUS_LICENSE_EXPERIMENT_NEVER_SHIP', 'NEVER SHIP',
                   'cyrusOwnedLabClock', 'cyrusOwnedLabActivate',
                   'cyrusOwnedLabBrushEnd', 'cyrusSignedLabInstall'):
        if marker.encode('utf-16le') in data or marker.encode('ascii') in data:
            raise RuntimeError('Refusing development licensing authority in product package: '+filename)
    if not allow_owned_preview and any('cyrusOwnedPreviewFault'.encode(encoding) in data for encoding in ('ascii','utf-16le')):
        raise RuntimeError('Refusing development preview fault injection in product package: '+filename)


def require_team_authority(data, header):
    key_ids = re.findall(r'CyrusTeamKeyID\[\]="(cyrus-team-[a-f0-9]{32})"', header.read_text(encoding='utf-8'))
    if len(key_ids) != 1 or key_ids[0].encode('ascii') not in data:
        raise RuntimeError('Scatter native module does not contain the selected owner verification key')
    if not any('cyrusLicenseImport'.encode(enc) in data for enc in ('ascii', 'utf-16le')):
        raise RuntimeError('Scatter requires the native team licensing module')
    return key_ids[0]


def library_payload(folder, version):
    """Only ship the explicitly qualified, hash-pinned example inventory."""
    inventory = json.loads((folder / 'inventory.json').read_text(encoding='utf-8'))
    if inventory.get('version') != version or inventory.get('max_year') != 2027:
        raise ValueError('Bundled examples require the matching qualified version/host inventory.')
    files = inventory.get('files', {})
    if not files or len(files) > 1000:
        raise ValueError('Invalid bundled example inventory.')
    result = {}
    total = 0
    for name, expected in files.items():
        if not re.fullmatch(r'[A-Za-z0-9_.\-/]+', name) or '..' in name or name.startswith('/'):
            raise ValueError('Unsafe bundled example path: '+name)
        path = (folder / name).resolve()
        if not path.is_relative_to(folder.resolve()) or path.suffix.lower() not in ('.json', '.png', '.cspaint', '.max', '.md', '.txt'):
            raise ValueError('Unsupported bundled example: '+name)
        data = path.read_bytes();total += len(data)
        if total > 128*1024*1024 or sha(data) != expected:
            raise ValueError('Bundled example bounds/hash mismatch: '+name)
        result['Library/'+name] = data
    result['Library/inventory.json'] = (folder/'inventory.json').read_bytes()
    names = sorted(name.removeprefix('Library/') for name in result)
    result['LibraryFiles.ms'] = ('#('+','.join('@"'+name+'"' for name in names)+')\n').encode('utf-8')
    return result


def package(project, name, version, native_names, script_name, args, build_dir):
    if project == 'AminScatter' and version != scatter_version():
        raise ValueError('Requested Scatter version differs from generated source. Use a frozen checkout for historical versions.')
    payload = {}
    for filename in native_names:
        payload[filename] = (build_dir / project / filename).read_bytes()
        reject_development_binary(filename, payload[filename])
    team_key = require_team_authority(payload['AminScatter.dlx'], args.team_trust_header) if project == 'AminScatter' else None
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
    if project == 'AminScatter':
        payload['CyrusGallery.dll'] = (build_dir / project / 'CyrusGallery.dll').read_bytes()
        installer = build_dir / project / 'CyrusInstaller.dll'
        installer_receipt = json.loads(installer.with_suffix('.build.json').read_text(encoding='utf-8'))
        if installer_receipt['artifact_sha256'] != sha(installer.read_bytes()) or installer_receipt['source_sha256'] != sha((ROOT / project / 'setup/InstallEngine.cs').read_bytes()):
            raise RuntimeError('Installer core source/artifact identity differs from its build receipt.')
        payload['CyrusInstaller.dll'] = installer.read_bytes()
        payload['Clipper2-LICENSE.txt'] = (ROOT / project / 'third_party/clipper2/LICENSE').read_bytes()
        payload['nlohmann-json-LICENSE.txt'] = (ROOT / 'CyrusLicensing/third_party/nlohmann/LICENSE.MIT').read_bytes()
        payload.update(library_payload(Path(getattr(args, 'library_dir', None) or ROOT / project / 'library'), version))
    payload['INSTALL.txt'] = (
        f'{name} {version} - 3ds Max {args.max_year} x64\n'
        'Run this MZP through Scripting > Run Script, then restart Max.\n'
        + ('Enable, Manual/Live and Update scatter stay together at the top of Modify.\n'
           'Team licensing: open License / activation, save an activation request and send it to the owner.\n'
           'Import the returned .cyruslicense file. It expires 30 days after the owner issued it.\n'
           'Without a valid license, existing scenes remain loadable/renderable; creation/editing are locked.\n'
           'Workflow: Layers > Surfaces > Models > Layout > Amount > Update scatter; Painting is optional.\n'
           'Then Include / exclude areas > Transforms > Spacing & cleanup > Viewport & render > Statistics & diagnostics.\n'
           'Completed phases: cached/pending feedback; named settings and curve presets; slope/altitude eligibility; UV-channel/map-resolution controls; Paint/spline snapshots.\n'
           'Presets... is available in Amount, Transforms, Spacing and the curve editor; Apply respects Manual/Live and supports Undo.\n'
           'Include / exclude areas > Surface eligibility offers slope/altitude ranges with inward soft transitions.\n'
           'Density mapping selects UV channel 1..99 and 64/128/256/512 samples per side; defaults are 1 and 128.\n'
           'Layers > Recipes saves complete static multi-layer settings including Paint. Review external scene roles, then Add layers or import a new setup as one Undo.\n'
           'Keep each .csrecipe.json and its paint-<id>.payload folder together. Models/maps/receivers remain external; Paint needs compatible terrain, frame and saved system units.\n'
           'Recipes offers search, categories, tags and stored PNG thumbnails. Browse My recipes, Bundled examples or an explicit custom folder.\n'
           'Bundled examples live in the versioned Library folder beside the installed script. Open an example .max scene, select its Scatter and review the recipe bindings.\n'
           'User recipes remain in Documents/CyrusScatter/Library, separate from versioned bundled content.\n'
           'Unsupported authored Scatter Edit/radius overrides or nonstatic parameter controllers block Save Everything.\n'
           'Amount > Mesh channel density reads vertex colors (0) or map channels (1..99), with component, range, invert and Density curve controls.\n'
           'Use Data Channel Curvature > Vertex Output or VertexPaint to author values. White permits plants; black excludes them.\n'
           'Preview mask is an explicit cached snapshot of at most 2,048 grayscale face-centre markers; refresh after edits.\n'
           'Paint controls have short hover help for density/scale fades, edges, brush actions and feedback.\n'
           'Painting > Export spline creates an independent local-XY snapshot. Pick spline... imports closed contours using Replace or Add and a world-unit tolerance.\n'
           'Select a layer; its Surfaces and Models are independent of other layers. Paint Areas are optional.\n'
           'Edit layers in the Scatter controller Modify panel.\n'
           'Source rectangles open compact collection properties for moving and resizing.\n'
           'Advanced options start collapsed inside each section; opening them does not regenerate placements.\n'
           'Hover controls for short explanations. Models & Points offers Pick object and Make point.\n'
           'Each layer owns models and count/density. Named Paint Areas target its receivers and combine coverage without duplicate plants.\n'
           'Population, transforms and cleanup belong to the layer. Capacity: 10 populations; area APIs bound each layer to 128 areas/receivers.\n'
           'CyrusUnified1, schema 58: create fresh current setups. Earlier development scenes and retired payloads are rejected without migration.\n'
           'Preserve old scenes with their matching build. Earlier stroke formats are not converted and have no legacy brush fallback.\n'
           'Density preserves unchanged receiver candidates below the cap. Fixed Total redistributes quotas and preserves surviving base candidates.\n'
           'Changing local Relax neighborhoods, masks, spacing or geometry can change accepted output; face IDs do not survive arbitrary remeshing.\n'
           'Spacing offers Within this layer and Between layers.\n'
           'Accepted target refills a bounded prefix. Read shortfall/round/attempt diagnostics; limits do not prove a full surface.\n'
           'Individual CS Edit plants/clones can have world-radius or multiplier overrides.\n'
           'Painting: add/select a Paint Area and its Surface, then Paint/Erase, Fill/Clear or Undo. Repeated gestures edit the same area.\n'
           'Spacing uses accepted plants and protected reservations; conflicting manual overrides are preserved and reported.\n'
           'Vector areas support projected local-XY terrain/planes. Closed, vertical, folded or stacked projected receivers are rejected.\n'
           'Inside/outside fade widths and independent density/scale curves operate on the final border.\n'
           'Removing a receiver keeps its area inactive; restoring the same node restores eligibility.\n'
           'Manual mode updates the mask immediately and publishes plants when Update is pressed.\n'
           'Random/Clusters, prepared spline Bands and Analyzer assignment share the same ordered pipeline.\n'
             'Spline Bands > Scale (below density): Off, Follow Density, or Custom with Edit scale curve.\n'
             'The profile multiplies Band Min/Max size; Follow Density links the curve shape, not Density %.\n'
           'Bands have stable identities, Consecutive/Independent ranges, Rounded/Sharp corners, density curves and display colors.\n'
           'Manual field previews can show pending inputs while plants and radii remain from the last Update.\n'
           'Auto Radius uses conservative XY/3D bounds for explicitly supported source types; other source types retain Manual radius.\n'
           'Point and constrained boundary Relax prepare ordinary candidates before eligibility and protected Edit.\n'
           'Source containers are labelled helpers. Create/Pick selects an own pool automatically.\n'
           'Select the Scatter controller for planting settings; parked sources retain their metadata.\n'
           'Count supports 1,000,000 per population within a shared 1,000,000 controller candidate budget, including retries.\n'
           'Translation commits eligible static source models in one Undo. Resize/rotate/scale only change the boundary.\n'
           'Wholly managed groups move together; partial groups, locked/animated/constrained transforms and instanced helpers are guarded.\n'
           'Randomize XYZ has separate Undoable rotation, scale, whole-scale and movement resets.\n'
           'Brush with unprojected random movement remains outside this release.\n'
           'Retained Nitrous point-cloud buffers, GPU-instanced geometry preview and deferred synchronization during held input.\n'
           'Point Cloud, Proxy and Mesh reuse GPU buffers during navigation.\n'
           'Viewport & render has independent Navigating / Idle caps shared across visible layers; 0 means unlimited.\n'
           'Caps count points, proxy instances or Mesh triangles. Memory/input safeguards still apply at zero.\n'
           'Mesh uses cached boxes when triangle or memory allowances cannot admit full geometry.\n'
           'Emergency graphics fallback uses bounded centre markers instead of CPU source triangles.\n'
           'Includes native source filtering/transforms, batched edit notifications, and bounded clustered queries.\n'
           'Automatic clustered calculations use at most 4 total CPU participants. GPU compute is not enabled.\n'
           'Statistics & diagnostics > Advanced records bounded process-wide events. Start, Stop and Save work without MCP.\n'
           'Read recording status explicitly; the diagnostic controls have no polling timer or background disk writes.\n'
           'Box, Sphere and Pyramid proxies use retained instanced geometry; CPU fallback remains available.\n'
           'Surface Analyzer 0.14 is independently installed; this Scatter package does not change it.\n'
           'Outdated guides retain the last complete scatter. Analyze first, then Update scatter in Manual mode.\n'
           if project == 'AminScatter' else 'Published guide freshness is saved. Older guides need one explicit Analyze.\n'
           'Pending geometry events are checked before validation, analysis and saving.\n') +
        'Create > Geometry > Cyrus, then select the tool and use Modify.\n'
        'Use saved test scene copies to compare performance and verify output.\n'
        + ('Development build: use the accompanying qualification report for this exact script/native pair. Vector storage is implemented; physical brush input and sustained production-scene performance remain acceptance gates.\n'
           'Cyrus Automation/MCP is separate. Plan 0.73 supports a bounded locally approved authoring subset.\n'
           'Full Brush/container/Edit authoring and ML are outside the closed plan. Old plan schemas are rejected.\n'
           if project == 'AminScatter' else '')
    ).encode('utf-8')
    if project == 'AminScatter':
        # Exclude the launching script and outer manifest from the inner inventory
        # to avoid a self-referential digest. The outer ZIP hashes all files.
        installed = {n: data for n, data in payload.items() if n not in ('install.ms', 'mzp.run')}
        content_id = sha(''.join(n + ':' + sha(data) + '\n' for n, data in sorted(installed.items())).encode('utf-8'))[:12]
        inventory = ('CyrusScatterInstall1\t' + version + '\t' + str(args.max_year) + '\t' + content_id + '\n' +
                     ''.join(n + '\t' + sha(data) + '\t' + str(len(data)) + '\n' for n, data in sorted(installed.items()))).encode('utf-8')
        payload['InstallInventory.txt'] = inventory
        payload['install.ms'] = payload['install.ms'].replace(b'__INSTALL_HASH__', sha(inventory).encode('ascii'))
    manifest = dict(product=name, version=version, max_year=args.max_year,
                    toolset=args.tools_version, windows_sdk=args.windows_sdk,
                    configuration='Release', native_id=native_id,
                    files={n: sha(data) for n, data in sorted(payload.items())})
    if team_key:
        manifest['licensing'] = {'mode': 'offline-team', 'key_id': team_key, 'term_days': 30}
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
    parser.add_argument('--team-trust-header', type=Path, default=ROOT / 'CyrusLicensing/team/team_public_key.h')
    args = parser.parse_args()
    if not args.team_trust_header.is_file():
        raise SystemExit('Initialize the owner issuer and export its public header; see tools/licensing/README.md')
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
             '-DCYRUS_NATIVE_LICENSE_EXPERIMENT=OFF', '-DCYRUS_LICENSE_INSTALLATION_CONTEXT=OFF',
             *(['-DCYRUS_TEAM_LICENSE=ON', f'-DCYRUS_TEAM_TRUST_DIR={args.team_trust_header.resolve().parent}'] if project == 'AminScatter' else []),
             f'-DMAXSDK_ROOT={args.sdk_root.resolve()}'], env)
        run(['cmake', '--build', dest], env)
        run(['ctest', '--test-dir', dest, '--output-on-failure'], env)
        if project == 'AminScatter':
            run([sys.executable, ROOT / project / 'tools/build_installer.py', '--output', dest / 'CyrusInstaller.dll'], env)
    package('AminScatter', 'Cyrus Scatter', scatter_version(), ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh'],
            'AminScatterObject.ms', args, base)
    package('CyrusSurfaceAnalyzer', 'Cyrus Surface Analyzer', '0.14', ['CyrusSurfaceAnalyzer.dlx'],
            'CyrusSurfaceAnalyzer.ms', args, base)


if __name__ == '__main__':
    main()
