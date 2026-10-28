"""Alternate producers on one fixture; compare exact numerical poses, not timing alone."""
from argparse import ArgumentParser
from pathlib import Path
import hashlib,json,statistics,subprocess
ROOT=Path(__file__).resolve().parents[3]
p=ArgumentParser();p.add_argument('--old',type=Path,required=True);p.add_argument('--new',type=Path,required=True)
p.add_argument('--fixture',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
out=a.output.resolve();assert out.is_relative_to(ROOT/'build');out.mkdir(parents=True,exist_ok=False)
records=[]
for i,label in enumerate(('old','new','new','old')):
    exe=(a.old if label=='old' else a.new).resolve()/'interactions_tests.exe'
    run=subprocess.run([str(exe),'--fixture',str(a.fixture.resolve()),'14'],text=True,capture_output=True)
    (out/f'{i}-{label}.stdout').write_text(run.stdout,encoding='utf-8');(out/f'{i}-{label}.stderr').write_text(run.stderr,encoding='utf-8')
    if run.returncode:raise RuntimeError(run.stderr)
    raw=json.loads(run.stdout);states=[raw['initial'],*raw['steps']]
    records.append({'label':label,'exe_sha256':hashlib.sha256(exe.read_bytes()).hexdigest(),'median_ms':raw['median_step_ms'],
                    'poses':[s['pose_digest_fnv64'] for s in states],
                    'quality_warnings':[s['quality_warning_guides'] for s in states],
                    'maximum_edge_change':[s['maximum_checked_stem_edge_change'] for s in states],
                    'work':{k:sum(float(s.get(k,0)) for s in states) for k in states[0] if k.startswith('exact_') or k.startswith('worker_') or k=='mesh_refinement_work'}})
    print(label,raw['median_step_ms'],flush=True)
assert all(r['poses']==records[0]['poses'] and r['quality_warnings']==records[0]['quality_warnings'] and r['maximum_edge_change']==records[0]['maximum_edge_change'] for r in records)
old=statistics.median(r['median_ms'] for r in records if r['label']=='old');new=statistics.median(r['median_ms'] for r in records if r['label']=='new')
result={'scope':'Copied numeric kernel, alternating producer order; not Max presented FPS','fixture':str(a.fixture.resolve()),
        'fixture_sha256':hashlib.sha256(a.fixture.read_bytes()).hexdigest(),'poses_and_warnings_identical':True,
        'old_median_ms':old,'new_median_ms':new,'improvement_percent':100*(1-new/old),'records':records}
(out/'summary.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
