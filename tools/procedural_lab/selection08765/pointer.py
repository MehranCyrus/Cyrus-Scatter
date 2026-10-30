"""Actual Max viewport message route, using an isolated SDK test probe."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
out=Path(str(r.GardenRun));report={}
def pump(n=10):
    for _ in range(n):r.windows.processPostedMessages();r.redrawViews();time.sleep(.05)
def capture(name):
    b=r.gw.getViewportDib();b.filename=str(out/name);r.save(b);r.close(b)
try:
    r.loadDllsFromDir(str(out.parent/'probe')+'/', 'SelectionProbeV2.dlx')
    r.execute('subObjectLevel=0;clearSelection();CyrusSelectionTimer.Start()')
    pump()
    sample=json.loads((out/'workflow.json').read_text())['samples'][0]
    x,y=sample['x'],sample['y']
    helper=r.CyrusPointOwner(r.VPNode)
    report['owns_highlight']=int(r.selectionProbeOwnHighlight(helper))
    before=list(r.cyrusRetainedStreamStats());epoch=int(r.VPRoot.procEpoch)
    report['sdk_hit_owner']=str(r.cyrusViewportSelectionOwner(r.selectionProbeNode(x,y)))
    r.selectionProbeHover(x,y);pump(15);capture('native-hover.png')
    r.selectionProbeClick(x,y);pump(18)
    report['selection']=[str(n.name) for n in r.selection]
    report['edit_level']=int(r.subObjectLevel)
    edit=r.VPNode.modifiers[0]
    report['selected_ids']=[str(row[4]) for row in r.cyrusEditInspect(edit,0,500)[3] if row[7]]
    report['expected_id']=sample['id'];report['active_layer_owner']=int(r.VPRoot.selectedLayer().procNativeOwner)
    report['streams_unchanged']=before==list(r.cyrusRetainedStreamStats());report['epoch_unchanged']=epoch==int(r.VPRoot.procEpoch)
    capture('native-selected.png')
    assert report['edit_level']==1 and report['selected_ids']==[sample['id']]
    assert report['active_layer_owner']==sample['layer']
    assert report['streams_unchanged'] and report['epoch_unchanged']
    report['status']='complete'
except Exception:report.update(status='failed',error=traceback.format_exc())
(out/'pointer.json').write_text(json.dumps(report,indent=2))
