"""Actual control-handler smoke probes in the owned UI host."""
from pathlib import Path
import json, time, traceback
from pymxs import runtime as r

out=Path(str(r.GardenRun)); case=str(r.CVProfileCase)
report={'case':case,'status':'running','checks':[]}
def run(name,code):
    try:
        value=r.execute(code)
        report['checks'].append({'name':name,'status':'pass','value':str(value)})
        return value
    except Exception:
        report['checks'].append({'name':name,'status':'fail','error':traceback.format_exc()})
        return None
def pump():
    for _ in range(10):
        r.windows.processPostedMessages();time.sleep(.02)
try:
    if case=='setup':
        run('fixture','UIRoot.surfaceNodes=#(UIPlane);UIRoot.newLayer();UILayer=UIRoot.selectedLayer();'
            'UILayer.addModelSource UIModel;UILayer.amount=40;UIRoot.updateMode=1;'
            'UIRoot.refreshAll();select UINode;max modify mode;modPanel.setCurrentObject UIRoot')
        pump()
        run('open panels','for i=1 to UIRoot.mainUI.slots.count do (UIRoot.mainUI.slots[i].open=true;'
            'UIRoot.mainUI.bindSection UIRoot.mainUI.editors[i]);true')
        run('capture captions','for key in #(#diversityUI_removePath,#diversityUI_addOutside,#diversityUI_addInside) '
            'collect (getProperty UIRoot.layoutUI key).text')
        run('point add actual handler','UIRoot.modelsUI.sourceUI_addPoint.pressed();'
            '#(UILayer.sources.count,UILayer.sourcePoint as array,UILayer.sourceEmpty as array,UILayer.validSources())')
        pump()
        run('point publication','UIRoot.refreshAll();if UILayer.previewError!="" do throw UILayer.previewError;'
            '#(UILayer.generatedCount,UILayer.previewError)')
        run('source lists agree','#(UIRoot.modelsUI.sourceUI_plantList.items,UIRoot.interactionsUI.interactionsUI_modelList.items)')
    elif case=='paint':
        run('remove placeholder for independent Paint probe','if UILayer.sources.count>1 do UILayer.removeModelSources #{2};UIRoot.refreshAll();'
            'if UILayer.previewError!="" do throw UILayer.previewError')
        run('add area actual handler','UIRoot.coverageUI.setsUI_paintedCheck.checked=true;'
            'UIRoot.coverageUI.setsUI_paintedCheck.changed true;UIRoot.coverageUI.setsUI_addButton.pressed()')
        pump()
        run('paint state','#(UILayer.paintEnabled,UILayer.paintAreas.count,UIRoot.coverageUI.brushUI_obj)')
        run('fill actual handler','UIRoot.coverageUI.brushUI_fillButton.pressed();UIRoot.refreshAll();UILayer.generatedCount')
        run('inside fade actual handler','UIRoot.coverageUI.brushUI_insideSpin.value=20;'
            'UIRoot.coverageUI.brushUI_insideSpin.changed 20;'
            'cyrusBrushFalloff UIRoot.coverageUI.brushUI_obj.paintDocument')
        run('fade publication','UIRoot.refreshAll();if UILayer.previewError!="" do throw UILayer.previewError;'
            '#(UILayer.generatedCount,UILayer.previewError)')
    report['status']='pass' if all(x['status']=='pass' for x in report['checks']) else 'failed'
except Exception:
    report.update(status='failed',error=traceback.format_exc())
(out/(case+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
