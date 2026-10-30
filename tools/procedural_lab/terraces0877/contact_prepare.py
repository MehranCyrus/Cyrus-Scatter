from pathlib import Path
import json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));root=Path(__file__).resolve().parents[3]
try:
    r.execute('''WFRoot.updateMode=2;WFRoot.autoRender=false
    for leaf in WFRoot.layerObjects do (leaf.interactionCollider=false;leaf.interactionReact=false)
    WFRoot.layerEnabled=#(false,false,true,false,false)
    WFRoot.layerObjects[3].interactionReact=true
    WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
    ''')
    r.fileIn(str(root/'tools/procedural_lab/drag08756/scene_stone.ms'))
    r.execute('''WFRoot.layerObjects[3].interactionsResponseSetting #interactionResponse 1
    WFRoot.layerObjects[3].interactionsResponseSetting #interactionTrunkBend 0.2
    WFRoot.layerObjects[3].interactionsResponseSetting #interactionFixedBase 0.3
    WFRoot.layerObjects[3].interactionsResponseSetting #interactionBendTransition 0.3
    WFRoot.layerObjects[3].interactionsResponseSetting #interactionCoverRoots false
    viewport.setLayout #layout_1;viewport.setType #view_persp_user;clearSelection()
    WFRoot.interactionsEnsure();CyrusPointSync();completeRedraw()''')
    r.saveMaxFile(str(out.parent/'Contact_Real_Tree_Fixture.max'),quiet=True)
    report=dict(status='complete',stats=json.loads(str(r.WFRoot.interactionsStatistics())))
except Exception:report=dict(status='failed',error=traceback.format_exc())
(out/'contact-prepare.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
