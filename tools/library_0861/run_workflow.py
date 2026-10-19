"""Exercise real library load/timer callbacks and authored history in an owned host."""
from pathlib import Path
import argparse,json,shutil,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args();assert a.host.startswith('library-surface0861-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
library=host/'library'
if not library.exists():shutil.copytree(ROOT/'AminScatter/library',library)
inventory=json.loads((library/'inventory.json').read_text())
for filename,slug in [('meadow-package.txt','meadow'),('mask-package.txt','curvature')]:
 entries=[entry for entry in inventory['entries'] if entry['id']==slug or (slug=='curvature' and 'Valley' in entry['name'])];assert len(entries)==1
 (host/filename).write_text((library/entries[0]['ready_package']).as_posix())
(host/'library-path.txt').write_text(library.as_posix())
probe=host/'workflow-probe.ms'
def wait_for(expression):
 probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"probe.txt") (('+expression+') as string)',encoding='utf-8-sig')
 end=time.monotonic()+120
 while True:
  send(host,probe,'poll progress')
  if (host/'probe.txt').read_text(encoding='utf-8-sig')=='true':return
  if time.monotonic()>end:raise TimeoutError('Inspect existing progress callback before retrying')
  time.sleep(.5)
script=ROOT/'tools/library_0861/workflow.ms'
for phase in ['setup','load','verify','undo','verifyUndo','redo','verifyRedo','append','verifyAppend','undo','verifyAppendUndo','save','reopen','boundaries','cancel','idleStart','idleEnd']:
 if phase=='load':wait_for('CyrusRecipeBrowser!=undefined and not CyrusRecipeBrowser.scanTimer.active')
 if phase in ('verify','verifyAppend'):wait_for('CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished')
 if phase=='idleEnd':
  for _ in range(3):time.sleep(10)
 (host/'phase.txt').write_text(phase);send(host,script,phase)
 result=(host/f'workflow-{phase}.txt').read_text(encoding='utf-8-sig');assert 'PASS: complete' in result and 'FAIL:' not in result,result
 print(result.strip(),flush=True)
print('SELECTED-SURFACE WORKFLOW PASSED',flush=True)
