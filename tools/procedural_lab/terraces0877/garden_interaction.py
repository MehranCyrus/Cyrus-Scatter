from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    node=r.getNodeByName('GARDEN | Lakeside boulders',exact=True);root=node.baseObject
    source=next(n for n in r.GardenSources if ' | A069 | ' in str(n.name))
    pockets=[n for n in r.objects if str(n.name).startswith('GARDEN receiver | boulder pocket')]
    for layer in root.layerObjects:layer.interactionCollider=True
    root.newLayer();leaf=root.selectedLayer();root.layerNames[-1]='Interactive grass at the boulders'
    leaf.addModelSource(source);leaf.sourceScales=r.Array(6.);leaf.amount=160;leaf.randomSeed=8761
    leaf.scaleMinimum=.8;leaf.scaleMaximum=1.15;leaf.interactionFoliage=1.;leaf.interactionMinimumM=.005
    leaf.interactionBendStrength=.8;leaf.interactionFixedBase=.12;leaf.interactionResponse=3
    leaf.interactionCoverRoots=True;leaf.interactionGapWU=0.;leaf.interactionHideMarginWU=0.
    leaf.interactionPruneAmount=.35;leaf.interactionConnectionM=.01
    root.setLayerSurfaces(leaf,r.Array(*pockets));leaf.autoRender=True
    start=time.perf_counter();leaf.interactionsPrepare(r.Array(source));data['prepare_seconds']=time.perf_counter()-start
    root.updateMode=2;root.refreshAll();root.interactionsEnsure();r.CyrusPointSync()
    for _ in range(15):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
    data['stats']=json.loads(str(root.interactionsStatistics()))
    data['errors']=[str(l.previewError) for l in root.layerObjects];assert not any(data['errors'])
    edit=r.CyrusScatterEdit();r.addModifier(node,edit)
    r.execute('global TCGardenColliderNode,TCGardenColliderRoot,TCGardenEdit,TCGardenGrass')
    r.TCGardenColliderNode=node;r.TCGardenColliderRoot=root;r.TCGardenEdit=edit;r.TCGardenGrass=leaf
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Interactive_08761.max'),quiet=True)
    r.CyrusPointSync();data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-interaction.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
