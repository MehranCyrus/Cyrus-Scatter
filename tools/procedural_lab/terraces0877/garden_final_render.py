"""Render and reopen the owned delivery scene; never touch the artist source."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    scene=out.parent/'Terraces_Garden_0.87.6.1_Max2027.max'
    assert scene.is_file()
    r.renderers.current.progressive_passLimit=16
    start=time.perf_counter()
    b=r.render(camera=r.TCBoulderCamera,outputwidth=1200,outputheight=750,vfb=False,outputfile=str(out/'Terraces_Garden_0.87.6.1.png'))
    r.close(b);data['render_seconds']=time.perf_counter()-start
    assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True)
    r.execute('''global GardenNodes=#(),TCGardenColliderNode,TCGardenColliderRoot,TCGardenEdit,TCGardenGrass,TCBoulderCamera
      for n in objects where classof n.baseObject==AminScatterObject and matchPattern n.name pattern:"GARDEN | *" do append GardenNodes n
      TCGardenColliderNode=getNodeByName "GARDEN | Lakeside boulders" exact:true;TCGardenColliderRoot=TCGardenColliderNode.baseObject
      TCGardenEdit=TCGardenColliderNode.modifiers[1];TCGardenGrass=TCGardenColliderRoot.layerObjects[4]
      TCBoulderCamera=getNodeByName "GARDEN | 04 Boulder garden" exact:true
      for n in GardenNodes do n.baseObject.refreshAll();CyrusPointSync();clearSelection();viewport.setCamera TCBoulderCamera''')
    for _ in range(25):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
    r.cyrusRetainedInteraction(False);r.redrawViews()
    data['controllers']=[dict(name=str(n.name),counts=[int(l.generatedCount) for l in n.baseObject.layerObjects],errors=[str(l.previewError) for l in n.baseObject.layerObjects]) for n in r.GardenNodes]
    assert not any(e for c in data['controllers'] for e in c['errors'])
    data['contact']=json.loads(str(r.TCGardenColliderRoot.interactionsStatistics()))
    data['presentation']=str(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.TCGardenColliderNode)))
    data['water_renderable']=bool(r.getNodeByName('msh_water_surface',exact=True).renderable)
    data['scene_bytes']=scene.stat().st_size
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-final-render.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
