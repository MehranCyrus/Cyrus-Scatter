from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    source=r.getNodeByName('SOURCE | ROCK10 | Lakeside boulder',exact=True)
    geo=json.loads((out/'stone-proxy.json').read_text())
    proxy=r.getNodeByName('COLLIDER | ROCK10 closed envelope',exact=True)
    if proxy is None:proxy=r.mesh(name='COLLIDER | ROCK10 closed envelope',vertices=r.Array(*[r.Point3(*p) for p in geo['vertices']]),faces=r.Array(*[r.Point3(*p) for p in geo['faces']]))
    # snapshotAsMesh exported world vertices; do not apply the source frame twice.
    proxy.transform=r.Matrix3(1);proxy.renderable=False;proxy.isHidden=True
    r.setUserProp(proxy,'CyrusColliderProxy',True)
    node=r.getNodeByName('GARDEN | Lakeside boulders',exact=True);root=node.baseObject
    for leaf in list(root.layerObjects)[:3]:leaf.interactionsSetProxy(source,proxy)
    root.refreshAll();root.interactionsEnsure();r.CyrusPointSync()
    for _ in range(15):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
    data['stats']=json.loads(str(root.interactionsStatistics()));data['errors']=[str(l.previewError) for l in root.layerObjects]
    assert not any(data['errors'])
    edit=next((m for m in node.modifiers if r.classOf(m)==r.CyrusScatterEdit),None)
    if edit is None:edit=r.CyrusScatterEdit();r.addModifier(node,edit)
    r.execute('global TCGardenColliderNode,TCGardenColliderRoot,TCGardenEdit,TCGardenGrass')
    r.TCGardenColliderNode=node;r.TCGardenColliderRoot=root;r.TCGardenEdit=edit;r.TCGardenGrass=root.layerObjects[-1]
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Interactive_08761.max'),quiet=True);r.CyrusPointSync()
    data['proxy_faces']=len(geo['faces']);data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-proxy-assignment.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
