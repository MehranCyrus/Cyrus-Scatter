"""Independent physical-distance and serialized-mesh oracles inside the owned host."""
from pathlib import Path
import hashlib,json,math,re,struct,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('density0862-reliability-')
package=Path((OUT/'preset-transfer-package.txt').read_text()).resolve()
assert package.is_relative_to(ROOT/'build/reliability-0870-20261019') or package.is_relative_to(ROOT/'AminScatter/library')
token=(OUT/'preset-transfer-case.txt').read_text();assert re.fullmatch(r'[a-z0-9_-]+',token)
doc=json.loads((package/'entry.csrecipe.json').read_text());graph=json.loads((package/'assets.json').read_text())
report={'status':'running','case':token,'distance_checks':0,'vertices_checked':0,'paint_radii':0,'source_models':0}
try:
 units=float(r.units.decodeValue('1m'));owners=list(r.PRoot.layerObjects)[1:];assert len(owners)==len(doc['layers'])
 fields=[name for name,kind,distance in re.findall(r'\{"(\w+)","(\w+)",(true|false)\}',(ROOT/'AminScatter/src/recipe_fields.inc').read_text()) if distance=='true']
 def scalar(actual,expected):
  assert math.isclose(float(actual)/units,float(expected),rel_tol=3e-6,abs_tol=3e-7),(actual,expected,units)
 def settings(owner,saved):
  for name in fields:
   actual=r.getProperty(owner,r.Name(name));expected=saved[name]
   if isinstance(expected,list):
    assert len(actual)==len(expected),name
    for value,target in zip(actual,expected):scalar(value,target);report['distance_checks']+=1
   else:scalar(actual,expected);report['distance_checks']+=1
 def paint(owner,saved):
  if saved is not None:
   data=r.cyrusBrushRecipeExport(owner.paintDocument)
   assert math.isclose(float(data[1])/units,saved['radius']/doc['unitsPerMetre'],rel_tol=3e-6,abs_tol=3e-7)
   report['paint_radii']+=1
 roles={role:node for node in graph['nodes'] for role in node['roles']};meshes={x['id']:x['file'] for x in graph['meshes']};files={x['id']:x for x in graph['files']}
 checked=set()
 for owner,saved in zip(owners,doc['layers']):
  settings(owner,saved['settings']);paint(owner,saved['paint'])
  for area,record in zip(owner.paintAreas,saved['areas']):settings(area,record['settings']);paint(area,record['paint'])
  assert len(owner.sources)==len(saved['settings']['sources'])
  for source,role in zip(owner.sources,saved['settings']['sources']):
   if role is None or role in checked:continue
   node=roles[role];descriptor=files[meshes[node['mesh']]]
   data=(package/'assets'/(descriptor['sha256']+'.cmesh')).read_bytes();assert hashlib.sha256(data).hexdigest()==descriptor['sha256'] and data[:8]==b'CYRUSM01'
   vertices,faces,channels=struct.unpack_from('<III',data,8);mesh=source.mesh;assert int(mesh.numverts)==vertices
   for i in range(vertices):
    expected=struct.unpack_from('<ddd',data,20+i*24);actual=r.getVert(mesh,i+1)
    for value,target in zip((actual.x,actual.y,actual.z),expected):scalar(value,target)
   report['vertices_checked']+=vertices;report['source_models']+=1;checked.add(role)
 report.update(status='passed',units_per_metre=units,recipe_sha256=hashlib.sha256((package/'entry.csrecipe.json').read_bytes()).hexdigest())
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(OUT/('physical-'+token+'.json')).write_text(json.dumps(report,indent=2)+'\n')
