from pathlib import Path
import json,time,traceback,pymxs
from pymxs import runtime as r
out=Path(str(r.GardenRun));rows=[]
def snap(label):
    rows.append([label,bool(r.theHold.Holding()),bool(r.theHold.IsSuspended())])
try:
    snap('initial')
    r.theHold.Begin();snap('initial Begin');r.theHold.Cancel()
    with pymxs.undo(False):
        snap('off');r.theHold.Begin();snap('off Begin');r.theHold.Cancel()
        r.theHold.Resume();snap('off resumed');r.theHold.Begin();snap('off resumed Begin');r.theHold.Cancel();r.theHold.Suspend()
    r.execute('global SharedProbe=#(); rollout SharedProbeEditor "Probe" (timer pulse interval:100 active:true;on pulse tick do (pulse.active=false;append SharedProbe #(theHold.Holding(),theHold.IsSuspended());theHold.Begin();append SharedProbe #(theHold.Holding(),theHold.IsSuspended());theHold.Cancel())) ;createDialog SharedProbeEditor')
    end=time.time()+1
    while time.time()<end:r.windows.processPostedMessages();time.sleep(.01)
    rows.append(['timer',str(r.SharedProbe)]);r.destroyDialog(r.SharedProbeEditor)
    out.joinpath('probe.json').write_text(json.dumps(rows));out.joinpath('completed.json').write_text('{}')
except Exception:out.joinpath('error.txt').write_text(traceback.format_exc())
