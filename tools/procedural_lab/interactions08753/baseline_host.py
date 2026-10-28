"""Record the reported pre-fix paths using the matched 0.87.5.2 payload."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));report={}
def error(fn):
    try:fn();return ''
    except Exception as e:return str(e)
try:
    root=r.WFRoot;root.interactionsEnsure();r.CyrusPointSync()
    rows=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[1])[0];stone=r.WFCollider.validSources()[0]
    report['scale']={'source_node':[float(x) for x in stone.scale],'model_multiplier':float(r.WFCollider.sourceScale(1)),
                     'placed_axis_magnitude':float(r.length(rows[0].row1)),'source_triangles':int(r.getNumFaces(stone.mesh)),
                     'plant_triangles':int(r.getNumFaces(r.WFGrass.validSources()[0].mesh))}
    report['render_nodes_error']=error(lambda:r.cyrusInteractionRenderNodes(root.interactionState,r.Array()))
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    for _ in range(30):r.windows.processPostedMessages();time.sleep(.02)
    panel=root.mainUI;panel.selectLayerView(r.WFCollider);root.modelsUISlot.open=True;root.interactionsUISlot.open=True
    panel.bindSection(root.modelsUI);panel.bindSection(root.interactionsUI);r.AuditModels=root.modelsUI;r.AuditInteractions=root.interactionsUI
    report['before_items']=list(map(str,r.AuditInteractions.interactionsUI_modelList.items))
    root.updateMode=1;r.execute('AuditModels.sourceUI_plantList.selection=#{1};AuditModels.sourceUI_removePlant.pressed()')
    for _ in range(10):r.windows.processPostedMessages();time.sleep(.02)
    report['after_remove']={'authored_sources':len(r.WFCollider.sources),
        'interaction_items':list(map(str,r.AuditInteractions.interactionsUI_modelList.items)),
        'interaction_remove_enabled':bool(r.AuditInteractions.interactionsUI_sourceRemoveButton.enabled)}
    report['ensure_after_remove_error']=error(lambda:root.interactionsEnsure())
    report['status']='recorded'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(out/'baseline-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
