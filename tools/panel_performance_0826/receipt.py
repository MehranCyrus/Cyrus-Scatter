"""Seal final local I01/I02 evidence and source identities before packaging."""
from pathlib import Path
import hashlib,json,subprocess,re
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/panel-0826-20261015-01'
NATIVE=OUT/'script-delivery-final'
MAIN=ROOT/'build/mcp-qualification/foundation-roadmap-panel0826-final100-20261015-01'
DPI=ROOT/'build/mcp-qualification/foundation-roadmap-panel0826-final150-20261015-01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text())
native=read(NATIVE/'receipt.json')
assert native['max_year']==2027 and all(s['exit_code']==0 for s in native['stages'])
for name,digest in native['sources'].items():assert sha(ROOT/name)==digest,name
# The final follow-up only repairs three glyph captions, shortens two rollout
# headings and corrects a comment. Prove no behavior changed before reusing the
# calculation/idle campaign; qualify the final presentation in fresh hosts.
def behavior(text):
    lines=text.splitlines()[1:]
    for i,line in enumerate(lines):
        if '-- Zoom extents on a constant curve' in line:lines[i]='';continue
        if any(token in line for token in ('diversityUI_removePath.text=','diversityUI_addOutside.text=','diversityUI_addInside.text=',
                                          'rollout areasUISlot ','rollout statisticsUISlot ')):
            lines[i]=re.sub(r'"[^"\n]*"','"<caption>"',line,count=1)
    return '\n'.join(lines)
behavior_script=MAIN/'scripts/CyrusScatter.ms'
delivery_script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
assert behavior(behavior_script.read_text(encoding='utf-8-sig'))==behavior(delivery_script.read_text(encoding='utf-8-sig'))
evidence={}
for host,labels in [(MAIN,['load','panels','manual','live','live_observe','unrelated','failure','undo_observe','passive','selection-off','selection-on','paint-bands','reopen','heavy','idle-off-observe','idle-on-observe']),
                    (DPI,['load','panels','paint-bands','reopen'])]:
    launch=read(host/'launch.json')
    assert launch['max_year']==2027 and not launch['normal_profile_modified']
    assert launch['script_sha256']==sha(behavior_script)
    assert sha(host/'scripts/CyrusScatter.ms')==launch['script_sha256']
    for name,digest in launch['binaries'].items():assert sha(NATIVE/name)==sha(host/'bin'/name)==digest
    for label in labels:
        path=host/('qualification-'+label+'.json');assert read(path)['status']=='passed',path
        evidence[path.relative_to(ROOT).as_posix()]=sha(path)
    for name in ['launch.json','loaded.tsv','ready.json']:
        path=host/name;evidence[path.relative_to(ROOT).as_posix()]=sha(path)
    scale='100' if host==MAIN else '150'
    for name in ['layout-final'+scale+'.json','layout-settled'+scale+'-paint.json','layout-settled'+scale+'-bands.json']:
        path=host/name
        data=read(path);assert data['status']=='passed' and data['clipped_count']==0
        assert data['overlap_count']==0
        assert len(data['pages'])==12 and all(p['controls'] for p in data['pages'])
        evidence[path.relative_to(ROOT).as_posix()]=sha(path)
for scale in ['100','150']:
    host=ROOT/('build/mcp-qualification/foundation-roadmap-panel0826-delivery'+scale+'-20261015-01')
    launch=read(host/'launch.json')
    assert launch['script_sha256']==sha(delivery_script)==sha(host/'scripts/CyrusScatter.ms')
    for name,digest in launch['binaries'].items():assert sha(NATIVE/name)==sha(host/'bin'/name)==digest
    for name in ['launch.json','loaded.tsv','ready.json','qualification-presentation_scene.json',
                 'layout-settled'+scale+'-paint.json','layout-settled'+scale+'-bands.json']:
        path=host/name
        if name.startswith(('qualification','layout')):assert read(path)['status']=='passed'
        if name.startswith('layout'):
            data=read(path);assert len(data['pages'])==12 and data['clipped_count']==data['overlap_count']==0
        evidence[path.relative_to(ROOT).as_posix()]=sha(path)

profile=Path(read(MAIN/'launch.json')['profile_template'])
assert sha(profile)==read(MAIN/'launch.json')['profile_template_sha256']
sources=dict(native['sources'])
for base in ['AminScatter/tools/ui','tools/panel_performance_0826']:
    for path in (ROOT/base).rglob('*'):
        if path.is_file() and path.suffix in ('.ms','.cjs','.py','.json'):
            sources[path.relative_to(ROOT).as_posix()]=sha(path)
result={'version':'0.82.6','max_year':2027,'source_hashes':sources,'evidence':evidence,
        'behavior_script_sha256':sha(behavior_script),'presentation_only_delta_verified':True,
        'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'native_receipt_sha256':sha(NATIVE/'receipt.json'),
        'normal_profile_modified':False,'installed':False,'phase6':'paused',
        'limits':['100% and 150% Max custom UI scaling in private profiles; no physical 4K/mixed-monitor certification.',
                  'Local synthetic scene timings, not arbitrary scene/renderer/FPS guarantees.']}
(OUT/'final-receipt.json').write_text(json.dumps(result,indent=2)+'\n')
print(OUT/'final-receipt.json')
