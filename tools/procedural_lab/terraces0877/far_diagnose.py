from pathlib import Path
import json
from pymxs import runtime as r
out=Path(str(r.GardenRun))
r.execute('WFRoot.layerEnabled[WFRoot.layerObjects.count]=true;TCFarLayer.amount=1000;WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()')
leaf=r.TCFarLayer
data=dict(accepted=int(leaf.generatedCount),error=str(leaf.previewError),stats=str(leaf.procStatistics()),props={})
for p in r.getPropNames(leaf):
    if any(k in str(p).lower() for k in ['area','paint','mask','density','slope','altitude','placementmode','distribution','sourceweights','sourcepoint','sourceempty','populat']):
        try:data['props'][str(p)]=str(r.getProperty(leaf,p))[:250]
        except Exception:pass
(out/'far-diagnose.json').write_text(json.dumps(data,indent=2))
