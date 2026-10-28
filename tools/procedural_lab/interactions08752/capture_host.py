"""Capture copied numeric source/pose inputs only from the owned 0.87.5 host."""
from pathlib import Path
import hashlib,json
from pymxs import runtime as r
host=Path(str(r.GardenRun));phase=str(r.CVProfileCase);out=host/'numeric'/phase;out.mkdir(parents=True,exist_ok=False)
root=r.WFRoot;unit=1/float(r.units.decodeValue('1m'))
fixture={'metres_per_unit':unit,'layers':[],'instances':[],'compact_audit':True,'compact_export':str(out/'gpu-probe.bin'),'audit':True}
for li,item in enumerate(root.procPublishedOwners):
    role=(1 if item.interactionCollider else 0)+(2 if item.interactionReact else 0);sources=[]
    values=item.interactionsSources(root.procPublishedSources[li],role)
    for si,node in enumerate(root.procPublishedSources[li]):
        if not role:continue
        mesh=out/f'source-{li}-{si}.bin';r.cyrusInteractionSourceSnapshot(values[si],str(mesh));entry={'kind':'plant' if role==2 else 'collider','mesh':str(mesh),'sha256':hashlib.sha256(mesh.read_bytes()).hexdigest(),'node_name':str(node.name)}
        if role==2:
            entry['preparation_limits']=[int(v) for v in item.interactionsLimits()]
            slot=list(str(x) for x in item.interactionSourceIDs).index(str(item.sourceRowIDs[si]));saved=out/f'definition-{li}-{si}.json';saved.write_text(str(item.interactionDefinitions[slot]),encoding='utf-8');entry['definition']=str(saved)
        sources.append(entry)
    fixture['layers'].append({'role':role,'cover':bool(item.interactionCoverRoots),'gap':float(item.interactionGapWU)*unit,'stiffness':float(item.interactionStiffness),'hide_margin':float(item.interactionHideMarginWU)*unit,'hide_under':int(item.interactionHideArea)==2,'sources':sources})
    if role:
        rows=root.groupSnapshotRows[li] if role==2 else r.cyrusInteractionRows(root.interactionState,li+1);token=r.cyrusPlacementToken(rows);count=int(r.getProperty(rows,r.Name('count')))
        for placement in [p for start in range(0,count,500) for p in r.cyrusPlacementPage(rows,token,start,min(500,count-start))]:
            tm=placement[0];fixture['instances'].append({'layer':li,'source':int(placement[1])-1,'identity':str(placement[2]),'transform':[float(x) for v in [tm.row1,tm.row2,tm.row3,tm.row4] for x in v]})
(out/'fixture.json').write_text(json.dumps(fixture,indent=2),encoding='utf-8')
