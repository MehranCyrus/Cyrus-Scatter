from pathlib import Path
import argparse,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--library',required=True,type=Path);a=p.parse_args();assert a.host.startswith('library-surface0861-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host);(host/'save-scene.txt').write_text((a.library.resolve()/'borders.max').as_posix());script=ROOT/'tools/library_0861/save_roundtrip.ms';probe=host/'save-probe.ms'
for phase in ('save','verifySave','verifyLoad'):
 if phase!='save':
  editor='CyrusPresetSaveEditor' if phase=='verifySave' else 'CyrusReadyPresetEditor'
  probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"save-ready.txt") (('+editor+'!=undefined and '+editor+'.finished) as string)')
  end=time.monotonic()+120
  while True:
   send(host,probe,'observe save/load worker')
   if (host/'save-ready.txt').read_text(encoding='utf-8-sig')=='true':break
   if time.monotonic()>end:raise TimeoutError('Observe worker before retrying')
   time.sleep(.5)
 (host/'save-phase.txt').write_text(phase);send(host,script,phase);result=(host/f'save-{phase}.txt').read_text(encoding='utf-8-sig');print(result,flush=True);assert 'PASS: complete' in result and 'FAIL:' not in result
