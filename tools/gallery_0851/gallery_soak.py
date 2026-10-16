"""Thirty-minute mixed gallery exercise; host callbacks remain short and interactive."""
from pathlib import Path
import argparse,json,subprocess,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args();folder=a.profile.resolve()
assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-gallery0851-')
out=folder/('gallery-soak-'+uuid.uuid4().hex+'.json')
started=time.monotonic();results=[];baseline=None
while time.monotonic()-started<1800 or len(results)<60:
 cycle=len(results)+1;cycle_start=time.monotonic()
 for operation in ('begin','catalog','finish'):
  deadline=time.monotonic()+30
  while True:
   (folder/'command.json').write_text(json.dumps({'operation':operation,'cycle':cycle,'mixed':True}),encoding='utf-8')
   subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(folder),str(ROOT/'tools/gallery_0851/lifecycle.py'),'--timeout','30'],check=True,capture_output=True,text=True)
   result=json.loads((folder/'lifecycle-current.json').read_text(encoding='utf-8'))
   if result['status']=='passed':break
   if result['status']!='waiting' or time.monotonic()>deadline:raise RuntimeError(result)
   time.sleep(.1)
 identity=(result['fingerprint'],result['work'])
 if baseline is None:baseline=identity
 assert identity==baseline,'Passive gallery work changed scene output/work'
 result['elapsed_seconds']=time.monotonic()-started;result['cycle_seconds']=time.monotonic()-cycle_start;results.append(result)
 out.write_text(json.dumps({'status':'running','cycles':results},indent=2),encoding='utf-8')
 if cycle%5==0:print('Soak',cycle,'cycles,',round(time.monotonic()-started),'seconds',result['resources'],flush=True)
 remaining=30-(time.monotonic()-cycle_start)
 if remaining>0:time.sleep(remaining)
out.write_text(json.dumps({'status':'passed','elapsed_seconds':time.monotonic()-started,'cycles':results},indent=2),encoding='utf-8')
print('PASS',out,flush=True)
