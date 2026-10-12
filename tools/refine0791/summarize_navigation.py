"""Validate and retain compact receipts for the point-example navigation study."""
from pathlib import Path
import hashlib,json,statistics,shutil

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'docs/Point_Workflow_0.79.1_2026-10-11'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def diff(before,after):
    changes=[]
    assert [n['name'] for n in before]==[n['name'] for n in after]
    for b,a in zip(before,after):
        for key in ('epoch','groups','layers'):
            if b[key]!=a[key]:changes.append(dict(node=b['name'],field=key,before=b[key],after=a[key]))
        # Draw count may advance; all publication/preparation/upload identities must stay put.
        if b['retained'] is not None:
            for i in (0,1,2,3,4,5,6,8,9,10,11,12):
                if b['retained'][i]!=a['retained'][i]:changes.append(dict(node=b['name'],field='retained_'+str(i),before=b['retained'][i],after=a['retained'][i]))
    return changes

source=ROOT/'build/vector-brush-078/include-exclude-visible2026-01/Include_Exclude_Point_Examples.max'
evidence=dict(baseline_commit='15957a66de0480679dea6c533c7c5d09d9598d54',product_modified=False,
    scene=dict(path=str(source),sha256_after=sha(source),size=source.stat().st_size),hosts={},
    limits=['Scripted synchronous redraw duration is not presented FPS.',
            'Cached-access/overlay-suppression variants are private diagnostics, not a shipped fix.',
            'Saved Top view and fitted perspective use private viewport sizes, not an exact reproduction of the artist window.',
            'Two ordinary Max processes were also open; perspective campaigns were serialized.',
            'The first Max 2026 Top-view measurements overlapped a brief failed 2027 control fixture; use the later perspective comparison.'])
for year in (2026,2027):
    folder=ROOT/f'build/mcp-qualification/refine0791-navigation{year}-01'
    load=read(folder/'navigation-load.json')
    assert not load['errors']
    assert load['input_sha256']==evidence['scene']['sha256_after']
    idle=diff(load['before_idle'],load['after_idle']);assert not idle
    host=dict(launch=read(folder/'launch.json'),loaded_modules=(folder/'loaded.tsv').read_text(encoding='utf-8'),
        inventory=load['inventory'],baseline=load['realized'],idle_changes=idle,
        load_ms=load['load_ms'],forced_update_all_ms=load['first_update_all_ms'],phases={},raw_receipts={})
    for phase in ('load','ab','perspective'):
        path=folder/f'navigation-{phase}.json';data=read(path);assert not data['errors']
        host['raw_receipts'][phase]=dict(path=str(path),sha256=sha(path))
        if phase=='load':continue
        results=[]
        for m in data['measurements']:
            delta=diff(m['before'],m['after']);assert not delta,(year,phase,m['label'],delta)
            row={k:v for k,v in m.items() if k not in ('before','after','background_before','background_after')}
            row['cache_changes']=delta
            row['breakdown_mean_per_callback_ms']={k:v/m['callbacks'] for k,v in m['breakdown_total_ms'].items()} if m['callbacks'] else None
            if 'background_before' in m:
                row['background_before']=m['background_before']
                row['background_unchanged']=m['background_before']==m['background_after']
                assert row['background_unchanged']
            results.append(row)
        host['phases'][phase]=dict(view_type=data.get('view_type'),view_tm=data.get('view_tm'),measurements=results)
    evidence['hosts'][str(year)]=host
folder=ROOT/'build/mcp-qualification/refine0791-navigation2027-01'
controls=read(folder/'navigation-controls.json');assert not controls['errors']
inventory=evidence['hosts']['2027']['inventory']
assert all(controls['restored_fingerprints'][n['name']]==[l['fingerprint'] for l in n['layers']] for n in inventory)
evidence['radius_controls']=dict(restored_fingerprints_match=True,pending_manual=controls['manual_pending_radius_change'],
    measurements=[{k:v for k,v in m.items() if k not in ('before','after','background_before','background_after')} for m in controls['measurements']],
    edits=[{k:v for k,v in c.items() if k not in ('before','after')} for c in controls['control_edits']],
    raw=dict(path=str(folder/'navigation-controls.json'),sha256=sha(folder/'navigation-controls.json')))
evidence['fixture_error']=dict(description='Initial control fixture used template control names instead of generated prefixed names. It failed before editing any radius setting; corrected and rerun.',
    errors=read(folder/'navigation-controls-fixture-error.json')['errors'])
evidence['totals']=dict(controllers=len(inventory),points=sum(l['shown'] for n in inventory for l in n['layers']),
    rings=sum(l['radii'] for n in inventory for l in n['layers']))
evidence['totals']['radius_segments']=evidence['totals']['rings']*24
evidence['fixtures']={n:sha(Path(__file__).with_name(n)) for n in ('navigation_probe.py','navigation_probe.ms','summarize_navigation.py')}
evidence['source_script_sha256']=sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
for host in evidence['hosts'].values():assert host['launch']['script_sha256']==evidence['source_script_sha256']
(DEST/'navigation-evidence.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
images=DEST/'navigation-images';images.mkdir(exist_ok=True)
shutil.copy2(folder/'navigation-perspective.png',images/'perspective.png')
print(json.dumps(dict(totals=evidence['totals'],hosts=list(evidence['hosts']),cache_changes=0,original_preserved=True,settings_restored=True)))
