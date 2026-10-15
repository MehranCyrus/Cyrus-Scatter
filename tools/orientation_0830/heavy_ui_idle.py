"""Observe deferred work after the heavy panel test returned to Max's event loop."""
from pathlib import Path
import json,sys,time
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-orientation0830-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
source=sorted(OUT.glob('heavy-ui-[0-9]*.json'))[-1];prior=json.loads(source.read_text(encoding='utf-8'));assert prior['status']=='passed'
node=r.getNodeByName('Orientation qualification');root=node.baseObject
after={'orientation':list(r.cyrusOrientationStats())[:3],'epoch':int(root.procEpoch),
 'receiver':[list(x.receiverCacheStats()) for x in root.layerObjects],
 'prepare':[int(x.procPreparedBuilds) for x in root.layerObjects],
 'preview':[int(x.previewBuildCount) for x in root.layerObjects],
 'display':list(r.cyrusRetainedStats(r.CyrusPointOwner(node))),
 'rows':[fingerprint(x) for x in root.groupSnapshotRows]}
before=prior['after'];same=all(before[k]==after[k] for k in ('orientation','epoch','prepare','preview','rows'))
# Viewport redraw count is presentation, not preparation or upload work.
same=same and before['display'][:7]+before['display'][8:]==after['display'][:7]+after['display'][8:]
same=same and all(a[0]==b[0] and a[2]==b[2] for a,b in zip(before['receiver'],after['receiver']))
result={'status':'passed' if same else 'failed','source':source.name,'elapsed_since_source_write_seconds':time.time()-source.stat().st_mtime,'before':before,'after':after}
(OUT/('heavy-ui-idle-'+str(time.time_ns())+'.json')).write_text(json.dumps(result,indent=2),encoding='utf-8');assert same
