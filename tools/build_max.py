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
sys.path.insert(0, str(ROOT/'tools'))
import build_inputs


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

def verify_gallery(path, version, year):
    receipt = json.loads(path.with_suffix('.build.json').read_text(encoding='utf-8'))
    assembly_version = '.'.join(version.split('.') + ['0'] * (4-len(version.split('.'))))
    if (receipt.get('assembly_version') != assembly_version or receipt.get('max_year') != year
        or receipt.get('artifact_sha256') != sha(path.read_bytes())
        or receipt.get('source_sha256') != sha((ROOT/'AminScatter/ui/LibraryGallery.cs').read_bytes())
        or receipt.get('shared_source_sha256') != sha((ROOT/'AminScatter/shared/LibraryLocation.cs').read_bytes())):
        raise ValueError('Gallery release/host/source/artifact differs from its verified build receipt. Rebuild the gallery.')
    build_inputs.verify_managed(path, 'gallery', ROOT, (
        'AminScatter/ui/LibraryGallery.cs', 'AminScatter/shared/LibraryLocation.cs',
        'AminScatter/CMakeLists.txt', 'AminScatter/tools/build_gallery.py', 'tools/build_inputs.py'))
    return receipt


def verify_installer(path):
    return build_inputs.verify_managed(path, 'installer-core', ROOT,
        (*build_inputs.CORE_SOURCES, 'AminScatter/tools/build_installer.py', 'tools/build_inputs.py'))


def verify_native_receipt(path, project, year, binaries):
    receipt=json.loads(Path(path).read_text(encoding='utf-8'))
    expected='scatter' if project=='AminScatter' else 'analyzer'
    if (receipt.get('schema')!='cyrus.native-build/2' or receipt.get('status')!='complete'
            or receipt.get('project')!=expected or receipt.get('max_year')!=year
            or not receipt.get('clean_compilation') or receipt.get('preview_fault_lab')
            or receipt.get('placement_qualification')
            or {stage['stage'] for stage in receipt.get('stages',[])}!={'configure','build','tests'}
            or any(stage['exit_code'] for stage in receipt['stages']) or not receipt.get('compiler_dependencies')):
        raise ValueError('A complete matching version 2 native receipt is required; rebuild the selected product.')
    manifest=receipt['input_manifest']
    if receipt['input_manifest_sha256']!=build_inputs.identity(manifest):
        raise ValueError('Native input manifest identity differs.')
    build_inputs.verify_frozen(manifest,ROOT)
    if build_inputs.source_manifest(ROOT,project,receipt['source_selection'])['files']!=receipt['sources']:
        raise ValueError('Native selected source set changed after qualification.')
    for name,artifact in binaries.items():
        original=Path(receipt['build_directory'])/name
        recorded=receipt['binaries'].get(build_inputs.key(original,ROOT))
        if not recorded or recorded!=build_inputs.digest(artifact):
            raise ValueError('Native package artifact differs from its complete build receipt: '+name)
    return receipt


def reject_development_binary(filename, data, *, allow_owned_preview=False, allow_owned_placement=False):
    if allow_owned_placement:
        # Only the explicitly validated private host uses this exact marker.
        # Product packaging never supplies this allowance; other experiment or
        # licensing markers still reject below, including mixed test builds.
        marker='Cyrus Scatter NEVER SHIP native placement ownership qualification'
        found=False
        for encoding in ('ascii','utf-16le'):
            needle=marker.encode(encoding)
            if needle in data:found=True;data=data.replace(needle,b'')
        if not found:raise RuntimeError('Owned placement qualification marker is missing: '+filename)
    for marker in ('CYRUS_LICENSE_EXPERIMENT_NEVER_SHIP', 'NEVER SHIP',
                   'cyrusOwnedLabClock', 'cyrusOwnedLabActivate',
                   'cyrusOwnedLabBrushEnd', 'cyrusSignedLabInstall'):
        if marker.encode('utf-16le') in data or marker.encode('ascii') in data:
            raise RuntimeError('Refusing development licensing authority in product package: '+filename)
    if not allow_owned_preview and any('cyrusOwnedPreviewFault'.encode(encoding) in data for encoding in ('ascii','utf-16le')):
        raise RuntimeError('Refusing development preview fault injection in product package: '+filename)
    if not allow_owned_placement and any('cyrusOwnedNativeFault'.encode(encoding) in data for encoding in ('ascii','utf-16le')):
        raise RuntimeError('Refusing development native failure injection in product package: '+filename)


def require_team_authority(data, header):
    key_ids = re.findall(r'CyrusTeamKeyID\[\]="(cyrus-team-[a-f0-9]{32})"', header.read_text(encoding='utf-8'))
    if len(key_ids) != 1 or key_ids[0].encode('ascii') not in data:
        raise RuntimeError('Scatter native module does not contain the selected owner verification key')
    if not any('cyrusLicenseImport'.encode(enc) in data for enc in ('ascii', 'utf-16le')):
        raise RuntimeError('Scatter requires the native team licensing module')
    return key_ids[0]


def library_payload(folder, version, year=2027):
    """Only ship the explicitly qualified, hash-pinned example inventory."""
    inventory = json.loads((folder / 'inventory.json').read_text(encoding='utf-8'))
    if inventory.get('version') != version or inventory.get('max_year') != year or year not in (2024,2026,2027):
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
        allowed = path.suffix.lower() in ('.json', '.png', '.cspaint', '.max', '.md', '.txt')
        if path.suffix.lower() == '.cmesh':
            allowed = re.fullmatch(r'Presets/[a-f0-9]{64}/assets/[a-f0-9]{64}\.cmesh', name) is not None
        if not path.is_relative_to(folder.resolve()) or not allowed:
            raise ValueError('Unsupported bundled example: '+name)
        data = path.read_bytes();total += len(data)
        if total > 128*1024*1024 or sha(data) != expected:
            raise ValueError('Bundled example bounds/hash mismatch: '+name)
        result['Library/'+name] = data
    result['Library/inventory.json'] = (folder/'inventory.json').read_bytes()
    names = sorted(name.removeprefix('Library/') for name in result)
    result['LibraryFiles.ms'] = ('#('+','.join('@"'+name+'"' for name in names)+')\n').encode('utf-8')
    return result


def external_content_payload(folder, version, year=2027):
    """Pin a bounded sidecar; large library models stay outside the MZP/EXE."""
    folder = folder.resolve()
    manifest_path = folder / 'content-manifest.json'
    if manifest_path.stat().st_size > 1024 * 1024:
        raise ValueError('External content manifest exceeds 1 MiB.')
    raw = manifest_path.read_bytes()
    manifest = json.loads(raw.decode('utf-8'))
    content_version = manifest.get('version')
    if not isinstance(content_version,str) or not re.fullmatch(r'0\.\d{1,3}\.\d{1,3}(?:\.\d{1,3})?',content_version):
        raise ValueError('Invalid independent content revision.')
    identity = dict(format='cyrus.scatter.content', schema=1, version=content_version, max_year=year)
    if manifest.get('schema') == 2 and year in (2024,2026,2027):
        identity = dict(format='cyrus.scatter.content', schema=2, version=content_version, max_year=2024,
                        hosts={'2024':1,'2026':1,'2027':1})
    if any(manifest.get(key) != value for key, value in identity.items()):
        raise ValueError('External content version/host/schema differs.')
    files = manifest.get('files')
    if not isinstance(files, dict) or not 1 <= len(files) <= 4096:
        raise ValueError('External content requires 1-4096 declared files.')
    total, names = 0, set()
    for name, descriptor in files.items():
        parts = name.split('/')
        if (not name.startswith('Library/') or name == 'Library/content-manifest.json' or
                any(not part or part in ('.', '..') or part.rstrip(' .') != part or
                    re.search(r'[<>:"\\|?*\x00-\x1f]', part) for part in parts) or name.casefold() in names):
            raise ValueError('Unsafe/duplicate external content path: ' + name)
        names.add(name.casefold())
        size, expected = descriptor.get('bytes'), descriptor.get('sha256')
        if type(size) is not int or not 0 <= size <= 2 * 1024**3 or not isinstance(expected, str) or not re.fullmatch('[0-9a-f]{64}', expected):
            raise ValueError('Invalid external content descriptor: ' + name)
        total += size
        if total > 16 * 1024**3:
            raise ValueError('External content exceeds 16 GiB.')
        path = (folder / name).resolve()
        if not path.is_relative_to(folder) or path.stat().st_size != size:
            raise ValueError('External content path/size differs: ' + name)
        digest = hashlib.sha256()
        with path.open('rb') as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(block)
        if digest.hexdigest() != expected:
            raise ValueError('External content hash differs: ' + name)
    identity['manifest_sha256'] = sha(raw)
    relative_names = sorted(name.removeprefix('Library/') for name in files)
    relative_names.append('content-manifest.json')
    # This legacy uninstall inventory contains names only, never large payloads.
    listing = '#(' + ','.join('@"' + name + '"' for name in relative_names) + ')\n'
    return {'ExternalContent.json': (json.dumps(identity, indent=2) + '\n').encode('utf-8'),
            'LibraryFiles.ms': listing.encode('utf-8')}


def pattern_payload(folder):
    """Explicit product catalog only; task QA fixtures never enter a release."""
    index=json.loads((folder/'index.json').read_text(encoding='utf-8'))
    if index.get('format')!='cyrus.density-patterns' or index.get('version')!=1 or len(index.get('entries',[]))>128:
        raise ValueError('Unsupported density pattern catalog.')
    result={};expected=[];total=0
    for entry in index['entries']:
        name=entry['file']
        if not re.fullmatch(r'[a-z0-9][a-z0-9_-]{0,80}\.png',name):raise ValueError('Unsafe pattern filename.')
        data=(folder/name).read_bytes();total+=len(data)
        if len(data)>2*1024*1024 or total>32*1024*1024 or sha(data)!=entry['sha256'] or data[:8]!=b'\x89PNG\r\n\x1a\n':
            raise ValueError('Pattern bytes/hash/bounds differ from the catalog.')
        if 'Patterns/'+name in result:raise ValueError('Duplicate pattern filename.')
        result['Patterns/'+name]=data
        expected.append('\t'.join(entry[key] for key in ('id','name','family','file','sha256')))
    if (folder/'catalog.tsv').read_text(encoding='utf-8').splitlines()!=expected:raise ValueError('Pattern picker catalog differs from its index.')
    for name in ('index.json','catalog.tsv','README.md'):result['Patterns/'+name]=(folder/name).read_bytes()
    return result


def package(project, name, version, native_names, script_name, args, build_dir):
    if project == 'AminScatter' and version != scatter_version():
        raise ValueError('Requested Scatter version differs from generated source. Use a frozen checkout for historical versions.')
    native_receipts=getattr(args,'native_receipts',{})
    native_receipt_path=Path(native_receipts.get(project,build_dir/project/'receipt.json'))
    native_receipt=verify_native_receipt(native_receipt_path,project,args.max_year,
        {filename:build_dir/project/filename for filename in native_names})
    installer=build_dir/'AminScatter/CyrusInstaller.dll'
    installer_receipt=verify_installer(installer)
    producer_receipts={'native':{'schema':native_receipt['schema'],
        'receipt_sha256':build_inputs.digest(native_receipt_path),
        'input_manifest_sha256':native_receipt['input_manifest_sha256']},
        'installer':build_inputs.producer_link(installer,installer_receipt)}
    package_inputs=build_inputs.frozen([ROOT/'tools/build_max.py',ROOT/'tools/build_inputs.py',
        ROOT/project/'scripts'/script_name,ROOT/project/'CMakeLists.txt',native_receipt_path,
        *list((ROOT/project/'installer').iterdir()),installer,installer.with_suffix('.build.json'),
        *(build_dir/project/filename for filename in native_names)],
        {'product':project,'version':version,'max_year':args.max_year,'toolset':args.tools_version,
         'windows_sdk':args.windows_sdk,'producers':producer_receipts},ROOT)
    payload = {'CyrusInstaller.dll':installer.read_bytes()}
    for filename in native_names:
        payload[filename] = (build_dir / project / filename).read_bytes()
        reject_development_binary(filename, payload[filename])
    team_key = require_team_authority(payload['AminScatter.dlx'], args.team_trust_header) if project == 'AminScatter' else None
    native_id = sha(b''.join(payload[n] for n in sorted(native_names)))[:12]
    analyzer_script = (ROOT / project / 'scripts' / script_name).read_bytes() if project == 'CyrusSurfaceAnalyzer' else b''
    analyzer_tokens = {
        '__MAX_YEAR__': args.max_year, '__MAX_VERSION__': (args.max_year - 1998) * 1000,
        '__VERSION__': version, '__RUNTIME_ID__': sha(payload.get('CyrusSurfaceAnalyzer.dlx', b'') + analyzer_script)[:16],
        '__NATIVE_SHA256__': sha(payload.get('CyrusSurfaceAnalyzer.dlx', b'')),
        '__SCRIPT_SHA256__': sha(analyzer_script),
        '__STARTUP_SHA256__': sha((ROOT/project/'installer/CyrusSurfaceAnalyzerStartup.ms').read_text(encoding='utf-8-sig').encode('utf-8')) if project == 'CyrusSurfaceAnalyzer' else '',
        '__HELPER_SHA256__': sha(payload['CyrusInstaller.dll']),
        '__HELPER_MVID__': installer_receipt['module_version_id'],
    }
    if project=='CyrusSurfaceAnalyzer':
        descriptor=('CyrusAnalyzerPackage1\n'+str(args.max_year)+'\n'+version+'\n'+analyzer_tokens['__RUNTIME_ID__']+'\n'+
            analyzer_tokens['__NATIVE_SHA256__']+'\n'+analyzer_tokens['__SCRIPT_SHA256__']+'\n'+analyzer_tokens['__STARTUP_SHA256__']+'\n').encode('utf-8')
        payload['AnalyzerPackage.txt']=descriptor
        analyzer_tokens['__DESCRIPTOR_SHA256__']=sha(descriptor)
    for path in sorted((ROOT / project / 'installer').iterdir()):
        if path.is_file():
            text = path.read_text(encoding='utf-8-sig')
            if project == 'AminScatter':
                if path.name == 'install.ms' and '__MAX_VERSION__' not in text:
                    raise RuntimeError('Missing Scatter installer host guard')
                if path.name == 'install.ms' and any(token not in text for token in ('__HELPER_SHA256__', '__HELPER_MVID__')):
                    raise RuntimeError('Missing Scatter installer helper identity guard')
                for token, value in {'__MAX_YEAR__': args.max_year,
                                     '__MAX_VERSION__': (args.max_year - 1998) * 1000,
                                     '__HELPER_SHA256__': sha(payload['CyrusInstaller.dll']),
                                     '__HELPER_MVID__': installer_receipt['module_version_id'],
                                     '__NATIVE_ID__': native_id, '__VERSION__': version}.items():
                    text = text.replace(token, str(value))
            else:
                if path.name == 'install.ms' and '__MAX_VERSION__' not in text:
                    raise RuntimeError('Missing Analyzer installer host guard')
                for token, value in analyzer_tokens.items():
                    text = text.replace(token, str(value))
            if path.name == 'mzp.run':
                # MZP uses a numeric version; retain full SemVer in its name,
                # filename and manifest, rather than emitting 1.0.0 syntax.
                mzp_version='.'.join(version.split('.')[:2])
                text = f'name "{name} {version} for 3ds Max {args.max_year}"\nversion {mzp_version}\nrun "install.ms"\n'
            payload[path.name] = text.encode('utf-8')
    payload['CyrusScatter.ms' if project == 'AminScatter' else script_name] = (ROOT / project / 'scripts' / script_name).read_bytes()
    if project == 'AminScatter':
        gallery_path=build_dir/project/'CyrusGallery.dll'
        gallery_receipt=verify_gallery(gallery_path, version, args.max_year)
        gallery_producer=build_inputs.producer_link(gallery_path,gallery_receipt)
        if native_receipt.get('producer_receipts',{}).get('gallery')!=gallery_producer:
            raise ValueError('Gallery producer differs from the complete native build receipt.')
        producer_receipts['gallery']=gallery_producer
        payload['CyrusGallery.dll'] = (build_dir / project / 'CyrusGallery.dll').read_bytes()
        payload['Clipper2-LICENSE.txt'] = (ROOT / project / 'third_party/clipper2/LICENSE').read_bytes()
        payload['Clipper2-NOTICE.txt'] = (ROOT / project / 'third_party/clipper2/CYRUS-CHANGES.md').read_bytes()
        payload['SurfaceGeodesic-LICENSE.txt'] = (ROOT / project / 'third_party/geodesic/LICENSE').read_bytes()
        payload['SurfaceGeodesic-NOTICE.txt'] = (ROOT / project / 'third_party/geodesic/CYRUS_CHANGES.md').read_bytes()
        payload['nlohmann-json-LICENSE.txt'] = (ROOT / 'CyrusLicensing/third_party/nlohmann/LICENSE.MIT').read_bytes()
        jpeg = ROOT / project / 'third_party/libjpeg-turbo-3.2.0'
        payload['libjpeg-turbo-LICENSE.txt'] = (jpeg / 'LICENSE.md').read_bytes()
        payload['libjpeg-turbo-IJG-README.txt'] = (jpeg / 'README.ijg').read_bytes()
        payload['libjpeg-turbo-NOTICE.txt'] = (jpeg / 'CYRUS-NOTICE.txt').read_bytes()
        content_dir = getattr(args, 'content_dir', None)
        if version == '0.86.6.2' and not content_dir:
            raise ValueError('The individual-model delivery requires --content-dir; legacy bundled examples cannot be shipped in 0.86.6.2.')
        if content_dir:
            payload.update(external_content_payload(Path(content_dir), version, args.max_year))
        else:
            payload.update(library_payload(Path(getattr(args, 'library_dir', None) or ROOT / project / 'library'), version,args.max_year))
        payload.update(pattern_payload(ROOT/project/'patterns'))
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
           'Image/pattern density supports World XY, Scatter-local XY or explicit receiver UVs, physical size, repeat/clamp, rotation and offsets.\n'
           'Load image or pick a supported 2D texture output; live procedural/non-PNG maps require an explicit portable PNG snapshot before complete Save.\n'
           'Image resolution 64/128/256/512 changes detail, independently of pattern size. Numeric mesh channels are a separate density input.\n'
           'Show mask stays enabled during relevant edits; Hide mask stops it. Combined shows eligibility before spacing/count limits.\n'
           'Select one terrain mesh, then use Cyrus Library (Customize > Cyrus category), or Layers > Recipes from an existing setup.\n'
           'Load onto surface imports supported models/materials, creates a setup when needed and adds layers as one Undo. Existing layers are preserved.\n'
           'Save Recipe includes complete settings and Paint; keep Include models, materials, terrain and paths enabled for a ready preset.\n'
           'Keep each .csrecipe.json, recipe-data folder and Presets package directory together. Paint requires compatible geometry/frame/units; mesh masks require their numeric channel.\n'
           'Cyrus Library offers Plant models, personal recipes and a custom library. Model imports display success or failure feedback.\n'
           'The installer detects Max and existing content automatically. Select Max versions, then Install or Update; Uninstall retains shared content and scenes.\n'
           'To install content, place CyrusScatter-Content-0.86.7.zip beside the EXE and check Install / update plant library. Unchecked updates keep existing content. All compatible Max versions share one library.\n'
           'Library content has its own revision; a plugin patch does not require recreating it. Existing releases and old scene texture paths are retained.\n'
           'User recipes remain in Documents/CyrusScatter/Library, separate from the shared plant content.\n'
           'Unsupported authored Scatter Edit/radius overrides or nonstatic parameter controllers block Save Everything.\n'
           'Amount > Mesh channel density reads vertex colors (0) or map channels (1..99), with component, range, invert and Density curve controls.\n'
           'Use Data Channel Curvature > Vertex Output or VertexPaint to author values. White permits plants; black excludes them.\n'
           'Preview mask is an explicit cached snapshot of at most 2,048 grayscale face-centre markers; refresh after edits.\n'
           'Paint controls have short hover help for density/scale fades, edges, brush actions and feedback.\n'
           'Painting > Export spline offers Optimized and Exact independent snapshots. Optimized reduces planar boundary knots within a world-unit tolerance; original Paint remains unchanged. Attached surface exports retain Exact geometry.\n'
           'Pick spline... imports closed contours using Replace or Add and a world-unit tolerance.\n'
           'Select a layer; its Surfaces and Models are independent of other layers. Paint Areas are optional.\n'
           'Edit layers in the Scatter controller Modify panel.\n'
           'Source rectangles open compact collection properties for moving and resizing.\n'
           'Advanced options start collapsed inside each section; opening them does not regenerate placements.\n'
           'Hover controls for short explanations. Models & Points offers Pick object and Make point.\n'
           'Each layer owns models and count/density. Named Paint Areas target its receivers and combine coverage without duplicate plants.\n'
           'Population, transforms and cleanup belong to the layer. Capacity: 10 populations; area APIs bound each layer to 128 areas/receivers.\n'
           'CyrusUnified2, schema 59: existing supported schema 58 scenes require the explicit scene upgrade command; save an upgraded copy.\n'
           'Preserve old scenes with their matching build. Earlier stroke formats are not converted and have no legacy brush fallback.\n'
           'Density preserves unchanged receiver candidates below the cap. Fixed Total redistributes quotas and preserves surviving base candidates.\n'
           'Changing local Relax neighborhoods, masks, spacing or geometry can change accepted output; face IDs do not survive arbitrary remeshing.\n'
           'Spacing offers Within this layer and Between layers.\n'
           'Accepted target refills a bounded prefix. Read shortfall/round/attempt diagnostics; limits do not prove a full surface.\n'
           'Individual CS Edit plants/clones can have world-radius or multiplier overrides.\n'
           'Painting: add/select a Paint Area and its Surface, then Paint/Erase, Fill/Clear or Undo. Repeated gestures edit the same area.\n'
           'Spacing uses accepted plants and protected reservations; conflicting manual overrides are preserved and reported.\n'
           'Vector areas retain terrain painting and support spheres, boxes and manifold curved surfaces through surface-attached coverage. Degenerate/nonmanifold geometry requires repair.\n'
           'Inside/outside fade widths and independent density/scale curves operate on the final border.\n'
           'Removing a receiver keeps its area inactive; restoring the same node restores eligibility.\n'
           'Manual mode updates the mask immediately and publishes plants when Update is pressed.\n'
           'Random/Clusters, prepared spline Bands and Analyzer assignment share the same ordered pipeline.\n'
             'Spline Bands > Scale (below density): Off, Follow Density, or Custom with Edit scale curve.\n'
             'The profile multiplies Band Min/Max size; Follow Density links the curve shape, not Density %.\n'
           'Bands have stable identities, Consecutive/Independent ranges, Rounded/Sharp corners, density curves and display colors.\n'
           'Dense Bands admit up to 8,192 total sampled vertices under bounded construction, query and outline work. Complex overlaps may still reach a separate limit; failed successors retain the last complete result.\n'
           'Models & Points > Source access: Select sources keeps visibility; Show/Hide sources preserves renderable flags; Edit material opens the assigned scene material in Slate. Shared instances change together.\n'
           'Manual field previews can show pending inputs while plants and radii remain from the last Update.\n'
           'Auto Radius uses conservative XY/3D bounds for explicitly supported source types; other source types retain Manual radius.\n'
           'Point and constrained boundary Relax prepare ordinary candidates before eligibility and protected Edit.\n'
           'Source containers are labelled helpers. Create/Pick selects an own pool automatically.\n'
           'Select the Scatter controller for planting settings; parked sources retain their metadata.\n'
           'Count supports 1,000,000 per population within a shared 1,000,000 controller candidate budget, including retries.\n'
           '0.86.0 keeps placement generation, masks, Edit, acceptance and output ownership in native storage.\n'
           'Sparse Edit Undo shares unchanged authored blocks; large edits still need proportional memory.\n'
           'System-memory admission and the existing candidate cap still apply. Failed updates retain the previous complete result and Undo.\n'
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
           'Surface Analyzer 0.14.2 is independently installed; this Scatter package does not change it.\n'
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
        # Max itself extracts an MZP before our managed core runs. Keep archive
        # names short even when that host has legacy .NET path behavior.
        source_names = {}
        for index, (n, data) in enumerate(sorted(installed.items())):
            source_names[n] = f'p/{index:04d}{Path(n).suffix.lower()}' if n.startswith('Library/') else n
            if source_names[n] != n:
                del payload[n]
                payload[source_names[n]] = data
        inventory = ('CyrusScatterInstall2\t' + version + '\t' + str(args.max_year) + '\t' + content_id + '\n' +
                     ''.join(n + '\t' + sha(data) + '\t' + str(len(data)) + '\t' + source_names[n] + '\n' for n, data in sorted(installed.items()))).encode('utf-8')
        payload['InstallInventory.txt'] = inventory
        payload['install.ms'] = payload['install.ms'].replace(b'__INSTALL_HASH__', sha(inventory).encode('ascii'))
    manifest = dict(product=name, version=version, max_year=args.max_year,
                    toolset=args.tools_version, windows_sdk=args.windows_sdk,
                    configuration='Release', native_id=native_id,
                    files={n: sha(data) for n, data in sorted(payload.items())},
                    build_evidence_schema='cyrus.package-inputs/2',producer_receipts=producer_receipts,
                    package_inputs_sha256=build_inputs.identity(package_inputs))
    if team_key:
        manifest['licensing'] = {'mode': 'offline-team', 'key_id': team_key, 'term_days': 30}
    payload['manifest.json'] = (json.dumps(manifest, indent=2) + '\n').encode('utf-8')
    args.output.mkdir(parents=True, exist_ok=True)
    target = args.output / f'{name.replace(" ", "")}-{version}-Max{args.max_year}.mzp'
    target.with_suffix('.build.json').write_text(json.dumps({'schema':'cyrus.package-build/2','status':'pending'})+'\n',encoding='utf-8')
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
    build_inputs.verify_frozen(package_inputs,ROOT)
    verify_installer(installer)
    if project=='AminScatter':verify_gallery(gallery_path,version,args.max_year)
    target.with_suffix('.build.json').write_text(json.dumps({'schema':'cyrus.package-build/2','status':'complete',
        'artifact_sha256':build_inputs.digest(target),'input_manifest':package_inputs,
        'input_manifest_sha256':build_inputs.identity(package_inputs),'producer_receipts':producer_receipts},indent=2)+'\n',encoding='utf-8')
    target.with_suffix('.sha256').write_text(sha(target.read_bytes()) + '  ' + target.name + '\n')
    print(f'Package: {target}', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--max-year', type=int, choices=(2024, 2026, 2027), required=True)
    parser.add_argument('--sdk-root', type=Path, required=True)
    parser.add_argument('--vs-root', type=Path, default=Path('C:/Program Files/Microsoft Visual Studio/2022/Community'))
    parser.add_argument('--tools-version', default='14.38.33130')
    parser.add_argument('--windows-sdk', default='10.0.19041.0')
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    parser.add_argument('--content-dir', type=Path, help='Hash-pinned Content sidecar; replaces embedded legacy library examples')
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
        run([sys.executable,ROOT/'tools/procedural_lab/offline_build.py','--project',
             'scatter' if project=='AminScatter' else 'analyzer','--year',args.max_year,
             '--output',dest,'--sdk-root',args.sdk_root,'--vs-root',args.vs_root,
             '--tools-version',args.tools_version,'--windows-sdk',args.windows_sdk,
             '--team-trust-header',args.team_trust_header],env)
        if project == 'AminScatter':
            run([sys.executable, ROOT / project / 'tools/build_installer.py', '--output', dest / 'CyrusInstaller.dll'], env)
    package('AminScatter', 'Cyrus Scatter', scatter_version(), ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh'],
            'AminScatterObject.ms', args, base)
    package('CyrusSurfaceAnalyzer', 'Cyrus Surface Analyzer', '0.14.2', ['CyrusSurfaceAnalyzer.dlx'],
            'CyrusSurfaceAnalyzer.ms', args, base)


if __name__ == '__main__':
    main()
