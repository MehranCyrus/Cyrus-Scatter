from pathlib import Path
import csv,math,json,collections
root=Path(__file__).resolve().parents[2]
folder=root/'build/mcp-qualification/procedural07-real-scene-071-full'
path=[(float(p['x']),float(p['y'])) for p in csv.DictReader((folder/'curved-path.csv').open())]
segments=[]
for a,b in zip(path,path[1:]):
 dx,dy=b[0]-a[0],b[1]-a[1];segments.append((a[0],a[1],dx,dy,dx*dx+dy*dy))
closest_by_set={};failures=[]
for r in csv.DictReader((folder/'published-placements.csv').open()):
 px,py=float(r['x']),float(r['y']);closest=1e30
 for x,y,dx,dy,denom in segments:
  t=max(0,min(1,((px-x)*dx+(py-y)*dy)/denom))
  closest=min(closest,math.hypot(px-x-t*dx,py-y-t*dy))
 closest_by_set[r['set']]=min(closest,closest_by_set.get(r['set'],1e30))
 if closest<90:failures.append([r['set'],r['instance'],closest,px,py])
result={'minimum_centerline_distance_by_set_cm':closest_by_set,'within_90cm':sorted(failures,key=lambda r:r[2])}
(folder/'path-clearance-diagnostic.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
