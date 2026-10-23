"""Verify the final combined delivery without rebuilding qualified payloads."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'build/combined-installer-08685-20261022';CANDIDATE=WORK/'candidate03'
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def proof(p):return {'path':str(Path(p).relative_to(ROOT)),'sha256':sha(p)}
receipt=read(CANDIDATE/'package-receipt.json');exe=CANDIDATE/'CyrusScatter-0.86.8.5-Setup.exe'
assert sha(exe)==receipt['exe_sha256']
build=read(exe.with_suffix('.build.json'));assert build['max_years']==[2024,2026,2027]
assert len(build['packages'])==len(build['analyzer_packages'])==3
for n,h in build['sources'].items():assert sha(ROOT/n)==h,n
for native in receipt['builds'].values():
    assert native['clean_compilation'] and all(s['exit_code']==0 for s in native['stages'])
    for n,h in {**native['sources'],**native['binaries']}.items():assert sha(ROOT/n)==h,n
for name,h in receipt['packages'].items():
    p=CANDIDATE/'packages'/name;assert sha(p)==h
    with zipfile.ZipFile(p) as z:
        assert z.testzip() is None;m=json.loads(z.read('manifest.json'))
        assert set(z.namelist())==set(m['files'])|{'manifest.json'}
        for n,d in m['files'].items():assert hashlib.sha256(z.read(n)).hexdigest()==d,n
        assert not any('fixture' in n.lower() for n in z.namelist())
checks=read(WORK/'checks04/receipt.json');assert checks['exit_code']==0 and checks['checks']==134 and checks['exe_sha256']==sha(exe)
assert checks['fixture_sha256']==sha(ROOT/'tools/combined_installer_08685/CombinedInstallerChecks.cs')
assert '192 passed' in (WORK/'python.log').read_text(encoding='utf-8')
assert '16 passed' in (WORK/'focused-final.log').read_text(encoding='utf-8')
generated=read(WORK/'generated.log');assert generated['passed'] and generated['development_version']=='0.86.8.5'
assert generated['generated_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
hosts={};pids=[]
for year in [2024,2026,2027]:
    folder=WORK/f'host02-{year}';metadata=read(folder/'qualification.json');pids.append(metadata['pid'])
    assert metadata['installer_exe_sha256']==sha(exe)
    for name,path in metadata['paths'].items():assert sha(path)==metadata['hashes'][name],name
    rows=read(folder/'batch.json')
    if year==2024:
        assert len(rows)==22 and rows[-1]['scenario']=='R1-M06' and rows[-1]['status']=='fail'
        passed=rows[:-1]+read(folder/'batch-successor02.json')
    else:
        assert len(rows)==38 and all(r['status']=='pass' for r in rows)
        upgrade=read(folder/'upgrade.json');assert upgrade['status']=='pass'
        passed=rows+[{'scenario':'R4-M12-UPGRADE','status':'pass','seconds':None}]
    assert len(passed)==39 and len({r['scenario'] for r in passed})==39 and all(r['status']=='pass' for r in passed)
    results=[];ids={r['scenario'] for r in passed}
    for p in folder.glob('result-*.json'):
        r=read(p)
        if r['status']=='pass' and r['scenario_id'] in ids:
            assert r['terminal']=='complete' and r['assertions'] and all(a['status']=='pass' for a in r['assertions']);results.append(proof(p))
    assert len(results)==39
    hosts[str(year)]={'qualification':proof(folder/'qualification.json'),'loaded':proof(folder/'loaded.tsv'),'cases':passed,'result_receipts':results}
    log=(WORK/f'migration-final-{year}.log').read_text(encoding='utf-8');path=Path(log.strip().splitlines()[-1])/'receipt.json';migration=read(path)
    assert migration['status']=='passed' and migration['max_year']==year and len(migration['checks'])==61
    assert migration['package_sha256']==receipt['packages'][f'CyrusScatter-0.86.8.5-Max{year}.mzp']
    hosts[str(year)]['migration']=proof(path)
command='Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -in @('+','.join(map(str,pids))+') } | Select-Object ProcessId,CommandLine | ConvertTo-Json -Compress'
active=subprocess.check_output(['powershell','-NoProfile','-Command',command],text=True).strip();assert not active,'Owned hosts still running: '+active
out=ROOT/'dist/CyrusScatter-0.86.8.5-20261022';out.mkdir(exist_ok=True)
destination=out/exe.name
if destination.exists():assert sha(destination)==sha(exe),'Do not replace an existing different delivery'
else:shutil.copy2(exe,destination)
assert sha(destination)==sha(exe)
data={'status':'passed','version':'0.86.8.5','analyzer_version':'0.14.1','max_years':[2024,2026,2027],
      'exe':proof(destination),'exe_bytes':destination.stat().st_size,'build':proof(exe.with_suffix('.build.json')),
      'native_ctest_per_host':51,'analyzer_core_per_host':1,'python_tests':192,'focused_recheck':16,'combined_exe_checks':134,
      'migration_checks_per_host':61,'functional_cases_per_host':39,'hosts':hosts,
      'owned_host_pids_closed':pids,'artist_installed_or_restarted':False,'git_commit_push':False,'website_deployed':False,
      'limits':['Max 2024 Live uses a preserved explicit top-level settlement successor; original fixed-delay and nested-helper failures retained',
                'Scripted host/control/DPI evidence is not physical input, presented FPS, renderer or soak acceptance',
                'Per-product/host transactions; no global transaction across all independent installs','Plant content remains optional and separate']}
(WORK/'delivery-seal.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:data[k] for k in ['status','version','analyzer_version','max_years','exe','exe_bytes','combined_exe_checks','functional_cases_per_host']}))
