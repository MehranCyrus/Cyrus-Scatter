"""Separate generated source-button actions, including canonical row Undo/Redo."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));path=O/'source-controls.json';phase=int(r.WFSourcePhase)
report={'checks':[]} if phase==0 else json.loads(path.read_text())
def check(name,test):assert test,name;report['checks'].append(name)
def ids(leaf):return [str(x) for x in leaf.sourceRowIDs]
try:
    root=r.WFRoot;leaf=r.WFGrass
    # Undo/Redo readbacks must be read-only. Reassigning updateMode or binding
    # authored view selection between Undo and Redo can clear Max's redo stack.
    if phase<4:
        root.updateMode=1
        if phase==0 and len(leaf.sources)>1:
            leaf.removeModelSources(r.Array(*range(2,len(leaf.sources)+1)));root.refreshAll();r.CyrusPointSync()
        r.execute('subObjectLevel=0;select WFOwner;modPanel.setCurrentObject WFRoot')
        until=time.monotonic()+3
        while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
        panel=root.mainUI;panel.selectLayerView(leaf);panel.slots[12].open=True;panel.slots[2].open=True
        panel.bindSection(panel.editors[2]);panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12]
    if phase==0:
        r.execute('global WFExtraSource');r.WFExtraSource=r.copy(leaf.validSources()[0]);r.WFExtraSource.name='08732 source button fixture';r.hide(r.WFExtraSource)
        report['original_ids']=ids(leaf);report['epoch']=int(root.procEpoch)
        check('Technical admission remains folded',str(r.WFSection.advancedToggle.text)=='Preparation limits' and not bool(r.WFSection.advancedToggle.checked))
        check('Everyday preparation settings are visible',all(bool(r.getProperty(r.WFSection,r.Name('interactionsUI_'+n)).visible) for n in ['minimumSpin','stiffnessSpin','connectionSpin']))
    elif phase==1:
        r.execute('WFSection.interactionsUI_sourcePickButton.picked WFExtraSource')
        report['added_ids']=ids(leaf)
        check('Plus enrolls the original model in the same layer',len(leaf.sources)==2 and leaf.sources[1]==r.WFExtraSource and len(report['added_ids'])==2)
        check('Models and Interactions show the same two rows',len(r.WFSection.interactionsUI_modelList.items)==2 and len(panel.editors[2].sourceUI_plantList.items)==2)
        check('Plus preserves Manual pending placements',int(root.procEpoch)==report['epoch'] and int(leaf.generatedCount)==50)
    elif phase==2:
        r.execute('WFSection.interactionsUI_sourcePickButton.picked WFExtraSource')
        check('Picking an enrolled source does not duplicate it',ids(leaf)==report['added_ids'])
    elif phase==3:
        r.WFSection.interactionsUI_modelList.selection=2;r.execute('WFSection.interactionsUI_sourceRemoveButton.pressed()')
        check('Remove unregisters the row and keeps its scene object',ids(leaf)==report['original_ids'] and bool(r.isValidNode(r.WFExtraSource)))
        check('Both source views refresh after removal',len(r.WFSection.interactionsUI_modelList.items)==1 and len(panel.editors[2].sourceUI_plantList.items)==1)
    elif phase==4:
        check('Undo restores the exact stable row identity',ids(leaf)==report['added_ids'] and bool(r.isValidNode(r.WFExtraSource)))
    elif phase==5:
        check('Redo removes only the row again',ids(leaf)==report['original_ids'] and bool(r.isValidNode(r.WFExtraSource)))
        report['status']='pass'
except Exception:report['error']=traceback.format_exc()
path.write_text(json.dumps(report,indent=2),encoding='utf-8')
