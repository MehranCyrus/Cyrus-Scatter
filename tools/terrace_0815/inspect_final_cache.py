from pathlib import Path
import json,time
from pymxs import runtime as r
OUT=Path(str(r.MCPFixtureDir)).resolve()
root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject
data={'prior':json.loads((OUT/'garden-final-acceptance.json').read_text())['baseline'],'states':[]}
for i in range(3):
    data['states'].append({'epoch':int(root.procEpoch),'fingerprints':[str(r.cyrusEditFingerprint(rows,'garden-final815')) for rows in root.groupSnapshotRows],'prepared':[int(l.procPreparedBuilds) for l in root.layerObjects],'counts':[int(l.generatedCount) for l in root.layerObjects],'errors':[str(l.previewError) for l in root.layerObjects]})
    start=time.perf_counter();root.evaluateGroups();data['states'][-1]['evaluate_ms']=(time.perf_counter()-start)*1000
(OUT/'garden-cache-probe.json').write_text(json.dumps(data,indent=2))
