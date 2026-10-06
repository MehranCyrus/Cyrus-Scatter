"""Independent geometric checks of the actual Max publication, not pass counts."""
from pathlib import Path
import csv,json,math,hashlib,collections,itertools
ROOT=Path(__file__).resolve().parents[2]
folder=ROOT/'build/mcp-qualification/procedural07-real-scene-071-full'
rows=list(csv.DictReader((folder/'published-placements.csv').open(encoding='utf-8-sig')))
for r in rows:
 for k in ('x','y','z','radius','sx','sy','sz'):r[k]=float(r[k])
 for k in ('set','owner'):r[k]=int(r[k])
 assert all(math.isfinite(r[k]) for k in ('x','y','z','radius','sx','sy','sz'))
 assert r['radius']>=0 and min(r['sx'],r['sy'],r['sz'])>0
keys=[(r['set'],r['instance']) for r in rows]
assert len(keys)==len(set(keys)), 'Duplicate final IDs within one paint set'
def inside(r,x,y,w,h):return abs(r['x']-x)<w/2-0.001 and abs(r['y']-y)<h/2-0.001
for r in rows:
 if r['owner']!=3:
  assert not inside(r,0,650,1550,1170), 'Plant on pavilion terrace'
  assert not inside(r,-1050,670,590,710), 'Plant in reflecting pool'
  assert not inside(r,0,-480,355,1200), 'Plant on entry path'
 else:assert inside(r,-400,-445,170,1000) or inside(r,400,-445,170,1000), 'Lavender escaped include ribbon'
# Check the explicitly authored fixture rules with exhaustive distance pairs.
# This does not call the native collision evaluator or reuse its spatial index.
checks=0;min_clearance=1e30
groups=collections.defaultdict(list)
for r in rows:groups[r['set']].append(r)
for sa,sb in itertools.combinations_with_replacement(groups,2):
 planar=True
 if sa==sb and sa<=3:factor,gap,planar=.85,6,False
 elif sa==sb==7:factor,gap,planar=.65,2,False
 elif groups[sa][0]['owner']!=groups[sb][0]['owner']:factor,gap=.72,10
 elif {sa,sb}=={4,6}:factor,gap=.7,2
 elif {sa,sb}=={7,8}:factor,gap=.65,2
 else:continue
 pairs=itertools.combinations(groups[sa],2) if sa==sb else itertools.product(groups[sa],groups[sb])
 for a,b in pairs:
  d=math.sqrt((a['x']-b['x'])**2+(a['y']-b['y'])**2+(0 if planar else (a['z']-b['z'])**2))
  clearance=d-(factor*(a['radius']+b['radius'])+gap)
  assert clearance>=-.02, (a,b,clearance)
  min_clearance=min(min_clearance,clearance);checks+=1
path_clearance=None
if 7 in groups:
 path=[(float(p['x']),float(p['y'])) for p in csv.DictReader((folder/'curved-path.csv').open())]
 segments=[]
 for a,b in zip(path,path[1:]):
  dx,dy=b[0]-a[0],b[1]-a[1];segments.append((a[0],a[1],dx,dy,dx*dx+dy*dy))
 path_clearance=1e30
 for r in rows:
  closest=1e30
  for x,y,dx,dy,denom in segments:
   t=max(0,min(1,((r['x']-x)*dx+(r['y']-y)*dy)/denom))
   closest=min(closest,math.hypot(r['x']-x-t*dx,r['y']-y-t*dy))
  assert closest>=90,('Plant center encroaches on painted walking trail',r,closest)
  path_clearance=min(path_clearance,closest-76) # includes 6 cm edging
before=(folder/'published-placements.csv').read_bytes()
after=(folder/'published-placements-after.csv').read_bytes()
assert before==after, 'Campaign failed to restore exact exported publication'
result={'status':'PASS','instances':len(rows),'unique_ids':len(set(keys)), 'collision_pairs_checked':checks,'minimum_rule_clearance_cm':min_clearance,'minimum_plant_center_clearance_from_walk_edge_cm':path_clearance,'finite_transforms':True,'include_exclude_oracle':True,'campaign_export_identical':True,'sha256':hashlib.sha256(before).hexdigest(),'counts':dict(collections.Counter(r['set'] for r in rows))}
(folder/'independent-oracle.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
