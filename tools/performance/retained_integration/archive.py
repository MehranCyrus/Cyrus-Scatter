"""Archive curated integration evidence; preserve bytes and verify the package chain."""
import argparse
import hashlib
import json
import shutil
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / 'build/retained-integration-2026-10-02'
DEST = ROOT / 'docs/Retained_Point_Preview_2026-10-02/evidence'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def verify():
    manifest = read(DEST / 'manifest.json')
    for record in manifest['files']:
        path = (DEST / record['path']).resolve()
        if not path.is_relative_to(DEST.resolve()):
            raise SystemExit('Invalid archive path')
        if path.stat().st_size != record['bytes'] or digest(path) != record['sha256']:
            raise SystemExit(f'Archive mismatch: {path}')
    print(f"Verified {len(manifest['files'])} archived files")


def archive(run_name):
    run = (BASE / run_name).resolve()
    if run.parent != BASE.resolve():
        raise SystemExit('Run must be a direct child of the private build directory')
    if DEST.exists():
        raise SystemExit('Archive already exists; verify it rather than overwriting evidence')
    closure = read(run / 'closure.json')
    if not closure['private_process_exited'] or not closure['original_scene_unchanged']:
        raise SystemExit('Missing successful closure/preservation check')
    for required in ['lifecycle.json', 'hardening.json', 'manual-navigation.json',
                     'artist-maximized-trials.json', 'shutdown.json']:
        read(run / required)

    packages = read(BASE / 'packages.json')
    embedded = {}
    for record in packages:
        path = Path(record['package'])
        if digest(path) != record['sha256']:
            raise SystemExit(f'Package identity mismatch: {path}')
        with zipfile.ZipFile(path) as z:
            if z.testzip() is not None:
                raise SystemExit(f'Corrupt package: {path}')
            manifest = json.loads(z.read('manifest.json'))
            for name, expected in manifest['files'].items():
                if hashlib.sha256(z.read(name)).hexdigest() != expected:
                    raise SystemExit(f'Embedded file mismatch: {path} / {name}')
            for name in ['AminScatter.dlx', 'CyrusScatterEdit.dlm']:
                expected = manifest['files'][name]
                if digest(BASE / f"max{record['year']}" / name) != expected:
                    raise SystemExit(f'Current build mismatch: {name}')
                if record['year'] == 2027 and digest(run / 'bin' / name) != expected:
                    raise SystemExit(f'Interactive-tested binary mismatch: {name}')
            script_hash = manifest['files']['AminScatterObject.ms']
            if digest(run / 'AminScatterObject.ms') != script_hash or digest(ROOT / 'AminScatter/scripts/AminScatterObject.ms') != script_hash:
                raise SystemExit('Current/tested/packaged scripts differ')
            embedded[f"max{record['year']}-manifest.json"] = manifest

    DEST.mkdir(parents=True)
    records = []

    def copy(source, relative):
        target = DEST / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        records.append({'path': target.relative_to(DEST).as_posix(),
                        'source': source.relative_to(ROOT).as_posix(),
                        'bytes': target.stat().st_size, 'sha256': digest(target)})

    def write(relative, value):
        target = DEST / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')
        records.append({'path': relative, 'source': 'generated archive metadata',
                        'bytes': target.stat().st_size, 'sha256': digest(target)})

    for source in sorted(run.iterdir()):
        if source.suffix in {'.json', '.csv', '.png'} or source.name.startswith('recipe-') and source.suffix == '.ms':
            copy(source, f'{run_name}/{source.name}')
    copy(run / 'AminScatterObject.ms', 'tested-script/AminScatterObject.ms')
    for year in [2026, 2027]:
        for name in ['build-0.log', 'build-1.log', 'build-2.log', 'identity.json']:
            copy(BASE / f'max{year}' / name, f'builds/max{year}/{name}')
        copy(ROOT / f'build/max{year}-release/CyrusSurfaceAnalyzer/Testing/Temporary/LastTest.log',
             f'builds/max{year}/analyzer-LastTest.log')
    for source in sorted(Path(__file__).parent.iterdir()):
        if source.suffix in {'.py', '.ms', '.md'}:
            copy(source, f'harness/{source.name}')
    changed_sources = [
        'AminScatter/CMakeLists.txt', 'AminScatter/include/point_preview.h',
        'AminScatter/include/preview_sampling.h', 'AminScatter/src/point_display.cpp',
        'AminScatter/src/preview.cpp', 'AminScatter/src/edit_plugin.cpp',
        'AminScatter/src/max_bridge.cpp', 'AminScatter/tests/preview_sampling_tests.cpp',
        'AminScatter/tools/ui/generate.cjs', 'AminScatter/tools/ui/retained-points.cjs',
        'tools/build_max.py',
    ]
    for relative in changed_sources:
        copy(ROOT / relative, f'source/{relative}')
    copy(BASE / 'packages.json', 'packages.json')
    for name, manifest in embedded.items():
        write('packages/' + name, manifest)
    write('source-state.json', {
        'base_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'scope': 'Uncommitted retained-point candidate source, plus exact tested generated script. Other concurrent work is excluded.',
        'source_hashes': {relative: digest(ROOT / relative) for relative in changed_sources},
        'binary_script_package_chain_verified': True,
    })
    (DEST / 'manifest.json').write_text(json.dumps({'schema': 1, 'run': run_name,
        'files': sorted(records, key=lambda r: r['path'])}, indent=2) + '\n', encoding='utf-8')
    verify()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--run', default='run04')
    parser.add_argument('--verify', action='store_true')
    args = parser.parse_args()
    if args.verify:
        verify()
    else:
        archive(args.run)
