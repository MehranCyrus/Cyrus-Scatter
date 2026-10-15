from pathlib import Path
import json,math
from pymxs import runtime as r
OUT=Path(str(r.MCPFixtureDir));assert OUT.name.startswith('foundation-terrace0815-candidate2027-')
camera=r.getNodeByName('PhysCamera002');tm=camera.transform
data={'rays':[],'materials':[],'tree_groups':[]}
for x,y in [(550,250),(550,285),(550,335),(950,381),(70,505),(620,552)]:
    direction=-tm.row3+tm.row1*((x/1100*2-1)*math.tan(math.radians(float(camera.fov))/2))+tm.row2*((1-y/619*2)*619/1100*math.tan(math.radians(float(camera.fov))/2))
    hits=[]
    for hit in r.intersectRayScene(r.ray(tm.row4,r.normalize(direction))):
        n=hit[0]
        if not n.renderable or n.isHidden:continue
        hits.append({'node':str(n.name),'distance':float(r.distance(tm.row4,hit[1].pos)),'point':str(hit[1].pos),'material':str(n.material)})
    data['rays'].append({'pixel':[x,y],'hits':sorted(hits,key=lambda h:h['distance'])[:4]})
for name in ['CGt_02_Acer platanoides-3','palm tree']:
    n=r.getNodeByName(name);children=[]
    for i in range(1,int(r.getNumSubMtls(n.material))+1):
        m=r.getSubMtl(n.material,i);fields={}
        if m is None:continue
        for p in ['colorDiffuse','colorTranslucency','texmapDiffuse','texmapOpacity','texmapTranslucency','baseTexmap','opacityTexmap']:
            if r.isProperty(m,r.Name(p)):fields[p]=str(getattr(m,p))
        children.append({'index':i,'material':str(m),'fields':fields})
    data['materials'].append({'node':name,'submaterials':children})
for n in r.objects:
    if str(n.name).startswith(('Tree','trees','tree_Mesh','leaves_leaves')):
        data['tree_groups'].append({'name':str(n.name),'parent':str(n.parent),'pos':str(n.pos),'scale':str(n.scale),'bounds':str(r.nodeGetBoundingBox(n,n.transform))})
(OUT/'render-gaps.json').write_text(json.dumps(data,indent=2)+'\n')
