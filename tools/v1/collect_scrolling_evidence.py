"""Curate 1.2.3 gesture results and verify the tested/packaged native bytes."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/cyrus-v1'
DEST = ROOT / 'docs/Classic_Layout_2026-10-04/evidence/scrolling-1.2.3'
VERSION = '1.2.3'
NATIVE = ('AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def require(value, message):
    if not value:
        raise RuntimeError(message)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', default='classic-layout-scroll-release-20261004')
    args = parser.parse_args()
    host = (BASE / 'hosts' / args.run).resolve()
    require(host.parent == (BASE / 'hosts').resolve() and host.name.startswith('classic-layout-scroll-'),
            'Expected one private scrolling profile')
    identity = json.loads((host / 'loaded-identity.json').read_text())
    require(identity['script_version'] == VERSION, 'Wrong loaded script revision')
    loaded = {name: Path(path) for name, path in identity['modules']}
    require(set(loaded) == set(NATIVE), 'Wrong native module set')
    require(all(path.parent == host / 'bin' for path in loaded.values()), 'Unexpected loaded native path')

    results = ['scroll-wheel-down.json', 'scroll-drag-down.json', 'scroll-drag-up.json',
               'scroll-wheel-header.json', 'scroll-header-click.json', 'scroll-drag-after-lifecycle.json']
    for name in results:
        result = json.loads((host / name).read_text())
        require(result['passed'] and result['version'] == VERSION, 'Failed gesture: ' + name)
    layout = json.loads((host / 'classic-layout-acceptance.json').read_text())
    require(layout['version'] == VERSION and layout['retained_controls_and_caches'], 'Failed layout check')
    manager = json.loads((host / 'classic-manager-acceptance.json').read_text())
    require(manager['version'] == VERSION and all(value is True for key, value in manager.items() if key != 'version'),
            'Failed manager lifecycle check')

    sources = ['AminScatter/CMakeLists.txt', 'AminScatter/src/rollout_scroll.cpp',
               'AminScatter/scripts/AminScatterObject.ms', 'AminScatter/tools/ui/layers-first.cjs',
               'AminScatter/tools/ui/templates/layers-first-host.ms',
               'AminScatter/tools/ui/templates/layers-first-panel.ms', 'tools/v1/scrolling_prepare.ms',
               'tools/v1/collect_scrolling_evidence.py', 'tools/v1/package.py', 'tools/build_max.py']
    manifest = dict(version=VERSION, run=host.name, host=identity['host'],
                    source_sha256={name: sha((ROOT / name).read_bytes()) for name in sources}, packages={})
    DEST.mkdir(parents=True, exist_ok=True)
    script_hash = sha((ROOT / 'AminScatter/scripts/AminScatterObject.ms').read_bytes())
    for year in (2026, 2027):
        package = ROOT / f'dist/classic-layout-{VERSION}/CyrusScatter-{VERSION}-Max{year}.mzp'
        with zipfile.ZipFile(package) as archive:
            metadata = json.loads(archive.read('manifest.json'))
            require(metadata['version'] == VERSION and metadata['max_year'] == year, 'Wrong package identity')
            require(archive.testzip() is None, 'Invalid package ZIP')
            for name, expected in metadata['files'].items():
                require(sha(archive.read(name)) == expected, 'Invalid package member: ' + name)
            require(metadata['files']['CyrusScatter.ms'] == script_hash, 'Package script differs from qualified source')
            for name in NATIVE:
                expected = metadata['files'][name]
                require(sha((BASE / f'max{year}' / name).read_bytes()) == expected, 'Native build/package mismatch')
                if year == 2027:
                    require(sha(loaded[name].read_bytes()) == expected, 'Loaded/package native mismatch')
            (DEST / f'package-max{year}.json').write_text(json.dumps(metadata, indent=2) + '\n')
        tests = BASE / f'max{year}/build-2.log'
        require('100% tests passed, 0 tests failed out of 12' in tests.read_text(), 'Native suites did not pass')
        shutil.copy2(tests, DEST / f'native-tests-max{year}.txt')
        manifest['packages'][str(year)] = dict(file=package.relative_to(ROOT).as_posix(),
                                               sha256=sha(package.read_bytes()),
                                               native_suites_passed=12, runtime_gestures_tested=(year == 2027))
    results += ['scroll-prepared.json', 'loaded-identity.json', 'classic-layout-acceptance.json',
                'classic-manager-acceptance.json', 'layout-check.ms']
    for name in results:
        shutil.copy2(host / name, DEST / name)
    manifest['evidence_sha256'] = {path.name: sha(path.read_bytes()) for path in sorted(DEST.iterdir())
                                  if path.is_file() and path.name != 'MANIFEST.json'}
    (DEST / 'MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Verified both packages, Max 2027 loaded binaries, six gestures, layout/lifecycle and 24 native suites.')


if __name__ == '__main__':
    main()
