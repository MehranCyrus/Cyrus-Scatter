"""Serial checks inside one owned host; independent hosts may run concurrently."""
from pathlib import Path
import argparse,json,subprocess,sys,time,hashlib
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('--installed',action='store_true');a=p.parse_args();out=a.profile.resolve()
assert out.parent==ROOT/'build/mcp-qualification' and out.name.startswith('foundation-ui0852-')
report={'status':'running','steps':[]};target=out/'ui-acceptance.json'
def run(fixture,command=None,file=None):
 if command is not None:(out/file).write_text(json.dumps(command),encoding='utf-8')
 before=time.perf_counter();done=subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(out),str(ROOT/'tools/ui_0852'/fixture),'--timeout','120'],capture_output=True,text=True)
 report['steps'].append({'fixture':fixture,'command':command,'exit_code':done.returncode,'seconds':time.perf_counter()-before,'transport':done.stdout+done.stderr,
  'fixture_sha256':hashlib.sha256((ROOT/'tools/ui_0852'/fixture).read_bytes()).hexdigest()});target.write_text(json.dumps(report,indent=2))
 if done.returncode:raise RuntimeError(done.stdout+done.stderr)
def pause():time.sleep(1)
try:
 run('prepare.py');pause()
 run('native_navigation.py',{'operation':'configure','width':260,'publish':True,'label':'configured'},'navigation-command.json');pause()
 for gesture in ('wheel','drag'):
  for direction in ('down','up'):
   command={'operation':'prepare_probe','label':f'fixed-{gesture}-{direction}-prepare','gesture':gesture,'direction':direction}
   for attempt in range(8):
    run('native_navigation.py',command,'navigation-command.json');pause()
    if json.loads((out/'navigation-prepared.json').read_text())['ready']:break
   else:raise RuntimeError('No visible overflowing native background')
   command.update(operation='probe',label=f'fixed-{gesture}-{direction}-delivered')
   run('native_navigation.py',command,'navigation-command.json');pause()
   command.update(operation='verify_probe',label=f'fixed-{gesture}-{direction}')
   run('native_navigation.py',command,'navigation-command.json')
 for owner in (0,1):
  run('layout.py',{'label':f'layout-{owner}-prepare','owner_index':owner,'prepare':True,'close':False,'advanced':True},'layout-command.json');pause()
  run('layout.py',{'label':f'layout-{owner}','owner_index':owner,'observe':True,'close':False,'capture':owner==0},'layout-command.json')
  data=json.loads((out/f'layout-layout-{owner}.json').read_text());assert data['status']=='passed',data
 for size in ([1000,680],[850,620],[1120,760]):
  label='library-'+'x'.join(str(x) for x in size)
  run('library.py',{'operation':'open','size':size,'installed':a.installed},'library-command.json');pause()
  deadline=time.monotonic()+60
  while True:
   run('status.py')
   if not json.loads((out/'status.json').read_text())['library_loading']:break
   if time.monotonic()>deadline:raise TimeoutError('Library completion')
   time.sleep(.3)
  run('library.py',{'operation':'verify','label':label},'library-command.json')
 run('library.py',{'operation':'browse','label':'library-browse'},'library-command.json')
 report['status']='passed';target.write_text(json.dumps(report,indent=2));print('PASS',target,flush=True)
except Exception as error:
 report['status']='failed';report['error']=str(error);target.write_text(json.dumps(report,indent=2));raise
