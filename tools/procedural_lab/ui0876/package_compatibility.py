"""Add the requested 2024/2026 packages without replacing qualified 2027 bytes.

Compile older SDKs separately with offline_build.py --build-only first. This
command packages and inspects resources; it never launches Max or the installer.
"""
from argparse import ArgumentParser, Namespace
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / 'tools'), str(ROOT / 'AminScatter/tools')]
import build_max
import build_installer

VERSION = '0.87.6'
NAMES = ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh']
QUALIFIED = ROOT / 'build/ui0876-20261028-01/final/packages/CyrusScatter-0.87.6-Max2027.mzp'
QUALIFIED_SHA = '0dd193dc54accf658fad54ce339a1e00a7b401e2621f4f3c51c602bac2547a89'
PRODUCER_2027 = ROOT / 'build/ui0876-20261028-01/final/native-2027'
CORE = ROOT / 'build/ui0876-20261028-01/package-01/AminScatter/CyrusInstaller.dll'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--run', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    run, output = args.run.resolve(), args.output.resolve()
    assert run.is_relative_to(ROOT / 'build') and output.is_relative_to(ROOT / 'dist')
    assert build_max.scatter_version() == VERSION and sha(QUALIFIED) == QUALIFIED_SHA
    build_installer.verify_core(CORE)
    output.mkdir(parents=True, exist_ok=False)
    packages, builds = [], {}
    for year in (2024, 2026, 2027):
        native = PRODUCER_2027 if year == 2027 else run / f'native-{year}'
        receipt_path = native / 'receipt.json'
        receipt = build_max.verify_native_receipt(
            receipt_path, 'AminScatter', year, {name: native / name for name in NAMES})
        assert receipt['tests_run'] is False and receipt['source_selection']['build_testing'] is False
        package = output / f'CyrusScatter-{VERSION}-Max{year}.mzp'
        if year == 2027:
            shutil.copy2(QUALIFIED, package)
            shutil.copy2(QUALIFIED.with_suffix('.build.json'), package.with_suffix('.build.json'))
        else:
            stage = run / f'package-{year}' / 'AminScatter'
            stage.mkdir(parents=True, exist_ok=False)
            for name in NAMES + ['CyrusGallery.dll', 'CyrusGallery.build.json']:
                shutil.copy2(native / name, stage / name)
            for name in ('CyrusInstaller.dll', 'CyrusInstaller.build.json'):
                shutil.copy2(CORE.parent / name, stage / name)
            settings = Namespace(
                max_year=year, tools_version='14.38.33130', windows_sdk='10.0.19041.0', output=output,
                team_trust_header=ROOT / 'CyrusLicensing/team/team_public_key.h',
                content_dir=ROOT / 'dist/CyrusScatter-0.86.7-20261020/Content',
                native_receipts={'AminScatter': receipt_path})
            build_max.package('AminScatter', 'Cyrus Scatter', VERSION, NAMES,
                              'AminScatterObject.ms', settings, stage.parent)
        with zipfile.ZipFile(package) as archive:
            assert archive.testzip() is None
            manifest = json.loads(archive.read('manifest.json'))
            assert manifest['version'] == VERSION and manifest['max_year'] == year
            assert set(archive.namelist()) == set(manifest['files']) | {'manifest.json'}
            for name, digest in manifest['files'].items():
                assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
            guard = archive.read('install.ms')
            assert str((year - 1998) * 1000).encode() in guard and b'__MAX_' not in guard
            with zipfile.ZipFile(QUALIFIED) as qualified:
                assert archive.read('CyrusScatter.ms') == qualified.read('CyrusScatter.ms')
        packages.append(package)
        builds[str(year)] = {
            'receipt': str(receipt_path), 'receipt_sha256': sha(receipt_path),
            'producer_build_only': True,
            'separate_native_suites_passed': 23 if year == 2027 else 0,
            'separate_host_ui_tested': year == 2027,
            'runtime_evidence': ('docs/plans/ui-settings-0876-20261028/QUALIFICATION.json'
                                 if year == 2027 else None),
            'native': {name: sha(native / name) for name in NAMES},
        }
    exe = output / f'CyrusScatter-{VERSION}-Setup.exe'
    build_installer.build_exe(exe, packages, CORE)
    # Reflection reads embedded streams without executing the installer entry point.
    source, probe = run / 'ExeResources.cs', run / 'ExeResources.exe'
    source.write_text(
        'using System;using System.IO;using System.Reflection;using System.Security.Cryptography;'
        'class Probe {static void Main(string[] a){var assembly=Assembly.LoadFile(Path.GetFullPath(a[0]));'
        'foreach(var name in assembly.GetManifestResourceNames()){using(var stream=assembly.GetManifestResourceStream(name))'
        '{Console.WriteLine(name+"\\t"+BitConverter.ToString(SHA256.Create().ComputeHash(stream)).Replace("-","").ToLowerInvariant());}}}}',
        encoding='utf-8')
    compiler = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
    subprocess.run([str(compiler), '/nologo', '/target:exe', '/platform:x64', '/out:' + str(probe), str(source)],
                   check=True, capture_output=True)
    result = subprocess.check_output([str(probe), str(exe)], text=True)
    resources = dict(line.split('\t') for line in result.splitlines())
    assert len(resources) == 3
    for year, package in zip((2024, 2026, 2027), packages):
        assert resources[f'Cyrus.Payload.{year}.mzp'] == sha(package)
    assert sha(packages[-1]) == QUALIFIED_SHA
    receipt = {
        'status': 'passed', 'version': VERSION, 'exe': str(exe), 'exe_bytes': exe.stat().st_size,
        'exe_sha256': sha(exe), 'packages': {p.name: sha(p) for p in packages},
        'embedded_resources': resources, 'builds': builds, 'qualified_2027_preserved': True,
        'scope': '2024/2026 SDK compilation/package only. Max 2027 UI/settings and 23 native suites are recorded separately. '
                 'This packaging step does not launch Max or execute the installer. Installer UI and artist-profile installation are not tested.',
        'analyzer': 'Independent installation retained; not rebuilt or bundled.',
        'content': 'Existing 0.86.7 shared content retained; optional archive not embedded.',
    }
    (output / 'DELIVERY_RECEIPT.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    (output / 'SHA256SUMS.txt').write_text(
        ''.join(sha(p) + '  ' + p.name + '\n' for p in [exe, *packages]), encoding='utf-8')
    (output / 'READ_ME.txt').write_text(
        'CyrusScatter 0.87.6 for Max 2024, 2026 and 2027.\n\n'
        'Save work and close the Max versions selected for installation. Run the EXE, select the installed '
        'versions and choose Install / Update. Reopen Max afterward.\n'
        'Alternative: Scripting > Run Script > matching Max-year MZP, then restart.\n\n'
        'Max 2024/2026 are compiled/package checked only, without host testing. The exact original 2027 '
        'UI-qualified package is retained. Native Scene presets remain Max 2027 only. '
        'Existing shared content and independent Analyzer installation are retained.\n', encoding='utf-8')
    print(json.dumps({'exe': str(exe), 'bytes': exe.stat().st_size, 'sha256': sha(exe),
                      'embedded_max_years': [2024, 2026, 2027]}, indent=2))


if __name__ == '__main__':
    main()
