from pathlib import Path
import argparse,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args();assert a.host.startswith('library-surface0861-');host=ROOT/'build/mcp-qualification'/a.host;ready(host)
(host/'macro-path.txt').write_text((ROOT/'AminScatter/installer/CyrusScatter.mcr').as_posix());script=ROOT/'tools/library_0861/failures_passive.ms'
for phase in ('rollback','deleted','verifyDeleted','browserRace','verifyBrowserRace','verifyReopenedLoad','macro','idleStart','idleEnd'):
 if phase=='verifyDeleted':time.sleep(3)
 if phase in ('verifyBrowserRace','verifyReopenedLoad'):
  probe=host/'extra-probe.ms';probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"extra-ready.txt") ((CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished) as string)')
  end=time.monotonic()+120
  while True:
   send(host,probe,'Observe captured browser load')
   if (host/'extra-ready.txt').read_text(encoding='utf-8-sig')=='true':break
   if time.monotonic()>end:raise TimeoutError('Inspect existing progress before retrying')
   time.sleep(.3)
 if phase=='idleStart':time.sleep(3)
 if phase=='idleEnd':
  for _ in range(3):time.sleep(10)
 (host/'extra-phase.txt').write_text(phase);send(host,script,phase);result=(host/f'extra-{phase}.txt').read_text(encoding='utf-8-sig');print(result,flush=True);assert 'PASS: complete' in result and 'FAIL:' not in result
