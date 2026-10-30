from pathlib import Path
import json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    props={}
    for p in r.getPropNames(r.renderers.current):
        if any(s in str(p).lower() for s in ['override','material','color','tone','lut']):
            try:props[str(p)]=str(r.getProperty(r.renderers.current,p))[:220]
            except Exception:pass
    data['renderer']=props
    rows=[]
    for n in r.GardenSources:
        maps=[]
        for cls,prop in [('Bitmaptexture','filename'),('CoronaBitmap','filename')]:
            try:
                for m in r.getClassInstances(r.execute(cls),target=n.material):
                    value=str(r.getProperty(m,r.Name(prop)))
                    maps.append(dict(path=value,exists=Path(value).is_file(),resolved=str(r.mapPaths.getFullFilePath(value))))
            except Exception as e:maps.append(dict(error=str(e)))
        rows.append(dict(name=str(n.name),maps=maps))
    data['sources']=rows;data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-material-audit.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
