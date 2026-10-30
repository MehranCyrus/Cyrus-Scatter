"""Repeat only already-mounted panels, plus closed-page invalidation."""
from pathlib import Path
import json,time,traceback,statistics
from pymxs import runtime as r
out=Path(str(r.GardenRun));report={}
def pump():
    for _ in range(3):r.windows.processPostedMessages();time.sleep(.01)
try:
    root=r.UIRoot;leaf=r.UILayer
    for slot in root.mainUI.slots:slot.open=True
    pump();r.cyrusDiagnosticStop();r.cyrusDiagnosticStart('warm-panels-only',4000,4*1024*1024,120000)
    epoch=int(root.procEpoch);rows=[]
    for slot in root.mainUI.slots:
        samples=[]
        for _ in range(6):
            slot.open=False;pump();start=time.perf_counter();slot.open=True;pump()
            samples.append((time.perf_counter()-start)*1000)
        rows.append(dict(name=str(slot.title),median_ms=statistics.median(samples),max_ms=max(samples),samples_ms=samples))
    r.cyrusDiagnosticStop()
    report.update(panels=rows,diagnostics=json.loads(str(r.cyrusDiagnosticSnapshot(0,500))),epoch_before=epoch,epoch_after=int(root.procEpoch))
    root.mainUI.slots[2].open=False
    leaf.sourceWeights[0]=2.;leaf.markInputDirty()
    root.mainUI.slots[2].open=True;pump()
    report['closed_page_current']='2.00' in str(root.modelsUI.sourceUI_plantList.items[0])
    report['status']='complete'
except Exception:report.update(status='failed',error=traceback.format_exc())
(out/'ui-warm.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
