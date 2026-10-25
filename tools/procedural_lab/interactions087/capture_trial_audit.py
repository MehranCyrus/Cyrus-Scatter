"""Freeze the current post-Update trial as SI numeric inputs for an independent mesh audit."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun))/'final-trial-kernel';out.mkdir(exist_ok=False)
try:
    root=r.TRoot
    assert not str(root.interactionError)
    fixture={'metres_per_unit':1/float(r.units.decodeValue('1m')),'layers':[],'instances':[],'audit':True}
    meshes={}
    for li,leaf in enumerate(root.procPublishedOwners):
        role=(1 if leaf.interactionCollider else 0)+(2 if leaf.interactionReact else 0)
        assert not (role&1) or int(leaf.interactionColliderMode)==1
        sources=[]
        if role:
            for si,node in enumerate(root.procPublishedSources[li]):
                values=[entry[1] for entry in leaf.interactionSourceCache if entry[0]==node];assert len(values)==1
                key=(int(r.getHandleByAnim(node)),role)
                if key not in meshes:
                    path=out/f'source-{len(meshes)}.bin';r.cyrusInteractionSourceSnapshot(values[0],str(path));meshes[key]=path
                item={'kind':'plant' if role&2 else 'collider','mesh':str(meshes[key])}
                if role&2:
                    slot=list(str(x) for x in leaf.interactionSourceIDs).index(str(leaf.sourceRowIDs[si]))
                    definition=out/f'accepted-{li}-{si}.json';definition.write_text(str(leaf.interactionDefinitions[slot]));item['definition']=str(definition)
                sources.append(item)
        fixture['layers'].append({'role':role,'cover':bool(leaf.interactionCoverRoots),'gap':float(leaf.interactionGapWU)*fixture['metres_per_unit'],'stiffness':float(leaf.interactionStiffness),'sources':sources})
        if role:
            rows=root.groupSnapshotRows[li];token=r.cyrusPlacementToken(rows);count=int(r.getProperty(rows,r.Name('count')))
            for first in range(0,count,500):
                for row in r.cyrusPlacementPage(rows,token,first,min(500,count-first)):
                    tm=row[0];fixture['instances'].append({'layer':li,'source':int(row[1])-1,'identity':str(row[2]),'transform':[float(x) for v in [tm.row1,tm.row2,tm.row3,tm.row4] for x in v]})
    (out/'fixture.json').write_text(json.dumps(fixture))
    (out/'host-statistics.json').write_text(str(root.interactionsStatistics()))
except Exception:(out/'capture-error.txt').write_text(traceback.format_exc());raise
