from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
out=Path(str(r.GardenRun));data={}
try:
    assert (out/'Review_08763.max').is_file()
    r.loadMaxFile(str(out/'Review_08763.max'),quiet=True,useFileUnits=True)
    r.execute('''global RKOwner=getNodeByName "Review fixture" exact:true,RKRoot=RKOwner.baseObject
    global RKA=RKRoot.layerObjects[1],RKB=RKRoot.layerObjects[2],RKEdit
    for m in RKOwner.modifiers where classof m==CyrusScatterEdit do RKEdit=m
    RKRoot.interactionsEnsure();CyrusPointSync()
    ''')
    for _ in range(6):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.02)
    assert not str(r.RKRoot.interactionError),str(r.RKRoot.interactionError)
    r.execute('cyrusEditActiveLayers RKEdit #(RKB.editLayerKey);cyrusEditSelect RKEdit #(1)')
    row=next(x for x in r.cyrusEditInspect(r.RKEdit,0,500)[3] if x[7])
    data.update(status='moved',layer=int(row[0]),id=str(row[4]),before=[float(x) for x in row[12].row4],count=int(r.RKB.generatedCount),stats=json.loads(str(r.RKRoot.interactionsStatistics())))
    assert data['count']==500
    r.execute('undo "Review sparse Edit" on (cyrusEditCommand RKEdit 4 (transMatrix [.01,0,0]))')
    for _ in range(5):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.02)
    row=next(x for x in r.cyrusEditInspect(r.RKEdit,0,500)[3] if int(x[0])==data['layer'] and str(x[4])==data['id']);data['after']=[float(x) for x in row[12].row4]
    assert str(row[4])==data['id'] and abs(data['after'][0]-data['before'][0]-.01)<1e-6
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'persistence.json').write_text(json.dumps(data,indent=2))
