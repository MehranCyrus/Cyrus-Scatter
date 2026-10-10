from pathlib import Path
import json,csv,collections,math
R=Path.cwd(); H=R/'build/mcp-qualification/courtyard-study075';O=R/'Test Scene/Courtyard_Study_075'
polys=dict(json.loads((H/'polygons.json').read_text())['polygons'])
def inside(x,y,poly):
 hit=False
 for i,a in enumerate(poly):
  b=poly[(i+1)%len(poly)]
  if (a[1]>y)!=(b[1]>y) and x < (b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:hit=not hit
 return hit
counts=collections.Counter();path=collections.Counter();outside=collections.Counter();finite=True
for row in csv.DictReader((O/'Placements.tsv').open(),delimiter='\t'):
 l=int(row['layer']);x,y,z=[float(row[k]) for k in ('x','y','z')];counts[l]+=1;finite &= all(map(math.isfinite,(x,y,z)))
 if l!=9 and any(inside(x,y,p) for n,p in polys.items() if n.startswith('EXCLUDE + BANDS')):path[l]+=1
 if l in (1,2,3,4,10) and not any(inside(x,y,p) for n,p in polys.items() if n.startswith('INCLUDE')):outside[l]+=1
d={'counts':dict(counts),'plant_pivots_in_paths':dict(path),'bed_layer_pivots_outside_beds':dict(outside),'finite':finite}
# Independent triangle interpolation on the actual exported curved receiver.
mesh=json.loads((H/'curved-receiver.json').read_text());verts=mesh['vertices'];max_error=0;misses=0;checked=0
for row in csv.DictReader((O/'Placements.tsv').open(),delimiter='\t'):
 if int(row['layer'])!=7:continue
 x,y,z=[float(row[k]) for k in ('x','y','z')];hit=None
 for f in mesh['faces']:
  a,b,c=[verts[i-1] for i in f];det=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(det)<1e-12:continue
  u=((b[1]-c[1])*(x-c[0])+(c[0]-b[0])*(y-c[1]))/det
  v=((c[1]-a[1])*(x-c[0])+(a[0]-c[0])*(y-c[1]))/det;w=1-u-v
  if min(u,v,w)>=-1e-5:hit=u*a[2]+v*b[2]+w*c[2];break
 if hit is None:misses+=1
 else:checked+=1;max_error=max(max_error,abs(z-hit))
d['curved_projection']={'checked':checked,'misses':misses,'max_error_cm':max_error,'tolerance_cm':0.02}
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def intersects(a,b,c,d):return cross(a,b,c)*cross(a,b,d)<-1e-8 and cross(c,d,a)*cross(c,d,b)<-1e-8
tent=polys['EXCLUDE | tent footprint'];overlaps=[]
for name,p in polys.items():
 if not name.startswith('EXCLUDE + BANDS'):continue
 overlap=any(inside(v[0],v[1],p) for v in tent) or any(inside(v[0],v[1],tent) for v in p)
 overlap |= any(intersects(a,tent[(i+1)%len(tent)],b,p[(j+1)%len(p)]) for i,a in enumerate(tent) for j,b in enumerate(p))
 if overlap:overlaps.append(name)
d['tent_path_overlap']=overlaps
d['passed']=not overlaps and finite and not path and not outside and misses==0 and checked>0 and max_error<0.02
(H/'placement-validation.json').write_text(json.dumps(d,indent=2));print(json.dumps(d,indent=2))
assert d['passed'], 'Independent geometry validation failed'

