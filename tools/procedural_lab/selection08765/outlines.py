"""Owned Max 2027 mesh cue, retained selection and native gesture checks."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback,statistics
out=Path(str(r.GardenRun));report={}

def pump(n=8):
    for _ in range(n):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.04)
def stats():return list(r.cyrusViewportOutlineStats())
def capture(name):
    b=r.gw.getViewportDib();b.filename=str(out/name);r.save(b);r.close(b)
def selected():return [str(row[4]) for row in r.cyrusEditInspect(r.VPNode.modifiers[0],0,500)[3] if row[7]]

try:
    r.loadDllsFromDir(str(out.parent/'probe')+'/', 'SelectionProbeV2.dlx')
    r.execute('subObjectLevel=0;clearSelection();CyrusSelectionTimer.Start()')
    pump()
    samples=json.loads((out/'workflow.json').read_text())['samples']
    sample=next(s for s in samples if s['layer']==int(r.VPB.procNativeOwner))
    x,y=sample['x'],sample['y']
    streams=list(r.cyrusRetainedStreamStats());epoch=int(r.VPRoot.procEpoch)
    r.selectionProbeHover(x,y);pump(12);capture('mesh-hover.png')
    report['hover']=stats();assert report['hover'][2]>12
    r.selectionProbeClick(x,y);pump(16)
    assert selected()==[sample['id']] and int(r.subObjectLevel)==1
    r.selectionProbeHover(5,5);pump(12)
    report['selected_pointer_away']=stats();capture('selected-pointer-away.png')
    assert report['selected_pointer_away'][2]==0 and report['selected_pointer_away'][3]>12 and report['selected_pointer_away'][4]==1
    before=stats();times=[]
    for _ in range(24):
        start=time.perf_counter();r.redrawViews();r.windows.processPostedMessages();times.append((time.perf_counter()-start)*1000)
    assert before==stats(),'Warm redraw rebuilt outline'
    assert epoch==int(r.VPRoot.procEpoch) and streams==list(r.cyrusRetainedStreamStats())
    report['warm']=dict(before=before,after=stats(),median_redraw_submission_ms=statistics.median(times),max_ms=max(times),unchanged_epochs_and_streams=True)
    r.CyrusSelectionTimer.Stop()
    r.execute('VPA.amount=10;VPRoot.updateMode=2;VPRoot.refreshAll();clearUndoBuffer()');pump(20)
    report['before_drag']=stats()
    r.selectionProbeGesture(0);r.selectionProbeGesture(1);pump(15)
    report['during_drag']=stats();capture('during-drag.png')
    assert report['during_drag'][5] is True
    assert report['during_drag'][1]==report['before_drag'][1],'Selection outline rebuilt during gesture'
    r.selectionProbeGesture(2);pump(20)
    report['after_drag']=stats();capture('after-drag.png')
    assert not report['after_drag'][5] and report['after_drag'][3]>12 and selected()==[sample['id']]
    r.execute('max undo');pump(15);report['undo']=stats()
    assert report['undo'][3]>12 and selected()==[sample['id']]
    r.execute('max redo');pump(15);report['redo']=stats()
    assert report['redo'][3]>12 and selected()==[sample['id']]
    # Distinct selection state, not a frozen copy of the last hovered object.
    edit=r.VPNode.modifiers[0]
    r.execute('subObjectLevel=0');pump();report['exit_edit']=stats()
    assert report['exit_edit'][3]==0 and report['exit_edit'][4]==0
    report['status']='complete'
except Exception:
    report.update(status='failed',error=traceback.format_exc())
    try:r.selectionProbeGesture(3)
    except Exception:pass
(out/'outlines.json').write_text(json.dumps(report,indent=2))
