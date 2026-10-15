from pathlib import Path
import json
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-candidate')
n=r.TerraceMovingRectangle;v=n.baseObject
data={'rectangle':str(n.pos),'members':len(v.movementSources),'units':len(v.movementUnits),
      'status':str(v.movementStatus),'native_stats':[str(x) for x in v.movementStats()],
      'consumers':[str(x) for x in v.consumerRows],
      'models':[{ 'name':str(m.name),'pos':str(m.pos),'movable':bool(r.cyrusContainerMovable(m))} for m in v.movementSources]}
(OUT/'movement-diagnosis.json').write_text(json.dumps(data,indent=2)+'\n')
