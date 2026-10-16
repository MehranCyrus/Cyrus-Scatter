from pathlib import Path
import json,sys
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
nodes=[n for n in r.objects if r.classOf(n.baseObject)==r.AminScatterObject]
result=[]
for n in nodes:
 root=n.baseObject;layers=[]
 for i,leaf in enumerate(root.layerObjects):
  rows=root.groupSnapshotRows[i]
  layers.append({'name':str(root.layerNames[i]),'rows':len(rows),'fingerprint':fingerprint(rows),'mode':int(leaf.placementMode),
   'domains':list(leaf.procReceiverVariationIDs),'owners':list(leaf.procReceiverIDs),'seed':int(leaf.randomSeed),
   'origin':[float(leaf.gridOriginXWU),float(leaf.gridOriginYWU)],'pitch':[float(leaf.gridColumnWU),float(leaf.gridRowWU)],
   'first':[[str(x) for x in row] for row in list(rows)[:3]]})
 result.append({'node':str(n.name),'layers':layers})
(OUT/'import-probe.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
