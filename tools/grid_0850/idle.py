from pathlib import Path
import json,sys,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
result={'status':'running'};path=OUT/('idle-'+str(time.time_ns())+'.json')
try:
 node=r.getNodeByName('Grid heavy setup');root=node.baseObject
 before=json.loads((OUT/'passive-baseline.json').read_text(encoding='utf-8'))
 after={'observed_seconds':time.monotonic(),'rows':[fingerprint(x) for x in root.groupSnapshotRows],
  'grid':list(r.cyrusGridStats())[:3],'orientation':list(r.cyrusOrientationStats())[:3],'epoch':int(root.procEpoch),
  'receiver':[list(x.receiverCacheStats()) for x in root.layerObjects],
  'prepare':[int(x.procPreparedBuilds) for x in root.layerObjects],
  'preview':[int(x.previewBuildCount) for x in root.layerObjects],
  'display':list(r.cyrusRetainedStats(r.CyrusPointOwner(node)))}
 elapsed=after['observed_seconds']-before['observed_seconds'];result.update(before=before,after=after,elapsed_seconds=elapsed)
 assert elapsed>=30
 assert all(before[k]==after[k] for k in ('rows','grid','orientation','epoch','prepare','preview'))
 assert before['display'][5]==after['display'][5] and before['display'][3]==after['display'][3]
 assert all(a[0]==b[0] and a[2]==b[2] for a,b in zip(before['receiver'],after['receiver']))
 result['status']='passed'
except Exception:result['status']='failed';result['error']=traceback.format_exc();raise
finally:path.write_text(json.dumps(result,indent=2),encoding='utf-8')
