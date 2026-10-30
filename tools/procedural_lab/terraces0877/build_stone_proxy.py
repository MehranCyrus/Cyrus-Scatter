"""Scene-specific closed convex proxy for an open-bottom boulder; not plugin policy."""
from pathlib import Path
import json,sys,numpy as np
root=Path(__file__).resolve().parents[3];out=root/'build/terraces0877-20261029-01/host-candidate'
sys.path.insert(0,str(out.parent/'python-deps'))
from scipy.spatial import ConvexHull
data=json.loads((out/'stone-proxy-input.json').read_text());points=np.array(data['vertices'])
hull=ConvexHull(points);ids=sorted(set(hull.simplices.ravel()));remap={old:i+1 for i,old in enumerate(ids)};faces=[]
for simplex,equation in zip(hull.simplices,hull.equations):
    a,b,c=[int(i) for i in simplex]
    if np.dot(np.cross(points[b]-points[a],points[c]-points[a]),equation[:3])<0:b,c=c,b
    faces.append([remap[a],remap[b],remap[c]])
data=dict(vertices=points[ids].tolist(),faces=faces,source_faces=data['source_faces'],scope='Explicit scene proxy. Convex envelope fills concavities; use only for this rounded rock, not walls with openings.')
(out/'stone-proxy.json').write_text(json.dumps(data),encoding='utf-8')
print({'source_faces':data['source_faces'],'proxy_faces':len(faces),'proxy_vertices':len(ids)})
