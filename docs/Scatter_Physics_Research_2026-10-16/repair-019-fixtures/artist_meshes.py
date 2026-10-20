"""Recreate captured render meshes in an owned test scene, without artist access."""
import json
from pathlib import Path
from pymxs import runtime as r
fixture=Path(__file__).resolve().parents[3]/'CyrusPhysicsLab/tests/fixtures/artist-hulls-018.json'
data=json.loads(fixture.read_text())['input']
r.CPLArtistModels=r.Array()
per_metre=float(r.units.decodeValue('1m'))
for i,s in enumerate(data['sources']):
    verts=r.Array(*[r.Point3(*[v*per_metre for v in p]) for p in s['render']['vertices']])
    faces=r.Array(*[r.Point3(*[v+1 for v in p]) for p in s['render']['faces']])
    node=r.mesh(vertices=verts,faces=faces,name='Captured_'+str(i))
    node.material=r.standardMaterial()
    r.hide(node)
    r.append(r.CPLArtistModels,node)
