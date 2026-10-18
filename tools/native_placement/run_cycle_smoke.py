"""Fast mixed-history regression; explicitly not the one-hour soak."""
import argparse,json,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
h=ROOT/'build/mcp-qualification'/a.host;ready(h)
entry=json.loads((ROOT/'AminScatter/library/inventory.json').read_text())['entries'][0]
(h/'soak-preset-path.txt').write_text((ROOT/'AminScatter/library'/entry['ready_package']).as_posix())
s=ROOT/'tools/native_placement/soak.ms';probe=h/'cycle-ready.ms'
probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"cycle-ready.txt") ((CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished) as string)')
send(h,s,'setup')
for cycle in range(4):
 for phase in ('count','countUndo','countRedo','copy','copyUndo','copyRedo','edit','editUndo','editRedo','preset','presetReady','presetUndo','presetRedo','finishCycle'):
  if phase=='presetReady':
   deadline=time.monotonic()+120
   while True:
    send(h,probe,'ready')
    if (h/'cycle-ready.txt').read_text(encoding='utf-8-sig')=='true':break
    if time.monotonic()>deadline:raise TimeoutError('Observe pending preset')
    time.sleep(.5)
  send(h,s,phase);time.sleep(.2)
send(h,s,'release');print('FOUR MIXED CYCLES PASSED; NOT A SOAK',flush=True)
