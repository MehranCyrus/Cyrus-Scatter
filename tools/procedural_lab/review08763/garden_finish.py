from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
out=Path(str(r.GardenRun));p=out/'garden-drag.json';data=json.loads(p.read_text())
try:
    assert data['status']=='complete'
    for mode in ('edit','scene'):
        rows=[x for x in data['samples'] if x['mode']==mode]
        assert len(rows)==12 and all(x['stats']['affected']>0 for x in rows)
        assert len(set(x['frame'][1] for x in rows))==12
        assert len(set(x['frame'][2] for x in rows))>=11
        for key in ('layouts','source_captures','source_preparations','collider_cooks'):
            assert rows[0]['stats']['process_work'][key]==rows[-1]['stats']['process_work'][key],key
    orbit=[x for x in data['samples'] if x['mode']=='orbit']
    assert len(orbit)==6 and orbit[0]['stats']['process_work']==orbit[-1]['stats']['process_work']
    for _ in range(5):r.redrawViews();r.windows.processPostedMessages();time.sleep(.02)
    frame=[str(x) for x in r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.RDOwner))]
    assert frame[1]==frame[2] and not str(r.RDRoot.interactionError),frame
    data['final_frame']=frame;data['system_units_per_metre']=float(r.units.decodeValue('1m'))
    data['verification']='passed'
    image=r.gw.getViewportDib();image.filename=str(out/'garden-final.png');r.save(image);r.close(image)
except Exception:data.update(verification='failed',error=traceback.format_exc())
p.write_text(json.dumps(data,indent=2))
