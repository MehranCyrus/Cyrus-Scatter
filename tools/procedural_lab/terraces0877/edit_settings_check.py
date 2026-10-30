from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    def ready():
        until=time.monotonic()+20
        while time.monotonic()<until:
            r.CyrusPointSync();r.completeRedraw();r.windows.processPostedMessages();time.sleep(.03)
            state=r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.WFOwner))
            if int(state[3])==2:return str(state)
        raise RuntimeError(str(state))
    r.execute('''(WFRoot.interactionSceneColliders=#();DGStone.isHidden=true
      WFRoot.layerEnabled[2]=true;WFCollider.interactionCollider=true
      WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync())''')
    ready()
    r.execute('cyrusEditActiveLayers WFEdit #(WFCollider.editLayerKey);cyrusEditCommand WFEdit 1 undefined;cyrusEditCommand WFEdit 4 (transMatrix [4,0,0]);WFRoot.interactionsEnsure();CyrusPointSync()')
    ready()
    for label,value in [('scale',3.2),('restore',3.)]:
        r.WFCollider.sourceScales=r.Array(value);r.WFCollider.markInputDirty();r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
        data[label]=dict(frame=ready(),stats=json.loads(str(r.WFRoot.interactionsStatistics())),errors=[str(l.previewError) for l in r.WFRoot.layerObjects])
        assert not any(data[label]['errors'])
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'edit-settings-check.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
