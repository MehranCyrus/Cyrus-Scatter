"""Freeze the reported surface-only failure as copied numeric inputs."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun))/'fern-surface-regression';O.mkdir(exist_ok=False)
try:
    root=r.WFRoot;fixture={'metres_per_unit':1/float(r.units.decodeValue('1m')),'layers':[],'instances':[],'audit':True}
    for li,leaf in enumerate(root.procPublishedOwners):
        role=(1 if leaf.interactionCollider else 0)+(2 if leaf.interactionReact else 0);sources=[]
        values=leaf.interactionsSources(root.procPublishedSources[li],role)
        for si,node in enumerate(root.procPublishedSources[li]):
            if not role:continue
            mesh=O/f'source-{li}-{si}.bin';r.cyrusInteractionSourceSnapshot(values[si],str(mesh));entry={'kind':'plant' if role==2 else 'collider','mesh':str(mesh)}
            if role==2:
                slot=list(str(x) for x in leaf.interactionSourceIDs).index(str(leaf.sourceRowIDs[si]));definition=O/f'definition-{li}-{si}.json';definition.write_text(str(leaf.interactionDefinitions[slot]));entry['definition']=str(definition)
            sources.append(entry)
        fixture['layers'].append({'role':role,'cover':bool(leaf.interactionCoverRoots),'gap':float(leaf.interactionGapWU)*fixture['metres_per_unit'],'stiffness':float(leaf.interactionStiffness),'sources':sources})
        if role:
            # React rows omit plants displayed by separate posed render nodes.
            # This fixture never edits plant placements: retain their base rows,
            # while collider rows must include the actual Cyrus Edit transform.
            rows=root.groupSnapshotRows[li] if role==2 else r.cyrusInteractionRows(root.interactionState,li+1)
            token=r.cyrusPlacementToken(rows);count=int(r.getProperty(rows,r.Name('count')))
            for row in r.cyrusPlacementPage(rows,token,0,count):
                tm=row[0];fixture['instances'].append({'layer':li,'source':int(row[1])-1,'identity':str(row[2]),'transform':[float(x) for v in [tm.row1,tm.row2,tm.row3,tm.row4] for x in v]})
    (O/'fixture.json').write_text(json.dumps(fixture,indent=2))
except Exception:(O/'capture-error.txt').write_text(traceback.format_exc());raise
