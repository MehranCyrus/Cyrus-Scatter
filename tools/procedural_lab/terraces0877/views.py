"""Compose owned cameras and inventory external maps; no original saves."""
from pathlib import Path
import json,traceback,ctypes,time
from pymxs import runtime as r
out=Path(str(r.GardenRun))
try:
    maps=[]
    for classname in ('Bitmaptexture','CoronaBitmap'):
        try:
            for m in r.getClassInstances(getattr(r,classname)):
                prop='filename'
                value=str(r.getProperty(m,r.Name(prop)))
                maps.append({'class':classname,'name':str(m.name),'path':value,'exists':bool(r.doesFileExist(value))})
        except Exception as e:
            maps.append({'class':classname,'error':str(e)})
    (out/'maps.json').write_text(json.dumps(maps,indent=2))
    # Resize only the explicitly owned process window, through the host handle.
    hwnd=int(r.windows.getMAXHWND())
    ctypes.windll.user32.SetWindowPos(ctypes.c_void_p(hwnd),0,30,30,1500,950,0x0014)
    r.execute('''global TCOverview,TCLake,TCHouse
      TCOverview=targetCamera name:"GARDEN | 01 Terraced estate" pos:[-15000,-23000,15000] target:(targetObject pos:[1800,2200,600]) fov:48
      TCLake=targetCamera name:"GARDEN | 02 Lake promenade" pos:[-10600,-7800,-450] target:(targetObject pos:[-1500,-1700,50]) fov:58
      TCHouse=targetCamera name:"GARDEN | 03 Meadow and house" pos:[-5500,-6500,450] target:(targetObject pos:[800,500,500]) fov:50
      hide (for n in shapes where superclassof n==shape collect n)
      clearSelection();viewport.setCamera TCOverview''')
    r.completeRedraw();r.windows.processPostedMessages()
    b=r.gw.getViewportDib(); b.filename=str(out/'overview-empty.png');r.save(b);r.close(b)
    r.execute('viewport.setCamera TCLake');r.completeRedraw();r.windows.processPostedMessages()
    b=r.gw.getViewportDib(); b.filename=str(out/'lake-empty.png');r.save(b);r.close(b)
    (out/'views.json').write_text(json.dumps({'status':'ready','maps':len(maps)}))
except Exception:
    (out/'views.json').write_text(json.dumps({'status':'failed','error':traceback.format_exc()}))
