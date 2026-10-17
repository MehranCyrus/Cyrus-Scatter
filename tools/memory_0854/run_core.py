"""Serialized real Max control callbacks; waiting leaves the host event loop free."""
from pathlib import Path
import argparse,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('--copy-only',action='store_true');a=p.parse_args()
assert a.name.startswith('foundation-memory0854-')
host=ROOT/'build/mcp-qualification'/a.name
def send(script):
    r=subprocess.run([sys.executable,str(ROOT/'tools/memory_0854/host.py'),'send',a.name,'--script',str(ROOT/'tools/memory_0854'/script)],capture_output=True,text=True)
    print(r.stdout,flush=True)
    if r.returncode:raise RuntimeError(r.stdout+r.stderr)
deadline=time.monotonic()+90
while not (host/'ready.json').exists():
    assert not (host/'startup-error.txt').exists(),(host/'startup-error.txt').read_text()
    if time.monotonic()>deadline:raise TimeoutError('Owned host startup did not settle')
    time.sleep(.25)
if not a.copy_only:
    send('fixture.ms')
    for phase in ['undo','checkUndo','redo','checkRedo','counts','manual','failure','undo','recover','stagedFailure','undo','stagedRecovery','passive','idleStart','idleEnd']:
        if phase=='idleEnd':
            print('Observing 65 seconds idle',flush=True);time.sleep(65)
        (host/'phase.txt').write_text(phase);print(phase,flush=True);send('exercise.ms')
else:
    setup=host/'cold-log.ms'
    # The helper definitions are loaded without running the Count fixture.
    text=(ROOT/'tools/memory_0854/fixture.ms').read_text();definitions=text.split('MFLog=createFile')[0]
    setup.write_text(definitions+'MFLog=createFile (MCPFixtureDir+"memory-fix.txt")\nformat "COLD_HEAP % free=%\\n" heapSize heapFree to:MFLog\nflush MFLog')
    r=subprocess.run([sys.executable,str(ROOT/'tools/memory_0854/host.py'),'send',a.name,'--script',str(setup)],capture_output=True,text=True);print(r.stdout,flush=True);assert r.returncode==0
for phase in ['copy','copyUndo','checkCopyUndo','copyRedo','checkCopyRedo','radii','reopen','release']:
    (host/'regression-phase.txt').write_text(phase);print(phase,flush=True);send('regression.ms')
send('grid.ms')
print('CORE PASSED',flush=True)
