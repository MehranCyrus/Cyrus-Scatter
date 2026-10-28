"""Record procedural constraints relevant to an edited terrace collider."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
host=Path(str(r.GardenRun));report={}
try:
    root=r.TRoot
    rows=[]
    for i,leaf in enumerate(root.layerObjects):
        parent=root.logicalParent(leaf)
        rows.append({'index':i+1,'name':str(root.layerNames[i]),'enabled':bool(root.enabledLayer(i+1)),
                     'collider':bool(parent.interactionCollider),'react':bool(parent.interactionReact),
                     'self_rule':[str(x) for x in leaf.procSelfRule()],
                     'sibling_enabled':bool(parent.procSiblingEnabled),'cleanup':bool(parent.finalCleanup),'relax':bool(parent.finalRelax),
                     'base_relax':bool(leaf.relaxEnabled),'slope_filter':bool(leaf.slopeEnabled),'altitude_filter':bool(leaf.altitudeEnabled),
                     'repair':bool(parent.procRepair),'placement_mode':int(parent.placementMode),
                     'accepted_target':int(parent.procPopulation)==2,'source_policy_overrides':len(leaf.clearanceSourceIDs),
                     'source_copies':[int(x) for x in leaf.clearanceCopies],
                     'source_others':[int(x) for x in leaf.clearanceOthers],
                     'source_external':[int(x) for x in leaf.clearanceExternal]})
    report={'status':'complete','update_mode':int(root.updateMode),'pair_rules':[bool(x) for x in root.procRuleEnabled],
            'layers':rows,'scope':'Authored procedural controls; does not prove a transform is safe to omit from placement invalidation'}
except Exception:
    report={'status':'failed','error':traceback.format_exc()}
(host/'terrace-dependencies.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
