from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
out=Path(str(r.GardenRun));p=out/'persistence.json';data=json.loads(p.read_text())
try:
    assert data['status']=='moved',data
    r.execute('max undo')
    for _ in range(6):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.02)
    row=next(x for x in r.cyrusEditInspect(r.RKEdit,0,500)[3] if int(x[0])==data['layer'] and str(x[4])==data['id']);data['undo']=[float(x) for x in row[12].row4]
    assert str(row[4])==data['id'] and max(abs(a-b) for a,b in zip(data['undo'],data['before']))<1e-6
    assert not str(r.RKRoot.interactionError)
    data['status']='undone'
except Exception:data.update(status='failed',error=traceback.format_exc())
p.write_text(json.dumps(data,indent=2))
