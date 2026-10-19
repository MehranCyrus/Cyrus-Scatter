"""Observe cold example publication across host callbacks before any import."""
from pathlib import Path
import json, sys, time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send
host=ROOT/'build/mcp-qualification/density0862-compat-max2026-01'
lib=host/'scripts/Library-0.86.2';entry=next(x for x in json.loads((lib/'inventory.json').read_text())['entries'] if x['id']=='borders')
for name,value in [('example-id.txt','borders'),('example-scene.txt',(lib/entry['scene']).as_posix()),('example-package.txt',(lib/entry['ready_package']).as_posix()),('example-phase.txt','setup')]: (host/name).write_text(value)
send(host,ROOT/'tools/density_0862/examples.ms','Reproduce cold borders setup')
for i in range(3):
    time.sleep(2)
    script=host/f'cold-observe-{i}.ms'
    script.write_text('''(
local f=createFile (MCPFixtureDir+"cold-observe-'''+str(i)+'''.txt")
format "Baseline=%\\nCurrent=%\\nEpoch=% Builds=% Mode=%\\nCounts=%\\n" EHash (cyrusRecipePublicationFingerprint ERoot.groupSnapshotRows) ERoot.procEpoch ERoot.groupBuilds ERoot.updateMode (for rows in ERoot.groupSnapshotRows collect rows.count) to:f
close f
)''',encoding='utf-8-sig')
    send(host,script,'Observe cold publication without import')
    print((host/f'cold-observe-{i}.txt').read_text(),flush=True)
