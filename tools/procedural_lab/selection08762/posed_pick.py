"""Compare retained posed viewport hits with independently baked CPU triangles.

Owned in-memory garden only; disposable bake nodes are always removed.
"""
from pathlib import Path
from pymxs import runtime as r
import json, time, traceback

out=Path(str(r.GardenRun)); data={}; baked=[]
try:
    r.CyrusSelectionTimer.Stop()
    r.loadDllsFromDir(str(out.parent/'probe')+'/', 'MeshProbe.dlx')
    node=r.getNodeByName('GARDEN | Lakeside boulders',exact=True); root=node.baseObject
    root.identificationMode=1; root.setGroupDisplay(3); root.viewportFaces=0; root.viewportNavigationFaces=0
    root.refreshDisplay(); root.interactionsEnsure()
    for _ in range(12):
        r.CyrusPointSync(); r.redrawViews(); r.windows.processPostedMessages(); time.sleep(.03)
    data['contact']=json.loads(str(root.interactionsStatistics()))
    data['layers']=[dict(index=i+1,name=str(root.layerNames[i]),react=bool(l.interactionReact),collider=bool(l.interactionCollider),count=int(l.generatedCount)) for i,l in enumerate(root.layerObjects)]
    plant_layer=next(i for i,l in enumerate(root.layerObjects) if l.interactionReact)
    edit=next(m for m in node.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    r.cyrusEditActiveLayers(edit,r.Array(root.layerObjects[plant_layer].editLayerKey))
    rows=r.cyrusEditInspect(edit,0,500)[3]
    grass_ids={(int(row[14]),str(row[4])) for row in rows if row[6]}
    # Bake contains only accepted poses, whereas the viewport also shares the
    # untouched source instances. Exclude those identities from this comparison.
    rest=r.cyrusInteractionRows(root.interactionState,plant_layer+1)
    rest_rows=r.cyrusPlacementPage(rest,r.cyrusPlacementToken(rest),0,int(rest.count))
    rest_ids={str(row[2]) for row in rest_rows}
    data['unposed_instances']=len(rest_ids)
    baked=list(r.cyrusInteractionBake(root.interactionState,plant_layer+1))
    assert baked, 'No accepted prepared geometry'
    r.select(r.Array(*baked)); r.viewport.setType(r.Name('view_top')); r.execute('max zoomext sel; clearSelection()')
    meshes=[r.snapshotAsMesh(n) for n in baked]
    data['baked_faces']=sum(int(r.getNumFaces(m)) for m in meshes)
    for n in baked:n.isHidden=True
    for _ in range(5):r.redrawViews();r.windows.processPostedMessages()
    before=(int(root.procEpoch),list(r.cyrusRetainedStreamStats()))
    points=[]
    for mesh in meshes:
        count=int(r.getNumFaces(mesh))
        for f in range(1,count+1,max(1,count//180)):
            face=r.getFace(mesh,f)
            p=(r.getVert(mesh,int(face.x))+r.getVert(mesh,int(face.y))+r.getVert(mesh,int(face.z)))/3
            r.gw.setTransform(r.Matrix3(1));s=r.gw.wTransPoint(p)
            points.append((int(s.x),int(s.y)))
    samples=[]
    for x,y in dict.fromkeys(points):
        hit=r.cyrusViewportPickAt(node,x,y)
        if hit is None or (int(hit[0]),str(hit[1])) not in grass_ids or str(hit[1]) in rest_ids:continue
        ray=r.mapScreenToWorldRay(r.Point2(x,y))
        refs=[r.selectionProbeMesh(n,x,y) for n in baked]
        refs=[v for v in refs if v is not None]
        assert refs, 'Posed pick hit geometry absent from CPU bake'
        closest=min(refs,key=lambda v:r.distance(ray.pos,v))
        error=float(r.distance(hit[3],closest))
        samples.append(dict(pixel=[x,y],identity=str(hit[1]),error_world_units=error,hit=str(hit[3]),reference=str(closest)))
        data['samples']=samples
        assert error<.25, f'Posed hit differs from CPU triangles by {error}'
    assert len(samples)>=8, f'Only {len(samples)} prepared hits'
    data['samples']=samples;data['max_error_world_units']=max(s['error_world_units'] for s in samples)
    data['unchanged_epoch_streams']=before==(int(root.procEpoch),list(r.cyrusRetainedStreamStats()))
    assert data['unchanged_epoch_streams']
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
finally:
    for n in baked:
        if r.isValidNode(n):r.delete(n)
    (out/'posed-pick.json').write_text(json.dumps(data,indent=2))
