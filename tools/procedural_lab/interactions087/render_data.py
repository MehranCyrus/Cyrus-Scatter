"""Bounded UV/material and actual native Bake delivery witnesses."""
from pathlib import Path
import json,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];OUT=Path(str(r.GardenRun))
try:
    with pymxs.undo(False):
        source=r.IGrass.sources[0]
        material=r.MultiMaterial(numsubs=3)
        for i,color in enumerate([(60,150,40),(210,70,90),(130,100,190)]):material.materialList[i]=r.standardMaterial(diffuse=r.color(*color),twoSided=True)
        source.material=material
        for face in range(1,int(r.getNumFaces(source))+1):r.setFaceMatID(source,face,1+(face%3))
        r.update(source);r.IGrass.interactionsAnalyze(source);r.IGrass.interactionsAccept();r.IRoot.refreshAll();r.CyrusPointSync()
        r.execute('ISettle 300')
        # Place a small collider at a genuinely leaning blade tip. A random
        # sparse layout can validly contain only covered roots and no bent mesh.
        definition=json.loads(str(r.IGrass.interactionDefinitions[0]))['source']['metadata']
        guide=max(definition['guides'],key=lambda g:(g['nodes'][-1][0]-g['nodes'][0][0])**2+(g['nodes'][-1][2]-g['nodes'][0][2])**2)
        tip=guide['nodes'][-1];unit=float(r.units.decodeValue('1m'))
        rows=r.IRoot.groupSnapshotRows[0];page=r.cyrusPlacementPage(rows,r.cyrusPlacementToken(rows),0,1);frame=page[0][0]
        target=r.Point3(tip[0]*unit,-tip[2]*unit,tip[1]*unit)*frame
        r.cyrusEditActiveLayers(r.IEdit,r.Array(r.IRocks.editLayerKey));r.cyrusEditSelect(r.IEdit,r.Array(1))
        r.cyrusEditTransform(r.IEdit,2,r.Point3(.1,.1,.1),r.Matrix3(1),True);r.execute('ISettle 150')
        origin=r.cyrusEditHandleMatrix(r.IEdit,r.IRocks.editLayerKey,1).translation
        r.cyrusEditTransform(r.IEdit,0,target-origin,r.Matrix3(1),False);r.execute('ISettle 150')
        info=json.loads(str(r.IRoot.interactionsStatistics()));assert info['posed']>0 and not info['error'],info
        nodes=list(r.cyrusInteractionBake(r.IRoot.interactionState,1));assert nodes,'The fixture must contain posed visible grass.'
        assert len(nodes)==1
        baked=nodes[0];assert r.getHandleByAnim(baked.material)==r.getHandleByAnim(material)
        source_ids={int(r.getFaceMatID(source,i)) for i in range(1,int(r.getNumFaces(source))+1)}
        delivered_ids={int(r.getFaceMatID(baked,i)) for i in range(1,int(r.getNumFaces(baked))+1)}
        assert delivered_ids==source_ids=={1,2,3}
        channels=[]
        for channel in range(1,5):
            if not r.meshop.getMapSupport(source,channel):continue
            assert r.meshop.getMapSupport(baked,channel)
            original={tuple(float(x) for x in r.meshop.getMapVert(source,channel,i)) for i in range(1,int(r.meshop.getNumMapVerts(source,channel))+1)}
            actual={tuple(float(x) for x in r.meshop.getMapVert(baked,channel,i)) for i in range(1,int(r.meshop.getNumMapVerts(baked,channel))+1)}
            assert actual.issubset(original),(channel,len(actual-original));channels.append(channel)
        assert channels,'The actual library source must supply at least one UV channel.'
        r.cvsInspect(baked,str(OUT/'delivered-grass'))
        baked.renderable=False;r.hide(baked)
        namespace={'__file__':str(ROOT/'tools/procedural_lab/interactions087/terraces.py')};text=Path(namespace['__file__']).read_text();exec(text[:text.rindex('try:\n')],namespace)
        namespace['capture_fixture'](r.IRoot,{'grass':r.IGrass,'rock':r.IRocks},{'grass':source,'rock':r.IRocks.sources[0]},'delivery')
        path=OUT/'delivery-kernel/fixture.json';fixture=json.loads(path.read_text());fixture['delivery_mesh']=str(OUT/'delivered-grass.bin')
        rows=r.cyrusInteractionRows(r.IRoot.interactionState,2);token=r.cyrusPlacementToken(rows);page=r.cyrusPlacementPage(rows,token,0,1)
        for row in fixture['instances']:
            if row['layer']==1:row['transform']=[float(x) for v in [page[0][0].row1,page[0][0].row2,page[0][0].row3,page[0][0].row4] for x in v]
        path.write_text(json.dumps(fixture))
        (OUT/'material-bake.json').write_text(json.dumps({'status':'pass','triangles':int(r.getNumFaces(baked)),'material_ids':sorted(delivered_ids),'uv_channels':channels,'scope':'Complete native Bake mesh; every delivered UV value belongs to the source UV set and all three material IDs remain present.'},indent=2))
        (OUT/'bridge-inputs.json').write_text(json.dumps({'owner':str(r.IOwner.name),'owner_class':str(r.classOf(r.IOwner.baseObject)),'expected_class':str(r.AminScatterObject),'class_matches':bool(r.classOf(r.IOwner.baseObject)==r.AminScatterObject),'hidden':bool(r.IOwner.isHidden),'render_flags':[bool(leaf.autoRender) for leaf in r.IRoot.layerObjects],'baked_name':str(baked.name),'output_nodes':[str(n.name) for n in r.IRoot.interactionOutputNodes],'statistics':info},indent=2))
        r.execute('global RBaked');r.RBaked=baked
except Exception:(OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
