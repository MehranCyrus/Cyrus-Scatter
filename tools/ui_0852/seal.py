"""Seal the completed owned UI correction without rebuilding qualified bytes."""
from pathlib import Path
import ast,hashlib,json,shutil,zipfile
ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'build/ui-0852-20261016-01';DOC=ROOT/'docs/plans/preset-gallery-improvements'
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
def record(path):return {'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
profiles=['foundation-ui0852-fixed-0-20261016-01','foundation-ui0852-fixed-1-20261016-01','foundation-ui0852-fixed-15-20261016-01','foundation-ui0852-recipient-c25417d4']
hosts=[]
for name in profiles:
 out=ROOT/'build/mcp-qualification'/name
 assert read(out/'ui-acceptance.json')['status']=='passed'
 assert (out/'closed-owned-session.txt').exists(),name
 names=['launch.json','ready.json','ui-acceptance.json','layout-layout-0.json','layout-layout-1.json','library-1000x680.json','library-850x620.json','library-1120x760.json','library-browse.json']
 layouts=[read(out/f'layout-layout-{i}.json') for i in (0,1)]
 assert all(j['status']=='passed' and j['clipped_count']==j['overlap_count']==0 for j in layouts)
 library=read(out/'library-1000x680.json');assert library['status']=='passed' and library['passive']
 host={'profile':name,'launch':record(out/'launch.json'),'panel_owner_layouts':sum(len(j['pages']) for j in layouts),'clipped':0,'overlap':0,'library':{k:library[k] for k in ['raw_scale','effective_scale','normalized_scale','font_points','dpi']}}
 if name in (profiles[0],profiles[2]):
  assert read(out/'ui-lifecycle.json')['status']=='passed';names+=['ui-lifecycle.json','visible-controls.json','pending-9.json','manual.json','live.json']
  host['native_gestures']=40;host['remounts']=10;host['idle_seconds']={mode:read(out/(mode+'.json'))['seconds'] for mode in ('manual','live')}
  assert all(v>=120 for v in host['idle_seconds'].values())
  for cycle in range(10):
   for gesture in ('wheel','drag'):
    for direction in ('down','up'):
     file=f'cycle-{cycle}-{gesture}-{direction}.json';j=read(out/file)
     assert j['status']=='passed' and j['moved'] and j['passive'] and j['state_before']==j['state_after'] and j['capture_before']==j['capture_after'];names.append(file)
 if name==profiles[-1]:
  assert read(out/'result.json')['status']=='passed';names+=['result.json','installer-wrapper-30fcd1d1c6534edda4399b559d17dc42.json']
 host['witnesses']=[record(out/n) for n in names];host['closed_marker']=record(out/'closed-owned-session.txt');hosts.append(host)
receipt=read(BASE/'native-01/receipt.json')
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
for name,digest in receipt['sources'].items():assert sha(ROOT/name)==digest,name
for name,digest in receipt['binaries'].items():assert sha(ROOT/name)==digest,name
candidate=read(BASE/'package-01/candidate.json');manifest=candidate['manifest'];assert manifest['version']=='0.85.2' and manifest['max_year']==2027
assert sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==candidate['script_sha256']==manifest['files']['CyrusScatter.ms']
assert sha(BASE/'native-01/receipt.json')==candidate['native_receipt_sha256']
mzp=BASE/'package-01/CyrusScatter-0.85.2-Max2027.mzp';exe=BASE/'package-01/CyrusScatter-0.85.2-Max2027-Setup.exe'
assert sha(mzp)==candidate['mzp_sha256'] and sha(exe)==candidate['exe_sha256']
with zipfile.ZipFile(mzp) as z:
 assert z.testzip() is None and set(z.namelist())==set(manifest['files'])|{'manifest.json'}
 for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest
 assert b'29000' in z.read('install.ms') and b'0.85.2' in z.read('install.ms')
previous=read(DOC/'PACKAGE_0851.json')['payload_manifest']['files']
unchanged=[name for name in manifest['files'] if name.startswith('Library/') and name not in ('Library/README.md','Library/inventory.json')]
assert all(previous[name]==manifest['files'][name] for name in unchanged)
dest=ROOT/'dist/CyrusScatter-0.85.2-20261016';dest.mkdir(exist_ok=True)
artifacts=[]
for source in (mzp,exe):
 target=dest/source.name
 if target.exists():assert sha(target)==sha(source)
 else:shutil.copy2(source,target)
 artifacts.append({**record(target),'bytes':target.stat().st_size})
package={'version':'0.85.2','max_year':2027,'signed':False,'artist_profile_installed':False,'artifacts':artifacts,'payload_manifest':manifest,'native_receipt':record(BASE/'native-01/receipt.json'),'qualified_script_sha256':candidate['script_sha256'],'unchanged_library_content_files':len(unchanged),'owned_recipient_actual_exe_and_mzp':'passed'}
(DOC/'PACKAGE_0852.json').write_text(json.dumps(package,indent=2)+'\n')
fixtures=list((ROOT/'tools/ui_0852').glob('*.py'))
for path in fixtures:ast.parse(path.read_text(encoding='utf-8-sig'),filename=str(path))
qualification={'version':'0.85.2','status':'passed for the declared UI correction subset','baseline_commit':'4eed74777e23c4c1c1a6490c80e2e09ded436d37','branch':'codex/workflow-0.75','max_year':2027,'script_sha256':candidate['script_sha256'],'native_receipt':record(BASE/'native-01/receipt.json'),'native_inputs_rehashed':len(receipt['sources']),'native_suites':39,'native_test_log':record(BASE/'native-01/tests.log'),'python_tests':166,'python_result':'166 passed, 25.96 s; terminal result observed in this campaign, raw log not retained','generated':record(BASE/'generated-01/generated-check.json'),'fixtures':{p.relative_to(ROOT).as_posix():sha(p) for p in fixtures},'pre_raise_native_fixture':record(BASE/'fixture-predecessors/navigation-native-occluded.py'),'hosts':hosts,'failed_occluded_predecessor':record(BASE/'fixture-predecessors/occluded-default/ui-lifecycle.json'),'limitations':['Actual native window messages; no desktop pointer motion or physical mouse/tablet qualification','Configured 0/default, 1/100%, 1.5/150% on DeviceDpi 96; physical 4K/mixed-monitor transitions unqualified','Native panel bounds are measured; black native software snapshots are not visual acceptance','Earlier 0.85.1 recipe/asset/renderer/heavy-memory gates remain historical and were not rerun by this UI patch','Artist profile not installed into or restarted; website build is not publication']}
(DOC/'QUALIFICATION_0852.json').write_text(json.dumps(qualification,indent=2)+'\n')
print('Sealed',dest,'with',sum(h['panel_owner_layouts'] for h in hosts),'panel/owner layouts')
