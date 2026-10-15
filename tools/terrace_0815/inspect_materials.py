from pathlib import Path
import json
from pymxs import runtime as r
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.name.startswith('foundation-terrace0815-')
data={}
for name in ['MT_PM_V41_Viola_sororia_01_05','crp_MT_PM_Rosa_rugosa_01_02','spl_terrace_1','spl_terrace_010','surf_terrace_002']:
    n=r.getNodeByName(name);m=n.material
    data[name]={'material':str(m),'props':[str(p) for p in r.getPropNames(m)],'children':[]}
    for j in range(1,int(r.getNumSubMtls(m))+1):
        sub=r.getSubMtl(m,j)
        if sub is not None and ('flower' in str(sub.name).lower() or 'petal' in str(sub.name).lower()):
            data[name]['children'].append({'name':str(sub),'props':[str(p) for p in r.getPropNames(sub)]})
(OUT/'material-properties.json').write_text(json.dumps(data,indent=2))
