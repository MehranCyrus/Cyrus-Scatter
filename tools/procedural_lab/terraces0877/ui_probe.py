"""Actual shared UI commands and bounded cold/warm panel measurements."""
from pathlib import Path
import json,time,traceback,statistics
from pymxs import runtime as r
out=Path(str(r.GardenRun));report={'status':'running'}
def pump():
    for _ in range(5):
        r.windows.processPostedMessages();time.sleep(.015)
def labels():
    return [str(x) for x in r.UIRoot.modelsUI.sourceUI_plantList.items]
try:
    r.execute('''resetMaxFile #noPrompt
    global UIPlane=plane name:"UI receiver" length:100 width:100 lengthsegs:1 widthsegs:1
    global UIModel=box name:"UI source" width:1 length:1 height:3 pos:[80,0,0]
    global UINode=AminScatterObject(),UIRoot=UINode.baseObject,UILayer
    UIRoot.surfaceNodes=#(UIPlane);UIRoot.newLayer();UILayer=UIRoot.selectedLayer()
    UILayer.addModelSource UIModel;UILayer.amount=40;UIRoot.updateMode=1;UIRoot.refreshAll()
    select UINode;max modify mode;modPanel.setCurrentObject UIRoot''')
    pump()
    r.execute('UIRoot.mainUI.slots[3].open=true;UIRoot.mainUI.bindSection UIRoot.modelsUI;UIRoot.mainUI.slots[5].open=true;UIRoot.mainUI.bindSection UIRoot.layoutUI')
    pump()
    r.execute('''global UIRect=rectangle name:"UI Band path" length:40 width:40
    UILayer.diversityMode=3;UILayer.addStroke UIRect side:1;UILayer.strokeModes[1]=2
    UIRoot.mainUI.bind();for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned UI fixture"''')
    pump()
    r.execute('UIRoot.modelsUI.sourceUI_addPoint.pressed()');pump()
    report['before_assignment']=labels()
    r.execute('UIRoot.layoutUI.diversityUI_setBandChoices #{1,2}')
    pump()
    report['after_assignment']=labels()
    report['authored_band_label']=str(r.UILayer.sourceBandLabel(2))
    report['point_label_current']=report['authored_band_label'] in report['after_assignment'][1]
    r.execute('UIRoot.mainUI.bind()');pump()
    report['after_forced_refresh']=labels()
    report['epoch_before_panels']=int(r.UIRoot.procEpoch)
    r.cyrusDiagnosticStop()
    r.cyrusDiagnosticStart('terrace-ui-panels',4000,4*1024*1024,120000)
    timings=[]
    for i,slot in enumerate(r.UIRoot.mainUI.slots,1):
        slot.open=False;pump()
        t=time.perf_counter();slot.open=True;pump()
        timings.append({'page':i,'name':str(slot.title),'cold_or_first_ms':(time.perf_counter()-t)*1000})
    for row,slot in zip(timings,r.UIRoot.mainUI.slots):
        samples=[]
        for _ in range(4):
            slot.open=False;pump()
            t=time.perf_counter();slot.open=True;pump()
            samples.append((time.perf_counter()-t)*1000)
        row['warm_ms']=samples;row['median_ms']=statistics.median(samples)
    r.cyrusDiagnosticStop()
    report['panel_timings']=timings
    report['diagnostics']=json.loads(str(r.cyrusDiagnosticSnapshot(0,500)))
    report['epoch_after_panels']=int(r.UIRoot.procEpoch)
    report['timing_scope']='Scripted rollout open plus five message-pump steps (75 ms requested delay); native inclusive stages recorded separately. Not physical UI latency.'
    report['status']='complete'
except Exception:
    report['status']='failed';report['error']=traceback.format_exc()
finally:
    (out/'ui-probe.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
