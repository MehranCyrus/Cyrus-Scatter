from pathlib import Path
import time,json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
def pump():
    for _ in range(5):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.03)
try:
    r.loadDllsFromDir(str(out.parent/'probe')+'/', 'SelectionProbeV2.dlx')
    r.execute('clearSelection();PKOther.showPoints=false;CyrusViewportRedraw()');pump()
    rows=r.cyrusEditInspect(r.PKEdit,0,100)[3];samples=[]
    for row in rows:
        if not row[6]:continue
        point=r.Point3(3,3,6)*row[12];r.gw.setTransform(r.Matrix3(1));s=r.gw.wTransPoint(point)
        x,y=int(s.x),int(s.y);direct=r.cyrusViewportPickAt(r.PKOne,x,y);node=r.selectionProbeNode(x,y)
        samples.append(dict(pixel=[x,y],id=str(row[4]),direct=str(direct),node=str(node),owner=bool(node and r.cyrusViewportSelectionOwner(node)==r.PKOne)))
    data['node_samples']=samples
    good=next(x for x in samples if x['owner']);data['native_node_pick']=True
    r.execute('select PKOne;max modify mode;modPanel.setCurrentObject PKEdit;subObjectLevel=1');pump()
    data['level']=int(r.subObjectLevel)
    hit=r.selectionProbeSub(*good['pixel'],True);data['sub_hit']=str(hit);pump()
    picked=r.cyrusEditInspect(r.PKEdit,0,100)[3]
    data['selected_ids']=[str(row[4]) for row in picked if row[7]]
    assert len(data['selected_ids'])==1
    data['matched_id']=data['selected_ids'][0] in good['direct'];assert data['matched_id']
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'picking-host.json').write_text(json.dumps(data,indent=2))
