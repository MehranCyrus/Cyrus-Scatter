"""Execute the shared managed engines on owned files, including child kills."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys
import time
import uuid
import zipfile
import pytest

ROOT = Path(__file__).resolve().parents[2]
CSC = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
FRAMEWORK = Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
pytestmark = pytest.mark.skipif(os.name != 'nt' or not CSC.is_file(), reason='Windows .NET Framework compiler required')


@pytest.fixture(scope='module')
def managed_fixture():
    output = ROOT/'build/r867i'/uuid.uuid4().hex[:8]
    output.mkdir(parents=True)
    core = output/'CyrusInstaller.dll'
    subprocess.run([sys.executable, str(ROOT/'AminScatter/tools/build_installer.py'), '--output', str(core)], check=True, capture_output=True, text=True)
    executable = output/'InstallerRepairChecks.exe'
    source = Path(__file__).with_name('fixtures')/'InstallerRepairChecks.cs'
    command = [str(CSC), '/nologo', '/noconfig', '/nostdlib+', '/langversion:latest', '/warnaserror+',
               '/target:exe', '/platform:x64', '/out:'+str(executable), '/reference:'+str(core),
               *('/reference:'+str(FRAMEWORK/n) for n in ('mscorlib.dll', 'System.dll', 'System.Core.dll')), str(source)]
    subprocess.run(command, check=True, capture_output=True, text=True)
    return executable, output


def run_fixture(executable, *args):
    result = subprocess.run([str(executable), *map(str, args)], capture_output=True, text=True, timeout=90)
    (Path(args[1])/('fixture-'+str(args[0])+'.log')).write_text(result.stdout+result.stderr,encoding='utf-8')
    assert result.returncode == 0, result.stdout + result.stderr
    return result.stdout


def test_backup_transactions_and_preservation(managed_fixture):
    executable, output = managed_fixture
    log = run_fixture(executable, 'checks', output/'cases')
    (output/'checks.log').write_text(log, encoding='utf-8')
    assert 'CHECKS ' in log


@pytest.mark.parametrize('product,phase', [
    ('scatter', 'backup:scatter-0:partial-write'), ('scatter', 'backup:scatter-0:after-flush'),
    ('scatter', 'backup:scatter-0:after-move'), ('scatter', 'journal'), ('scatter', 'publishing:1'),
    ('scatter', 'backup:scatter-registration:partial-write'), ('scatter', 'backup:scatter-registration:after-move'),
    ('analyzer', 'backup:analyzer-startup:partial-write'), ('analyzer', 'backup:analyzer-startup:after-flush'),
    ('analyzer', 'backup:analyzer-startup:after-move'), ('analyzer', 'analyzer-journal'), ('analyzer', 'analyzer-publish:1'),
])
def test_process_interruption_allows_safe_retry(managed_fixture, product, phase):
    executable, output = managed_fixture
    case = output/('k'+uuid.uuid4().hex[:6])
    run_fixture(executable, 'seed', case, product, 'p')
    marker = case/'ready.txt'
    command = [str(executable), 'child', str(case), product, 'p', phase, str(marker)]
    executable_hash = hashlib.sha256(executable.read_bytes()).hexdigest()
    with (case/'child.log').open('w', encoding='utf-8') as log:
        child = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 30
            while not marker.exists() and child.poll() is None and time.monotonic() < deadline:
                time.sleep(.02)
            assert marker.is_file(), (case/'child.log').read_text(encoding='utf-8')
            assert marker.read_text() == phase
            assert child.args == command and hashlib.sha256(executable.read_bytes()).hexdigest() == executable_hash
            child.kill()
            child.wait(timeout=10)
        finally:
            if child.poll() is None:
                child.kill()
                child.wait(timeout=10)
    retry = run_fixture(executable, 'retry', case, product, 'p')
    (case/'retry.log').write_text(retry, encoding='utf-8')
    (case/'process-kill.json').write_text(json.dumps({'product': product, 'checkpoint': phase,
        'owned_child_executable': str(executable), 'executable_sha256': executable_hash,
        'exit_code': child.returncode, 'retry': 'pass', 'scope': 'process termination, not power-loss qualification'}, indent=2)+'\n', encoding='utf-8')


@pytest.mark.parametrize('package,registered', [
    ('dist/CyrusSurfaceAnalyzer-0.14-Max2027.mzp','bin-max2027-e2318bd967cf'),
    ('dist/CyrusScatter-0.86.8.4-20261022/CyrusSurfaceAnalyzer-0.14.1-Max2027.mzp','r/6089dbb859775490/bin'),
])
def test_exact_archived_analyzer_upgrade_when_available(managed_fixture,package,registered):
    archive=ROOT/package
    if not archive.is_file():pytest.skip('Historical ignored package is unavailable in this checkout')
    executable,output=managed_fixture
    case=output/('legacy'+uuid.uuid4().hex[:6]);source=case/'archived';source.mkdir(parents=True)
    with zipfile.ZipFile(archive) as z:
        for name in ('CyrusSurfaceAnalyzer.dlx','CyrusSurfaceAnalyzer.ms','CyrusSurfaceAnalyzerStartup.ms'):
            (source/name).write_bytes(z.read(name))
    log=run_fixture(executable,'legacy',case,'analyzer','p',source,registered)
    (case/'legacy-upgrade.log').write_text(log,encoding='utf-8')


def test_linked_destination_is_rejected(managed_fixture):
    executable,output=managed_fixture
    case=output/('link'+uuid.uuid4().hex[:6]);case.mkdir()
    target=case/'target';target.mkdir()
    sentinel=target/'preserve.txt';sentinel.write_bytes(b'Owned destination sentinel')
    link=case/'scripts'
    quote=lambda path:"'"+str(path).replace("'","''")+"'"
    subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-Command',
                    'New-Item -ItemType Junction -Path '+quote(link)+' -Target '+quote(target)+' | Out-Null'],
                   check=True,capture_output=True,text=True)
    log=run_fixture(executable,'linked',case,link)
    assert sentinel.read_bytes()==b'Owned destination sentinel'
    assert [p.name for p in target.iterdir()]==['preserve.txt']
    (case/'linked-destination.log').write_text(log,encoding='utf-8')


@pytest.mark.parametrize('product',['scatter','analyzer'])
def test_custom_registration_is_preserved(managed_fixture,product):
    executable,output=managed_fixture
    case=output/('custom'+uuid.uuid4().hex[:6])
    log=run_fixture(executable,'registration',case,product,'p')
    (case/'custom-registration.log').write_text(log,encoding='utf-8')


@pytest.mark.parametrize('year,version,day,registered',[
    ('2026','0.81.6','20261013','bin-max2026-866ea3d51489'),
    ('2027','0.81.6','20261013','bin-max2027-7800997061d5'),
    ('2027','0.85.0','20261016','bin-max2027-29c9e9ffb122'),
    ('2024','0.86.8.2','20261021','r/95b2c365ca4e/bin'),
    ('2026','0.86.8.2','20261021','r/2659a612260f/bin'),
    ('2026','0.86.8.2','20261021','Releases/0.86.8.2-2659a612260f/bin'),
    ('2027','0.86.8.2','20261021','r/a0e8fbbd7f89/bin'),
    ('2027','0.86.8.3','20261022','r/872f09e13064/bin'),
    ('2027','0.86.8.4','20261022','r/09f2cdd4bbb1/bin'),
])
def test_exact_archived_scatter_registration_upgrade(managed_fixture,year,version,day,registered):
    archive=ROOT/'dist'/('CyrusScatter-'+version+'-'+day)/('CyrusScatter-'+version+'-Max'+year+'.mzp')
    if not archive.is_file():pytest.skip('Historical ignored package is unavailable in this checkout')
    executable,output=managed_fixture
    case=output/('ls'+uuid.uuid4().hex[:6]);source=case/'old';source.mkdir(parents=True)
    with zipfile.ZipFile(archive) as z:
        for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusScatterStartup.ms','CyrusScatter.mcr'):
            (source/name).write_bytes(z.read(name))
    log=run_fixture(executable,'legacy-scatter',case,'scatter','p',source,registered,year)
    (case/'legacy-upgrade.log').write_text(log,encoding='utf-8')


@pytest.mark.parametrize('scenario',['tampered','duplicate','wrong-year','rollback'])
def test_max2026_legacy_upgrade_guards_and_rollback(managed_fixture,scenario):
    archive=ROOT/'dist/CyrusScatter-0.81.6-20261013/CyrusScatter-0.81.6-Max2026.mzp'
    if not archive.is_file():pytest.skip('Historical ignored package is unavailable in this checkout')
    executable,output=managed_fixture
    case=output/('guard'+uuid.uuid4().hex[:6]);source=case/'old';source.mkdir(parents=True)
    with zipfile.ZipFile(archive) as z:
        for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusScatterStartup.ms','CyrusScatter.mcr'):
            (source/name).write_bytes(z.read(name))
    run_fixture(executable,'legacy-scatter',case,'scatter','p',source,'bin-max2026-866ea3d51489',
                '2027' if scenario=='wrong-year' else '2026',scenario)
