"""Create retaining-wall infill below the original open terrace boundaries."""
from pathlib import Path
import json,math
import numpy as np
from shapely.geometry import Polygon
from shapely.ops import unary_union
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/mcp-qualification/foundation-terrace0815-candidate2027-03'
data=json.loads((OUT/'scene-layout-data.json').read_text());walls=[]
for index,item in enumerate(data['receivers'][1:],2):
    v=np.array(item['vertices']);f=np.array(item['faces'],int)-1
    poly=unary_union([Polygon(t[:,:2]) for t in v[f]]).buffer(0);z=float(v[:,2].mean())
    verts=[];faces=[]
    for part in ([poly] if poly.geom_type=='Polygon' else poly.geoms):
        for ring in [part.exterior,*part.interiors]:
            coords=list(ring.coords);outline=[]
            for a,b in zip(coords[:-1],coords[1:]):
                distance=math.hypot(b[0]-a[0],b[1]-a[1]);steps=max(1,math.ceil(distance/65))
                outline.extend([(a[0]+(b[0]-a[0])*k/steps,a[1]+(b[1]-a[1])*k/steps) for k in range(steps)])
            start=len(verts);n=len(outline)
            for level in range(6):
                for x,y in outline:
                    rough=math.sin(x*.033+y*.057+level*2.1)*3
                    verts.append([x+rough,y+rough*.5,z-220*level/5])
            for level in range(5):
                for k in range(n):
                    a=start+level*n+k+1;b=start+level*n+(k+1)%n+1;c=a+n;d=b+n
                    faces.extend([[a,c,b],[b,c,d]])
    walls.append({'name':'WALL | original terrace %02d infill'%index,'vertices':verts,'faces':faces})
(OUT/'retaining-walls.json').write_text(json.dumps(walls)+'\n');print(len(walls),'walls')
