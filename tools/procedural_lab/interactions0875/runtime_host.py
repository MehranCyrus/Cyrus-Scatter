"""Owned real-model, retained-buffer and Cyrus Edit qualification for 0.87.5."""
from pathlib import Path
import hashlib,json,math,os,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running','scope':'Owned Max 2027; main-thread CPU update/redraw timings are not presented FPS'}
def pump(n=6):
    for _ in range(n):r.windows.processPostedMessages();r.completeRedraw();time.sleep(.02)
def stats():return json.loads(str(r.WFRoot.interactionsStatistics()))
def counters():
    owner=r.CyrusPointOwner(r.WFOwner)
    return {'streams':list(r.cyrusRetainedStreamStats()),'presentation':list(r.cyrusRetainedPresentationStats(owner)),
            'retained':list(r.cyrusRetainedStats(owner)),'mesh':list(r.cyrusRetainedMeshStats(owner)),
            'group':list(r.WFRoot.groupCounters()),'epoch':int(r.WFRoot.procEpoch)}
def require_ready():
    assert not str(r.WFRoot.interactionError),str(r.WFRoot.interactionError)
    s=counters()['presentation'];assert s[3]==2 and s[4] and s[5]==s[6],s
def edit_setup():
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(r.WFCollider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
def move(target):
    row=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0];r.CVCurrent=row.row4;r.CVTarget=target
    started=time.perf_counter();r.execute('undo "Shared pose collider move" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false');edited=time.perf_counter()
    # Native Cyrus Edit publishes contact successors directly. Forcing the
    # scripted full-controller sync here would measure an extra artist command
    # on every sample rather than the pointer gesture's native update path.
    ensured=edited;synced=edited;r.completeRedraw();drawn=time.perf_counter()
    for _ in range(8):
        s=counters()['presentation']
        if s[3]==2:break
        assert s[3]!=3,s;r.windows.processPostedMessages();r.completeRedraw()
    r.CVMoveTiming=json.dumps({'edit_ms':(edited-started)*1000,'ensure_ms':(ensured-edited)*1000,'sync_ms':(synced-ensured)*1000,'first_redraw_ms':(drawn-synced)*1000,'commit_redraw_ms':(time.perf_counter()-drawn)*1000})
def frame():
    preview=r.CyrusPointOwner(r.WFOwner);r.unhide(preview)
    for n in r.objects:
        if n!=r.WFOwner and n!=preview:r.hide(n)
    row=r.cyrusPlacementTransformGroups(r.WFRoot.groupSnapshotRows[0])[0][0];p=row.row4
    definition=json.loads(str(r.WFGrass.interactionDefinitions[-1]));height=max(v[1] for g in definition['source']['metadata']['guides'] for v in g['nodes'])*float(r.units.decodeValue('1m'))*float(r.length(row.row1))
    r.CVHeight=height;centre=p+r.Point3(0,0,height*.45);eye=centre+r.Point3(height*1.4,-height*2.5,height*1.1)
    back=r.normalize(eye-centre);right=r.normalize(r.cross(r.Point3(0,0,1),back));up=r.cross(back,right)
    r.viewport.setType(r.Name('view_persp_user'));r.viewport.setFOV(45);r.viewport.setTM(r.inverse(r.matrix3(right,up,back,eye)))
    r.viewport.SetRenderLevel(r.Name('smoothhighlights'));pump()
    return p,height
def prepare(name):
    root,leaf,collider=r.WFRoot,r.WFGrass,r.WFCollider
    leaf.interactionReact=False;collider.interactionCollider=False;root.interactionsEnsure();leaf.removeModelSources(r.Array(*range(1,len(leaf.sources)+1)))
    node=r.getNodeByName(name);assert r.isValidNode(node),name
    leaf.addModelSource(node);leaf.amount=1;leaf.interactionFoliage=1.;leaf.interactionMinimumM=.005;leaf.interactionConnectionM=.15;leaf.interactionGapWU=0;leaf.interactionHideMarginWU=0;leaf.interactionCoverRoots=True;leaf.interactionHideArea=1
    root.viewportFaces=0;root.viewportNavigationFaces=0;root.refreshAll();leaf.interactionsPrepare(leaf.validSources());leaf.interactionReact=True;collider.interactionCollider=True;root.interactionsEnsure();r.CyrusPointSync();pump()
    definition=json.loads(str(leaf.interactionDefinitions[-1]));return definition
try:
    if phase=='inspect':report.update(statistics=stats(),counters=counters())
    elif phase in ('mesh-frame','texture-frame'):
        r.WFRoot.setGroupDisplay(3);r.WFRoot.identificationMode=1 if phase=='mesh-frame' else 4;r.CyrusPointSync();frame();report.update(statistics=stats(),counters=counters());require_ready()
    elif phase=='demo-style':
        r.viewport.setLayout(r.Name('layout_1'));r.WFRoot.identificationMode=2;r.WFRoot.setGroupDisplay(3)
        r.WFGrass.layerIDColor=r.Color(100,210,100);r.WFCollider.layerIDColor=r.Color(175,175,175);r.execute('WFRoot.layerNames[1]="Plant";WFRoot.layerNames[2]="Collider - sphere"');r.WFRoot.refreshIdentification();r.CyrusPointSync();pump();frame();require_ready();report.update(statistics=stats(),counters=counters())
    elif phase=='warm':
        pump();before=counters()
        for angle in range(15):r.viewport.setFOV(44+angle*.1);r.completeRedraw();r.windows.processPostedMessages()
        pump();after=counters();report.update(before=before,after=after)
        assert before['streams']==after['streams'] and before['group']==after['group'] and before['epoch']==after['epoch'],report;require_ready()
    elif phase=='all-hidden':
        os.environ.pop('CYRUS_INTERACTION_CPU_PREVIEW',None);prepare('Outdoor_Plants_01_Grass_Wild_QMH_001');p,height=frame();leaf,root=r.WFGrass,r.WFRoot
        leaf.interactionHideArea=2;leaf.interactionHideMarginWU=0;r.WFSphere.radius=height*2;root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();pump();edit_setup();move(p+r.Point3(0,0,height*3));pump();require_ready()
        report['statistics']=stats();report['audit']=json.loads(str(r.cyrusInteractionValidate(root.interactionState,4000000)[2]));assert report['statistics']['covered']==1 and report['audit']['triangles']==0,report
        root.viewportFaces=100;root.viewportNavigationFaces=100;r.CyrusPointSync();pump();require_ready();report['box_counters']=counters();report['viewport']=list(r.cyrusRetainedViewportStats(r.CyrusPointOwner(r.WFOwner)));assert report['viewport'][7]>0,report
    elif phase=='failure':
        root,leaf=r.WFRoot,r.WFGrass;before=counters();original=float(leaf.interactionGapWU);leaf.interactionGapWU=-1;message=''
        try:root.interactionsEnsure()
        except Exception as e:message=str(e)
        assert message,'Invalid negative contact gap was accepted';after=counters();assert after['presentation'][4] and before['presentation'][12]==after['presentation'][12],after
        leaf.interactionGapWU=original;root.interactionsEnsure();r.CyrusPointSync();pump();require_ready();report.update(before=before,after=after,error=message,recovered=counters())
    elif phase=='record-undo':
        edit_setup();before=list(r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0].row4);move(r.Point3(*before)+r.Point3(float(r.CVHeight)*.2,0,0));pump();require_ready();report.update(before=before,after=list(r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0].row4),statistics=stats())
    elif phase in ('undo-read','redo-read'):
        r.CyrusPointSync();pump();require_ready();record=json.loads((out/'runtime-record-undo.json').read_text());tm=list(r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0].row4);expected=record['before' if phase=='undo-read' else 'after'];error=math.sqrt(sum((a-b)**2 for a,b in zip(tm,expected)))/float(r.units.decodeValue('1m'));assert error<2e-6,(record,tm,error);report.update(transform=tm,transform_error_m=error,statistics=stats(),counters=counters())
    elif phase in ('fern','grass','rosette'):
        os.environ.pop('CYRUS_INTERACTION_CPU_PREVIEW',None)
        names={'grass':'Outdoor_Plants_01_Grass_Wild_QMH_001','fern':'Outdoor_Plants_01_Brainea_Insignis_Fern_Medium03_001','rosette':'Outdoor_Plants_01_Neottopteris_Nidus_Bush05_001'}
        definition=prepare(names[phase]);report['preparation']=definition['source']['report'];p,height=frame();r.WFSphere.radius=max(height*.12,.2);r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();require_ready();edit_setup()
        report['away_target']=list(p+r.Point3(height*2,0,height*.5));move(p+r.Point3(height*2,0,height*.5));pump();before=counters();samples=[]
        for k in range(8):
            target=p+r.Point3(height*(.52-.045*k),0,height*.65);started=time.perf_counter();move(target);elapsed=(time.perf_counter()-started)*1000;s=stats();require_ready();samples.append({'wall_update_redraw_ms':elapsed,'timing':json.loads(str(r.CVMoveTiming)),'statistics':s,'streams':counters()['streams']})
        report.update(samples=samples,before=before,after=counters());assert any(x['statistics']['fitted_guides']>0 for x in samples),report
        report['audit']=json.loads(str(r.cyrusInteractionValidate(r.WFRoot.interactionState,4000000)[2]));assert report['audit']['passed'],report['audit'];frame()
    elif phase=='two-sources':
        os.environ.pop('CYRUS_INTERACTION_CPU_PREVIEW',None);prepare('Outdoor_Plants_01_Grass_Wild_QMH_001')
        root,leaf=r.WFRoot,r.WFGrass;leaf.interactionReact=False;root.interactionsEnsure();leaf.addModelSource(r.getNodeByName('Outdoor_Plants_01_Brainea_Insignis_Fern_Medium03_001'));leaf.interactionsPrepare(leaf.validSources());leaf.amount=8;leaf.interactionReact=True;root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();pump();require_ready()
        rows=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0]);assert rows[0] and rows[1]
        tm=rows[0][0];definition=json.loads(str(leaf.interactionDefinitions[0]));height=max(p[1] for g in definition['source']['metadata']['guides'] for p in g['nodes'])*float(r.units.decodeValue('1m'))*float(r.length(tm.row1));target=tm.row4+r.Point3(height*.25,0,height*.65)
        r.WFSphere.radius=height*.1;root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();pump();edit_setup();move(target+r.Point3(height*4,0,0));pump();before=counters();samples=[]
        r.CyrusPointSuspended=True
        for k in range(5):move(target+r.Point3(height*(.15-.02*k),0,0));require_ready();samples.append({'statistics':stats(),'streams':counters()['streams']})
        after=counters();r.CyrusPointSuspended=False;r.CyrusPointSync();pump();report.update(before=before,after=after,samples=samples,source_counts=[len(x) for x in rows]);assert after['streams'][8]>before['streams'][8],report
    elif phase=='authored-fern':
        scene=ROOT/'dist/CyrusScatter-0.87.4.2-20261027/Neottopteris_Selected_Leaves_0.87.4.2.max';assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined);r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1];r.WFSphere=r.WFCollider.validSources()[0];r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
        root,leaf=r.WFRoot,r.WFGrass;leaf.interactionFoliage=1.;leaf.interactionsPrepare(leaf.validSources());root.setGroupDisplay(3);root.identificationMode=1;root.interactionsEnsure();r.CyrusPointSync();pump();require_ready();definition=json.loads(str(leaf.interactionDefinitions[-1]));report['preparation']=definition['source']['report'];assert report['preparation']['fixed_parts']>0
        p,height=frame();tm=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0];guide=max(definition['source']['metadata']['guides'],key=lambda g:g['length_m']);q=guide['nodes'][int((len(guide['nodes'])-1)*.7)];local=r.Point3(q[0]*100,-q[2]*100,q[1]*100);r.CVPoint=local;r.CVMatrix=tm;target=r.execute('CVPoint*CVMatrix')
        r.WFSphere.radius=max(.1,guide['length_m']*100*.08*float(r.length(tm.row1)));root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();pump();edit_setup();move(target+r.Point3(float(r.WFSphere.radius)*.5,0,0));pump();require_ready();report['statistics']=stats();report['audit']=json.loads(str(r.cyrusInteractionValidate(root.interactionState,4000000)[2]));assert report['audit']['passed'];frame()
    elif phase.startswith('bench-'):
        # Identical source, seed, placements and drag path; the old CPU mesh
        # producer is selected only in this disposable process for comparison.
        _,mode,count=phase.split('-');count=int(count);assert mode in ('cpu','gpu') and count in (200,1000)
        if mode=='cpu':os.environ['CYRUS_INTERACTION_CPU_PREVIEW']='1'
        else:os.environ.pop('CYRUS_INTERACTION_CPU_PREVIEW',None)
        root,leaf=r.WFRoot,r.WFGrass;root.updateMode=1;leaf.amount=count;root.refreshAll();root.interactionsEnsure();root.setGroupDisplay(3);root.identificationMode=1;r.CyrusPointSync();pump();p,height=frame();edit_setup()
        rows=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0];target=rows[len(rows)//2].row4+r.Point3(0,0,height*.65);r.CVBenchCentre=target
        r.WFSphere.radius=height*1.2;root.refreshAll();root.interactionsEnsure();r.CyrusPointSync();pump();edit_setup()
        move(target+r.Point3(height*5,0,0));pump();before=counters();samples=[]
        # Isolate the same native path used while a real mouse button is held;
        # the separately checked idle sync resumes after this bounded trace.
        r.CyrusPointSuspended=True;report['script_idle_sync_suspended_during_trace']=True
        for k in range(14):
            started=time.perf_counter();move(target+r.Point3(height*(.5-.07*k),0,0));wall=(time.perf_counter()-started)*1000;s=stats();require_ready();samples.append({'wall_update_redraw_ms':wall,'timing':json.loads(str(r.CVMoveTiming)),'statistics':s,'streams':counters()['streams']})
        after=counters();report.update(mode=mode,plant_count=count,source=str(leaf.validSources()[0].name),samples=samples,before=before,after=after)
        r.CyrusPointSuspended=False;r.CyrusPointSync();pump();require_ready()
        if mode=='gpu':assert after['streams'][1]==before['streams'][1] and after['streams'][2]-before['streams'][2]<=48*len(samples)*2 and after['streams'][7]==before['streams'][7],report
    elif phase.startswith('save'):
        os.environ.pop('CYRUS_INTERACTION_CPU_PREVIEW',None)
        scene=out/((phase[5:] if phase.startswith('save-') else 'Shared_Pose')+'_Interaction_0.87.5.max');r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot');assert r.saveMaxFile(str(scene),quiet=True)
        # Save deliberately retires transient viewport nodes. Let the owned
        # post-save path restore them before asking for presentation telemetry.
        r.CyrusPointSync();pump();require_ready();report.update(scene=str(scene),statistics=stats(),counters=counters())
    elif phase.startswith('library'):
        if phase=='library-configured':
            content=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content';catalog=content/'Library/model-catalog.json';assert catalog.is_file()
            binding=Path(str(r.CyrusRecipeScriptDirectory))/'LibraryBinding.txt';state=Path(binding.read_text(encoding='utf-8-sig').splitlines()[1]);assert state.resolve().is_relative_to(out.parent)
            managed=Path(json.loads((out/'launch.json').read_text(encoding='utf-8'))['data'])/'author'
            state.write_text('CyrusLibrary1\n'+'\n'.join([str(catalog.parent),'0.86.7',hashlib.sha256(catalog.read_bytes()).hexdigest(),hashlib.sha256((content/'content-manifest.json').read_bytes()).hexdigest(),'2024',str(managed),'cyrus-plants'])+'\n',encoding='utf-8')
        r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot');pump();r.execute('WFRoot.mainUI.slots[1].open=true;WFRoot.mainUI.bindSection WFRoot.mainUI.editors[1];WFRoot.mainUI.editors[1].flow_layersUI_recipesButton.pressed()');pump(20)
        browser=r.CyrusRecipeBrowser;assert browser!=r.undefined;report['status_text']=str(browser.panel.StatusText);report['assembly_version']=str(r.execute('((dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")).GetName()).Version.ToString()'));assert report['assembly_version']=='0.87.5.0';assert 'error' not in report['status_text'].lower() and 'exception' not in report['status_text'].lower()
        if phase=='library-configured':assert '96 individual models' in report['status_text'],report
        r.destroyDialog(browser)
    elif phase=='bake':
        audit=json.loads(str(r.cyrusInteractionValidate(r.WFRoot.interactionState,4000000)[2]));nodes=r.cyrusInteractionBake(r.WFRoot.interactionState,1);report['nodes']=[str(n.name) for n in nodes];report['triangles']=sum(int(r.getNumFaces(n.mesh)) for n in nodes);assert report['triangles']==audit['triangles'],report
        for n in nodes:r.hide(n)
        report['audit']=audit
    elif phase=='drag-before':
        edit_setup();frame();report.update(counters=counters(),statistics=stats(),transform=list(r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0].row4))
    elif phase=='drag-after':
        pump();before=json.loads((out/'runtime-drag-before.json').read_text());report.update(counters=counters(),statistics=stats(),transform=list(r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(r.WFRoot.interactionState,2))[0][0].row4));assert report['transform']!=before['transform'];require_ready()
    elif phase=='reload-saved':
        os.environ.pop('CYRUS_INTERACTION_CPU_PREVIEW',None)
        saved=json.loads((out/'runtime-save-Grass.json').read_text());assert r.loadMaxFile(saved['scene'],quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
        r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined);r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1];r.WFSphere=r.WFCollider.validSources()[0];r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
        r.WFRoot.interactionsEnsure();r.CyrusPointSync();pump();frame();require_ready();report.update(scene=saved['scene'],statistics=stats(),counters=counters());assert str(r.WFRoot.uiVersion())=='0.87.5' and int(r.WFRoot.version)==63
    else:raise ValueError(phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc())
finally:r.CyrusPointSuspended=False
(out/'runtime-history').mkdir(exist_ok=True)
(out/'runtime-history'/(phase+'-'+str(time.time_ns())+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
(out/('runtime-'+phase+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
if report['status']!='pass':raise RuntimeError(report['error'])
