from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
out=Path(str(r.GardenRun));data={}
def pump():
    for _ in range(12):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.03)
def pixel(row):
    r.gw.setTransform(r.Matrix3(1));s=r.gw.wTransPoint(r.Point3(3,3,6)*row[12]);return int(s.x),int(s.y)
try:
    r.execute('select PKOne;max modify mode;modPanel.setCurrentObject PKEdit;subObjectLevel=1;PKOther.showPoints=false;CyrusViewportRedraw()');pump()
    rows=r.cyrusEditInspect(r.PKEdit,0,100)[3]
    initial=next(x for x in rows if x[6]);p=pixel(initial)
    assert r.selectionProbeSub(*p,True)!=r.undefined
    row=next(x for x in r.cyrusEditInspect(r.PKEdit,0,100)[3] if x[7]);identity=str(row[4]);data['identity']=identity
    r.cyrusEditCommand(r.PKEdit,4,r.transMatrix(r.Point3(20,0,0)));pump()
    row=next(x for x in r.cyrusEditInspect(r.PKEdit,0,100)[3] if str(x[4])==identity)
    p=pixel(row);hit=r.cyrusViewportPickAt(r.PKOne,*p)
    data['moved_hit']=str(hit);assert str(hit[1])==identity
    r.execute('subObjectLevel=0')
    center=r.Point3(0,0,30)*row[12]
    obstacle=r.box(name='Pick occlusion control',length=16,width=16,height=10,pos=center)
    r.clearSelection();pump()
    data['occluder_pick']=r.selectionProbeNode(*p)==obstacle;assert data['occluder_pick']
    r.delete(obstacle);pump()
    data['after_occluder_delete']=r.cyrusViewportSelectionOwner(r.selectionProbeNode(*p))==r.PKOne;assert data['after_occluder_delete']
    r.execute('select PKOne;max modify mode;modPanel.setCurrentObject PKEdit;subObjectLevel=1');pump()
    assert r.selectionProbeSub(*p,True)!=r.undefined
    r.cyrusEditCommand(r.PKEdit,2,r.undefined)
    data['authored_deleted']=[str(x[4]) for x in r.cyrusEditInspect(r.PKEdit,0,100)[3] if x[8]]
    assert identity in data['authored_deleted']
    # This fixture deliberately uses Manual; publish its successor explicitly.
    r.PKRoot.refreshAll();pump()
    hit=r.cyrusViewportPickAt(r.PKOne,*p);data['deleted_hit']=str(hit)
    assert hit==r.undefined or str(hit[1])!=identity
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'pick-lifecycle.json').write_text(json.dumps(data,indent=2))
