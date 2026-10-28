"""Reopen a saved trial copy and verify its stored tree/plant interaction setup."""
from pathlib import Path
import json, traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));root_dir=Path(__file__).resolve().parents[3]
report={'status':'running'}
try:
    trial=root_dir/'build/interactions08741-20261027-01/candidate-host-06/Small_Tree_Interaction_0.87.4.1.max'
    assert trial.is_file() and r.loadMaxFile(str(trial),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    root=owner.baseObject;layers=list(root.layerObjects);trees=layers[4]
    assert len(trees.validSources())==2 and len(trees.interactionProxyNodes)==2
    assert all(r.isValidNode(trees.interactionsProxy(source)) for source in trees.validSources())
    r.CyrusPointSync();r.completeRedraw();root.interactionsEnsure()
    stats=json.loads(str(root.interactionsStatistics()))
    assert not str(root.interactionError) and not stats.get('error') and stats['plants']==3650 and stats['obstacles']==2,stats
    report={'status':'pass','scene':str(trial),'version':str(root.uiVersion()),'schema':int(root.version),
            'tree_sources':[str(x.name) for x in trees.validSources()],
            'proxy_nodes':[str(trees.interactionsProxy(x).name) for x in trees.validSources()],
            'statistics':stats,'scope':'Owned saved-copy reopen; visual/renderer acceptance is separate'}
except Exception:
    report={'status':'failed','error':traceback.format_exc()}
(host/'tree-reopen.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
