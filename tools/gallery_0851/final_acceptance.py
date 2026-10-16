"""Finish exact-pair idle, bundled examples and installer-runtime checks serially."""
from pathlib import Path
import argparse,json,subprocess,sys,time,uuid,hashlib
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('--payload',required=True,type=Path);p.add_argument('--after-idle',action='store_true');p.add_argument('--examples-only',action='store_true');a=p.parse_args();folder=a.profile.resolve();payload=a.payload.resolve()
assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-gallery0851-')
assert payload.is_relative_to(ROOT/'build') and (payload/'InstallInventory.txt').is_file()
result={'status':'running','steps':[]};out=folder/('final-acceptance-'+uuid.uuid4().hex+'.json')
def save():out.write_text(json.dumps(result,indent=2),encoding='utf-8')
def run(fixture,command=None):
 if command is not None:(folder/'command.json').write_text(json.dumps(command),encoding='utf-8')
 path=ROOT/'tools/gallery_0851'/fixture;start=time.monotonic();print(fixture,command,flush=True)
 done=subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(folder),str(path),'--timeout','180'],capture_output=True,text=True)
 result['steps'].append({'fixture':fixture,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'command':command,'seconds':time.monotonic()-start,'exit_code':done.returncode,'transport':done.stdout+done.stderr});save()
 if done.returncode:raise RuntimeError(done.stdout+done.stderr)
try:
 for mode in (() if a.after_idle else ('manual','live')):
  if mode=='live':run('collections_performance.py',{'operation':'idle_start','mode':mode})
  before=json.loads((folder/('idle-'+mode+'-before.json')).read_text(encoding='utf-8'))
  while time.time()-before['started']<122:time.sleep(min(30,122-(time.time()-before['started'])))
  run('collections_performance.py',{'operation':'idle_verify','mode':mode})
 run('all_examples_prepare.py')
 for index in range(1,9):
  (folder/'example-index.txt').write_text(str(index),encoding='utf-8')
  for phase in ('prepare','apply'):
   (folder/'example-phase.txt').write_text(phase,encoding='utf-8');run('all_examples.ms');time.sleep(1)
 # Last example leaves a valid controller for the gallery, but export's own
 # fixture selects its known compatible painted-border scene and bindings.
 if not a.examples_only:
  run('package_bitmap_export.ms');time.sleep(1);run('package_export_verify.ms')
  run('import_layout.py',{'operation':'open'});time.sleep(1);run('import_layout.py',{'operation':'verify'})
  (folder/'installer-pilot-payload.txt').write_text(str(payload),encoding='utf-8')
  run('installer_host.ms')
  run('installer_mzp.py')
 result['status']='passed';save();print('PASS',out,flush=True)
except Exception as error:result['status']='failed';result['error']=str(error);save();raise
