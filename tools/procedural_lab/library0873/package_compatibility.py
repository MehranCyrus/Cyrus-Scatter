"""Package matched 0.87.3 payloads; preserve the qualified Max 2027 archive."""
from argparse import ArgumentParser, Namespace
from pathlib import Path
import hashlib
import json
import shutil
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / 'tools'), str(ROOT / 'AminScatter/tools')]
import build_installer
import build_max

NAMES = ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--older-producers', type=Path, required=True)
    parser.add_argument('--analyzer-producers', type=Path, required=True)
    parser.add_argument('--work', type=Path, required=True)
    args = parser.parse_args()
    work = args.work.resolve()
    work.mkdir(parents=True, exist_ok=False)
    output = ROOT / 'dist/CyrusScatter-0.87.3-20261026'
    native2027 = ROOT / 'build/library0873-release-20261026-01/AminScatter'
    core = native2027 / 'CyrusInstaller.dll'
    build_installer.verify_core(core)
    assert build_max.scatter_version() == '0.87.3'
    packages, analyzers, records = [], [], {}
    for year in (2024, 2026, 2027):
        native = native2027 if year == 2027 else args.older_producers.resolve() / f'max{year}'
        receipt_path = native / 'receipt.json'
        receipt = build_max.verify_native_receipt(receipt_path, 'AminScatter', year,
                                                  {n: native / n for n in NAMES})
        assert receipt['tests_run']
        package = output / f'CyrusScatter-0.87.3-Max{year}.mzp'
        if year != 2027 and not package.exists():
            stage = work / f'stage-{year}/AminScatter'
            stage.mkdir(parents=True)
            for name in [*NAMES, 'CyrusGallery.dll', 'CyrusGallery.build.json']:
                shutil.copy2(native / name, stage / name)
            for name in ['CyrusInstaller.dll', 'CyrusInstaller.build.json']:
                shutil.copy2(native2027 / name, stage / name)
            options = Namespace(max_year=year, tools_version='14.38.33130', windows_sdk='10.0.19041.0',
                output=output, team_trust_header=ROOT / 'CyrusLicensing/team/team_public_key.h',
                content_dir=ROOT / 'dist/CyrusScatter-0.86.7-20261020/Content',
                native_receipts={'AminScatter': receipt_path})
            build_max.package('AminScatter', 'Cyrus Scatter', '0.87.3', NAMES,
                              'AminScatterObject.ms', options, stage.parent)
        elif year == 2027:
            assert sha(package) == '9a292a12fb95446e9f1f31eb85bd5485174af4156dbb4cb8b4598efed1621f4e'
        with zipfile.ZipFile(package) as archive:
            assert archive.testzip() is None
            manifest = json.loads(archive.read('manifest.json'))
            assert manifest['version'] == '0.87.3' and manifest['max_year'] == year
            assert all(hashlib.sha256(archive.read(n)).hexdigest() == h
                       for n, h in manifest['files'].items())
        packages.append(package)
        # Analyzer code is unchanged. Repackage its original matched native producer
        # with the current shared installation transaction helper; retain its version.
        analyzer = args.analyzer_producers.resolve() / f'max{year}'
        analyzer_receipt = analyzer / 'receipt.json'
        build_max.verify_native_receipt(analyzer_receipt, 'CyrusSurfaceAnalyzer', year,
                                       {'CyrusSurfaceAnalyzer.dlx': analyzer / 'CyrusSurfaceAnalyzer.dlx'})
        analyzer_package = output / f'CyrusSurfaceAnalyzer-0.14.2-Max{year}.mzp'
        stage_root = work / f'analyzer-{year}'
        stage = stage_root / 'CyrusSurfaceAnalyzer'
        stage.mkdir(parents=True)
        shutil.copy2(analyzer / 'CyrusSurfaceAnalyzer.dlx', stage / 'CyrusSurfaceAnalyzer.dlx')
        installer_stage = stage_root / 'AminScatter'
        installer_stage.mkdir()
        for name in ['CyrusInstaller.dll', 'CyrusInstaller.build.json']:
            shutil.copy2(native2027 / name, installer_stage / name)
        options = Namespace(max_year=year, tools_version='14.38.33130', windows_sdk='10.0.19041.0',
            output=output, native_receipts={'CyrusSurfaceAnalyzer': analyzer_receipt})
        if not analyzer_package.exists():
            build_max.package('CyrusSurfaceAnalyzer', 'Cyrus Surface Analyzer', '0.14.2',
                              ['CyrusSurfaceAnalyzer.dlx'], 'CyrusSurfaceAnalyzer.ms', options, stage_root)
        analyzers.append(analyzer_package)
        records[str(year)] = {'receipt': str(receipt_path), 'receipt_sha256': sha(receipt_path),
            'mzp_sha256': sha(package), 'native_tests': True,
            'host_scope': 'Prior exact 0.87.3 Max 2027 Library qualification' if year == 2027
                          else 'Native tests passed; 0.87.3 not executed inside this Max host',
            'analyzer_native_receipt': str(analyzer_receipt),
            'analyzer_scope': 'Unchanged 0.14.2 source rebuilt and native-tested; no new host qualification'}
    exe = output / 'CyrusScatter-0.87.3-Setup.exe'
    assert not exe.exists()
    build_installer.build_exe(exe, packages, core, analyzers)
    result = {'version': '0.87.3', 'exe': str(exe), 'exe_sha256': sha(exe),
              'exe_bytes': exe.stat().st_size, 'hosts': records,
              'analyzer_version': '0.14.2', 'content_version': '0.86.7',
              'scope': 'Build/package verification. Artist profiles untouched. No new Max host launches.'}
    (output / 'COMPATIBILITY_RECEIPT.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf8')
    (output / 'SHA256SUMS.txt').write_text(''.join(sha(p) + '  ' + p.name + '\n'
        for p in [exe, *packages, *analyzers]), encoding='utf8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
