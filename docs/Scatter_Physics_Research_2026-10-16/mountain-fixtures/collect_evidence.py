"""Verify and summarize the final 0.1.7 owned receipts without scene geometry."""
from pathlib import Path
import collections,hashlib,json,re,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[3]
RUN=ROOT/'build/physics-mountain-017-20261018-01'
DOC=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def ref(p):return {'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p)}
def main():
 native=RUN/'native-01';receipt=read(native/'receipt.json')
 assert not receipt['faults'] and receipt['version']=='0.1.7' and receipt['max_year']==2027
 for name,value in receipt['source_hashes'].items():assert sha(ROOT/'CyrusPhysicsLab'/name)==value,name
 for name,value in receipt['shared_source_hashes'].items():assert sha(ROOT/name)==value,name
 for name,value in receipt['binaries'].items():assert sha(native/name)==value,name
 scene=ROOT/'Test Scene/Mountain Scene Brush Test.max'
 assert sha(scene)==sha(RUN/'Mountain Scene Brush Test.max')=='99ee36fd84f34995ca565aa27ad6292a5b83b46a24ea7cfbe92a7ab87315b28e'
 hosts={}
 for name in ('mountain-09','icon-05','layout150-07','fault-after-04'):
  folder=ROOT/('build/physics-lab-017-'+name);assert (folder/'completed.json').exists() and not (folder/'error.txt').exists(),name
  launch=read(folder/'launch.json');expect=read(RUN/('native-fault-01' if name=='fault-after-04' else 'native-01')/'receipt.json')
  assert launch['binaries']=={n:expect['binaries'][n] for n in ('CyrusPhysicsLab.dlx','CyrusPhysicsStorage.dlh')}
  assert launch['script_sha256']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
  exits=list((folder/'diagnostics').rglob('process-exit.json'));assert len(exits)==1,name
  exit_data=read(exits[0]);assert exit_data['exit_code']==0 and exit_data['exception_notifications']==0,name
  assert (exits[0].parent/'exception.txt').stat().st_size==0,name
  hosts[name]={'launch':ref(folder/'launch.json'),'assertions':(folder/'assertions.txt').read_text(encoding='utf-8-sig'),'computer_use':launch['computer_use'],'normal_profile_modified':launch['normal_profile_modified'],'clean_exit':exit_data,'exit_receipt':ref(exits[0])}
 mountain=read(ROOT/'build/physics-lab-017-mountain-09/mountain-results.json');assert mountain['pass'] and len(mountain['cases'])==5
 for case in mountain['cases']:assert case['overlay']['bodies']==case['final']['rows']
 replay=read(RUN/'replay-09/receipt.json');assert replay['pass'] and replay['core_library_sha256']==sha(native/'cpl_core.lib')
 package=ROOT/'dist/CyrusPhysicsLab-0.1.7-20261018-04/CyrusPhysicsLab-0.1.7-Max2027.mzp'
 with zipfile.ZipFile(package) as archive:
  assert archive.testzip() is None;manifest=json.loads(archive.read('manifest.json'))
  assert manifest['version']=='0.1.7' and manifest['max_year']==2027
  for name,value in manifest['payload'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==value,name
  assert manifest['payload']['scripts/CyrusPhysicsLab.ms']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
  for name in ('CyrusPhysicsLab.dlx','CyrusPhysicsStorage.dlh','CyrusPhysicsCrashWatch.exe'):assert manifest['payload']['native/'+name]==receipt['binaries'][name]
  assert '29000' in archive.read('install.ms').decode('utf-8-sig')
 installed=read(ROOT/'build/physics-lab-017-installer-04/installer-receipt.json');assert installed['pass'] and installed['package_sha256']==sha(package)
 installed_exits=[]
 for path in (ROOT/'build/physics-lab-017-installer-04').rglob('process-exit.json'):
  j=read(path);assert j['exit_code']==0 and j['exception_notifications']==0;assert (path.parent/'exception.txt').stat().st_size==0;installed_exits.append({'receipt':ref(path),'result':j})
 # Initial installer setup creates no Lab and does not start its recorder.
 # The restarted runtime, which exercises actual Lab objects, must exit cleanly.
 assert len(installed_exits)==1 and 'restart-diagnostics' in installed_exits[0]['receipt']['path']
 assert installed['installed_script_sha256']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
 native_reports={}
 for name in ('grip','collision','mountain'):
  path=native/(name+'-results.json');j=read(path);assert j['pass'];native_reports[name]={'receipt':ref(path),'result':j}
 assert '100% tests passed' in (native/'tests.log').read_text()
 previous=read(ROOT/'build/physics-settling-016-20261018-01/native-01/grip-results.json')
 assert previous['slopes']==native_reports['grip']['result']['slopes']
 events=[]
 for path in (RUN/'artist-diagnostics').glob('events*.jsonl'):
  for line in path.read_text(encoding='utf-8').splitlines():
   try:events.append(json.loads(line))
   except ValueError:pass
 events.sort(key=lambda r:r['seq']);counts=collections.Counter(r['event'] for r in events)
 errors=[r for r in events if r['event']=='live.command.error']
 source_errors=[r for r in errors if 'Spawn separation exceeds five' in str(r['data'])]
 paused=[r for r in errors if 'Brush is paused' in str(r['data'])]
 report={'version':'0.1.7','date':'2026-10-18','scope':'standalone Physics Lab; Max 2027; no Computer Use; no artist installation; no Scatter/preset integration; no commit/push',
  'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
  'original_scene':ref(scene),'original_scene_unchanged':True,
  'artist_log':{'snapshot_path':(RUN/'artist-diagnostics').relative_to(ROOT).as_posix(),'events':len(events),'counts':dict(counts),'spawn_errors':len(source_errors),'subsequent_paused_errors':len(paused),'exception_bytes':(RUN/'artist-diagnostics/exception.txt').stat().st_size},
  'old_actual_scene_reproduction':ref(ROOT/'build/physics-lab-017-before-01/assertions.txt'),
  'native_build':ref(native/'receipt.json'),'native_suite_log':ref(native/'tests.log'),'native_reports':native_reports,'source_archive':ref(RUN/'final-source-017.zip'),
  'private_probes':{'painter':ref(ROOT/'build/physics-lab-brush-probe-013/CyrusPhysicsProbe.dlx'),'icon_hit':ref(ROOT/'build/physics-lab-icon-probe-017/CyrusPhysicsIconProbe.dlx'),'icon_hit_source':ref(Path(__file__).with_name('icon_probe.cpp'))},
  'manual_birth_slope_rows_unchanged_from_016':len(previous['slopes']),
  'hosts':hosts,'mountain':mountain,'mountain_replay':replay,
  'installer':installed,'installer_receipt':ref(ROOT/'build/physics-lab-017-installer-04/installer-receipt.json'),'installer_clean_exits':installed_exits,
  'package':ref(package),'package_bytes':package.stat().st_size,
  'limits':['Scripted SDK/rollout checks do not certify physical mouse input, displayed UI pixels or presented FPS.','Automatic convex proxies may fill concavities.','Actual mountain matrix uses individual source types and scale 0.8 to 1.2; arbitrary mixed size ranges remain unqualified.','Actual-mountain sampled normal-depth bound is 10 mm; vertical depth is reported separately. A moving composition may require Freeze.','Footprint clearance uses a conservative triangle XY height bound; multi-level receivers can choose the upper surface.','Old pending sessions require their exact solver build for Resume; cached results remain readable.','The icon contributes zero-area picking edges to the evaluated mesh. Disable it before converting/exporting that mesh. Native physical geometry and JSON recipes omit the icon. Render identity is qualified with Max 2027 Scanline, not every renderer.']}
 (DOC/'MOUNTAIN_BRUSH_017_EVIDENCE.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 print('PASS final source/pair/package/installer/scene/host/replay evidence')
if __name__=='__main__':main()
