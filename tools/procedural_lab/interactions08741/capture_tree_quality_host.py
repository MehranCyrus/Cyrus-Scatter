"""Capture one independently audited tree-proxy quality failure for replay."""
from pathlib import Path
import hashlib, json, traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));out=host/'tree-quality-replay';out.mkdir(parents=True,exist_ok=False)
try:
    root=r.TSRoot
    report=json.loads((host/'small-tree-scenarios.json').read_text(encoding='utf-8'))
    failures=[x for x in report['full_mesh_audit']['results'] if x['maximum_stem_edge_change']>.25]
    assert len(failures)==1
    target=failures[0];target_id=target['identity'];target_layer=int(target['layer'])-1
    fixture={'metres_per_unit':1/float(r.units.decodeValue('1m')),'layers':[],'instances':[],'audit':True,
             'scope':'Single quality failure and all tree colliders captured from a real 3650-plant scene',
             'max_host_audit':target,'source_layer_names':[]}
    for li,item in enumerate(root.procPublishedOwners):
        role=(1 if item.interactionCollider else 0)+(2 if item.interactionReact else 0)
        sources=[];fixture['source_layer_names'].append([str(node.name) for node in root.procPublishedSources[li]])
        if role and (role==1 or li==target_layer):
            values=item.interactionsSources(root.procPublishedSources[li],role)
            for si,node in enumerate(root.procPublishedSources[li]):
                mesh=out/f'source-{li}-{si}.bin';r.cyrusInteractionSourceSnapshot(values[si],str(mesh))
                entry={'kind':'plant' if role==2 else 'collider','mesh':str(mesh),'sha256':hashlib.sha256(mesh.read_bytes()).hexdigest(),'node_name':str(node.name)}
                if role==2:
                    slot=list(str(x) for x in item.interactionSourceIDs).index(str(item.sourceRowIDs[si]))
                    definition=out/f'definition-{li}-{si}.json';definition.write_text(str(item.interactionDefinitions[slot]),encoding='utf-8')
                    entry.update(definition=str(definition),definition_sha256=hashlib.sha256(definition.read_bytes()).hexdigest())
                sources.append(entry)
        else:
            role=0
        fixture['layers'].append({'role':role,'cover':bool(item.interactionCoverRoots),'gap':float(item.interactionGapWU)*fixture['metres_per_unit'],'stiffness':float(item.interactionStiffness),'sources':sources})
        if role:
            rows=root.groupSnapshotRows[li] if role==2 else r.cyrusInteractionRows(root.interactionState,li+1)
            token,count=r.cyrusPlacementToken(rows),int(r.getProperty(rows,r.Name('count')))
            for placement in r.cyrusPlacementPage(rows,token,0,count):
                if role==2 and str(placement[2])!=target_id:continue
                tm=placement[0];fixture['instances'].append({'layer':li,'source':int(placement[1])-1,'identity':str(placement[2]),
                    'transform':[float(x) for v in [tm.row1,tm.row2,tm.row3,tm.row4] for x in v]})
    assert sum(x['layer']==target_layer for x in fixture['instances'])==1
    (out/'fixture.json').write_text(json.dumps(fixture,indent=2),encoding='utf-8')
    trial=host/'Small_Tree_Interaction_0.87.4.1.max'
    assert r.saveMaxFile(str(trial),quiet=True)
    (out/'capture.json').write_text(json.dumps({'status':'complete','fixture':str(out/'fixture.json'),'saved_scene':str(trial)},indent=2),encoding='utf-8')
except Exception:
    (out/'capture-error.txt').write_text(traceback.format_exc(),encoding='utf-8');raise
