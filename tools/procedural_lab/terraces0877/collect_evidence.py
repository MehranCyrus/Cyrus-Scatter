"""Summarize measured scopes without turning CPU timings into presented FPS."""
from pathlib import Path
import json,statistics,hashlib,re
ROOT=Path(__file__).resolve().parents[3];RUN=ROOT/'build/terraces0877-20261029-01'
OUT=ROOT/'docs/plans/terraces-performance-20261029';OUT.mkdir(exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def timing(v):
    s=sorted(v)
    return dict(samples=len(s),median=statistics.median(s),p95=s[min(len(s)-1,int(.95*(len(s)-1)))],maximum=max(s))
base=RUN/'host-baseline';candidate=RUN/'host-candidate'
data=dict(version='0.87.6.1',max_year=2027,scene_schema=65,recipe_format=9,edit_storage=3,interactions=15,
  status='scoped_pass',baseline='0.87.6 exact installer-r2, preserving the artist-endorsed 0.87.5.6 response',
  native_tests=dict(passed=62,total=62,host=2027,log_sha256=sha(RUN/'native-2027/tests.log')),
  package=read(RUN/'packages/PACKAGE_VERIFICATION.json'),generated=read(RUN/'generated-final/generated-check.json'))
data['input_integrity']={}
for name in ['Terraces_Final.max','Rock_Boulder_10/Rock_10.max']:
    p=ROOT/'Test Scene'/name
    data['input_integrity'][name]=dict(bytes=p.stat().st_size,sha256=sha(p))
assert data['input_integrity']['Terraces_Final.max']['sha256']==sha(RUN/'inputs/Terraces_Final.max')
data['ui']={}
for name,folder in [('baseline',base),('candidate',RUN/'host-ui-01')]:
    u=read(folder/'ui-warm.json');f=read(folder/'ui-fixture.json')
    data['ui'][name]=dict(point_label_current=f['point_label_current'],closed_page_current=u['closed_page_current'],
        epochs=[u['epoch_before'],u['epoch_after']],panels={p['name']:p['median_ms'] for p in u['panels']},stages=u['diagnostics']['measurements']['stages'])
data['ui']['final_package']=read(candidate/'ui-final-check.json')
data['contact']={}
for name,folder in [('baseline',base),('candidate',candidate)]:
    d=read(folder/'contact-sweep.json');assert d['status']=='complete'
    data['contact'][name]={c['case']:dict(fit_ms=timing([s['stats']['fit_ms'] for s in c['samples'][2:]]),
        max_queries=max(s['stats']['queries'] for s in c['samples']),max_fitted_guides=max(s['stats']['fitted_guides'] for s in c['samples']),
        fitted_guides=[s['stats']['fitted_guides'] for s in c['samples']]) for c in d['cases']}
    data['contact'][name]['orbit_work_unchanged']=all(s['stats']['process_work']==d['orbit']['before']['process_work'] for s in d['orbit']['samples'])
data['locality']=[]
for c in read(candidate/'locality-sweep.json')['cases']:
    samples=c['samples'];stats=[s.get('stats',s) for s in samples]
    data['locality'].append(dict(case=c['case'],accepted=c['accepted'],fit_ms=timing([s['fit_ms'] for s in stats[2:]]),max_affected=max(s['affected'] for s in stats),max_queries=max(s['queries'] for s in stats)))
data['proxy_comparison']=[dict(case=c['case'],faces=c['faces'],fit_ms=timing([s['fit_ms'] for s in c['samples'][2:]])) for c in read(candidate/'proxy-sweep.json')['cases']]
data['rapid']={}
for name in ['rapid-scene','rapid-edit']:
    text=(candidate/(name+'.txt')).read_text();steps=[];frames=[]
    for line in text.splitlines():
        if line.startswith('STEP '):
            m=re.match(r'STEP (\d+) native_ms:(\d+) redraw_ms:(\d+) stats:(.*)',line)
            steps.append(dict(step=int(m[1]),native_ms=int(m[2]),redraw_ms=int(m[3]),stats=json.loads(m[4])))
        elif line.startswith('FRAME '):
            m=re.match(r'FRAME #\(1, (\d+)L?, (\d+)L?, (\d+),',line)
            frames.append([int(m[i]) for i in (1,2,3)])
    assert len(steps)==24 and 'ERROR ' not in text
    data['rapid'][name]=dict(samples=len(steps),presented_during_movement=len(set(f[1] for f in frames[:12])),final_frame=frames[-1],
        fit_ms=timing([s['stats']['fit_ms'] for s in steps[:12]]),orbit_work_unchanged=len({json.dumps(s['stats']['process_work'],sort_keys=True) for s in steps[12:]})==1)
data['edit_settings']=read(candidate/'edit-settings-check.json')['status']
data['navigation']=[]
for c in read(candidate/'garden-navigation.json')['cases']:
    a,b=c['before'],c['after']
    data['navigation'].append(dict(case=c['case'],cpu_redraw_ms=timing(c['redraw_ms']),idle_triangles=sum(v['values'][5] for v in b['viewport']),navigation_triangles=sum(v['values'][6] for v in b['viewport']),
        work_unchanged=a['work']==b['work'],epochs_unchanged=a['epochs']==b['epochs'],stream_delta=[y-x for x,y in zip(a['stream'],b['stream'])],memory_estimates=b['memory']))
data['landscape']=read(candidate/'garden-drag-finish.json');assert data['landscape']['status']=='complete'
data['landscape']['drag_fit_ms']=timing([s['stats']['fit_ms'] for s in data['landscape']['samples']])
data['landscape']['counts']=sum(sum(c['counts']) for c in data['landscape']['controllers'])
data['landscape_render']=read(candidate/'garden-final-render.json')
assert data['landscape_render']['status']=='complete' and data['landscape_render']['water_renderable']
data['scene_files']={p.name:dict(bytes=p.stat().st_size,sha256=sha(p)) for p in [RUN/'Terraces_Garden_0.87.6.1_Max2027.max',RUN/'Contact_Distant_10000_Stress.max',candidate/'Terraces_Garden_0.87.6.1.png']}
data['loaded_identity']=read(candidate/'loaded-identity.json')
for name,loaded in data['loaded_identity']['modules'].items():
    assert loaded['sha256']==data['package']['builds']['2027']['native'][name]
script=(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_text(encoding='utf-8-sig')
assert data['loaded_identity']['script_fingerprint']==re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"',script)[1]
data['scene_proxy']=dict(source_triangles=752,proxy_triangles=140,reason='Source rock has an open bottom; explicit closed convex scene proxy used. No automatic convex policy added.')
data['cleanup']=dict(folders=21,logical_GiB=15.3185,scope='Older explicitly inventoried disposable build folders; small receipts archived; reparse candidate retained.')
data['limits']=['CPU/scripted redraw timings are not presented FPS or physical mouse latency.','2024/2026 compile/package only; no host execution.','Box proxy was not faster and was rejected as a general optimization. Convex proxies can fill openings.','Library 0.87.5.1 retains its own evidence.','Full renderer fidelity/long-session memory/device-loss/million-instance realtime remain unqualified.','Knowledge index and public website not rebuilt.']
(OUT/'QUALIFICATION.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(status=data['status'],version=data['version'],plants=data['landscape']['counts'],drag_fit_ms=data['landscape']['drag_fit_ms']),indent=2))
