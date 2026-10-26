"""Validate mounted Advanced controls and save the owned artist trial."""
from pathlib import Path
import hashlib,json,traceback
from pymxs import runtime as r

O=Path(str(r.GardenRun));ROOT=Path(__file__).resolve().parents[3];report={}
try:
    root=r.E873Root;owner=r.E873Owner
    root.selectLayer(1);r.select(owner);r.execute('max modify mode;modPanel.setCurrentObject E873Root')
    r.windows.processPostedMessages();panel=root.mainUI;assert len(panel.editors)==13;section=panel.editors[12]
    panel.slots[12].open=True;panel.bindSection(section);section.advancedToggle.checked=True;section.layout()
    report['controls']=[]
    for name,value in [('verticesLimitSpin',3000000),('trianglesLimitSpin',6000000),('partsLimitSpin',100000),('guidesLimitSpin',12000),('previewLimitSpin',500000),('memoryLimitSpin',4096),('workLimitSpin',256)]:
        control=r.getProperty(section,r.Name('interactionsUI_'+name));assert bool(control.visible);assert int(control.value)==value
        report['controls'].append({'name':name,'value':int(control.value),'visible':True})
    report['connection_visible']=bool(section.interactionsUI_connectionSpin.visible);assert report['connection_visible']
    report['statistics']=json.loads(str(root.interactionsStatistics()));assert not report['statistics']['error']
    report['preview_errors']=[str(l.previewError) for l in root.layerObjects];assert not any(report['preview_errors'])
    report['audit']=json.loads(str(r.cyrusInteractionValidate(root.interactionState,2000000)[2]));assert report['audit']['passed']
    root.selectLayer(2);r.execute('select E873Owner;max modify mode;modPanel.setCurrentObject E873Edit;subObjectLevel=1;max move;cyrusEditActiveLayers E873Edit #(E873Collider.editLayerKey);cyrusEditSelect E873Edit #(1)')
    trial=ROOT/'dist/CyrusScatter-0.87.3-20261026-interactions-r4/Trials/New_Plants_Interaction_0.87.3.max'
    r.saveMaxFile(str(trial),quiet=True);report['trial']=str(trial);report['trial_sha256']=hashlib.sha256(trial.read_bytes()).hexdigest()
    report['materials']='Opaque diagnostic Standard materials on the trial grass and sphere only; original input preserved. Original Corona material presentation is not qualified.'
    report['physical_drag']='Not qualified: Computer Use returned pixels from an unrelated foreground app; those captures were excluded and no pointer action was sent.'
    report['status']='pass'
except Exception:report['failure']=traceback.format_exc()
(O/'finished-trial.json').write_text(json.dumps(report,indent=2))
