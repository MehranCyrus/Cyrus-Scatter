"""Owned Test22 scale, Edit and bounded render regressions; Max 2027 only."""
from pathlib import Path
import json,math,statistics,sys,time,traceback
from pymxs import runtime as r
helper_dir=str(Path(__file__).resolve().parent)
if helper_dir not in sys.path:sys.path.insert(0,helper_dir)
from fixture_assets import load_owned_fixture

ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running','scope':'Owned copied Test22 scene, Max 2027 only; timings are CPU wall time, not presented FPS'}

def pump(n=10,draw=True):
    for _ in range(n):
        r.windows.processPostedMessages()
        if draw:r.completeRedraw()
        time.sleep(.02)

def acquire():
    r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1]
    r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)

def setup(count=10):
    load_owned_fixture(r,ROOT/'build/interactions08753-20261028-01/fixtures/New-Plants-22-input.max',ROOT,report)
    acquire();r.WFRoot.updateMode=2;r.WFGrass.amount=count;r.WFCollider.amount=1
    r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump()

def stats():return json.loads(str(r.WFRoot.interactionsStatistics()))

def placement_work():
    return [{'layer':str(leaf.layerID),'base':list(leaf.paintCacheStats()),
             'receiver':list(leaf.receiverCacheStats()),'edit_prepared_builds':int(leaf.procStatistics()[2])}
            for leaf in r.WFRoot.layerObjects]

def matrix():return r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0]

def vec(p):return [float(x) for x in p]

def signature():
    tm=matrix()
    return {'axis':float(r.length(tm.row1)),'position':vec(tm.row4),
            'model_scale':float(r.WFCollider.sourceScale(1)),'node_scale':vec(r.WFCollider.validSources()[0].scale),
            'source_id':str(r.WFCollider.sourceRowIDs[0]),'error':str(r.WFRoot.interactionError),
            'layer_errors':[str(x.previewError) for x in r.WFRoot.layerObjects]}

def close(a,b,tolerance=2e-4):assert len(a)==len(b) and max(abs(x-y) for x,y in zip(a,b))<tolerance,(a,b)

def bind_models():
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    pump();r.WFRoot.mainUI.selectLayerView(r.WFCollider);r.WFRoot.modelsUISlot.open=True
    r.WFRoot.mainUI.bindSection(r.WFRoot.modelsUI);r.AuditModels=r.WFRoot.modelsUI
    r.execute('AuditModels.sourceUI_plantList.selection=#{1};AuditModels.sourceUI_showSelectedColor()')

def scale_model(value):
    bind_models();r.AuditScale=float(value)
    r.execute('AuditModels.sourceUI_sourceScaleSpin.changed AuditScale')
    pump();r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump()

def edit_setup():
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    pump();r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(r.WFCollider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))

def edit_move(delta):
    before=vec(matrix().row4)
    r.AuditDelta=r.Point3(*delta)
    started=time.perf_counter();r.execute('undo "Test22 collider movement" on cyrusEditTransform WFEdit 0 AuditDelta (matrix3 1) false')
    elapsed=(time.perf_counter()-started)*1000;pump()
    close(vec(matrix().row4),[before[i]+delta[i] for i in range(3)])
    return elapsed

def current_info(mode=0):
    r.WFRoot.interactionsEnsure()
    return json.loads(str(r.cyrusInteractionRenderInfo(r.WFRoot.interactionState,mode)))

try:
    if phase=='opacity-diagnose':
        report['submaterials']=[]
        for i in range(1,int(r.getNumSubMtls(r.AuditGrassMaterial))+1):
            material=r.getSubMtl(r.AuditGrassMaterial,i);item={'class':str(r.classOf(material)),'properties':{},'bitmap':{}}
            for key in r.getPropNames(material):
                name=str(key)
                if 'opacity' in name.lower() or 'diffuse' in name.lower():item['properties'][name]=str(r.getProperty(material,key))
            if r.isProperty(material,r.Name('texmapOpacity')):
                bitmap=r.getProperty(material,r.Name('texmapOpacity'))
                if bitmap!=r.undefined:
                    for key in r.getPropNames(bitmap):
                        name=str(key)
                        if any(x in name.lower() for x in ('filename','alpha','mono','rgb')):item['bitmap'][name]=str(r.getProperty(bitmap,key))
                    if r.isProperty(bitmap,r.Name('filename')):item['bitmap']['exists']=Path(str(bitmap.filename)).is_file()
            report['submaterials'].append(item)
    elif phase=='asset-diagnose':
        materials=[]
        for leaf in r.WFRoot.layerObjects:
            for node in leaf.validSources():
                m=node.material;item={'node':str(node.name),'material':str(m.name) if m!=r.undefined else None,'class':str(r.classOf(m))}
                try:item['submaterials']=[str(r.classOf(r.getSubMtl(m,i))) for i in range(1,int(r.getNumSubMtls(m))+1)]
                except Exception:pass
                materials.append(item)
        report['materials']=materials
        owner=r.CyrusPointOwner(r.WFOwner)
        report.update(mesh_stats=list(r.cyrusRetainedMeshStats(owner)),retained=list(r.cyrusRetainedStats(owner)),
                      viewport=list(r.cyrusRetainedViewportStats(owner)),detail=str(r.CyrusPointDetailStatus),point_error=str(r.CyrusPointLastError),
                      plant_node_scale=vec(r.WFGrass.validSources()[0].scale),plant_placed_axis=float(r.length(r.cyrusPlacementTransformGroups(r.WFRoot.groupSnapshotRows[0])[0][0].row1)))
        report['layers_visible']=[bool(r.WFRoot.visibleLayer(i+1)) for i in range(len(r.WFRoot.layerObjects))]
        report['bounds']=[vec(p) for p in r.nodeGetBoundingBox(owner,r.matrix3(1))]
        source=r.WFGrass.validSources()[0]
        report['plant_local_bounds']=[vec(p) for p in r.nodeGetBoundingBox(source,source.transform)]
        report['owner_hidden']=bool(owner.isHidden)
        report['edit_sample']=[{'layer':int(x[0]),'active':bool(x[5]),'shown':bool(x[6]),'deleted':bool(x[8]),'delta':str(x[10])} for x in r.cyrusEditInspect(r.WFEdit,0,3)[3]]
        cache=r.WFGrass.cachedPoints
        report['base_cache']={'points':int(r.aminScatterPreviewCount(cache)),'faces':int(r.cyrusPreviewFaces(cache)),'triangles':str(r.cyrusPreviewTriangles(cache,3))}
        for name,rows in [('published',r.WFRoot.groupSnapshotRows[0]),('contact',r.cyrusInteractionRows(r.WFRoot.interactionState,1))]:
            token=r.cyrusPlacementToken(rows);count=int(r.getProperty(rows,r.Name('count')))
            report[name]=[{'position':vec(item[0].row4),'axis':float(r.length(item[0].row1))} for offset in (0,max(0,count//2-2),max(0,count-5)) for item in r.cyrusPlacementPage(rows,token,offset,min(5,count-offset))]
    elif phase=='manual-diagnose':
        root=r.WFRoot
        report.update(generated=int(r.WFGrass.generatedCount),amount=int(r.WFGrass.amount),pending=bool(root.interactionsMembershipPending()),
                      error=str(root.interactionError),layer_errors=[str(x.previewError) for x in root.layerObjects],epoch=int(root.procEpoch),
                      status_text=str(root.interactionsStatus()),published_sources=[[str(n.name) if r.isValidNode(n) else '<missing>' for n in ns] for ns in root.procPublishedSources],
                      authored_sources=[[str(n.name) if r.isValidNode(n) else '<missing>' for n in leaf.validSources()] for leaf in root.procPublishedOwners])
    elif phase=='scale-setup':
        setup();before=signature();expected=before['node_scale'][0]*before['model_scale'];report['initial']=before
        if int(r.cyrusInteractionVersion())>=13:assert math.isclose(before['axis'],expected,rel_tol=2e-5),before
        edit_setup();report['edit_ms']=edit_move([25.,10.,0.]);after=signature();close(after['position'],[before['position'][0]+25,before['position'][1]+10,before['position'][2]])
        r.AuditEditedPosition=r.Point3(*after['position']);r.AuditInitialAxis=before['axis'];report['moved']=after
        # Keep an exact before/after inspector receipt for stable Edit identities.
        r.AuditEditRows=r.cyrusEditInspect(r.WFEdit,0,16);report['edit_ids']=[[str(x[3]),str(x[4])] for x in r.AuditEditRows[3]]
    elif phase=='scale-model':
        before=signature();scale_model(.8);after=signature();report.update(before=before,after=after)
        assert not after['error'] and not any(after['layer_errors']),after
        close(after['position'],vec(r.AuditEditedPosition));assert math.isclose(after['axis']/before['axis'],1.6,rel_tol=2e-5)
        now=r.cyrusEditInspect(r.WFEdit,0,16);assert [[str(x[3]),str(x[4])] for x in now[3]]==[[str(x[3]),str(x[4])] for x in r.AuditEditRows[3]]
    elif phase=='scale-source-node':
        before=signature();source=r.WFCollider.validSources()[0];source.scale=source.scale*1.25;pump(25)
        r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();after=signature();report.update(before=before,after=after)
        assert not after['error'] and not any(after['layer_errors']),after
        close(after['position'],vec(r.AuditEditedPosition));assert math.isclose(after['axis']/before['axis'],1.25,rel_tol=2e-5)
    elif phase=='scale-save-reload':
        before=signature();target=out/'Test22-scaled-edit.max';r.execute('subObjectLevel=0;clearSelection()')
        assert r.saveMaxFile(str(target),quiet=True)
        load_owned_fixture(r,target,ROOT,report);acquire()
        r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();after=signature();report.update(before=before,after=after,scene=str(target))
        assert not after['error'] and before['source_id']==after['source_id'];close(before['position'],after['position']);assert math.isclose(before['axis'],after['axis'],rel_tol=2e-5)
    elif phase in ('render-small','render-dense'):
        count=50 if phase=='render-small' else 1000;setup(count);r.WFRoot.updateMode=1
        # Preserve the artist's authored Edit rotations in current builds.
        # The old build's legacy Scale guard needs a separate isolated sizing
        # control; resetting all edits changes the plants' orientation.
        if int(r.cyrusInteractionVersion())<13:r.cyrusEditCommand(r.WFEdit,0,r.matrix3(1))
        # A broad low-poly stone exercises many plants. Normalize source scale
        # in both old/new hosts so the comparison has identical footprints.
        source=r.WFCollider.validSources()[0];source.scale=r.Point3(1,1,1)
        r.WFCollider.sourceScales=r.Array(.65);r.WFRoot.refreshAll()
        errors=[str(x.previewError) for x in r.WFRoot.layerObjects]
        if any(errors):raise RuntimeError('Dense successor rejected: '+str(errors))
        r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump()
        report['statistics']=stats();report['scale']=signature()
        report['info']=current_info(2 if phase=='render-small' else 1)
        assert report['info']['outputs'] and not str(r.WFRoot.interactionError),report
        if phase=='render-small':
            assert report['info']['constructed_faces']>0,report['info']
            before={int(r.getHandleByAnim(n)) for n in r.objects};created=r.cyrusInteractionBake(r.WFRoot.interactionState,1)
            baked=sum(int(r.getNumFaces(n.mesh)) for n in created);expected=report['info']['constructed_faces']
            assert baked==expected,(baked,expected);report['bake']={'nodes':len(created),'faces':baked}
            for n in created:r.delete(n)
            assert {int(r.getHandleByAnim(n)) for n in r.objects}==before
        else:
            assert sum(o['combined_construction_bytes'] for o in report['info']['outputs'])>1024**3,report['info']
            assert all(o['batches']>1 for o in report['info']['outputs']),report['info']
    elif phase=='dense-under':
        r.WFGrass.interactionHideArea=2;r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump()
        report['statistics']=stats();assert not str(r.WFRoot.interactionError)
    elif phase=='reprepare-bindings':
        before=stats();streams=list(r.cyrusRetainedStreamStats())
        r.execute('WFGrass.interactionsPrepare #((WFGrass.validSources())[1]) rebuild:true enable:true')
        r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump()
        after=stats();now=list(r.cyrusRetainedStreamStats())
        report.update(before=before,after=after,upload_delta={str(i):now[i]-streams[i] for i in (1,2,3,6,7)})
        assert not str(r.WFRoot.interactionError)
        assert after['process_work']['source_preparations']>before['process_work']['source_preparations']
        assert report['upload_delta']['7']>0,'A new immutable preparation incorrectly reused old source bindings'
    elif phase in ('drag-ready','drag-arm'):
        if phase=='drag-ready':
            r.WFRoot.updateMode=2;r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump()
            edit_setup()
        report['before']=signature();report['statistics']=stats()
        report['groups']=list(r.WFRoot.groupCounters());report['epoch']=int(r.WFRoot.procEpoch)
        report['placement_work']=placement_work()
        report['streams']=list(r.cyrusRetainedStreamStats());report['started']=time.perf_counter()
        (out/'physical-drag-before.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    elif phase in ('drag-check','drag-check-final'):
        before=json.loads((out/'physical-drag-before.json').read_text());pump();report['after']=signature();report['statistics']=stats()
        streams=list(r.cyrusRetainedStreamStats());report['upload_delta']={str(i):streams[i]-before['streams'][i] for i in (1,2,3,6,7)}
        report['groups']=list(r.WFRoot.groupCounters());report['epoch']=int(r.WFRoot.procEpoch)
        report['placement_work']=placement_work()
        report['work_delta']={key:report['statistics']['process_work'][key]-value for key,value in before['statistics']['process_work'].items()}
        assert not report['after']['error'] and not any(report['after']['layer_errors'])
        assert sum((x-y)**2 for x,y in zip(report['after']['position'],before['before']['position']))>1e-6,'No actual Edit movement'
        assert report['upload_delta']['1']==0,'Collider movement re-uploaded unchanged geometry'
        if phase=='drag-check-final':assert report['upload_delta']['7']==0,'Unchanged immutable source bindings uploaded again'
        # Mouse-up must publish edited rows. Epoch, Edit/filter preparation and
        # one contact-layout successor may advance; immutable candidate and
        # receiver construction must remain cached.
        for previous,current in zip(before['placement_work'],report['placement_work']):
            assert previous['base'][0]==current['base'][0] and previous['receiver'][0]==current['receiver'][0],(previous,current)
        for key in ('source_preparations','source_captures','collider_cooks'):
            assert before['statistics']['process_work'][key]==report['statistics']['process_work'][key],key
    elif phase=='dense-move':
        edit_setup();before=stats();samples=[];origin=matrix().row4
        for k in range(8):
            dt=edit_move([5. if k%2==0 else -5.,0.,0.]);s=stats();assert not str(r.WFRoot.interactionError)
            samples.append({'wall_edit_ms':dt,'fit_ms':s['fit_ms'],'affected':s['affected'],'process_work':s['process_work']})
        after=stats();close(vec(matrix().row4),vec(origin))
        for key in ('source_preparations','source_captures','collider_cooks','layouts'):assert before['process_work'][key]==after['process_work'][key],key
        report.update(before=before,after=after,samples=samples,median_wall_edit_ms=statistics.median(x['wall_edit_ms'] for x in samples),median_fit_ms=statistics.median(x['fit_ms'] for x in samples))
    else:raise ValueError(phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:
    (out/'campaign-history').mkdir(exist_ok=True)
    (out/'campaign-history'/(phase+'-'+str(time.time_ns())+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
    (out/(phase+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
