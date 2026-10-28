"""Reproduce an artist choosing the sphere as a reacting plant, on separate UI ticks."""
from pathlib import Path
import json, time, traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun)); phase=int(r.CVCaptureDirection)
path=host/'wrong-source-recovery.json'
report={'status':'running'} if phase==1 else json.loads(path.read_text(encoding='utf-8'))
try:
    root,collider=r.WFRoot,r.WFCollider
    if phase==1:
        r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
        panel=root.mainUI
        end=time.monotonic()+10
        while not bool(panel.controlsReady) and time.monotonic()<end:
            r.windows.processPostedMessages();time.sleep(.02)
        assert panel.controlsReady
        panel.selectLayerView(collider);panel=root.mainUI;panel.slots[12].open=True;panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12]
        r.execute('WFSection.interactionsUI_chooseColliderMode 2')
        assert int(collider.interactionColliderMode)==2
        report['status']='box_selected'
    elif phase==2:
        assert str(r.execute('(local n=WFSection.interactionsUI_currentSource();if isValidNode n then n.name else "undefined")'))==str(r.WFSphere.name)
        r.execute('WFSection.interactionsUI_chooseRole 3')
        r.execute('WFSection.interactionsUI_prepareButton.pressed()')
        report['message']=str(r.WFSection.interactionsUI_info.text)
        report['collider_reacts']=bool(collider.interactionReact)
        assert 'no reliable' in report['message'].lower(),report
        report['status']='expected_preparation_failure'
    else:
        raise ValueError('Use phases 1 and 2')
except Exception:
    report['status']='failed';report['error']=traceback.format_exc()
else:
    report.pop('error',None)
finally:
    path.write_text(json.dumps(report,indent=2),encoding='utf-8')
