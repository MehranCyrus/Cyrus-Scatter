from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={};saved=None
try:
    node=r.TCGardenColliderNode;root=node.baseObject
    data['root_handles']=[int(r.getHandleByAnim(r.TCGardenColliderRoot)),int(r.getHandleByAnim(root))]
    r.TCGardenColliderRoot=root
    edits=[m for m in node.modifiers if r.classOf(m)==r.CyrusScatterEdit]
    assert edits,'Missing owned interaction modifier'
    for duplicate in edits[1:]:r.deleteModifier(node,duplicate)
    edit=edits[0];r.TCGardenEdit=edit
    root.refreshAll();root.interactionsEnsure();r.CyrusPointSync()
    def ready():
        until=time.monotonic()+20
        while time.monotonic()<until:
            r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages();time.sleep(.025)
            state=r.cyrusRetainedPresentationStats(r.CyrusPointOwner(node))
            if int(state[3])==2:return str(state)
        raise RuntimeError(str(state))
    for n in r.GardenNodes:
        n.baseObject.viewportFaces=10000000 if 'Woodland' in str(n.name) else 6000000
        n.baseObject.viewportNavigationFaces=2000000 if 'Woodland' in str(n.name) else 1000000
        n.baseObject.refreshDisplay()
    r.CyrusPointSync();ready();r.viewport.setCamera(r.TCBoulderCamera)
    r.cyrusEditActiveLayers(edit,r.Array(root.layerObjects[0].editLayerKey));r.cyrusEditCommand(edit,1,r.undefined)
    r.execute('global TCGardenHeldBefore=CyrusInteractionHeld;fn CyrusInteractionHeld=true')
    samples=[]
    for i in range(12):
        start=time.perf_counter();r.cyrusEditCommand(edit,4,r.transMatrix(r.Point3(10 if i<6 else -10,0,0)))
        r.CyrusPointSync();cpu=(time.perf_counter()-start)*1000
        frame=ready();samples.append(dict(step=i,cpu_sync_ms=cpu,frame=frame,stats=json.loads(str(root.interactionsStatistics()))))
    r.execute('CyrusInteractionHeld=TCGardenHeldBefore')
    data['samples']=samples
    assert len({s['stats']['generation'] for s in samples})>1,'Movement did not publish new contact generations'
    data['active_grass_sources']=int(r.TCGardenGrass.interactionSourceIDs.count)
    data['controllers']=[dict(name=str(n.name),counts=[int(l.generatedCount) for l in n.baseObject.layerObjects],errors=[str(l.previewError) for l in n.baseObject.layerObjects]) for n in r.GardenNodes]
    assert not any(e for c in data['controllers'] for e in c['errors'])
    r.execute('clearSelection();viewport.setCamera TCBoulderCamera;CyrusPointSync();completeRedraw()')
    for _ in range(20):r.windows.processPostedMessages();time.sleep(.05)
    r.cyrusRetainedInteraction(False);r.redrawViews()
    b=r.gw.getViewportDib();b.filename=str(out/'garden-final-viewport.png');r.save(b);r.close(b)
    r.renderers.current.progressive_passLimit=16
    water=r.getNodeByName('msh_water_surface',exact=True);water.renderable=True
    water.material.baseColor=r.Color(16,52,62);water.material.baseRoughness=.08
    water.material.baseIor=1.333;water.material.refractionAmount=.25
    r.renderWidth=1600;r.renderHeight=1000
    path=out.parent/'Terraces_Garden_0.87.6.1_Max2027.max'
    r.saveMaxFile(str(path),quiet=True);r.CyrusPointSync()
    data['scene']=str(path);data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
finally:
    r.execute('if TCGardenHeldBefore!=undefined do CyrusInteractionHeld=TCGardenHeldBefore')
(out/'garden-drag-finish.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
