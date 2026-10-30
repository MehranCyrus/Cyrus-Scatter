from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.GardenRun))
rows=[]
for i,leaf in enumerate(r.WFRoot.layerObjects):
    rows.append(dict(name=str(r.WFRoot.layerNames[i]),enabled=bool(r.WFRoot.layerEnabled[i]),amount=int(leaf.amount),accepted=int(leaf.generatedCount),react=bool(leaf.interactionReact),error=str(leaf.previewError),surfaces=[str(x) for x in leaf.surfaceNodes],parent=str(leaf.logicalParentID)))
(out/'contact-inspect.json').write_text(json.dumps(rows,indent=2))
