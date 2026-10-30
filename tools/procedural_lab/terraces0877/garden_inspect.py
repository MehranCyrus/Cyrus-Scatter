from pathlib import Path
import json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    data['material_stats']=str(r.cyrusMaterialPreviewStats())
    rows=[]
    for node in r.GardenSources:
        mat=node.material
        row=dict(name=str(node.name),material=str(mat),type=str(r.classOf(mat)))
        props={}
        for p in r.getPropNames(mat):
            if any(s in str(p).lower() for s in ['diffuse','base','color','texmap','opacity']):
                try:props[str(p)]=str(r.getProperty(mat,p))[:180]
                except Exception:pass
        row['properties']=props
        row['children']=[str(r.getSubMtl(mat,i)) for i in range(1,r.getNumSubMtls(mat)+1)]
        rows.append(row)
    data['materials']=rows
    data['display']=[dict(name=str(n.name),mode=int(n.baseObject.viewportMode),idmode=int(n.baseObject.identificationMode),faces=int(n.baseObject.viewportFaces),nav=int(n.baseObject.viewportNavigationFaces)) for n in r.GardenNodes]
    data['status']='complete'
except Exception:data['error']=traceback.format_exc()
(out/'garden-inspect.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
