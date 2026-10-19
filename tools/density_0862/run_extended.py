from pathlib import Path
import argparse,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--phases',nargs='*');a=p.parse_args();assert a.host.startswith('density0862-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
if not a.phases:send(host,ROOT/'tools/density_0862/initial.ms','initial')
for phase in a.phases or ('maskRefresh','maskUndo','maskRedo','hiddenIdle','lateFailure','heavy','heavyIdle','noise'):
    time.sleep(5 if phase in ('hiddenIdle','heavyIdle') else .5)
    (host/'extended-phase.txt').write_text(phase)
    send(host,ROOT/'tools/density_0862/extended.ms',phase)
    result=(host/('extended-'+phase+'.txt')).read_text(encoding='utf-8-sig');print(result,flush=True);assert 'PASS: complete' in result
