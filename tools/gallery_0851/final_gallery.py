"""Serial exact-recipient gallery performance, idle and thirty-minute lifecycle."""
from pathlib import Path
import argparse,json,subprocess,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('--current-scene',action='store_true');p.add_argument('--native-rows',action='store_true');a=p.parse_args();folder=a.profile.resolve()
assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-gallery0851-')
result={'status':'running','steps':[]};out=folder/('final-gallery-'+uuid.uuid4().hex+'.json')
def run(fixture,command):
 if a.native_rows:command={**command,'native_rows':True,'retained_fixture':a.current_scene}
 (folder/'command.json').write_text(json.dumps(command),encoding='utf-8')
 done=subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(folder),str(ROOT/'tools/gallery_0851'/fixture),'--timeout','120'],capture_output=True,text=True)
 result['steps'].append({'fixture':fixture,'command':command,'exit_code':done.returncode,'transport':done.stdout+done.stderr});out.write_text(json.dumps(result,indent=2),encoding='utf-8')
 if done.returncode:raise RuntimeError(done.stdout+done.stderr)
def settled():
 end=time.monotonic()+300
 while True:
  run('collections_performance.py',{'operation':'status'})
  status=json.loads((folder/'performance-status.json').read_text(encoding='utf-8'))
  if not status['scanning'] and not status['loading']:return
  if time.monotonic()>end:raise RuntimeError('Catalog/decode deadline: '+str(status))
  time.sleep(3)
try:
 run('collections.py',{'operation':'open','current_scene':a.current_scene});settled();run('collections.py',{'operation':'verify'});settled()
 for count in (128,2000,10000):
  print('Catalog',count,flush=True);run('collections_performance.py',{'operation':'large_start','count':count});settled();run('collections_performance.py',{'operation':'large_verify'});settled()
 for mode in ('manual','live'):
  run('collections_performance.py',{'operation':'idle_start','mode':mode});print('Idle',mode,flush=True)
  until=time.monotonic()+122
  while time.monotonic()<until:time.sleep(min(30,until-time.monotonic()))
  run('collections_performance.py',{'operation':'idle_verify','mode':mode})
 print('Starting thirty-minute installed gallery soak',flush=True)
 done=subprocess.run([sys.executable,str(ROOT/'tools/gallery_0851/gallery_soak.py'),str(folder)])
 assert done.returncode==0
 result['status']='passed';out.write_text(json.dumps(result,indent=2),encoding='utf-8');print('PASS',out,flush=True)
except Exception as error:result['status']='failed';result['error']=str(error);out.write_text(json.dumps(result,indent=2),encoding='utf-8');raise
