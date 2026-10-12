"""Real SDK creation callback sequence; does not send OS mouse input."""
from pathlib import Path
import sys,traceback,time
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('create-callbacks')
try:
    year=2027 if int(r.maxVersion()[0])==29000 else 2026
    r.loadDllsFromDir(str(ROOT/f'build/refine0795-create-20261011/probe{year}-nmake')+'\\','CyrusPrivateCreateProbe.dlx')
    mx('max select');r.resetMaxFile(r.Name('noPrompt'));r.viewport.setType(r.Name('view_top'));r.completeRedraw()
    rec.step('Enter Create',lambda:r.startObjectCreation(r.AminScatterObject),redraw=False)
    rec.step('Initial panel messages',lambda:pump(150),redraw=False)
    # A normal redraw before the first click publishes the empty scene. The
    # creation icon must not depend on a later layer/placement publication.
    r.CyrusPointSync()
    rec.data['events']=[]
    def event(label,message,point,x,y):
        started=time.perf_counter();result=r.cyrusPrivateCreateEvent(message,point,x,y);elapsed=(time.perf_counter()-started)*1000
        started=time.perf_counter();r.completeRedraw();redraw_ms=(time.perf_counter()-started)*1000
        started=time.perf_counter();pump(50);messages_ms=(time.perf_counter()-started)*1000
        rec.data['events'].append(dict(label=label,result=int(result),elapsed_ms=elapsed,redraw_ms=redraw_ms,messages_ms=messages_ms,mode=str(r.toolMode.commandMode),records_dirty=bool(r.CyrusViewportRecordsDirty),registered=[str(n.name) for n in r.CyrusTimeOwners],display_records=[str(row[0].name) for row in r.CyrusViewportRecords],nodes=[dict(name=str(n.name),size=float(n.iconSize)) for n in controllers()]));rec.write()
    event('first point',1,0,240,200)
    for i in range(10):event('sizing '+str(i),2,1,250+i*5,210+i*3)
    event('finish size',1,1,300,250);pump(500)
    rec.check(len(controllers())==1,'One completed two-click object')
    rec.data['final_nodes']=[str(n.name) for n in controllers()];rec.write()
    mx('max select')
except Exception:rec.error(traceback.format_exc())
