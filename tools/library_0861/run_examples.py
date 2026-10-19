"""Eight presets on selected compatible terrain with package-independent Redo."""
from pathlib import Path
import argparse,json,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--library',type=Path);a=p.parse_args();assert a.host.startswith('library-surface0861-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host);library=(a.library or host/'library').resolve();inventory=json.loads((library/'inventory.json').read_text());assert library.is_relative_to(ROOT/'build')
probe=host/'example-probe.ms';probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"example-ready.txt") ((CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished) as string)')
for entry in inventory['entries']:
 (host/'example-id.txt').write_text(entry['id']);(host/'example-scene.txt').write_text((library/entry['scene']).as_posix());package=library/entry['ready_package'];(host/'example-package.txt').write_text(package.as_posix())
 for phase in ['setup','load','verify','undo','verifyUndo','redo','verifyRedo']:
  if phase=='undo':
   unavailable=package.with_name(package.name+'-unavailable');assert not unavailable.exists();package.rename(unavailable)
  if phase=='verify':
   end=time.monotonic()+120
   while True:
    send(host,probe,'observe prepared example')
    if (host/'example-ready.txt').read_text(encoding='utf-8-sig')=='true':break
    if time.monotonic()>end:raise TimeoutError('Inspect existing callback before retrying')
    time.sleep(.3)
  (host/'example-phase.txt').write_text(phase);send(host,ROOT/'tools/library_0861/examples.ms',entry['id']+' '+phase)
  result=(host/f"example-{entry['id']}-{phase}.txt").read_text(encoding='utf-8-sig');assert 'PASS: complete' in result and 'FAIL:' not in result,result
  print(result.strip(),flush=True)
  if phase=='verifyRedo':unavailable.rename(package)
print('ALL EIGHT EXAMPLES PASSED',flush=True)
