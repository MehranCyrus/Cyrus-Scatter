"""Curate 1.1 assertions and identities; never copy binaries, scenes or secrets."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import zipfile
import xml.etree.ElementTree as ET
from build import ROOT, BASE


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def private(value):
    path = value.resolve()
    if not path.is_relative_to(BASE / 'hosts') or not (path / 'launch.json').is_file():
        raise ValueError('Expected a disposable Max profile')
    return path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--profile', type=Path, required=True)
    parser.add_argument('--install', type=Path, required=True)
    parser.add_argument('--legacy', type=Path, required=True)
    args = parser.parse_args()
    profile, install, legacy = map(private, (args.profile, args.install, args.legacy))
    out = ROOT / 'docs/Planting_Groups_2026-10-03/evidence'
    out.mkdir(parents=True, exist_ok=True)
    records = {}

    def copy(path, name):
        destination = out / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        records[name] = dict(source=path.relative_to(ROOT).as_posix(), sha256=sha(destination))

    for name in ('planting-groups-acceptance.json', 'planting-output-acceptance.json',
                 'planting-advanced-acceptance.json', 'groups-reopen-acceptance.json',
                 'native-v1-fixture.json', 'navigation-acceptance.json',
                 'render-acceptance.json', 'groups-ui-gesture.json',
                 'groups-demo.json', 'loaded-identity.json'):
        json.loads((profile / name).read_text())
        copy(profile / name, name)
    copy(install / 'installation-verified.json', 'installation-verified.json')
    copy(install / 'uninstall-acceptance.json', 'uninstall-acceptance.json')
    verified = json.loads((install / 'installation-verified.json').read_text())
    if not verified.get('clean_startup') or verified['version'] != '1.1.0':
        raise ValueError('Missing verified 1.1 installed startup')
    copy(legacy / 'planting-legacy-acceptance.json', 'planting-legacy-acceptance.json')
    for name in ('group-manager.png', 'paint-coverage.png'):
        copy(profile / 'screenshots' / name, 'screenshots/' + name)

    xml = BASE / 'groups-python-tests.xml'
    suites = ET.parse(xml).getroot().findall('testsuite')
    if sum(int(s.get('tests', 0)) for s in suites) != 62 or any(int(s.get(k, 0)) for s in suites for k in ('failures', 'errors')):
        raise ValueError('Python regression did not pass')
    copy(xml, 'python-tests.xml')
    package_records = {}
    for year in (2026, 2027):
        native = BASE / f'max{year}'
        tests = (native / 'build-2.log').read_text()
        if '100% tests passed, 0 tests failed out of 12' not in tests:
            raise ValueError(f'Incomplete native test results for {year}')
        for name in ('build-0.log', 'build-1.log', 'build-2.log', 'identity.json'):
            copy(native / name, f'max{year}/{name}')
        package = ROOT / f'dist/v1/CyrusScatter-1.1.0-Max{year}.mzp'
        with zipfile.ZipFile(package) as archive:
            manifest = json.loads(archive.read('manifest.json'))
            for name, digest in manifest['files'].items():
                if hashlib.sha256(archive.read(name)).hexdigest() != digest:
                    raise ValueError('Package payload mismatch: ' + name)
            for name in ('AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh'):
                if sha(native / name) != manifest['files'][name]:
                    raise ValueError('Packaged native differs from tested build: ' + name)
            if sha(ROOT / 'AminScatter/scripts/AminScatterObject.ms') != manifest['files']['CyrusScatter.ms']:
                raise ValueError('Packaged script differs from source')
            (out / f'max{year}/package-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        package_records[str(year)] = dict(sha256=sha(package), native_id=manifest['native_id'])
    if package_records['2027']['sha256'] != verified['package_sha256']:
        raise ValueError('The current package was not the verified installation')

    sources = subprocess.check_output(['git', 'ls-files', '-co', '--exclude-standard',
                                      'AminScatter', 'tools/v1', 'tools/build_max.py'], cwd=ROOT, text=True).splitlines()
    source_hashes = {p: sha(ROOT / p) for p in sorted(set(sources)) if (ROOT / p).is_file()}
    demo = profile / 'Cyrus_Scatter_1.1_Plant_Groups_Demo.max'
    manifest = dict(version='1.1.0', recorded_date='2026-10-03',
                    source_base_commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                    source_files_sha256=source_hashes, results=records, packages=package_records,
                    demo_sha256=sha(demo), demo_format='Max 2027',
                    limits=['Max 2026 SDK/native only', 'Navigation steps are not presented FPS',
                            'Scanline synthetic render only; other renderers need qualification'])
    (out / 'MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Curated {len(records)} evidence files, {len(source_hashes)} source identities, both MZPs')


if __name__ == '__main__':
    main()
