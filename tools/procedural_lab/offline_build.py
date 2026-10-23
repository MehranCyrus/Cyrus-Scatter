"""Build/test into an owned directory with frozen inputs. Never starts Max."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
import build_inputs


def source_hashes(project, options=None):
    return build_inputs.source_manifest(ROOT, project, options)['files']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--year', type=int, choices=(2024, 2026, 2027))
    parser.add_argument('--project', choices=('scatter', 'analyzer'), default='scatter')
    parser.add_argument('--generator', choices=('NMake Makefiles', 'Ninja'), default='NMake Makefiles')
    parser.add_argument('--jobs', type=int, choices=range(1, 5), default=1)
    parser.add_argument('--preview-fault-lab', action='store_true', help='NEVER SHIP: isolated Scatter SDK preview faults')
    parser.add_argument('--placement-qualification', action='store_true', help='NEVER SHIP: isolated placement/Undo probes')
    parser.add_argument('--sdk-root', type=Path)
    parser.add_argument('--team-trust-header', type=Path, default=ROOT/'CyrusLicensing/team/team_public_key.h')
    parser.add_argument('--vs-root', type=Path, default=Path('C:/Program Files/Microsoft Visual Studio/2022/Community'))
    parser.add_argument('--tools-version', default='14.38.33130')
    parser.add_argument('--windows-sdk', default='10.0.19041.0')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.jobs > 1 and args.generator != 'Ninja':
        parser.error('Parallel qualification builds require --generator Ninja')
    if args.preview_fault_lab and (args.project != 'scatter' or not args.year):
        parser.error('Preview fault qualification requires a Scatter SDK build')
    if args.placement_qualification and (args.project != 'scatter' or args.year != 2027 or args.preview_fault_lab):
        parser.error('Placement qualification requires a separate Max 2027 Scatter SDK build')
    spec = importlib.util.spec_from_file_location('build_max', ROOT/'tools/build_max.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    env = module.compiler_environment(args.vs_root, args.tools_version, args.windows_sdk)
    folder = args.output.resolve() if args.output else ROOT/'build/offline-implementation-20261005'/(f'max{args.year}' if args.year else 'core')
    folder.mkdir(parents=True, exist_ok=True)
    project = 'AminScatter' if args.project == 'scatter' else 'CyrusSurfaceAnalyzer'
    options = {'max_year': args.year, 'generator': args.generator, 'configuration': 'Release',
               'build_testing': True, 'team_license': bool(args.year and args.project == 'scatter'),
               'team_trust_header': str(args.team_trust_header.resolve()),
               'preview_fault_lab': args.preview_fault_lab, 'placement_qualification': args.placement_qualification}
    pending = {'schema': 'cyrus.native-build/2', 'status': 'pending', 'project': args.project, 'max_year': args.year}
    (folder/'receipt.json').write_text(json.dumps(pending)+'\n', encoding='utf-8')
    initial = build_inputs.source_manifest(ROOT, project, options)
    enable_flag = 'AMIN_BUILD_MAX' if args.project == 'scatter' else 'CYRUS_ANALYZER_BUILD_MAX'
    command = ['cmake', '-S', str(ROOT/project), '-B', str(folder), '-G', args.generator,
               '-DCMAKE_BUILD_TYPE=Release', '-DBUILD_TESTING=ON', f'-D{enable_flag}='+('ON' if args.year else 'OFF'),
               '-DCYRUS_NATIVE_LICENSE_EXPERIMENT=OFF', '-DCYRUS_LICENSE_INSTALLATION_CONTEXT=OFF']
    if args.project == 'scatter':
        command += ['-DCYRUS_PREVIEW_TEST_FAULTS='+('ON' if args.preview_fault_lab else 'OFF'),
                    '-DCYRUS_PLACEMENT_QUALIFICATION='+('ON' if args.placement_qualification else 'OFF')]
        if args.year:
            command += ['-DCYRUS_TEAM_LICENSE=ON', '-DCYRUS_TEAM_TRUST_DIR='+str(args.team_trust_header.resolve().parent)]
    if args.year:
        sdk = args.sdk_root.resolve() if args.sdk_root else ROOT/f'build/tooling/max{args.year}-sdk/Program Files/Autodesk/3ds Max {args.year} SDK/maxsdk'
        command += [f'-DCYRUS_MAX_YEAR={args.year}', f'-DMAXSDK_ROOT={sdk}']
    build_command = ['cmake', '--build', str(folder), '--clean-first']
    if args.jobs > 1:
        build_command += ['--parallel', str(args.jobs)]
    results = []

    def stage(name, cmd):
        result = subprocess.run(cmd, cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (folder/f'{name}.log').write_text(result.stdout, encoding='utf-8')
        results.append({'stage': name, 'exit_code': result.returncode, 'command': list(map(str, cmd))})
        print(f'{name}: {result.returncode}', flush=True)
        if result.returncode or name == 'tests':
            print(result.stdout[-18000:], flush=True)
        if result.returncode:
            raise SystemExit(result.returncode)

    build_inputs.query_cmake(folder)
    stage('configure', command)
    if build_inputs.source_manifest(ROOT, project, options) != initial:
        raise SystemExit('Inputs changed during configuration; receipt remains pending.')
    frozen = build_inputs.native_manifest(ROOT, project, folder, env, options)
    (folder/'inputs-before.json').write_text(json.dumps(frozen, indent=2)+'\n', encoding='utf-8')
    stage('build', build_command)
    stage('tests', ['ctest', '--test-dir', str(folder), '--output-on-failure', '-j', '1'])
    if build_inputs.source_manifest(ROOT, project, options) != initial:
        raise SystemExit('Selected sources changed during build/tests; receipt remains pending.')
    if build_inputs.native_manifest(ROOT, project, folder, env, options) != frozen:
        raise SystemExit('Effective configuration or build inputs changed; receipt remains pending.')
    audit = build_inputs.audit_dependencies(ROOT, folder, frozen, env)
    binary_suffixes = {'.dlx', '.dlm', '.dlh', '.dlu', '.dll', '.exe', '.lib'}
    binaries = build_inputs.snapshot([p for p in folder.rglob('*') if p.is_file() and p.suffix.lower() in binary_suffixes], ROOT)
    producers = {}
    if args.project == 'scatter' and args.year:
        gallery = folder/'CyrusGallery.dll'
        receipt = module.verify_gallery(gallery, module.scatter_version(), args.year)
        producers['gallery'] = build_inputs.producer_link(gallery, receipt)
    build_inputs.verify_frozen(frozen, ROOT)
    if build_inputs.source_manifest(ROOT, project, options) != initial:
        raise SystemExit('Inputs changed before sealing; receipt remains pending.')
    complete = {**pending, 'status': 'complete', 'stages': results, 'build_directory': str(folder),
        'host_launched': False, 'installed': False, 'clean_compilation': True, 'generator': args.generator,
        'build_jobs': args.jobs, 'binaries': binaries, 'sources': initial['files'], 'source_selection': options,
        'input_manifest': frozen, 'input_manifest_sha256': build_inputs.identity(frozen),
        'producer_receipts': producers, **audit,
        'preview_fault_lab': args.preview_fault_lab, 'placement_qualification': args.placement_qualification,
        'qualification': 'SDK compilation and native executables only; generated MAXScript is hashed, not compiled by Max.'}
    (folder/'receipt.json').write_text(json.dumps(complete, indent=2)+'\n', encoding='utf-8')


if __name__ == '__main__':
    main()
