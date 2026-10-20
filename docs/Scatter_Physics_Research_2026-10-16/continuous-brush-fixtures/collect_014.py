"""Verify and retain bounded evidence for the standalone 0.1.4 delivery."""
from pathlib import Path
import hashlib,json,math,statistics,zipfile

ROOT=Path(__file__).resolve().parents[3]
DOC=Path(__file__).resolve().parents[1]
RUN=ROOT/'build/physics-continuous-014-20261017-01'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
receipt=read(RUN/'qualified/receipt.json')
assert receipt['version']=='0.1.4' and receipt['max_year']==2027 and not receipt['faults']
assert all(sha(ROOT/'CyrusPhysicsLab'/p)==h for p,h in receipt['source_hashes'].items())
assert all(sha(RUN/'qualified'/p)==h for p,h in receipt['binaries'].items())
package=ROOT/'dist/CyrusPhysicsLab-0.1.4-20261017-03/CyrusPhysicsLab-0.1.4-Max2027.mzp'
with zipfile.ZipFile(package) as z:
 assert z.testzip() is None
 manifest=json.loads(z.read('manifest.json'))
 assert all(hashlib.sha256(z.read(p)).hexdigest()==h for p,h in manifest['payload'].items())
 for name in ['CyrusPhysicsLab.dlx','CyrusPhysicsStorage.dlh','CyrusPhysicsCrashWatch.exe']:
  assert manifest['payload']['native/'+name]==receipt['binaries'][name]
 assert manifest['payload']['scripts/CyrusPhysicsLab.ms']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
 assert '29000' in z.read('install.ms').decode('utf-8-sig')
 assert all('Probe' not in p for p in z.namelist())

e={'product':'CyrusPhysicsLab','version':'0.1.4','date':'2026-10-17','max_year':2027,
   'computer_use':False,'integrated_into_scatter':False,'artist_installation':False,
   'qualified_build':str((RUN/'qualified').relative_to(ROOT)), 'build_receipt':receipt,
   'package':{'path':str(package.relative_to(ROOT)),'sha256':sha(package),'bytes':package.stat().st_size,'manifest':manifest},
   'native_tests':(RUN/'qualified/LastTest.log').read_text(),
   'stress':read(RUN/'stress-qualified.json'),'host':{}}
for label,name in [('installed','physics-lab-014-installer-01'),('secondary','physics-lab-014-secondary-host-03'),('recovery','physics-lab-014-recovery-host-03'),('faults','physics-lab-014-fault-host-04'),('timing','physics-lab-014-performance-host-02')]:
 p=ROOT/'build'/name
 assert (p/'completed.json').exists() and not (p/'error.txt').exists()
 e['host'][label]={'path':str(p.relative_to(ROOT)),'launch':read(p/'launch.json'),'assertions':(p/'assertions.txt').read_text(encoding='utf-8-sig')}
 if label not in ['faults']:
  assert all(v==receipt['binaries'][k] for k,v in e['host'][label]['launch']['binaries'].items())
installation=read(ROOT/'build/physics-lab-014-installer-01/installer-receipt.json')
assert installation['pass'] and not installation['normal_profile_modified'] and installation['package_sha256']==sha(package)
e['host']['installed']['installer_receipt']=installation
e['host']['secondary']['layout']=read(ROOT/'build/physics-lab-014-secondary-host-03/ui-layout.json')
assert all(x['inside'] and x['glyphs_fit'] for p in e['host']['secondary']['layout'] for x in p['controls'])
assert not any(p['overlaps'] for p in e['host']['secondary']['layout'])
e['fault_build']=read(RUN/'native-01/receipt.json');assert e['fault_build']['faults']
assert e['fault_build']['source_hashes']==receipt['source_hashes']

e['timing_comparison']={}
for label,name in [('before','physics-lab-014-performance-host-01'),('after','physics-lab-014-performance-host-02')]:
 p=ROOT/'build'/name;j=read(p/'latency.json');samples=sorted(j['latency_ms']);f=next(p.glob('diagnostics/*/live-recovery-0.json'))
 e['timing_comparison'][label]={**j,'p50_ms':statistics.median(samples),'p95_ms':samples[math.ceil(.95*len(samples))-1],'max_ms':max(samples),'recovery_bytes':f.stat().st_size,'recovery_sha256':sha(f)}
e['timing_comparison']['scope']='Same final native pair; timing preceded only the subsequent long-error-label layout fix. No physical input or presented-frame timing. Shared workstation, not an exclusive benchmark.'

e['crash']={}
for name in ['physics-lab-014-fatal-02','physics-lab-014-hardkill-02']:
 p=ROOT/'build'/name;folder=next((p/'diagnostics').iterdir());recovery=folder/'live-recovery-0.json'
 events=[json.loads(line) for f in sorted(folder.glob('events-*.jsonl')) for line in f.read_text().splitlines()]
 assert events and all(a['seq']<b['seq'] for a,b in zip(events,events[1:]))
 data=read(recovery);assert data['core']['schema']==2 and len(data['core']['current']['births'])==3
 item={'path':str(p.relative_to(ROOT)),'launch':read(p/'launch.json'),'exit':read(folder/'process-exit.json'),'core_solver':data['core']['solver'],'recovery_bytes':recovery.stat().st_size,'recovery_sha256':sha(recovery),'events':len(events),'first_sequence':events[0]['seq'],'last_sequence':events[-1]['seq']}
 assert all(v==receipt['binaries'][k] for k,v in item['launch']['binaries'].items())
 if 'fatal' in name:
  dump=folder/'exception-1.dmp';assert dump.read_bytes()[:4]==b'MDMP'
  item['dump']={'path':str(dump.relative_to(ROOT)),'sha256':sha(dump),'bytes':dump.stat().st_size,'receipt':read(folder/'exception-1.dmp.json')}
  assert item['dump']['receipt']['dump_written']
  item['attempts']=[json.loads(x) for x in (folder/'dump-attempts.jsonl').read_text().splitlines()]
 else:assert item['exit']['exit_code']==77 and item['exit']['exception_notifications']==0
 e['crash'][name]=item
e['limits']=['Physical mouse/tablet feel, presented FPS and artist acceptance remain open.','5,000 distributed low-poly bodies is a capacity stress, not an interactive or dense-pile promise.','Sampled native process memory is not a global allocation-failure guarantee.','Last unflushed commands/steps can be absent from crash recovery.','Development native-01 now contains private fault modules; qualified/ and the MZP contain the ordinary pair.']
(DOC/'CONTINUOUS_BRUSH_014_EVIDENCE.json').write_text(json.dumps(e,indent=2)+'\n',encoding='utf-8')
print('PASS source, ordinary/fault pair, package, installed restart, geometry, recovery, diagnostics and evidence identities')
