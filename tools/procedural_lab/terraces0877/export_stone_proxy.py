from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.GardenRun));src=r.getNodeByName('SOURCE | ROCK10 | Lakeside boulder',exact=True)
mesh=r.snapshotAsMesh(src)
vertices=[[float(v) for v in r.getVert(mesh,i)] for i in range(1,int(mesh.numverts)+1)]
(out/'stone-proxy-input.json').write_text(json.dumps(dict(vertices=vertices,source_faces=int(mesh.numfaces))),encoding='utf-8')
r.free(mesh)
