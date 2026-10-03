"""Curate only the 1.0.1 patch campaign; preserve the frozen v1.0.0 evidence."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import zipfile
from build import ROOT, BASE
from collect_evidence import check_public


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--product-run', default='v101-installed')
    parser.add_argument('--installer-run', default='v101-relax-reset')
    parser.add_argument('--reopen-run', default='v101-reopen')
    args = parser.parse_args()
    evidence = ROOT / 'docs/Brush_Relax_Reset_2026-10-03/evidence'
    evidence.mkdir(exist_ok=True)
    records = []

    def host(run):
        path = (BASE / 'hosts' / run).resolve()
        if path.parent != (BASE / 'hosts').resolve():
            raise ValueError('Expected one private run directory')
        return path

    def collect(source, name):
        data = source.read_bytes()
        check_public(json.loads(data))
        (evidence / name).write_bytes(data)
        records.append(dict(file=name, source=source.relative_to(ROOT).as_posix(),
                            sha256=digest(data), bytes=len(data)))

    product, installer, reopen = (host(run) for run in (args.product_run, args.installer_run, args.reopen_run))
    identity = json.loads((product / 'loaded-identity.json').read_text())
    clicks = json.loads((product / 'native-reset-clicks.json').read_text())
    restored = json.loads((reopen / 'patch-reopen.json').read_text())
    if identity['script_version'] != '1.0.1' or clicks['actual_mouse_click_groups'] != [1, 2, 3, 4]:
        raise ValueError('Expected installed 1.0.1 and all four actual button checks')
    if restored['script_version'] != '1.0.1' or restored['preview_error'] or not restored['saved_settings_preserved']:
        raise ValueError('Reopen did not restore the paused layer')
    for name in ('brush-relax-patch.json', 'random-reset-patch.json', 'native-reset-clicks.json',
                 'patch-save.json', 'loaded-identity.json', 'native-v1-fixture.json', 'brush-acceptance.json',
                 'cache-copy-acceptance.json', 'curved-edit-acceptance.json', 'output-restore-prepared.json'):
        collect(product / name, name)
    collect(installer / 'installation-verified.json', 'installation-verified.json')
    collect(reopen / 'patch-reopen.json', 'patch-reopen.json')
    collect(reopen / 'loaded-identity.json', 'reopen-loaded-identity.json')
    python_log = BASE / 'v101-python-tests.log'
    python_data = python_log.read_bytes()
    if '62 passed' not in python_data.decode('utf-8'):
        raise ValueError('No passing patch Python test log')
    (evidence / 'python-tests.log').write_bytes(python_data)
    records.append(dict(file='python-tests.log', source=python_log.relative_to(ROOT).as_posix(),
                        sha256=digest(python_data), bytes=len(python_data)))
    packages = []
    source_script = digest((ROOT / 'AminScatter/scripts/AminScatterObject.ms').read_bytes())
    for year in (2026, 2027):
        path = ROOT / f'dist/v1/CyrusScatter-1.0.1-Max{year}.mzp'
        baseline = json.loads((ROOT / f'docs/Cyrus_Scatter_V1_2026-10-03/evidence/package-max{year}.json').read_text())
        with zipfile.ZipFile(path) as archive:
            manifest = json.loads(archive.read('manifest.json'))
            if archive.testzip() is not None or manifest['version'] != '1.0.1':
                raise ValueError('Invalid patch installer')
            for name, expected in manifest['files'].items():
                if digest(archive.read(name)) != expected:
                    raise ValueError('Package payload differs: ' + name)
            if manifest['files']['CyrusScatter.ms'] != source_script:
                raise ValueError('Package script differs from generated source')
            for name in ('AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh'):
                if manifest['files'][name] != baseline['files'][name]:
                    raise ValueError('Native binary changed from the qualified v1 baseline: ' + name)
            data = (json.dumps(manifest, indent=2) + '\n').encode()
            name = f'package-max{year}.json'
            (evidence / name).write_bytes(data)
            records.append(dict(file=name, source=path.relative_to(ROOT).as_posix() + ':manifest.json',
                                sha256=digest(data), bytes=len(data)))
        packages.append(dict(file=path.relative_to(ROOT).as_posix(), max_year=year,
                             sha256=digest(path.read_bytes()), native_binaries_unchanged=True))
    verified = json.loads((installer / 'installation-verified.json').read_text())
    if not verified.get('clean_startup') or verified['package_sha256'] != packages[1]['sha256']:
        raise ValueError('No verified clean startup from the current installer')
    sources = {}
    for folder in ('AminScatter/include', 'AminScatter/src', 'AminScatter/scripts', 'AminScatter/tools/ui',
                   'AminScatter/installer', 'tools/v1'):
        for path in sorted((ROOT / folder).rglob('*')):
            if path.is_file() and path.suffix in {'.h', '.cpp', '.inc', '.rc', '.def', '.ms', '.cjs', '.py', '.run', '.mcr'}:
                sources[path.relative_to(ROOT).as_posix()] = digest(path.read_bytes().replace(b'\r\n', b'\n'))
    sources['tools/build_max.py'] = digest((ROOT / 'tools/build_max.py').read_bytes().replace(b'\r\n', b'\n'))
    manifest = dict(version='1.0.1', date='2026-10-03', baseline_commit='c78c349e48d87028d4793db8e37cc0f6649665d6',
                    working_branch=subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT, text=True).strip(),
                    source_hash_encoding='SHA-256 with CRLF normalized to LF; source snapshot before patch commit',
                    source_files=sources, packages=packages, evidence=records,
                    qualification_scope='Max 2027 installed startup, broad v1 fixtures, focused patch fixtures, four actual mouse clicks/Undo and fresh-process save/reopen. Max 2026 package bytes/native baseline verified; no Max 2026 host test.',
                    native_test_scope='No C++ changes or new native-suite run. Both SDK binaries exactly match the v1 baseline that passed all 11 suites per SDK.')
    (evidence / 'MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Curated {len(records)} patch records; both packages and unchanged native binaries verified.')


if __name__ == '__main__':
    main()
