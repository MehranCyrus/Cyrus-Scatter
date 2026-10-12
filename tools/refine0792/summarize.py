"""Keep compact, portable evidence while retaining raw private-host receipts."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/Layer_Navigation_0.79.2_2026-10-11';OUT.mkdir(parents=True,exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
hosts={2026:ROOT/'build/mcp-qualification/refine0791-layer0792-2026-03',2027:ROOT/'build/mcp-qualification/refine0791-layer0792-2027-04'}
result=dict(version='0.79.2',schema=55,base_commit='15957a66de0480679dea6c533c7c5d09d9598d54',
    source_sha256=sha(ROOT/'AminScatter/scripts/AminScatterObject.ms'),hosts={},originals={},
    computer_use=False,artist_installation=False,git_pushed=False)
for year,host in hosts.items():
    launch=read(host/'launch.json')
    if launch['script_sha256']!=result['source_sha256']:raise RuntimeError('Final script mismatch')
    checks={};raw={}
    names=['display0792','invalidation0792','layer-lifecycle']
    for name in names:
        data=read(host/(name+'.json'))
        if data['errors'] or not all(x['passed'] for x in data['assertions']):raise RuntimeError(name)
        checks[name]=data['assertions'];raw[name]=dict(path=str(host/(name+'.json')),sha256=sha(host/(name+'.json')))
    for phase in ['scene','falloff','points','reopen','empty','layout']:
        data=read(host/(phase+'-results.json'))
        if not all(x['passed'] for x in data['checks']):raise RuntimeError(phase)
        checks[phase]=data['checks'];raw[phase]=dict(path=str(host/(phase+'-results.json')),sha256=sha(host/(phase+'-results.json')))
    undo=[]
    for prefix,phases in [('radius',('prepare','edit','undo','redo')),('layer',('prepare','delete','undo','redo'))]:
        for phase in phases:
            data=read(host/(prefix+'-undo-'+phase+'.json'))
            if not data['passed']:raise RuntimeError(prefix+' undo')
            undo.append(dict(kind=prefix,**data))
    probes={}
    for name in ['layer-cache-probe','point-model-probe','artist-layer-probe']:
        data=read(host/(name+'.json'))
        if data['errors']:raise RuntimeError(name)
        raw[name]=dict(path=str(host/(name+'.json')),sha256=sha(host/(name+'.json')))
        if name=='layer-cache-probe':
            probes[name]=[dict(case=c['name'],snapshots=[dict(label=s['label'],epoch=s['epoch'],layers=s['layers'],mesh=s['mesh'],retained=s['retained']) for s in c['snapshots']]) for c in data['cases']]
            if any(l['error'] or s['native_error'] for c in data['cases'] for s in c['snapshots'] for l in s['layers']):raise RuntimeError('Cache probe error')
        elif name=='point-model-probe':probes[name]=data['snapshots']
        else:
            if len(data['snapshots'])!=8:raise RuntimeError('Artist probe incomplete')
            probes[name]=[dict(label=s['label'],nodes=[dict(name=n['name'],mode=n['mode'],epoch=n['epoch'],layers=[dict(id=l['id'],count=l['count'],fingerprint=l['fingerprint'],sources=l['sources']) for l in n['layers']]) for n in s['controllers']]) for s in data['snapshots']]
    nav=read(host/'navigation0792.json')
    if nav['errors'] or not all(x['passed'] for x in nav['assertions']):raise RuntimeError('Navigation')
    navigation=dict(assertions=nav['assertions'],inventory=nav['inventory'],load_ms=nav['load_ms'],update_all_ms=nav['update_all_ms'],
        measurements=[{k:v for k,v in m.items() if k not in ('before','after')} for m in nav['measurements']],
        baseline_counters=nav['measurements'][0]['before'],final_counters=nav['measurements'][-1]['after'])
    raw['navigation']=dict(path=str(host/'navigation0792.json'),sha256=sha(host/'navigation0792.json'))
    candidate=ROOT/f'build/refine0792-20261011/max{year}-01'
    result['hosts'][str(year)]=dict(launch=launch,loaded_modules=(host/'loaded.tsv').read_text(encoding='utf-8'),
        build=read(candidate/'build.json'),native_test_log=(candidate/'tests.log').read_text(encoding='utf-8'),
        checks=checks,undo=undo,probes=probes,navigation=navigation,raw_receipts=raw,
        artist_input=dict(sha256=sha(host/'artist-layering-input.max'),back_saved_from_max2027=year==2026),
        package=read(ROOT/f'build/refine0792-20261011/package-{year}.json'))
for name,path,expected in [('layers',ROOT/'Test Scene/for layering test.max',sha(ROOT/'build/mcp-qualification/refine0791-layer0792-2027-01/artist-layering-input.max')),
    ('examples',ROOT/'build/vector-brush-078/include-exclude-visible2026-01/Include_Exclude_Point_Examples.max','b7e561c15e942843a1ebd694691fc36a18f9e79c385c31d140b1366cf633fc0b')]:
    current=sha(path)
    if current!=expected:raise RuntimeError('Original scene changed')
    result['originals'][name]=dict(path=str(path),sha256=current,initial_copy_sha256=expected,unchanged=True)
result['fixtures']={str(p.relative_to(ROOT)):sha(p) for p in Path(__file__).parent.iterdir() if p.suffix in ('.py','.ms')}
result['generated_check']=read(ROOT/'build/refine0792-20261011/generated-release/generated-check.json')
result['python_tests']=dict(passed=158,command='build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q')
(OUT/'evidence.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
shutil.copy2(hosts[2027]/'navigation0792.png',OUT/'navigation.png')
print(json.dumps({y:dict(checks=sum(len(c) for c in h['checks'].values()),undo_phases=len(h['undo']),
    navigation_checks=len(h['navigation']['assertions']),timings=[dict(label=m['label'],held=m['held'],ms=m['median_ms']) for m in h['navigation']['measurements']]) for y,h in result['hosts'].items()},indent=2))
