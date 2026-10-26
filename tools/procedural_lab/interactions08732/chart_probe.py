"""Inspect graph endpoints of the actual broad leaves before selecting roots."""
exec(open('tools/procedural_lab/interactions08732/inspect_snapshot.py').read().split('summary=')[0])
import heapq
adj=[set() for _ in positions]
for f in faces:
    for a,c in zip(f,(f[1],f[2],f[0])):adj[a].add(c);adj[c].add(a)
def geo(vs,seed):
    ds={v:float('inf') for v in vs};ds[seed]=0;queue=[(0,seed)]
    while queue:
        d,a=heapq.heappop(queue)
        if d!=ds[a]:continue
        for c in adj[a]:
            nd=d+math.dist(positions[a],positions[c])
            if nd<ds[c]:ds[c]=nd;heapq.heappush(queue,(nd,c))
    return max(vs,key=lambda v:(ds[v],tuple(-p for p in positions[v]))),ds
result=[]
for ci,vs in vertices.items():
    if len(vs)<32 or len(vs)>200:continue
    a,db=geo(vs,min(vs,key=lambda v:positions[v]));c,da=geo(vs,a);_,db=geo(vs,c);diam=da[c]
    stations=max(3,min(16,math.ceil(diam/.02)+1));bins=[[] for _ in range(stations)]
    for v in vs:
        t=max(0,min(1,(da[v]-db[v]+diam)/(2*diam)));bins[min(stations-1,math.floor(t*(stations-1)+.5))].append(v)
    path=[tuple(sum(positions[v][k] for v in row)/len(row) for k in range(3)) for row in bins if row]
    result.append({'component':ci,'material':materials[triangles[ci][0]],'vertices':len(vs),'diameter':diam,'ends':[path[0],path[-1]],'path':path})
(O/'chart-probe.json').write_text(json.dumps(result,indent=2))
for v in result:
    if v['diameter']>.4:print(json.dumps({k:a for k,a in v.items() if k!='path'}))
