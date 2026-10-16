"""Drive 60 cycles through the owned host transport, allowing its event loop to settle."""
from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args();folder=a.profile.resolve()
assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-gallery0851-')
results=[]
for cycle in range(1,61):
 start=time.perf_counter()
 for operation in ('begin','catalog','finish'):
  deadline=time.monotonic()+30
  while True:
   (folder/'command.json').write_text(json.dumps({'operation':operation,'cycle':cycle}),encoding='utf-8')
   subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(folder),str(ROOT/'tools/gallery_0851/lifecycle.py'),'--timeout','30'],check=True,capture_output=True,text=True)
   result=json.loads((folder/'lifecycle-current.json').read_text(encoding='utf-8'))
   if result['status']=='passed':break
   if result['status']!='waiting' or time.monotonic()>deadline:raise RuntimeError(result)
   time.sleep(.1)
 result['cycle_ms']=(time.perf_counter()-start)*1000;results.append(result)
 (folder/'lifecycle-summary.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
 if cycle%10==0:print('Completed',cycle,'cycles;',result['resources'],flush=True)
print('PASS: 60 complete owned open/index/decode/close cycles',flush=True)
