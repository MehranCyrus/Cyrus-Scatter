"""Build matching older-host MZPs and embed the unchanged qualified 2027 MZP."""
from pathlib import Path
from types import SimpleNamespace
import hashlib, json, shutil, subprocess, sys, zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
import build_max
OUT = ROOT/'build/compatibility-0862-20261019/package01'
BASE = Path('D:/CyrusScatterBuilds/compatibility-0862-20261019')
CORE = ROOT/'build/ui-polish-0862-20261019/package01/staging/AminScatter/CyrusInstaller.dll'
OLD2027 = ROOT/'dist/CyrusScatter-0.86.2-20261019-ui02/CyrusScatter-0.86.2-Max2027.mzp'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert not OUT.exists() and build_max.scatter_version() == '0.86.2'
OUT.mkdir(parents=True)
packages = []; receipts = {}
for year in (2024, 2026, 2027):
    native = BASE/f'native{year}' if year != 2027 else Path('D:/CyrusScatterBuilds/ui-polish-0862-20261019/pair03')
    receipt = json.loads((native/'receipt.json').read_text())
    assert receipt['max_year'] == year and all(s['exit_code'] == 0 for s in receipt['stages'])
    assert not receipt.get('placement_qualification') and not receipt.get('preview_fault_lab')
    for key in ('sources', 'binaries'):
        for name, digest in receipt[key].items(): assert sha(ROOT/name) == digest, name
    package = OUT/f'CyrusScatter-0.86.2-Max{year}.mzp'
    if year == 2027:
        assert sha(OLD2027) == '5c8900f5a8f1341f15b125abdadee3801a07c233165655b18380268c3236f125'
        shutil.copy2(OLD2027, package)
    else:
        stage = OUT/f'staging{year}/AminScatter'; stage.mkdir(parents=True)
        names = ['AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh']
        for name in names+['CyrusGallery.dll']: shutil.copy2(native/name, stage/name)
        for p in (CORE, CORE.with_suffix('.build.json')): shutil.copy2(p, stage/p.name)
        args = SimpleNamespace(max_year=year, tools_version='14.38.33130', windows_sdk='10.0.19041.0', output=OUT,
            team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h', library_dir=OUT.parent/f'libraries/library{year}')
        build_max.package('AminScatter', 'Cyrus Scatter', '0.86.2', names, 'AminScatterObject.ms', args, stage.parent)
    with zipfile.ZipFile(package) as archive:
        assert archive.testzip() is None
        manifest = json.loads(archive.read('manifest.json'))
        assert manifest['max_year'] == year and manifest['version'] == '0.86.2'
        assert set(archive.namelist()) == set(manifest['files']) | {'manifest.json'}
        for name, digest in manifest['files'].items(): assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
        assert manifest['files']['CyrusScatter.ms'] == sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
        for name in ('AminScatter.dlx', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh', 'CyrusScatterEdit.dlm', 'CyrusGallery.dll'):
            assert manifest['files'][name] == sha(native/name), name
        assert str((year-1998)*1000).encode() in archive.read('install.ms')
        assert manifest['licensing']['mode'] == 'offline-team'
        patterns = json.loads(archive.read('Patterns/index.json'))['entries']; assert len(patterns) == 3
        for row in patterns: assert hashlib.sha256(archive.read('Patterns/'+row['file'])).hexdigest() == row['sha256']
        archive.extractall(OUT/f'payload{year}')
    packages.append(package)
    receipts[str(year)] = {'native_receipt': str(native/'receipt.json'), 'native_receipt_sha256': sha(native/'receipt.json'),
        'mzp_sha256': sha(package), 'manifest': manifest}
exe = OUT/'CyrusScatter-0.86.2-Setup.exe'
command = [sys.executable, str(ROOT/'AminScatter/tools/build_installer.py'), '--output', str(exe), '--core', str(CORE)]
for p in packages: command += ['--package', str(p)]
subprocess.run(command, check=True)
(OUT/'candidate.json').write_text(json.dumps({'version':'0.86.2', 'status':'Candidate; runtime/distribution qualification separate',
    'exe_sha256':sha(exe), 'packages':receipts}, indent=2)+'\n')
print('Verified multi-host candidate:', OUT)
