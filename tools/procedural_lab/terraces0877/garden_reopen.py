from pathlib import Path
import json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun))
try:
    r.loadMaxFile(str(out.parent/'Terraces_Garden_Textured.max'),quiet=True,useFileUnits=True)
    r.execute('''global GardenNodes=#(),GardenLayers=#(),GardenSources=#(),TCOverview,TCLake,TCHouse
    for n in objects do (
    if matchPattern n.name pattern:"SOURCE | *" do append GardenSources n
    if classof n.baseObject==AminScatterObject and matchPattern n.name pattern:"GARDEN | *" do (append GardenNodes n;join GardenLayers n.baseObject.layerObjects)
    )
    for n in cameras do (if matchPattern n.name pattern:"*Overview*" do TCOverview=n;if matchPattern n.name pattern:"*Lake*" do TCLake=n;if matchPattern n.name pattern:"*house*" do TCHouse=n)
    ''')
    data=dict(status='complete',controllers=[str(n.name) for n in r.GardenNodes],cameras=[str(n.name) for n in r.cameras])
    source=next(n for n in r.GardenSources if 'A056' in str(n.name));mat=r.getSubMtl(source.material,5)
    data['leaf']={str(p):str(r.getProperty(mat,p))[:150] for p in r.getPropNames(mat) if any(k in str(p).lower() for k in ['diffuse','opacity','level','color'])}
    data['renderer_props']={str(p):str(r.getProperty(r.renderers.current,p))[:120] for p in r.getPropNames(r.renderers.current) if any(k in str(p).lower() for k in ['passlimit','timelimit','denois','progressive','limit'])}
except Exception:data=dict(status='failed',error=traceback.format_exc())
(out/'garden-reopen.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
