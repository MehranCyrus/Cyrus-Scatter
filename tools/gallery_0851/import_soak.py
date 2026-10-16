"""One hour of alternating clone/share transactions; no scene resets or Undo flush."""
from pathlib import Path
import argparse,hashlib,json,subprocess,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('--seconds',type=int,default=3600);p.add_argument('--cycles',type=int,default=60);a=p.parse_args();folder=a.profile.resolve()
assert a.seconds>0 and a.cycles>0
assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-gallery0851-')
run=uuid.uuid4().hex;out=folder/('import-soak-'+run+'.json');started=time.monotonic();results=[]
(folder/'soak-run.txt').write_text(run,encoding='utf-8')
try:
 while time.monotonic()-started<a.seconds or len(results)<a.cycles:
  cycle=len(results)+1;begin=time.monotonic();(folder/'soak-cycle.txt').write_text(str(cycle),encoding='utf-8')
  for phase in ('begin','undo','redo','finish'):
   (folder/'soak-phase.txt').write_text(phase,encoding='utf-8')
   completed=subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(folder),str(ROOT/'tools/gallery_0851/import_soak.ms'),'--timeout','120'],capture_output=True,text=True)
   if completed.returncode:raise RuntimeError(completed.stdout+completed.stderr)
   # Undo callbacks can defer ordinary display-helper disposal. Yield to the
   # actual Max event loop; still require exact inventory, including helpers.
   if phase!='finish':time.sleep(1)
  log=folder/f'import-soak-{run}-cycle-{cycle}.txt'
  if completed.returncode or not log.is_file() or 'PASS: complete' not in log.read_text(encoding='utf-8-sig'):raise RuntimeError(completed.stdout+completed.stderr)
  results.append({'cycle':cycle,'seconds':time.monotonic()-begin,'elapsed':time.monotonic()-started,'log':str(log),'fixture_sha256':hashlib.sha256((ROOT/'tools/gallery_0851/import_soak.ms').read_bytes()).hexdigest()})
  out.write_text(json.dumps({'status':'running','cycles':results},indent=2),encoding='utf-8')
  if cycle%5==0:print('Import/reuse soak',cycle,'cycles',round(time.monotonic()-started),'seconds',flush=True)
  delay=a.seconds/a.cycles-(time.monotonic()-begin)
  if delay>0:time.sleep(delay)
 out.write_text(json.dumps({'status':'passed','seconds':time.monotonic()-started,'cycles':results},indent=2),encoding='utf-8')
 print('PASS',out,flush=True)
except Exception as error:
 out.write_text(json.dumps({'status':'failed','seconds':time.monotonic()-started,'error':str(error),'cycles':results},indent=2),encoding='utf-8');raise
