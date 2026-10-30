from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    water=r.getNodeByName('msh_water_surface',exact=True)
    data['water']=dict(class_name=str(r.classOf(water)),material=str(water.material),position=str(water.pos),hidden=bool(water.isHidden),renderable=bool(water.renderable))
    data['lights']=[dict(name=str(n.name),class_name=str(r.classOf(n))) for n in r.lights]
    data['renderer']=str(r.renderers.current)
    for name in ['01 Terraced estate','02 Lake promenade','03 Meadow and house','04 Boulder garden']:
        cam=r.getNodeByName('GARDEN | '+name,exact=True)
        r.viewport.setCamera(cam);r.completeRedraw();r.windows.processPostedMessages();time.sleep(.15)
        b=r.gw.getViewportDib();b.filename=str(out/('resolved-view-'+name[:2]+'.png'));r.save(b);r.close(b)
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-views-final.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
