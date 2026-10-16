"""Read-only diagnostic of a failed exact-row example comparison."""
from pathlib import Path
import json,uuid
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
roots=[n.baseObject for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject']
result={'heap_free':int(r.heapFree),'heap_size':int(r.heapSize),'roots':[],'differences':[]}
for root in roots:
 result['roots'].append({'id':str(root.layerID),'counts':[len(rows) for rows in root.groupSnapshotRows],
  'status':str(root.procEpoch),'leaves':[{'error':str(x.previewError),'source_names':[str(s.name) for s in x.sources]} for x in root.layerObjects]})
if len(roots)==2:
 for index,(a,b) in enumerate(zip(roots[0].layerObjects,roots[1].layerObjects)):
  for field in r.CyrusRecipeFields():
   av=str(r.getProperty(a,r.Name(str(field[0]))));bv=str(r.getProperty(b,r.Name(str(field[0]))))
   if av!=bv:result['differences'].append({'layer':index,'field':str(field[0]),'a':av[:3000],'b':bv[:3000]})
(OUT/('example-compare-'+uuid.uuid4().hex+'.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
