"""Scoped interaction/viewport acceptance in the explicitly owned 2027 host."""
from pathlib import Path
import hashlib,json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];host=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running'}
def pump(n=12):
    for _ in range(n):r.windows.processPostedMessages();time.sleep(.025);r.completeRedraw()
def stats():return json.loads(str(r.WFRoot.interactionsStatistics()))
def bind():
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    pump(3);p=r.WFRoot.mainUI;p.selectLayerView(r.WFGrass);p=r.WFRoot.mainUI;p.slots[12].open=True;p.bindSection(p.editors[12]);r.WFSection=p.editors[12]
def event(name,value):
    bind();r.execute('WFSection.interactionsUI_'+name+(' '+str(value) if value is not None else ''));pump();assert not str(r.WFRoot.interactionError),str(r.WFRoot.interactionError)
def counters():
    owner=r.CyrusPointOwner(r.WFOwner)
    return {'group':list(r.WFRoot.groupCounters()),'epoch':int(r.WFRoot.procEpoch),'retained':list(r.cyrusRetainedStats(owner)),'mesh':list(r.cyrusRetainedMeshStats(owner))}
def move(target):
    pump(3);r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(r.WFCollider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
    row=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0];r.CVCurrent=row.row4;r.CVTarget=target
    r.execute('undo "Hide margin collider move" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
    r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();assert not str(r.WFRoot.interactionError),str(r.WFRoot.interactionError)
    return stats()
try:
    if phase=='migration':
        scene=ROOT/'dist/CyrusScatter-0.87.4.2-20261027/Neottopteris_Selected_Leaves_0.87.4.2.max'
        assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        owners=[n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject']
        report['layers']=[{'schema':int(n.baseObject.version),'gap':float(n.baseObject.interactionGapWU),'margin':float(n.baseObject.interactionHideMarginWU),'area':int(n.baseObject.interactionHideArea)} for n in owners]
        assert report['layers'] and all(x['schema']==63 and x['area']==1 and abs(x['margin']-x['gap'])<1e-6 for x in report['layers']),report
    elif phase=='setup':
        root,leaf,collider=r.WFRoot,r.WFGrass,r.WFCollider
        root.updateMode=1;leaf.interactionReact=False;collider.interactionCollider=False;root.interactionsEnsure()
        leaf.removeModelSources(r.Array(*range(1,len(leaf.sources)+1)))
        node=r.getNodeByName('Outdoor_Plants_01_Grass_Wild_QMH_001');assert r.isValidNode(node)
        leaf.addModelSource(node);leaf.amount=1;leaf.interactionFoliage=1.;leaf.interactionMinimumM=.001;leaf.interactionConnectionM=.01;leaf.interactionMaxPreview=2000000
        leaf.interactionGapWU=0;leaf.interactionCoverRoots=True;leaf.interactionHideMarginWU=0;leaf.interactionHideArea=1
        root.refreshAll();r.CyrusPointSync();bind()
        r.execute('WFSection.interactionsUI_chooseRole 3;WFSection.interactionsUI_prepareButton.pressed()');pump()
        assert leaf.interactionsReady(leaf.validSources()),str(r.WFSection.interactionsUI_info.text)
        definition=json.loads(str(leaf.interactionDefinitions[-1]));report['preparation']=definition['source']['report'];report['metadata']=definition['source']['metadata']
        r.execute('global CVBase,CVScale,CVRadius,CVHeight;CVBase=(cyrusPlacementTransformGroups WFRoot.groupSnapshotRows[1])[1][1].row4;CVScale=length (cyrusPlacementTransformGroups WFRoot.groupSnapshotRows[1])[1][1].row1')
        guides=definition['source']['metadata']['guides'];height=max(q[1] for g in guides for q in g['nodes']);radius=max(.015,height*.15)*100*float(r.CVScale)
        r.CVRadius=radius;r.CVHeight=height*100*float(r.CVScale);r.WFSphere.radius=radius
        root.refreshAll();collider.interactionCollider=True;collider.interactionColliderMode=1;root.interactionsEnsure();r.CyrusPointSync();pump()
        report['far']=move(r.CVBase+r.Point3(10000,10000,10000))
        report['hover']=move(r.CVBase+r.Point3(0,0,float(r.CVHeight)+radius*2))
        assert report['hover']['hidden_roots']==0,report
        root.setGroupDisplay(3);root.identificationMode=4;r.CyrusPointSync();pump();bind()
        report.update(source=str(node.name),base=list(r.CVBase),radius_scene_units=radius,height_scene_units=float(r.CVHeight),counters=counters())
        (host/'definition-before.json').write_text(json.dumps(definition),encoding='utf-8')
    elif phase=='under-auto':
        r.WFGrass.interactionHideArea=2;r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();report['statistics']=stats();assert report['statistics']['hidden_roots']>0
    elif phase=='under':
        report['before']=json.loads((host/'check-setup.json').read_text())['counters'];assert int(r.WFGrass.interactionHideArea)==2;report['after']=counters();report['statistics']=stats()
        assert report['statistics']['hidden_roots']>0,report
        assert report['before']['epoch']==report['after']['epoch'] and report['before']['group'][0]==report['after']['group'][0],report
        assert json.loads(str(r.WFGrass.interactionDefinitions[-1]))==json.loads((host/'definition-before.json').read_text()),'Hide area reprepared source'
    elif phase=='margin':
        report['before']=stats();report['counters_before']=counters();event('hideMarginSpin.changed',float(r.CVHeight));report['after']=stats();report['counters_after']=counters()
        assert report['after']['hidden_roots']>report['before']['hidden_roots'],report
        assert float(r.WFGrass.interactionGapWU)==0 and int(r.WFRoot.procEpoch)==report['counters_before']['epoch']
    elif phase=='undo-read':
        pump();report.update(margin=float(r.WFGrass.interactionHideMarginWU),statistics=stats());assert report['margin']==0,report
    elif phase=='redo-read':
        pump();report.update(margin=float(r.WFGrass.interactionHideMarginWU),statistics=stats());assert report['margin']>0,report
    elif phase=='restore':
        target=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0].row4;report['covered']=stats();report['away']=move(r.CVBase+r.Point3(10000,10000,10000));assert report['away']['hidden_roots']==0
        report['back']=move(target);assert report['back']['hidden_roots']==report['covered']['hidden_roots'],report
    elif phase=='pending':
        root=r.WFRoot;root.updateMode=1;published=int(r.WFGrass.generatedCount);r.WFGrass.amount=published+1;before=counters();event('hideMarginSpin.changed',float(r.CVHeight)*.5);after=counters()
        assert before['epoch']==after['epoch'] and int(r.WFGrass.generatedCount)==published,after
        report.update(before=before,after=after,pending_amount=int(r.WFGrass.amount),published_count=int(r.WFGrass.generatedCount));r.WFGrass.amount=published
    elif phase=='bend':
        r.WFGrass.interactionHideArea=2;r.WFGrass.interactionHideMarginWU=0;r.WFGrass.interactionGapWU=0;r.WFRoot.interactionsEnsure()
        definition=json.loads(str(r.WFGrass.interactionDefinitions[-1]));guide=max(definition['source']['metadata']['guides'],key=lambda g:g['length_m']);p=guide['nodes'][max(1,int((len(guide['nodes'])-1)*.7))];r.CVPoint=r.Point3(p[0]*100,-p[2]*100,p[1]*100);r.CVMatrix=r.cyrusPlacementTransformGroups(r.WFRoot.groupSnapshotRows[0])[0][0];target=r.execute('CVPoint*CVMatrix')+r.Point3(float(r.CVRadius)*.6,0,0)
        report['statistics']=move(target);report['audit']=json.loads(str(r.cyrusInteractionValidate(r.WFRoot.interactionState,4000000)[2]));assert report['statistics']['fitted_guides']>0,report
    elif phase=='scale200':
        r.WFRoot.updateMode=1;r.WFGrass.amount=200;r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();report.update(statistics=stats(),counters=counters(),count=int(r.WFGrass.generatedCount));assert report['count']==200 and not str(r.WFRoot.interactionError)
    elif phase=='save':
        r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot');bind()
        scene=host/'Grass_Hide_Margin_0.87.4.3.max';assert r.saveMaxFile(str(scene),quiet=True);report['scene']=str(scene);report['settings']=[float(r.WFGrass.interactionHideMarginWU),int(r.WFGrass.interactionHideArea),float(r.WFGrass.interactionGapWU)];report['statistics']=stats()
    elif phase=='reload':
        saved=json.loads((host/'check-save.json').read_text());assert r.loadMaxFile(saved['scene'],quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined);r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1];r.WFSphere=r.WFCollider.validSources()[0];r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
        r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();report['settings']=[float(r.WFGrass.interactionHideMarginWU),int(r.WFGrass.interactionHideArea),float(r.WFGrass.interactionGapWU)];assert report['settings']==saved['settings'];report['statistics']=stats();assert not str(r.WFRoot.interactionError)
    elif phase.startswith('view-'):
        # Set the mode through its generated viewport UI action in later phases.
        name=phase[5:];root=r.WFRoot
        if name=='split':
            before=counters();r.viewport.setLayout(r.Name('layout_4'));bounds=json.loads((host/'check-view-grass.json').read_text())['guide_bounds_world']
            for i in range(1,5):
                r.viewport.activeViewport=i;r.viewport.setType(r.Name('view_persp_user'));r.viewport.SetRenderLevel(r.Name('wireframe' if i==1 else 'smoothhighlights'));r.viewport.ZoomToBounds(False,r.Point3(*bounds[0]),r.Point3(*bounds[1]))
            r.CyrusPointSync();pump(24);after=counters();report.update(before=before,after=after);assert after['mesh'][7]>before['mesh'][7] and after['mesh'][8]>before['mesh'][8],report;assert after['retained'][5:7]==before['retained'][5:7],report
        elif name=='setup':
            move(r.CVBase+r.Point3(10000,10000,10000));setattr(r.WFGrass,'interactionHideArea',1);r.WFRoot.interactionsEnsure();event('hideMarginSpin.changed',0)
            root.setGroupDisplay(3);root.identificationMode=1;r.CyrusPointSync();pump()
            # Frame the prepared instance and one original source side by side.
            node=r.WFGrass.validSources()[0];report['source']=str(node.name)
            surfaces=[n for n in r.objects if str(r.classOf(n.baseObject)) in ('Plane','Editable_Poly','Editable_mesh') and n!=node and n not in list(r.WFCollider.validSources())];r.hide(r.Array(*surfaces))
            bounds=r.nodeGetBoundingBox(node,r.Matrix3(1));report['source_bounds']=[list(p) for p in bounds]
            r.viewport.setType(r.Name('view_persp_user'));r.viewport.ZoomToBounds(False,r.CVBase-r.Point3(float(r.CVHeight),float(r.CVHeight),10),r.CVBase+r.Point3(float(r.CVHeight),float(r.CVHeight),float(r.CVHeight)*1.4));pump()
        elif name=='material':
            r.execute('ColorPipelineMgr.Mode=#OCIO_Default;(WFGrass.validSources())[1].material=standardMaterial diffuse:(color 70 130 35) opacity:100');root.refreshDisplay();r.CyrusPointSync();pump()
        elif name=='zoom':
            r.viewport.setFOV(12);pump()
        elif name=='sphere':
            row=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0];centre=row.row4;v=r.Point3(float(r.CVRadius)*1.5,float(r.CVRadius)*1.5,float(r.CVRadius)*1.5);r.viewport.ZoomToBounds(False,centre-v,centre+v);pump()
        elif name=='grass':
            definition=json.loads(str(r.WFGrass.interactionDefinitions[-1]));tm=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0];rows=[list(tm.row1),list(tm.row2),list(tm.row3),list(tm.row4)];points=[]
            for g in definition['source']['metadata']['guides']:
                for p in g['nodes']:
                    q=[p[0]*100,-p[2]*100,p[1]*100];points.append([sum(q[j]*rows[j][k] for j in range(3))+rows[3][k] for k in range(3)])
            lo=[min(p[k] for p in points) for k in range(3)];hi=[max(p[k] for p in points) for k in range(3)];r.viewport.ZoomToBounds(False,r.Point3(*lo),r.Point3(*hi));pump();report['guide_bounds_world']=[lo,hi]
        elif name=='close':
            v=r.Point3(float(r.CVHeight)*.3,float(r.CVHeight)*.3,float(r.CVHeight)*.3);r.viewport.ZoomToBounds(False,r.CVBase-v,r.CVBase+v);pump()
        elif name in ('mesh-wire','texture-wire'):
            root.identificationMode=1 if name=='mesh-wire' else 4;root.setGroupDisplay(3);r.CyrusPointSync();r.viewport.SetRenderLevel(r.Name('smoothhighlights'));pump();before=counters();r.viewport.SetRenderLevel(r.Name('wireframe'));pump(24);after=counters();report.update(before=before,after=after,identification_mode=int(root.identificationMode));assert before['retained'][2:7]==after['retained'][2:7],report;assert before['group'][0]==after['group'][0] and before['epoch']==after['epoch'],report;assert after['mesh'][7]>before['mesh'][7],report
        elif name in ('mesh','texture'):
            root.identificationMode=1 if name=='mesh' else 4;root.setGroupDisplay(3);r.CyrusPointSync();pump()
        elif name in ('wire','shade'):
            r.viewport.SetRenderLevel(r.Name('wireframe' if name=='wire' else 'smoothhighlights'));pump(24)
        report.update(level=str(r.viewport.GetRenderLevel()),counters=counters(),statistics=stats())
    else:raise ValueError(phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc())
(host/('check-'+phase+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
if report['status']!='pass':raise RuntimeError(report['error'])
