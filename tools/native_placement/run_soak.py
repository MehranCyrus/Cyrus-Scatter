"""At least one hour and ten mixed history/preset/copy cycles on one exact pair."""
import argparse,hashlib,json,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--seconds',type=int,default=3600);p.add_argument('--cycles',type=int,default=60);a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-') and a.seconds>=3600 and a.cycles>=10
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
script=ROOT/'tools/native_placement/soak.ms';identity=hashlib.sha256(script.read_bytes()).hexdigest()
entry=json.loads((ROOT/'AminScatter/library/inventory.json').read_text())['entries'][0]
(host/'soak-preset-path.txt').write_text((ROOT/'AminScatter/library'/entry['ready_package']).as_posix())
probe=host/'soak-ready.ms';probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"soak-ready.txt") ((CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished) as string)')
send(host,script,'setup');start=time.monotonic();cycles=[]
try:
 while time.monotonic()-start<a.seconds or len(cycles)<a.cycles:
  begin=time.monotonic()
  if cycles:send(host,script,'idle')
  for phase in ('count','countUndo','countRedo','copy','copyUndo','copyRedo','edit','editUndo','editRedo','preset','presetReady','presetUndo','presetRedo','finishCycle'):
   if phase=='presetReady':
    deadline=time.monotonic()+120
    while True:
     send(host,probe,'ready')
     if (host/'soak-ready.txt').read_text(encoding='utf-8-sig')=='true':break
     if time.monotonic()>deadline:raise TimeoutError('Observe incomplete preset before proceeding')
     time.sleep(.5)
   send(host,script,phase);time.sleep(.4)
  cycles.append({'cycle':len(cycles)+1,'elapsed':time.monotonic()-start,'work_seconds':time.monotonic()-begin})
  (host/'native-soak.json').write_text(json.dumps({'status':'running','cycles':cycles,'fixture_sha256':identity},indent=2))
  delay=a.seconds/a.cycles-(time.monotonic()-begin)
  if delay>0:time.sleep(delay)
 send(host,script,'idle');send(host,script,'release')
 (host/'native-soak.json').write_text(json.dumps({'status':'passed','seconds':time.monotonic()-start,'cycles':cycles,'fixture_sha256':identity},indent=2))
except Exception as e:
 (host/'native-soak.json').write_text(json.dumps({'status':'failed','error':str(e),'seconds':time.monotonic()-start,'cycles':cycles,'fixture_sha256':identity},indent=2));raise
print('ONE-HOUR NATIVE MIXED HISTORY SOAK PASSED',flush=True)
