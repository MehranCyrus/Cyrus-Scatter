"""Owned Max 2027 selection and shared-control fixture. No artist scene writes."""
from pathlib import Path
import json, time, traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3]
out=Path(str(r.GardenRun));report={}
def pump(n=6):
    for _ in range(n):r.windows.processPostedMessages();r.redrawViews();time.sleep(.03)
def ready(node):
    for _ in range(60):
        r.CyrusPointSync();pump(1)
        helper=r.CyrusPointOwner(node)
        if helper and int(r.cyrusRetainedPresentationStats(helper)[3])==2:return helper
    raise RuntimeError('Display not ready: '+str(node))
def save(): (out/'smoke.json').write_text(json.dumps(report,indent=2))
try:
    assert str(r.CyrusLibraryVersion())=='0.87.6.2'
    r.execute('global MCPFixtureDir=GardenRun,MCPFixtureTimer')
    if r.MCPFixtureTimer==r.undefined:r.fileIn(str(ROOT/'tools/mcp/development_transport.ms'))
    r.CyrusSelectionTimer.Stop()
    r.execute('resetMaxFile #noPrompt')
    r.execute('''undo on (
    global PKPlane=plane name:"Pick receiver" length:100 width:100 lengthsegs:1 widthsegs:1
    global PKSource=box name:"Pick source" length:9 width:9 height:12 pos:[300,0,0]
    global PKOne=AminScatterObject name:"Pick Scatter A",PKTwo=AminScatterObject name:"Pick Scatter B"
    global PKRoot=PKOne.baseObject,PKOther=PKTwo.baseObject,PKLayer,PKEdit
    for owner in #(PKRoot,PKOther) do (
        owner.surfaceNodes=#(PKPlane);owner.newLayer();local leaf=owner.selectedLayer()
        leaf.addModelSource PKSource;leaf.amount=12;owner.updateMode=1;owner.setGroupDisplay 3;owner.refreshAll()
    )
    PKLayer=PKRoot.selectedLayer();global PKOtherLayer=PKOther.selectedLayer();PKOtherLayer.randomSeed=27;PKOther.refreshAll()
    PKEdit=CyrusScatterEdit();addModifier PKOne PKEdit;PKRoot.refreshAll()
    viewport.setType #view_top
    select PKPlane;max zoomext sel;clearSelection()
    )
    ''')
    helper=ready(r.PKOne);ready(r.PKTwo)
    report['version']=str(r.CyrusLibraryVersion());report['helper']=str(helper)
    report['selection_api']=int(r.cyrusViewportSelectionVersion())
    report['owner_redirect_api']=r.cyrusViewportSelectionOwner(helper)==r.PKOne
    r.select(helper);pump()
    report['real_selection_callback']=list(r.selection)==[r.PKOne]
    assert report['real_selection_callback'],str(r.selection)
    r.select(r.Array(r.PKOne,r.PKTwo));pump()
    report['multi_window']=bool(r.CyrusSelectionUI.open)
    assert report['multi_window']
    before=[int(n.baseObject.procEpoch) for n in (r.PKOne,r.PKTwo)]
    r.PKLayer.amount=37;r.PKLayer.markInputDirty()
    r.execute('CyrusSelectionUI.navigation.changed 123456')
    pump();after=[int(n.baseObject.procEpoch) for n in (r.PKOne,r.PKTwo)]
    report['manual_before_after']=[before,after]
    report['budgets']=[int(n.baseObject.viewportNavigationFaces) for n in (r.PKOne,r.PKTwo)]
    assert before==after and report['budgets']==[123456,123456]
    # Undo is exercised in separate transport events, after this file's hold ends.
    r.execute('CyrusSelectionUI.updateButton.pressed()');pump();ready(r.PKOne)
    report['updated_count']=int(r.PKLayer.generatedCount)
    assert report['updated_count']==37
    r.execute('CyrusSelectionUI.hideButton.pressed()');pump()
    report['previews_hidden']=[bool(n.baseObject.showPoints) for n in (r.PKOne,r.PKTwo)]
    assert not any(report['previews_hidden'])
    r.execute('CyrusSelectionUI.showButton.pressed()');ready(r.PKOne)
    report['previews_shown']=[bool(n.baseObject.showPoints) for n in (r.PKOne,r.PKTwo)]
    assert all(report['previews_shown'])
    r.execute('clearSelection();PKOther.showPoints=false;CyrusViewportRedraw()');ready(r.PKOne)
    rows=r.cyrusEditInspect(r.PKEdit,0,100)[3]
    report['edit_rows']=len(rows)
    samples=[]
    for row in rows:
        if not row[6]:continue
        point=row[12].row4;r.gw.setTransform(r.Matrix3(1));screen=r.gw.wTransPoint(point)
        start=time.perf_counter();hit=r.cyrusViewportPickAt(r.PKOne,int(screen.x),int(screen.y));elapsed=(time.perf_counter()-start)*1000
        samples.append(dict(id=str(row[4]),pixel=[int(screen.x),int(screen.y)],hit=str(hit),ms=elapsed))
    report['picks']=samples
    report['mesh_hits']=sum(x['hit']!='undefined' for x in samples)
    assert report['mesh_hits']>0
    # Actual native hover overlay through the registered viewport draw callback.
    last=next(x for x in samples if x['hit']!='undefined');r.cyrusViewportPickAt(r.PKOne,*last['pixel']);r.redrawViews()
    bitmap=r.gw.getViewportDib();bitmap.filename=str(out/'hover.png');r.save(bitmap);r.close(bitmap)
    report['status']='complete'
except Exception:report.update(status='failed',error=traceback.format_exc())
save()
