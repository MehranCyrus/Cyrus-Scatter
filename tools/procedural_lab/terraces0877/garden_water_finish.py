from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    water=r.getNodeByName('msh_water_surface',exact=True);water.renderable=True
    data['material']={str(p):str(r.getProperty(water.material,p))[:140] for p in r.getPropNames(water.material) if any(k in str(p).lower() for k in ['color','rough','refract','transmi','ior','level'])}
    data['before']=dict(point_suspended=bool(r.CyrusPointSuspended),point_pending=bool(r.CyrusPointPending),last_error=str(r.CyrusPointLastError),render_held=bool(r.AminScatterRenderRedrawHeld))
    # Saving deliberately clears native caches. Explicit sync waits for their successor.
    r.CyrusPointSync()
    for _ in range(20):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
    data['frames']=[dict(name=str(n.name),frame=str(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(n)))) for n in r.GardenNodes]
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Art_Direction.max'),quiet=True)
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-water-finish.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
