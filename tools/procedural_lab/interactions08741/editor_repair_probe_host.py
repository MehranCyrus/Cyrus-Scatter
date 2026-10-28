"""Inspect the reported trunk/leaves source in a separately owned 2027 host."""
from pathlib import Path
import json, time, traceback
from pymxs import runtime as r

host = Path(str(r.GardenRun))
report = {'status': 'running'}
try:
    node = r.getNodeByName('Outdoor_Plants_01_Neottopteris_Nidus_Bush05_001')
    assert node != r.undefined
    root, leaf = r.WFRoot, r.WFGrass
    root.updateMode = 1
    leaf.interactionReact = False
    r.WFCollider.interactionCollider = False
    leaf.removeModelSources(r.Array(*range(1, len(leaf.sources)+1)))
    leaf.addModelSource(node)
    leaf.amount = 1
    leaf.interactionMinimumM = .05
    leaf.interactionConnectionM = .001
    leaf.interactionFoliage = .05
    leaf.markInputDirty()
    root.refreshAll()
    report['node'] = str(node.name)
    report['settings'] = list(leaf.interactionsSettings())[:3]
    r.ERNode = node
    r.execute('global ERSource=cyrusInteractionSource ERNode undefined (WFGrass.interactionsSettings()) 1')
    report['analysis'] = json.loads(str(r.cyrusInteractionSourceInfo(r.ERSource)))
    snapshot = host/'reported-plant.bin'
    if not snapshot.exists():
        r.cyrusInteractionSourceSnapshot(r.ERSource, str(snapshot))
    report['snapshot'] = str(snapshot)
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    end = time.monotonic()+6
    while not bool(root.mainUI.controlsReady) and time.monotonic()<end:
        r.windows.processPostedMessages();time.sleep(.02)
    panel = root.mainUI
    panel.selectLayerView(leaf)
    panel = root.mainUI
    panel.slots[12].open = True
    panel.bindSection(panel.editors[12])
    r.WFSection = panel.editors[12]
    r.execute('WFSection.interactionsUI_editorButton.pressed()')
    end = time.monotonic()+8
    while time.monotonic()<end:
        r.windows.processPostedMessages();time.sleep(.02)
    report['editor'] = json.loads(str(r.cyrusPreparationEditorInfo()))
    report['status'] = 'captured'
except Exception:
    report.update(status='failed',error=traceback.format_exc())
(host/'editor-repair-probe.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
