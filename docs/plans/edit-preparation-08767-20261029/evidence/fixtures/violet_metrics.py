from pathlib import Path
import json,struct,math,statistics
run=Path.cwd()/'build/edit-size-review-20261029-01';folder=run/'violet-native';blob=(run/'violet-baseline/violet-0.bin').read_bytes();_,nv,nf,_=struct.unpack_from('<4I',blob);v=list(struct.iter_unpack('<3f',blob[16:16+nv*12]));faces=list(struct.iter_unpack('<3I',blob[16+nv*12:16+nv*12+nf*12]));parent=list(range(nv))
def root(i):
 while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
 return i
for f in faces:
 for i in f[1:]:
  a,b=root(f[0]),root(i);parent[max(a,b)]=min(a,b)
pieces={}
for i in range(nv):pieces.setdefault(root(i),[]).append(i)
pieces=list(pieces.values());base=json.loads((folder/'baseline.json').read_text());high=json.loads((folder/'stem-detail.json').read_text())
def sub(a,b):return [x-y for x,y in zip(a,b)]
def norm(a):return math.sqrt(sum(x*x for x in a))
def distance(p,path):
 best=1e9
 for a,b in zip(path,path[1:]):
  d=sub(b,a);t=max(0,min(1,sum(x*y for x,y in zip(sub(p,a),d))/sum(x*x for x in d)));q=[x+t*y for x,y in zip(a,d)];best=min(best,norm(sub(p,q)))
 return best
def paths(x):return {g['component']:[[p[0],-p[2],p[1]] for p in g['nodes']] for g in x['definition']['metadata']['guides']}
paths0,paths1=paths(base),paths(high);rows=[]
for part,path in paths0.items():
 ids=pieces[part];assert len(ids)%6==0
 centres=[[sum(v[i][d] for i in ids[k:k+6])/6 for d in range(3)] for k in range(0,len(ids),6)]
 # The source's six-sided rings are independently proven by the old ordered detector.
 e0=max(distance(p,path) for p in centres);e1=max(distance(p,paths1[part]) for p in centres)
 rows.append({'part':part,'automatic_points':len(path),'detail_points':len(paths1[part]),'automatic_max_mm':e0*1000,'detail_max_mm':e1*1000})
assert all(x['detail_max_mm']<x['automatic_max_mm'] for x in rows)
result={'status':'pass','metric':'Maximum source ring-centre distance to guide polyline, each of 12 known six-sided flower stems','rows':rows,'worst_automatic_mm':max(x['automatic_max_mm'] for x in rows),'worst_detail_mm':max(x['detail_max_mm'] for x in rows),'baseline_bytes':base['bytes'],'stem_detail_bytes':high['bytes'],'combined_bytes':json.loads((folder/'combined.json').read_text())['bytes']}
(folder/'metrics.json').write_text(json.dumps(result,indent=2));print(json.dumps({k:x for k,x in result.items() if k!='rows'},indent=2))
