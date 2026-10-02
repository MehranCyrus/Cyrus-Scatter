"""Build and run existing suites in isolated paths. See --help.

Host fixtures are byte-identical copies with the same relative directory layout.
They operate only in new hidden 3dsmaxbatch processes and disposable scenes.
No installers are invoked and no existing batch result is overwritten.
"""
from research_tools import ROOT, HERE, EVIDENCE, SCRATCH, digest, record, run_logged, stamp
import argparse
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

def environment():
    spec = importlib.util.spec_from_file_location('existing_build_tool', ROOT / 'tools/build_max.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),
                                       '14.38.33130', '10.0.19041.0')

def build(year):
    env = environment()
    sdk = ROOT / f'build/tooling/max{year}-sdk/Program Files/Autodesk/3ds Max {year} SDK/maxsdk'
    for project in ('AminScatter', 'CyrusSurfaceAnalyzer'):
        dest = SCRATCH / f'max{year}' / project
        run_logged(f'configure-{year}-{project}', ['cmake', '-S', ROOT/project, '-B', dest,
                   '-G', 'NMake Makefiles', '-DCMAKE_BUILD_TYPE=Release',
                   f'-DCYRUS_MAX_YEAR={year}', f'-DMAXSDK_ROOT={sdk}',
                   *(['-DAMIN_BUILD_BENCHMARKS=ON'] if project == 'AminScatter' else [])], env)
        run_logged(f'build-{year}-{project}', ['cmake', '--build', dest], env)
        run_logged(f'ctest-{year}-{project}', ['ctest', '--test-dir', dest, '--output-on-failure', '-V'], env)
    files = [p for p in (SCRATCH / f'max{year}').rglob('*') if p.suffix in ('.dlx','.dlm','.exe')]
    record(f'build-{year}-identity.json', dict(utc=stamp(), files=[dict(path=str(p), sha256=digest(p)) for p in files]))

def generator():
    dest = SCRATCH / 'generator' / 'AminScatter'
    if dest.exists():
        raise RuntimeError('Generator scratch already exists; preserve evidence and choose a fresh path')
    shutil.copytree(ROOT/'AminScatter/tools', dest/'tools')
    (dest/'scripts').mkdir()
    run_logged('generator', ['node', 'tools/ui/generate.cjs'], cwd=dest)
    a, b = ROOT/'AminScatter/scripts/AminScatterObject.ms', dest/'scripts/AminScatterObject.ms'
    data = dict(source_sha256=digest(a), generated_sha256=digest(b), identical=a.read_bytes()==b.read_bytes())
    record('generator-parity.json', data)
    if not data['identical']:
        raise RuntimeError('Generator differs from current script')
    print(data)

def packages():
    output = []
    for year in (2026,2027):
        p = ROOT/f'dist/CyrusScatter-0.62-Max{year}.mzp'
        with zipfile.ZipFile(p) as z:
            import json
            m = json.loads(z.read('manifest.json'))
            checks = {n: __import__('hashlib').sha256(z.read(n)).hexdigest()==h for n,h in m['files'].items()}
            item = dict(path=str(p), sha256=digest(p), zip_ok=z.testzip() is None,
                        manifest=m, checks=checks,
                        script_matches=z.read('AminScatterObject.ms')==(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_bytes())
            output.append(item)
            if not item['zip_ok'] or not all(checks.values()) or not item['script_matches']:
                raise RuntimeError('Package identity failed')
    record('package-identity.json', output)
    print('Both Scatter 0.62 packages: ZIP, all manifest hashes and source script equality passed')

def host(verified=False):
    hostroot = SCRATCH / ('host-verified-v4' if verified else 'host')
    if hostroot.exists():
        raise RuntimeError('Host scratch already exists; preserve evidence and choose a fresh path')
    for project, script in [('AminScatter','AminScatterObject.ms'),('CyrusSurfaceAnalyzer','CyrusSurfaceAnalyzer.ms')]:
        (hostroot/project/'scripts').mkdir(parents=True)
        shutil.copy2(ROOT/project/'scripts'/script, hostroot/project/'scripts'/script)
    testdir = hostroot/'tools/tests'
    testdir.mkdir(parents=True)
    (hostroot/'build').mkdir()
    for sub in ('viewport-performance-test','compute-performance-test'):
        (hostroot/'build'/sub).mkdir()
    config = hostroot/'max.ini'
    config.write_text('[Directories]\n')
    plugins = hostroot/'plugins.ini'
    plugins.write_text('[Directories]\nScatterResearch='+str(SCRATCH/'max2027/AminScatter')+
                       '\nAnalyzerResearch='+str(SCRATCH/'max2027/CyrusSurfaceAnalyzer')+'\n')
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    fixtures = [('max2027_smoke.ms','max2027-smoke-result.txt'),
                ('compute_performance_smoke.ms','compute-performance-test/result.txt'),
                ('viewport_performance_smoke.ms','viewport-performance-test/result.txt')]
    for fixture, result in fixtures:
        source = ROOT/'tools/tests'/fixture
        shutil.copy2(source, testdir/fixture)
        target = hostroot/'build'/result
        target.write_text('PENDING\n')
        label = ('verified-v4-' if verified else '')+fixture.removesuffix('.ms')
        entry=testdir/fixture
        if verified:
            entry=testdir/('identity-'+fixture)
            module_log=EVIDENCE/f'{label}-modules.txt'
            entry.write_text('(\nlocal identityLog=createFile @"'+module_log.as_posix()+'"\n'+
                'local currentProcess=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()\n'+
                'local currentModules=currentProcess.Modules\n'+
                'for i=0 to (currentModules.Count-1) do (\nlocal m=currentModules.Item[i]\n'+
                ' if (findItem #("3dsmax.exe","AminScatter.dlx","CyrusScatterEdit.dlm","CyrusSurfaceAnalyzer.dlx") m.ModuleName)>0 do format "%\\n" m.FileName to:identityLog\n'+
                ')\nclose identityLog\n)\nfileIn @"'+(testdir/fixture).as_posix()+'"\n',encoding='utf-8')
        command = ['C:/Program Files/Autodesk/3ds Max 2027/3dsmaxbatch.exe',str(entry),
                   '-i',str(config),'-p',str(plugins),
                   '-listenerlog',str(EVIDENCE/f'{label}-listener.txt'),
                   '-log',str(EVIDENCE/f'{label}-session.txt')]
        started = stamp()
        with (EVIDENCE/f'{label}-stdout.txt').open('wb') as stdout, (EVIDENCE/f'{label}-stderr.txt').open('wb') as stderr:
            p = subprocess.run(command, cwd=hostroot, stdout=stdout, stderr=stderr,
                               startupinfo=startup, timeout=300)
        report = target.read_text(encoding='utf-8-sig')
        (EVIDENCE/f'{label}-result.txt').write_text(report,encoding='utf-8')
        record(f'{label}-run.json',dict(started_utc=started,finished_utc=stamp(),argv=command,
             returncode=p.returncode,fixture_sha256=digest(source),copy_sha256=digest(testdir/fixture),
             result=report,scope='Separate hidden Max batch; synthetic disposable scene; no renderer test'))
        print(report,flush=True)
        if p.returncode or 'SUCCESS' not in report:
            raise RuntimeError(f'{label} failed')
        if verified:
            modules=[]
            for line in module_log.read_text(encoding='utf-8-sig').splitlines():
                module=Path(line)
                modules.append(dict(path=str(module),sha256=digest(module)))
            expected={str((SCRATCH/'max2027'/project/file).resolve()).lower() for project,file in
                      [('AminScatter','AminScatter.dlx'),('AminScatter','CyrusScatterEdit.dlm'),('CyrusSurfaceAnalyzer','CyrusSurfaceAnalyzer.dlx')]}
            actual={x['path'].lower() for x in modules}
            record(f'{label}-identity.json',dict(modules=modules,expected_modules_present=expected.issubset(actual)))
            if not expected.issubset(actual):raise RuntimeError('Host loaded unexpected plugin identity')

if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('action',choices=['build2027','build2026','generator','packages','host','hostverified'])
    a=p.parse_args().action
    EVIDENCE.mkdir(parents=True,exist_ok=True)
    if a.startswith('build'):
        build(int(a[-4:]))
    elif a=='hostverified':
        host(True)
    else:
        globals()[a]()
