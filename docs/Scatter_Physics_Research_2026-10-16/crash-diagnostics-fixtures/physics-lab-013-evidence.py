from pathlib import Path
import hashlib,json,struct,subprocess,shutil

R=Path.cwd()
D=R/'docs/Scatter_Physics_Research_2026-10-16'
B=R/'build/physics-lab-013-delivery-20261017-02'
def digest(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def ref(p):p=Path(p);return {'path':p.relative_to(R).as_posix(),'sha256':digest(p),'bytes':p.stat().st_size}
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def logs(folder):
 result=[]
 for p in sorted(folder.glob('diagnostics/*/events-*.jsonl')):
  result.extend(json.loads(l) for l in p.read_text().splitlines())
 return sorted(result,key=lambda x:x['seq'])
def artifacts(folder):
 return [ref(p) for p in sorted(folder.rglob('*')) if p.is_file() and
         (p.suffix.lower() in ('.json','.jsonl','.dmp','.tsv','.ms','.txt') and
          ('diagnostics' in p.parts or p.parent==folder))]

receipt=read(B/'receipt.json')
for p,h in receipt['source_hashes'].items():
 assert digest(R/'CyrusPhysicsLab'/p)==h,p
 assert digest(B/'source/CyrusPhysicsLab'/p)==h,p
for p,h in receipt['shared_source_hashes'].items():assert digest(R/p)==h,p
for p,h in receipt['binaries'].items():assert digest(B/p)==h,p
full=R/'build/physics-lab-013-final-03'
launch=read(full/'launch.json')
assert (full/'completed.json').exists() and not (full/'error.txt').exists()
assert launch['binaries']=={k:receipt['binaries'][k] for k in launch['binaries']}
assert launch['script_sha256']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
lines=logs(full)
memory=[x['data'] for x in lines if 'maxscript_heap_free_bytes' in x['data']]
assert memory and all(x['process_memory']['available'] for x in memory)
assert any(x['event']=='paint.ignored.closed' for x in lines)
assert any(x['event']=='stroke.cancel.ignored.rejected' for x in lines)

fatal=R/'build/physics-lab-013-fatal-03'
hard=R/'build/physics-lab-013-hardkill-02'
for folder in (fatal,hard):
 launch=read(folder/'launch.json')
 assert launch['binaries']=={k:receipt['binaries'][k] for k in launch['binaries']}
 assert launch['script_sha256']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
 assert launch['diagnostic_helper_sha256']==receipt['binaries']['CyrusPhysicsCrashWatch.exe']
 assert logs(folder)
fdir=next((fatal/'diagnostics').iterdir())
status=read(fdir/'exception-1.dmp.json')
assert status['dump_written'] and status['error']==0
dump=fdir/'exception-1.dmp';raw=dump.read_bytes()
signature,version,streams,rva=struct.unpack_from('<4sIII',raw)
assert signature==b'MDMP'
streamInfo=[];exception=None;memoryRanges=0;threadContexts=0
for i in range(streams):
 kind,size,offset=struct.unpack_from('<III',raw,rva+i*12)
 assert offset+size<=len(raw)
 streamInfo.append({'type':kind,'size':size,'rva':offset})
 if kind==6:
  exception={'thread':struct.unpack_from('<I',raw,offset)[0],
             'code':struct.unpack_from('<I',raw,offset+8)[0],
             'address':struct.unpack_from('<Q',raw,offset+24)[0]}
  contextSize,contextRva=struct.unpack_from('<II',raw,offset+160)
  assert contextSize and contextRva+contextSize<=len(raw)
 if kind==5:
  count=struct.unpack_from('<I',raw,offset)[0]
  for j in range(count):
   address,length,where=struct.unpack_from('<QII',raw,offset+4+j*16)
   assert where+length<=len(raw)
  memoryRanges=count
 if kind==3:
  count=struct.unpack_from('<I',raw,offset)[0]
  for j in range(count):
   row=offset+4+j*48
   stackSize,stackRva,contextSize,contextRva=struct.unpack_from('<IIII',raw,row+32)
   assert stackRva+stackSize<=len(raw) and contextRva+contextSize<=len(raw)
  threadContexts=count
assert exception and exception['code']==0xc0000005
modules=read(fdir/'modules.json')
module=next(m for m in modules if m['base']<=exception['address']<m['base']+m['size'])
assert module['name']=='CyrusPhysicsProbe.dlx'
assert any(x['event']=='qa.before_forced_access_violation' for x in logs(fatal))
hardRecords=logs(hard)
assert hardRecords[-1]['event']=='qa.before_terminate_process'
hdir=next((hard/'diagnostics').iterdir())
assert read(hdir/'process-exit.json')['exit_code']==77

installed=R/'build/physics-lab-013-installed-02'
install=read(installed/'installer-receipt.json')
assert install['pass'] and install['normal_profile_modified'] is False
package=R/'dist/CyrusPhysicsLab-0.1.3-20261017-02/CyrusPhysicsLab-0.1.3-Max2027.mzp'
packageReceipt=read(package.parent/'package.json')
assert install['package_sha256']==digest(package)==packageReceipt['package_sha256']
for name,row in install['installed_pair'].items():assert row['sha256']==receipt['binaries'][name]
installedRoot=Path(next(iter(install['installed_pair'].values()))['path']).parent
assert digest(installedRoot/'CyrusPhysicsCrashWatch.exe')==receipt['binaries']['CyrusPhysicsCrashWatch.exe']
normal=read(R/'build/physics-lab-013-delivery-20261017-01/normal-profile-before-installer.json')
changed=[p for p,h in normal.items() if (digest(p) if Path(p).exists() else None)!=h]
assert not changed,changed

baseline=R/'build/physics-lab-013-old-crash-01'
error=(baseline/'error.txt').read_text()
assert 'C0000005' in error and '0000000000000100' in error
assert 'Wait for settling before another stroke' in (baseline/'before-late.json').read_text()
assert not (baseline/'unexpected-return.txt').exists()
oldpackage=R/'dist/CyrusPhysicsLab-0.1.2-20261016/CyrusPhysicsLab-0.1.2-Max2027.mzp'
assert digest(oldpackage)=='81b97157e364ea44fa11d58dc595d024014836e972f96faed966ad094714acae'

private=D/'crash-diagnostics-fixtures';private.mkdir(exist_ok=True)
for name in ['physics-lab-013-baseline-fixture.ms','physics-lab-013-lifecycle.ms','physics-lab-013-final-suite.ms',
             'physics-lab-013-crash-common.ms','physics-lab-013-fatal.ms','physics-lab-013-hardkill.ms','physics-lab-013-crash-runner.py']:
 shutil.copy2(R/'build'/name,private/name)
shutil.copy2(__file__,private/Path(__file__).name)

evidence={
 'product':'CyrusPhysicsLab','version':'0.1.3','max_year':2027,'schema':1,'solver_profile':'cpl-leaf-3',
 'date':'2026-10-17','scope':{'computer_use':False,'artist_profile_install_restart':False,'main_scatter_preset_changes':False,'commit_push':False},
 'baseline':{'launch':read(baseline/'launch.json'),'before_late':read(baseline/'before-late.json'),
             'error':error,'error_receipt':ref(baseline/'error.txt'),
             'observation':'Ordinary 0.1.2 Start/Stop/Start, release, rejected late callback clears session, next late hit causes native read AV at 0x100. MaxScript catches this injected SDK callback fault; not proof of the exact artist crash stack.',
             'private_driver_note':'The later private probe added a rejected-finish command after this baseline; the baseline private DLL hash was not separately frozen. Product native/script hashes and the exact executed fixture/error are retained.'},
 'build':{'receipt':ref(B/'receipt.json'),'identity':receipt,'native_pdb':ref(B/'CyrusPhysicsLab.pdb')},
 'full_host':{'folder':str(full.relative_to(R)),'launch':read(full/'launch.json'),'artifacts':artifacts(full),
              'assertions':(full/'assertions.txt').read_text(),'lifecycle_assertions':(full/'lifecycle-assertions.txt').read_text(),
              'qualification':'Final native/script hashes match. Helper was subsequently changed only for first/latest atomic dump publication and was separately qualified by final forced-fault, abrupt-exit and installed-pair tests.'},
 'memory':{'scope':'Owned final native/script tests; not the artist session or the original 0.1.2 baseline.',
           'samples':len(memory),'heap_free_bytes_min':min(x['maxscript_heap_free_bytes'] for x in memory),
           'heap_free_bytes_max':max(x['maxscript_heap_free_bytes'] for x in memory),
           'private_bytes_min':min(x['process_memory']['private_bytes'] for x in memory),
           'private_bytes_max':max(x['process_memory']['private_bytes'] for x in memory)},
 'fatal_capture':{'launch':read(fatal/'launch.json'),'artifacts':artifacts(fatal),'dump':ref(dump),
                  'status':status,'exception':exception,'fault_module':module,'streams':streamInfo,
                  'checked_memory_ranges':memoryRanges,'checked_thread_contexts':threadContexts,
                  'attempts':[json.loads(l) for l in (fdir/'dump-attempts.jsonl').read_text().splitlines()],
                  'note':'First complete original-fault dump is valid. A later rethrow dump attempt returned partial-copy when the owned harness terminated lingering Max (exit 78); its temporary file was not published and the complete first dump remained.'},
 'hard_termination':{'launch':read(hard/'launch.json'),'artifacts':artifacts(hard),
                     'exit':read(hdir/'process-exit.json'),'last_flushed_event':hardRecords[-1],
                     'pass':'Exit 77 without clean shutdown preserves all complete JSONL records and the final marker; no final SEH dump is expected from TerminateProcess.'},
 'installer':{'receipt':install,'artifacts':artifacts(installed),'final_helper_sha256':digest(installedRoot/'CyrusPhysicsCrashWatch.exe')},
 'package':packageReceipt,'preservation':{'normal_profile_before':normal,'normal_profile_changed':changed,'old_package':ref(oldpackage)},
 'private_probe':{'binary':ref(R/'build/physics-lab-brush-probe-013/CyrusPhysicsProbe.dlx'),'source':ref(R/'CyrusPhysicsLab/tests/paint_probe/probe.cpp'),'in_package':False},
 'historical_iterations':[
  {'run':'build/physics-lab-013-lifecycle-01','result':'361 assertions passed on preceding instrumentation; final native/script suite repeats them.'},
  {'run':'build/physics-lab-013-final-01','result':'All ten standard fixtures passed, then duplicate private probe function registration blocked combined fixture. Only verified owned Max PID11148 was stopped; tests now consistently use one private probe.'},
  {'run':'build/physics-lab-013-final-02','result':'Full suite and 361 lifecycle assertions passed before memory metrics were added.'},
  {'run':'build/physics-lab-013-fatal-01','result':'Original fault captured; later dump was partial. Successor helper publishes atomically and preserves complete dumps.'},
  {'run':'build/physics-lab-013-fatal-02','result':'Atomic dump capture iteration; final helper changes first/latest retention, qualified in fatal-03.'},
  {'run':'build/physics-lab-013-hardkill-01','result':'Earlier native/helper abrupt-exit durability pass; final hashes repeated in hardkill-02.'},
  {'run':'build/physics-lab-013-installed-01','result':'Earlier candidate installation/restart passed; superseded by final package installed-02.'},
  {'package':'dist/CyrusPhysicsLab-0.1.3-20261017','result':'Undelivered candidate preserved; final delivery uses 20261017-02.'}],
 'knowledge':{'status':'stale_evidence','sources_checked':38,'sources_verified':15,'physics_lab_enrolled':False,'fallback':'Direct current/frozen source inspection.'},
 'git':{'branch':subprocess.check_output(['git','branch','--show-current'],text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'status':subprocess.check_output(['git','status','--short'],text=True)},
 'limits':['No physical mouse/tablet or artist-profile interaction was tested.',
           'The exact artist crash stack remains unknown until the new package records it; the reproduced 0.1.2 native null-read path is fixed.',
           'First-chance fatal-code notifications can be handled or rethrown by Max; they do not alone prove an unhandled process crash.',
           'Hard kill/fail-fast, stack exhaustion, inaccessible memory, disk failure or power loss can prevent a final dump. Flushed logs and independent exit records cover the tested abrupt-termination path.',
           'Local snapshots/dumps may include geometry/process memory; no automatic upload.',
           'The separately observed edge-footprint whole-stroke abort and empty-gesture Undo entry are not redesigned in this patch.']}
(D/'CRASH_DIAGNOSTICS_013_EVIDENCE.json').write_text(json.dumps(evidence,indent=2)+'\n')
print(json.dumps({'pass':True,'heap_samples':len(memory),'valid_dump_bytes':len(raw),'memory_ranges':memoryRanges,'thread_contexts':threadContexts,'native':receipt['binaries'],'package_sha256':digest(package)},indent=2))
