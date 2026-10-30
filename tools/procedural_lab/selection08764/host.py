"""Disposable Max 2027 workflow fixture. Never saves an artist scene."""
from pathlib import Path
import json,time,traceback,statistics
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3]
out=Path(str(r.GardenRun));report={}
def save(): (out/'workflow.json').write_text(json.dumps(report,indent=2))
def pump(n=5):
    for _ in range(n):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.02)
def ready(node):
    for _ in range(80):
        pump(1);helper=r.CyrusPointOwner(node)
        if helper and int(r.cyrusRetainedPresentationStats(helper)[3])==2:return helper
    raise RuntimeError('Display not ready')
def counters():return dict(epoch=int(r.VPRoot.procEpoch),builds=list(r.VPRoot.groupCounters()),streams=list(r.cyrusRetainedStreamStats()))
def selected(edit):return [str(row[4]) for row in r.cyrusEditInspect(edit,0,500)[3] if row[7]]
try:
    assert str(r.CyrusLibraryVersion())=='0.87.6.4'
    r.execute('global MCPFixtureDir=GardenRun,MCPFixtureTimer')
    r.fileIn(str(ROOT/'tools/mcp/development_transport.ms'))
    r.CyrusSelectionTimer.Stop()
    r.execute('''resetMaxFile #noPrompt
    global VPPlane=plane name:"Owned receiver" length:100 width:100 lengthsegs:1 widthsegs:1
    global VPBox=box name:"Box source" length:6 width:6 height:8 pos:[200,0,0]
    global VPSphere=sphere name:"Sphere source" radius:4 segs:48 pos:[220,0,0]
    global VPNode=AminScatterObject name:"Owned layered scatter",VPRoot=VPNode.baseObject
    VPRoot.surfaceNodes=#(VPPlane);VPRoot.newLayer()
    global VPA=VPRoot.selectedLayer();VPA.addModelSource VPBox;VPA.amount=10;VPRoot.layerNames[1]="Boxes"
    VPRoot.newLayer();global VPB=VPRoot.selectedLayer();VPB.addModelSource VPSphere;VPB.amount=15;VPB.randomSeed=75;VPRoot.layerNames[2]="Spheres"
    VPRoot.updateMode=1;VPRoot.setGroupDisplay 3;VPRoot.refreshAll()
    hide VPBox;hide VPSphere
    viewport.setType #view_top;select VPPlane;max zoomext sel;clearSelection()
    ''')
    helper=ready(r.VPNode)
    report.update(version=str(r.CyrusLibraryVersion()),api=int(r.cyrusViewportSelectionVersion()),status='fixture-ready');save()
    samples=[]
    # Probe the actual source-surface hit path at a bounded pixel grid.
    w,h=int(r.gw.getWinSizeX()),int(r.gw.getWinSizeY())
    for y in range(25,h-25,25):
        for x in range(25,w-25,25):
            hit=r.cyrusViewportPickAt(r.VPNode,x,y)
            if hit!=r.undefined:samples.append(dict(x=x,y=y,layer=int(hit[0]),id=str(hit[1])))
    owners={s['layer'] for s in samples};assert len(owners)==2,owners
    report['samples']=samples;report['native_hits_across_layers']=True;save()
    # New Edit binds the retained result while Manual Count remains pending.
    r.VPA.amount=31;r.VPA.markInputDirty();pump()
    first=samples[0];r.select(r.VPNode);pump();before=counters()
    ticket=int(r.cyrusRetainedPresentationStats(helper)[2])
    request=r.Array(r.VPNode,first['layer'],first['id'],ticket)
    assert r.CyrusSelectionEnterInstance(request)
    edit=r.VPNode.modifiers[0];pump()
    report['new_edit']=dict(class_name=str(r.classOf(edit)),level=int(r.subObjectLevel),selected=selected(edit),passive=bool(r.cyrusEditSelectionPassive(edit)),before=before,after=counters(),pending_count=int(r.VPA.amount),visible_count=int(r.VPA.generatedCount))
    assert selected(edit)==[first['id']] and int(r.subObjectLevel)==1
    assert int(r.VPA.generatedCount)==10 and int(r.VPA.amount)==31
    # groupHits can increase on a cached read; solve and upload must not.
    assert before['epoch']==counters()['epoch'] and before['streams']==counters()['streams']
    second=next(s for s in samples if s['layer']!=first['layer'])
    assert r.CyrusSelectionEnterInstance(r.Array(r.VPNode,second['layer'],second['id'],ticket))
    pump();report['second_layer']=dict(selected=selected(edit),active=int(r.VPRoot.selectedLayer().procNativeOwner))
    assert selected(edit)==[second['id']] and report['second_layer']['active']==second['layer']
    # Stale publication tickets must not change selection or attach a modifier.
    assert not r.CyrusSelectionEnterInstance(r.Array(r.VPNode,first['layer'],first['id'],ticket-1))
    assert selected(edit)==[second['id']]
    r.execute('subObjectLevel=0;clearSelection()');pump()
    before=counters();times=[]
    for s in samples[:80]:
        t=time.perf_counter();r.cyrusViewportPickAt(r.VPNode,s['x'],s['y']);times.append((time.perf_counter()-t)*1000)
    r.redrawViews();image=r.gw.getViewportDib();image.filename=str(out/'hover.png');r.save(image);r.close(image)
    report['hover']=dict(before=before,after=counters(),median_ms=statistics.median(times),max_ms=max(times),samples=len(times))
    assert before['epoch']==counters()['epoch'] and before['streams']==counters()['streams']
    report['status']='complete';save()
except Exception:report.update(status='failed',error=traceback.format_exc());save()
r.execute('global MCPFixtureDir=GardenRun,MCPFixtureTimer')
r.fileIn(str(ROOT/'tools/mcp/development_transport.ms'))
