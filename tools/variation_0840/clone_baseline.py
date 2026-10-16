"""Observe existing Max Copy/Instance semantics in an owned disposable host."""
from pathlib import Path
import json,sys,traceback,time
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-variation0840-')
assert json.loads((OUT/'launch.json').read_text())['script_sha256']=='8ed01163ebd88909bb7ce34aaffd24ff10232d13705a0c60dfa32468e8b32eb1'
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
result={'status':'running','scope':'0.83.0 baseline observation, not I05 acceptance'};target=OUT/('clone-baseline-'+str(time.time_ns())+'.json')
def summary(node):
 root=node.baseObject
 return {'root_id':str(root.layerID),'node_handle':int(r.getHandleByAnim(node)),
  'owners':[{'layer_id':str(x.layerID),'handle':int(r.getHandleByAnim(x)),'edit_key':int(x.editLayerKey),'receivers':list(x.procReceiverIDs),'sources':list(x.procSourceIDs),'overlap_owner':int(r.getHandleByAnim(x.overlapOwner)) if x.overlapOwner else None} for x in root.layerObjects],
  'rows':[fingerprint(x) for x in root.groupSnapshotRows]}
try:
 with pymxs.undo(False):
  r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'))
  terrain=r.plane(name='Variation terrain',length=100,width=100,lengthsegs=1,widthsegs=1)
  model=r.pyramid(name='Variation model',width=1,depth=2,height=4,pos=r.Point3(-100,0,0))
  node=r.AminScatterObject(name='Original variation setup');root=node.baseObject;root.updateMode=1;root.autoRender=False
  for i in range(2):
   root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(terrain));leaf.sources=r.Array(model);leaf.ensureSourceRows()
   leaf.amount=50;leaf.procSelfOverride=True;leaf.procSelfEnabled=False;leaf.procLayerSelfEnabled=False
  root.refreshAll();result['original_before']=summary(node)
  copied=r.copy(node);copied.name='Copied variation setup';result['copy_before_evaluation']=summary(copied)
  copied.baseObject.refreshAll();result['copy_after_evaluation']=summary(copied);result['original_after_copy']=summary(node)
  result['copy_same_root']=copied.baseObject==root;result['copy_same_children']=[a==b for a,b in zip(root.layerObjects,copied.baseObject.layerObjects)]
  instanced=r.instance(node);instanced.name='Instanced variation setup';result['instance_same_root']=instanced.baseObject==root
  root.copyLogicalLayer(root.layerObjects[0]);root.refreshAll();result['layer_copy']=summary(node)
  r.saveMaxFile(str(OUT/'clone-baseline.max'),quiet=True);result['status']='observed'
except Exception:result['status']='failed';result['error']=traceback.format_exc();raise
finally:target.write_text(json.dumps(result,indent=2),encoding='utf-8')
