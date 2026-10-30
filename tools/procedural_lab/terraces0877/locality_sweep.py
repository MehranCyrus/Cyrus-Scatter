"""Local work versus distant vegetation; retain an optional stress scene."""
from pathlib import Path
import json,time,traceback,math
from pymxs import runtime as r
out=Path(str(r.GardenRun));cases=[]
def stats():return json.loads(str(r.WFRoot.interactionsStatistics()))
def sweep(label):
    origin=r.copy(r.DGStone.pos);samples=[];before=stats()
    for i in range(16):
        r.DGStone.pos=origin+r.Point3(35*math.sin(i*math.pi/7),0,0)
        r.CyrusSceneColliderWatch();r.WFRoot.interactionsEnsure();r.CyrusPointSync();r.redrawViews()
        for _ in range(2):r.windows.processPostedMessages();time.sleep(.01)
        samples.append(stats())
    r.DGStone.pos=origin;r.WFRoot.interactionsEnsure();r.CyrusPointSync()
    cases.append(dict(case=label,before=before,samples=samples,accepted=[int(l.generatedCount) for l in r.WFRoot.layerObjects]))
    (out/'locality-sweep.json').write_text(json.dumps(dict(status='running',cases=cases),indent=2))
try:
    r.execute('global TCFarLayer,TCFarPlane;if TCFarLayer!=undefined do WFRoot.layerEnabled[findItem WFRoot.layerObjects TCFarLayer]=false;WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()')
    sweep('local-only')
    r.execute('''(global TCFarLayer,TCFarPlane
    if TCFarLayer==undefined do (
    TCFarPlane=plane name:"BENCH | distant receiver" length:30000 width:30000 lengthsegs:1 widthsegs:1 pos:[100000,100000,0]
    TCFarPlane.isHidden=true;TCFarPlane.renderable=false
    WFRoot.newLayer();TCFarLayer=WFRoot.selectedLayer()
    AminScatterCopyLayer WFRoot.layerObjects[3] TCFarLayer variation:#same
    WFRoot.layerNames[WFRoot.activeLayer]="BENCH | distant trees"
    )
    WFRoot.setLayerSurfaces TCFarLayer #(TCFarPlane);TCFarLayer.procLayerSelfEnabled=false
    TCFarLayer.paintEnabled=false;TCFarLayer.paintAreas=#()
    WFRoot.layerEnabled[findItem WFRoot.layerObjects TCFarLayer]=true
    )''')
    for amount in (1000,10000):
        r.TCFarLayer.amount=amount;r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
        assert int(r.TCFarLayer.generatedCount)==amount,(amount,int(r.TCFarLayer.generatedCount),str(r.TCFarLayer.previewError))
        sweep('distant-'+str(amount))
    r.saveMaxFile(str(out.parent/'Contact_Distant_10000_Stress.max'),quiet=True)
    r.WFRoot.layerEnabled[-1]=False;r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
    r.execute('global TCSecondStone=copy DGStone;TCSecondStone.name="BENCH | second collider";TCSecondStone.pos+=[70,40,-20];WFRoot.interactionSceneColliders=#(DGStone,TCSecondStone)')
    r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();sweep('two-colliders')
    r.execute('WFRoot.interactionSceneColliders=#(DGStone);delete TCSecondStone')
    r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
    result=dict(status='complete',cases=cases)
except Exception:result=dict(status='failed',error=traceback.format_exc(),cases=cases)
(out/'locality-sweep.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
