from pathlib import Path
import json,traceback,time
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    lake=r.getNodeByName('spl_water_master',exact=True)
    assert r.aminScatterValidArea(lake)
    for node in r.GardenNodes:
        root=node.baseObject
        for leaf in root.layerObjects:
            leaf.areaNodes=r.Array(lake);leaf.areaModes=r.Array(2)
        root.refreshAll();r.CyrusPointSync()
    # Fold the delivered rock's authored orientation into its owned source mesh.
    r.resetXForm(r.TCStoneSource);r.collapseStack(r.TCStoneSource)
    r.TCStoneController.baseObject.refreshAll();r.CyrusPointSync()
    r.execute('TCOverview=getNodeByName "GARDEN | 01 Terraced estate" exact:true;TCLake=getNodeByName "GARDEN | 02 Lake promenade" exact:true;TCHouse=getNodeByName "GARDEN | 03 Meadow and house" exact:true;TCBoulderCamera=getNodeByName "GARDEN | 04 Boulder garden" exact:true;viewport.setCamera TCBoulderCamera;completeRedraw()')
    data['layers']=[dict(controller=str(n.name),counts=[int(l.generatedCount) for l in n.baseObject.layerObjects],errors=[str(l.previewError) for l in n.baseObject.layerObjects]) for n in r.GardenNodes]
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Shoreline.max'),quiet=True)
    for n in r.GardenNodes:
        n.baseObject.autoRender=True
        for l in n.baseObject.layerObjects:l.autoRender=True
    r.renderers.current.progressive_passLimit=2;r.renderers.current.denoise_filterType=0
    (out/'render-stage.txt').write_text('rendering two-pass composition proof')
    start=time.perf_counter()
    image=r.render(camera=r.TCBoulderCamera,outputwidth=960,outputheight=600,vfb=False,outputfile=str(out/'garden-render-proof.png'))
    r.close(image);data['render_seconds']=time.perf_counter()-start
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Renderable.max'),quiet=True)
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-refine.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
