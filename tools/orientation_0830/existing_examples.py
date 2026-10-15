"""Reopen the delivered schema-58 examples and preserve all v1 authored data."""
from pathlib import Path
import json,sys,hashlib,traceback,time
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-orientation0830-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
result={'status':'running','examples':[],'checks':[]};target=OUT/('existing-examples-'+str(time.time_ns())+'.json')
def save():target.write_text(json.dumps(result,indent=2),encoding='utf-8')
def check(ok,label):result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def plain(v):
 if v is None or isinstance(v,(str,int,float,bool)):return v
 a=list(v)
 if len(a)==2 and str(a[0])=='recipeObject':return {str(p[0]):plain(p[1]) for p in a[1]}
 return [plain(x) for x in a]
def capture_settings(settings,roles):
 # Role IDs are file-local; compare each semantic dependency by kind/name.
 mapping={x['id']:(x['kind'],x['name']) for x in roles}
 schema=list(r.cyrusRecipeSchema());out=dict(settings)
 for field in schema:
  key,kind=str(field[0]),str(field[1])
  if kind in ('node','texturemap'):out[key]=None if out[key] is None else mapping[out[key]]
  if kind=='nodetab':out[key]=[None if x is None else mapping[x] for x in out[key]]
 return out
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True
  inventory=json.loads((ROOT/'AminScatter/library/inventory.json').read_text(encoding='utf-8'))
  for spec in inventory['entries']:
   path=ROOT/'AminScatter/library'/spec['recipe'];before=hashlib.sha256(path.read_bytes()).hexdigest()
   old=plain(r.cyrusRecipeRead(str(path)));check(old['formatVersion']==2,'v1 read converts only orientation defaults: '+spec['id'])
   check(hashlib.sha256(path.read_bytes()).hexdigest()==before,'Reading leaves original recipe bytes unchanged: '+spec['id'])
   check(r.loadMaxFile(str(ROOT/'AminScatter/library'/spec['scene']),quiet=True,useFileUnits=True),'Delivered schema-58 scene reopens: '+spec['id'])
   node=r.getNodeByName('CYRUS EXAMPLE | '+spec['name']);root=node.baseObject;root.refreshAll()
   check([len(rows) for rows in root.groupSnapshotRows]==spec['counts'],'Existing accepted counts preserved: '+spec['id'])
   captured=plain(r.CyrusRecipeCapture(root,r.Array(*list(root.logicalLayers())),spec['name']))
   check(capture_settings(old['rootSettings'],old['roles'])==capture_settings(captured['rootSettings'],captured['roles']),'Every root setting preserved: '+spec['id'])
   for left,right in zip(old['layers'],captured['layers']):
    check(capture_settings(left['settings'],old['roles'])==capture_settings(right['settings'],captured['roles']),'Every layer setting preserved: '+spec['id']+'/'+left['name'])
    check(left['id']==right['id'] and len(left['areas'])==len(right['areas']),'Owner IDs and Paint Area counts preserved: '+spec['id'])
    for a,b in zip(left['areas'],right['areas']):
     check(capture_settings(a['settings'],old['roles'])==capture_settings(b['settings'],captured['roles']),'Every Paint Area setting preserved: '+spec['id'])
     # Native Paint bytes and feather settings are preserved exactly.
     check(a['paint']['payload']==b['paint']['payload'] and a['paint']['radius']==b['paint']['radius'] and a['paint']['erase']==b['paint']['erase'] and a['paint']['frame']==b['paint']['frame'],'Complete authored Paint preserved: '+spec['id'])
   record={'id':spec['id'],'rows':[fingerprint(rows) for rows in root.groupSnapshotRows],'counts':spec['counts']};result['examples'].append(record);save()
  r.CyrusPerfHeadless=False;r.CyrusPointSync()
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
