"""Bounded filesystem and unshown-form checks for the delivered installer r2.

All installation targets are generated beneath --run; no Max process is started.
"""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[3]
CSC = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
FRAMEWORK = Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')


def extract(package, output):
    output.mkdir(parents=True, exist_ok=False)
    with zipfile.ZipFile(package) as archive:
        for name in archive.namelist():
            path = (output / name).resolve()
            if not path.is_relative_to(output.resolve()):
                raise ValueError('Archive path escapes owned destination')
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(archive.read(name))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', required=True, type=Path)
    parser.add_argument('--package-dir', required=True, type=Path)
    args = parser.parse_args()
    run, packages = args.run.resolve(), args.package_dir.resolve()
    test = run / 'delivered-checks'
    test.mkdir(parents=True, exist_ok=False)
    core = run / 'core/CyrusInstaller.dll'
    shutil.copy2(core, test / core.name)
    exe = packages / 'CyrusScatter-0.87.6-Setup.exe'
    shutil.copy2(exe, test / exe.name)
    references = [FRAMEWORK / n for n in ('mscorlib.dll', 'System.dll', 'System.Core.dll',
                                          'System.Drawing.dll', 'System.Windows.Forms.dll')]
    for name, reference in [('InstallerRepairChecks', core), ('InstallerSelectionChecks', exe)]:
        command = [str(CSC), '/nologo', '/noconfig', '/nostdlib+', '/warnaserror+',
                   '/target:exe', '/platform:x64', '/out:' + str(test / (name + '.exe')),
                   '/reference:' + str(reference),
                   *('/reference:' + str(p) for p in references),
                   str(ROOT / 'tools/tests/fixtures' / (name + '.cs'))]
        result = subprocess.run(command, text=True, capture_output=True)
        (test / (name + '.build.log')).write_text(result.stdout + result.stderr, encoding='utf-8')
        if result.returncode:
            raise RuntimeError(result.stdout + result.stderr)
    report = []

    def check(name, command):
        result = subprocess.run(list(map(str, command)), capture_output=True, text=True, timeout=120)
        (test / (name + '.log')).write_text(result.stdout + result.stderr, encoding='utf-8')
        if result.returncode:
            raise RuntimeError(name + '\n' + result.stdout + result.stderr)
        report.append({'case': name, 'passed': result.stdout.count('PASS '), 'log': name + '.log'})
        print('PASS', name, flush=True)

    old_root = ROOT / 'dist/CyrusScatter-0.87.6-20261028-final'
    fixture = test / 'InstallerRepairChecks.exe'
    for year in (2024, 2026, 2027):
        new = test / ('new' + str(year))
        previous = test / ('old' + str(year))
        extract(packages / f'CyrusScatter-0.87.6-Max{year}.mzp', new)
        extract(old_root / f'CyrusScatter-0.87.6-Max{year}.mzp', previous)
        check('clean-' + str(year), [fixture, 'package-scatter', test / ('c' + str(year)), 'scatter', 'p', new, year])
        check('modern-' + str(year), [fixture, 'package-scatter', test / ('m' + str(year)), 'scatter', 'p', new, year, previous])
    for year, version, day, registered in (
        (2024, '0.86.8.2', '20261021', 'r/95b2c365ca4e/bin'),
        (2026, '0.81.6', '20261013', 'bin-max2026-866ea3d51489'),
    ):
        legacy = test / ('legacy' + str(year))
        extract(ROOT / f'dist/CyrusScatter-{version}-{day}/CyrusScatter-{version}-Max{year}.mzp', legacy)
        check('archived-' + str(year), [fixture, 'legacy-scatter', test / ('l' + str(year)),
              'scatter', 'p', legacy, registered, year, 'upgrade', test / ('new' + str(year))])
    check('combined-exe', [test / 'InstallerSelectionChecks.exe', test / 'combined',
                           test / 'legacy2026', test / 'old2027', packages])
    (run / 'delivered-tests.json').write_bytes((json.dumps({
        'status': 'passed', 'cases': report, 'checks': sum(c['passed'] for c in report),
        'exe_sha256': hashlib.sha256(exe.read_bytes()).hexdigest(),
        'scope': 'Managed filesystem and unshown EXE form commands, using owned profiles only. No native module loaded; no Max runtime qualification.',
    }, indent=2) + '\n').encode('utf-8'))


if __name__ == '__main__':
    main()
