"""Replay identical captured inputs; preserve raw receipts, compare poses and work."""
from argparse import ArgumentParser
from pathlib import Path
import hashlib,json,statistics,subprocess,time

ROOT=Path(__file__).resolve().parents[3]
p=ArgumentParser();p.add_argument('--producer',required=True,type=Path);p.add_argument('--output',required=True,type=Path)
p.add_argument('--steps',type=int,default=14);p.add_argument('--fixture',type=Path,action='append');p.add_argument('--compare',type=Path)
a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False)
assert out.is_relative_to(ROOT/'build')
exe=a.producer.resolve()/'interactions_tests.exe'
fixtures=a.fixture or [Path(s) for s in json.loads((out.parent/'fixtures.json').read_text())]
rows=[]
for i,fixture in enumerate(fixtures):
    t=time.perf_counter();run=subprocess.run([str(exe),'--fixture',str(fixture),str(a.steps)],cwd=ROOT,capture_output=True,text=True)
    (out/f'case-{i}.stdout').write_text(run.stdout,encoding='utf-8');(out/f'case-{i}.stderr').write_text(run.stderr,encoding='utf-8')
    if run.returncode: raise RuntimeError(f'{fixture}: {run.stderr}')
    raw=json.loads(run.stdout);(out/f'case-{i}.json').write_text(json.dumps(raw,indent=2),encoding='utf-8')
    states=[raw['initial'],*raw['steps']]
    row={'fixture':str(fixture.resolve()),'fixture_sha256':hashlib.sha256(fixture.read_bytes()).hexdigest(),
         'process_seconds':time.perf_counter()-t,'steps':len(raw['steps']),
         'median_step_ms':raw.get('median_step_ms'), 'poses':[s['pose_digest_fnv64'] for s in states],
         'summary':{k:sum(float(s.get(k,0)) for s in states) for k in states[0] if k.endswith('_ms') or k.endswith('_queries') or k.startswith('mesh_') or k.startswith('exact_')}}
    rows.append(row)
    print(json.dumps({k:v for k,v in row.items() if k not in ('poses','summary')}),flush=True)
result={'exe':str(exe),'exe_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'cases':rows}
if a.compare:
    before=json.loads(a.compare.read_text())
    assert len(before['cases'])==len(rows)
    result['comparison']=[]
    for b,n in zip(before['cases'],rows):
        assert b['fixture_sha256']==n['fixture_sha256'] and b['poses']==n['poses'],f'Pose/fixture mismatch: {n["fixture"]}'
        result['comparison'].append({'fixture':n['fixture'],'poses_identical':True,'before_median_ms':b['median_step_ms'],
                                     'after_median_ms':n['median_step_ms'],'improvement_percent':100*(1-n['median_step_ms']/b['median_step_ms']) if b['median_step_ms'] else None})
(out/'replay.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
