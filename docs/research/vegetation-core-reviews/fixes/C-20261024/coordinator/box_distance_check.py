"""Local feature-distance diagnostic for a physically disjoint triangle and OBB.
The independent C zero-clearance test first establishes no physical intersection.
This script does not certify arbitrary overlapping solids or a host renderer.
"""
from pathlib import Path
import itertools
import json
import math

stage=Path(__file__).resolve().parent
def add(a,b):return [x+y for x,y in zip(a,b)]
def sub(a,b):return [x-y for x,y in zip(a,b)]
def mul(a,t):return [x*t for x in a]
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def clamp(x):return max(0,min(1,x))
def norm2(a):return dot(a,a)
def pseg(p,a,b):
    e=sub(b,a);n=norm2(e)
    t=clamp(dot(sub(p,a),e)/n) if n else 0
    return norm2(sub(p,add(a,mul(e,t))))
def ptri(p,a,b,c):
    u=sub(b,a);v=sub(c,a);w=sub(p,a)
    aa=dot(u,u);bb=dot(u,v);cc=dot(v,v);d=dot(u,w);e=dot(v,w)
    det=aa*cc-bb*bb
    if det>0:
        s=(cc*d-bb*e)/det;t=(aa*e-bb*d)/det
        if s>=0 and t>=0 and s+t<=1:
            return norm2(sub(w,add(mul(u,s),mul(v,t))))
    return min(pseg(p,a,b),pseg(p,b,c),pseg(p,c,a))
def segments(a,b,c,d):
    u=sub(b,a);v=sub(d,c);w=sub(a,c)
    aa=dot(u,u);bb=dot(u,v);cc=dot(v,v);dd=dot(u,w);ee=dot(v,w)
    if aa==0:return pseg(a,c,d)
    if cc==0:return pseg(c,a,b)
    values=[]
    def at(s,t):return norm2(sub(add(w,mul(u,s)),mul(v,t)))
    for s in [0,1]:values.append(at(s,clamp((ee+s*bb)/cc)))
    for t in [0,1]:values.append(at(clamp((t*bb-dd)/aa),t))
    det=aa*cc-bb*bb
    if det>0:
        s=(bb*ee-cc*dd)/det;t=(aa*ee-bb*dd)/det
        if 0<=s<=1 and 0<=t<=1:values.append(at(s,t))
    return min(values)
def unrotate(p,q):
    # Independent inverse quaternion rotation matrix.
    n=math.sqrt(sum(x*x for x in q));x,y,z,w=[v/n for v in q]
    return [(1-2*(y*y+z*z))*p[0]+2*(x*y+w*z)*p[1]+2*(x*z-w*y)*p[2],
            2*(x*y-w*z)*p[0]+(1-2*(x*x+z*z))*p[1]+2*(y*z+w*x)*p[2],
            2*(x*z+w*y)*p[0]+2*(y*z-w*x)*p[1]+(1-2*(x*x+y*y))*p[2]]
data=json.loads((stage/'abc-release/rotated-box-evidence.json').read_text())
records=[]
for obstacle in data['obstacles']:
    h=obstacle['half_extents']
    corners=[[sign[i]*h[i] for i in range(3)] for sign in itertools.product([-1,1],repeat=3)]
    edges=[(a,b) for i,a in enumerate(corners) for b in corners[i+1:] if sum(x!=y for x,y in zip(a,b))==1]
    for index,tri in enumerate(data['triangles']):
        p=[unrotate(sub(data['positions'][i],obstacle['center']),obstacle['orientation']) for i in tri]
        candidates=[sum(max(abs(x)-half,0)**2 for x,half in zip(v,h)) for v in p]
        candidates += [ptri(v,*p) for v in corners]
        candidates += [segments(a,b,c,d) for a,b in [(p[0],p[1]),(p[1],p[2]),(p[2],p[0])] for c,d in edges]
        records.append({'obstacle_id':obstacle['id'],'triangle':index,'minimum_feature_distance_m':math.sqrt(max(0,min(candidates)))})
minimum=min(records,key=lambda x:x['minimum_feature_distance_m'])
result={'scope':'Independent feature-distance diagnostic after C physically disjoint zero-clearance control; no general robustness or host claim',
        'minimum':minimum,'target_clearance_m':data['clearance_m'],'penetration_tolerance_m':data['penetration_tolerance_m'],
        'C_axis_expanded_status':data['C_status'],'distance_meets_euclidean_target':minimum['minimum_feature_distance_m']>=data['clearance_m']-data['penetration_tolerance_m'],
        'triangle_obstacle_pairs':len(records),'records':records}
(stage/'box-distance-diagnostic.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='records'},indent=2))
