"""Actual eight-preset Load/Undo/Redo/save/reopen in one owned host."""
from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('name');a=p.parse_args()
assert a.name.startswith('foundation-memory0854-')
host=ROOT/'build/mcp-qualification'/a.name
inventory=json.loads((ROOT/'AminScatter/library/inventory.json').read_text())
def send(script):
    r=subprocess.run([sys.executable,str(ROOT/'tools/memory_0854/host.py'),'send',a.name,'--script',str(script)],capture_output=True,text=True)
    print(r.stdout,flush=True)
    if r.returncode:raise RuntimeError(r.stdout+r.stderr)
for entry in inventory['entries']:
    identity=entry['id'];(host/'acceptance-id.txt').write_text(identity)
    (host/'preset-path.txt').write_text((ROOT/'AminScatter/library'/entry['ready_package']).as_posix())
    for phase in ['setup','load','verify','undo','verifyUndo','redo','verifyRedo','reopen','verifyReopen']:
        (host/'acceptance-phase.txt').write_text(phase)
        if phase=='verify':
            probe=host/'await-ready.ms';probe.write_text('(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"preset-ready.txt") ((CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished) as string)')
            deadline=time.monotonic()+30
            while True:
                send(probe)
                if (host/'preset-ready.txt').read_text(encoding='utf-8-sig')=='true':break
                if time.monotonic()>deadline:raise TimeoutError('Preset progress did not settle')
                time.sleep(.2)
        print(identity,phase,flush=True);send(ROOT/'tools/memory_0854/presets.ms')
        result=(host/f'acceptance-{identity}-{phase}.txt').read_text(encoding='utf-8-sig')
        assert 'PASS: complete' in result and 'FAIL:' not in result,result
print('ALL EIGHT PRESETS PASSED',flush=True)
