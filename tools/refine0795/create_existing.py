"""Create, size and abort beside a populated setup; preserve its published data."""
from pathlib import Path
import sys,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('create-existing')
try:
    original=controllers();rec.check(bool(original),'Populated workflow prerequisite')
    r.clearSelection();mx('max select');r.CyrusPointSync();pump(300)
    before=state()['controllers'];rec.data['before']=before;rec.write()
    r.startObjectCreation(r.AminScatterObject);pump(150)
    r.cyrusPrivateCreateEvent(1,0,240,200);pump(50)
    for i in range(10):
        r.cyrusPrivateCreateEvent(2,1,250+i*5,210+i*3)
        r.AminScatterObjectDraw();pump(20)
    result=r.cyrusPrivateCreateEvent(1,1,300,250)
    rec.check(int(result)==0,'Second click finishes the sizing sequence')
    rec.check(len(controllers())==len(original)+1,'Two-click sequence adds exactly one controller')
    after=state()['controllers'];rec.data['after']=after;rec.write()
    for prev in before:
        now=next(x for x in after if x['name']==prev['name'])
        rec.check(all(now[k]==prev[k] for k in ('epoch','fingerprints','groups','layers')),prev['name']+': creation preserves placements and layer caches')
        rec.check(now['retained'][:7]==prev['retained'][:7],prev['name']+': creation does not upload unchanged buffers')
    # Max keeps its creation command active by design. A third placement click
    # starts the next object; abort must remove only that unfinished object.
    r.cyrusPrivateCreateEvent(1,0,350,220)
    rec.check(len(controllers())==len(original)+2,'A deliberate next placement starts a second object')
    r.cyrusPrivateCreateEvent(0,1,350,220);mx('max select');pump(200)
    rec.check(len(controllers())==len(original)+1,'Abort removes only the unfinished object')
    rec.write()
except Exception:rec.error(traceback.format_exc())
