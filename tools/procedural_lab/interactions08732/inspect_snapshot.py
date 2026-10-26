"""Numeric, source-local component inventory; no scene edits."""
from pathlib import Path
from collections import Counter, defaultdict
import json, struct, math
O=Path('build/interactions08732-neottopteris-20261026-01/baseline-host')
b=(O/'neottopteris-0.005.bin').read_bytes(); _,nv,nf,_=struct.unpack_from('<4I',b)
positions=list(struct.iter_unpack('<3f',b[16:16+12*nv])); start=16+12*nv
faces=list(struct.iter_unpack('<3I',b[start:start+12*nf]));materials=struct.unpack_from(f'<{nf}I',b,start+12*nf)
j=json.loads((O/'neottopteris-0.005.json').read_text())['source'];labels=j['labels'];meta=j['metadata']
vertices=defaultdict(list);triangles=defaultdict(list)
for i,ci in enumerate(labels):vertices[ci].append(i)
for i,f in enumerate(faces):triangles[labels[f[0]]].append(i)
rows=[]
for ci,vs in vertices.items():
    fs=triangles[ci];edges=Counter(tuple(sorted((faces[fi][k],faces[fi][(k+1)%3]))) for fi in fs for k in range(3))
    boundary=defaultdict(list)
    for (a,c),count in edges.items():
        if count==1:boundary[a].append(c);boundary[c].append(a)
    unseen=set(boundary);loops=[]
    while unseen:
        stack=[next(iter(unseen))];loop=[]
        while stack:
            v=stack.pop()
            if v not in unseen:continue
            unseen.remove(v);loop.append(v);stack.extend(boundary[v])
        loops.append(len(loop))
    lo=[min(positions[v][k] for v in vs) for k in range(3)];hi=[max(positions[v][k] for v in vs) for k in range(3)]
    rows.append(dict(component=ci,vertices=len(vs),triangles=len(fs),bounds=[lo,hi],materials=dict(Counter(materials[fi] for fi in fs)),boundary_loops=loops,nonmanifold=sum(n>2 for n in edges.values()),guide=meta['parts'][ci]))
summary={'vertices':nv,'faces':nf,'components':len(rows),'component_sizes':Counter(r['vertices'] for r in rows),'largest':sorted(rows,key=lambda r:r['vertices'],reverse=True)[:60],'flexible_vertices':sum(r['vertices'] for r in rows if r['guide']['stem']),'rigid_vertices':sum(r['vertices'] for r in rows if not r['guide']['stem']),'guide_lengths':sorted(g['length_m'] for g in meta['guides'])}
(O/'snapshot-inventory.json').write_text(json.dumps(summary,indent=2))
print(json.dumps({k:v for k,v in summary.items() if k not in ['largest','guide_lengths']},indent=2))
for r in summary['largest'][:14]:print(json.dumps(r))
