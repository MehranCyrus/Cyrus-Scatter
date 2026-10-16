from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args();out=a.profile.resolve()
assert out.parent==ROOT/'build/mcp-qualification' and out.name.startswith('foundation-ui0852-')
report={'status':'running','steps':[]};target=out/'ui-lifecycle.json'
def run(fixture,command,file):
 (out/file).write_text(json.dumps(command));done=subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(out),str(ROOT/'tools/ui_0852'/fixture),'--timeout','120'],capture_output=True,text=True)
 report['steps'].append({'fixture':fixture,'command':command,'exit_code':done.returncode,'transport':done.stdout+done.stderr});target.write_text(json.dumps(report,indent=2))
 if done.returncode:raise RuntimeError(done.stdout+done.stderr)
def life(op,label):run('lifecycle.py',{'operation':op,'label':label},'lifecycle-command.json')
try:
 life('controls','visible-controls');life('warm','warm-1');time.sleep(2);life('warm','warm-2');time.sleep(1);life('pending','pending')
 for cycle in range(10):
  life('clear',f'clear-{cycle}');time.sleep(.3);life('mount',f'mount-{cycle}');time.sleep(.7)
  run('native_navigation.py',{'operation':'configure','width':260 if cycle%2==0 else 600,'publish':False,'label':f'column-{cycle}'},'navigation-command.json');time.sleep(.5)
  previous=None;stable=0
  for sample in range(12):
   run('native_navigation.py',{'operation':'columns','label':f'columns-{cycle}-{sample}'},'navigation-command.json')
   current=json.loads((out/'native-columns-current.json').read_text());stable=stable+1 if current==previous else 0;previous=current
   if stable>=2:break
   time.sleep(.5)
  else:raise RuntimeError('Native column layout did not settle')
  for gesture,direction in [('wheel','down'),('wheel','up'),('drag','down'),('drag','up')]:
   command={'operation':'prepare_probe','label':f'cycle-{cycle}-{gesture}-{direction}-prepare','gesture':gesture,'direction':direction}
   for attempt in range(8):
    run('native_navigation.py',command,'navigation-command.json');time.sleep(.3)
    if json.loads((out/'navigation-prepared.json').read_text())['ready']:break
   else:raise RuntimeError('No visible overflowing nested background after bounded preparation')
   command.update(operation='probe',label=f'cycle-{cycle}-{gesture}-{direction}-delivered')
   run('native_navigation.py',command,'navigation-command.json');time.sleep(.3)
   command.update(operation='verify_probe',label=f'cycle-{cycle}-{gesture}-{direction}')
   run('native_navigation.py',command,'navigation-command.json')
  life('verify_pending',f'pending-{cycle}')
  print('Remount',cycle+1,flush=True)
 for mode in ('manual','live'):
  if mode=='live':life('live','live-mode');time.sleep(2)
  life('idle_start',mode);print('Idle',mode,flush=True)
  deadline=time.monotonic()+122
  while time.monotonic()<deadline:time.sleep(min(30,deadline-time.monotonic()))
  run('lifecycle.py',{'operation':'idle_verify','label':mode},'lifecycle-command.json')
 report['status']='passed';target.write_text(json.dumps(report,indent=2));print('PASS',target,flush=True)
except Exception as error:
 report['status']='failed';report['error']=str(error);target.write_text(json.dumps(report,indent=2));raise
