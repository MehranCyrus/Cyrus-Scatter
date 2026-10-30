"""Owned viewport identity, occlusion and helper lifetime checks."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));data={}
def pump(n=10):
    for _ in range(n):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.04)
def px(point):
    r.gw.setTransform(r.Matrix3(1));p=r.gw.wTransPoint(point);return int(p.x),int(p.y)
try:
    r.execute('global VPNode=getNodeByName "Owned layered scatter" exact:true;global VPRoot=VPNode.baseObject')
    r.VPRoot.refreshAll();pump(20)
    r.CyrusSelectionTimer.Stop()
    row=next(x for x in r.cyrusEditInspect(r.VPNode.modifiers[0],0,500)[3] if x[7]);identity=str(row[4]);point=r.Point3(0,0,4)*row[12]
    r.execute('subObjectLevel=0;clearSelection()');pump()
    x,y=px(point);hit=r.cyrusViewportPickAt(r.VPNode,x,y)
    assert hit!=r.undefined and str(hit[1])==identity
    assert r.cyrusViewportSelectionOwner(r.selectionProbeNode(x,y))==r.VPNode
    data['transformed_instance_pick']=True
    obstacle=r.box(name='Owned occluder',length=12,width=12,height=10,pos=point+r.Point3(0,0,20));pump()
    assert r.selectionProbeNode(x,y)==obstacle;data['ordinary_object_occlusion']=True
    r.delete(obstacle);pump()
    assert r.cyrusViewportSelectionOwner(r.selectionProbeNode(x,y))==r.VPNode
    r.VPRoot.showPoints=False;pump()
    assert r.cyrusViewportPickAt(r.VPNode,x,y)==r.undefined
    assert r.cyrusViewportSelectionOwner(r.selectionProbeNode(x,y))!=r.VPNode
    r.VPRoot.showPoints=True;pump();data['hidden_preview_not_pickable']=True
    r.select(r.VPNode);pump()
    assert int(r.subObjectLevel)==0;data['controller_selection_keeps_settings']=True
    other=r.AminScatterObject(name='Owned second scatter',pos=r.Point3(200,200,0))
    r.select(r.Array(r.VPNode,other));pump()
    assert len(list(r.CyrusSelectionTargets()))==2 and r.CyrusSelectionUI.open
    assert int(r.subObjectLevel)==0;data['multi_controller_controls']=True
    r.execute('try(destroyDialog CyrusSelectionUI)catch()');r.delete(other);r.clearSelection();pump()
    data['helpers_before_save']=len(list(r.CyrusPointOwners[0]))-1
    scene=out/'Selection_08764.max';r.saveMaxFile(str(scene),quiet=True)
    r.loadMaxFile(str(scene),quiet=True,useFileUnits=True);pump(20)
    owner=r.getNodeByName('Owned layered scatter',exact=True)
    owner.baseObject.refreshAll();pump(20)
    pairs=[p for p in r.CyrusPointOwners if p[0]==owner]
    assert len(pairs)==1 and len(list(pairs[0]))==3
    private=[n for n in r.objects if r.classOf(n.baseObject)==r.classOf(pairs[0][1].baseObject)]
    assert len(private)==2;data['save_reload_single_render_and_pick_helper']=True
    hit=r.cyrusViewportPickAt(owner,x,y);assert hit!=r.undefined and str(hit[1])==identity
    data['save_reload_stable_pick']=True
    r.delete(owner);pump()
    private=[n for n in r.objects if str(r.classOf(n.baseObject))=='Cyrus_Point_Display']
    assert len(list(r.CyrusPointOwners))==0 and len(private)==0
    data['delete_clears_owner_helpers']=True;data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'lifecycle.json').write_text(json.dumps(data,indent=2))
r.execute('global MCPFixtureDir=GardenRun,MCPFixtureTimer')
r.fileIn(str(ROOT/'tools/mcp/development_transport.ms'))
r.MCPFixtureLast=(out/'dev-request.txt').read_text()
