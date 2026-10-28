"""Source membership regressions through real generated UI handlers in an owned host.

Run after inspect_host initialized WFOwner/WFRoot/WFGrass/WFCollider. The root
campaign owns Max, the copied scene and the matched final payload. This script
never installs a profile or writes the artist input scene.

Run placeholder phases while the small Collider fixture is healthy, before
sources-replacement-fixture. The replacement fixture disables that layer's role
and enrolls only two grass models, two closed boxes and one replacement stone.
Run sources-replace-model, standalone `max undo`, sources-replace-undo-check,
standalone `max redo`, sources-replace-redo-check without intervening authoring.
Undo/Redo must be dispatched as host events, never inside this Python scope.
"""
from pathlib import Path
import hashlib,json,sys,time,traceback
from pymxs import runtime as r
helper_dir=str(Path(__file__).resolve().parent)
if helper_dir not in sys.path:sys.path.insert(0,helper_dir)
from fixture_assets import prepare_owned_fixture

out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running','scope':'Owned Max 2027 source membership and generated UI actions'}
def pump(n=18):
    for _ in range(n):r.windows.processPostedMessages();r.completeRedraw();time.sleep(.02)
def bind():
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    pump()
    panel=r.WFRoot.mainUI;panel.selectLayerView(r.WFCollider)
    r.WFRoot.modelsUISlot.open=True;r.WFRoot.interactionsUISlot.open=True
    panel.bindSection(r.WFRoot.modelsUI);panel.bindSection(r.WFRoot.interactionsUI)
    r.AuditModels=r.WFRoot.modelsUI;r.AuditInteractions=r.WFRoot.interactionsUI
def snapshot(rebind=True):
    if rebind:bind()
    r.AuditModels=r.WFRoot.modelsUI;r.AuditInteractions=r.WFRoot.interactionsUI
    leaf=r.WFCollider
    return {'ids':list(map(str,leaf.sourceRowIDs)),
            'nodes':[str(n.name) if r.isValidNode(n) else '<missing>' for n in leaf.sources],
            'interaction_ids':list(map(str,r.AuditInteractions.interactionsUI_modelIDs)),
            'interaction_items':list(map(str,r.AuditInteractions.interactionsUI_modelList.items)),
            'model_items':list(map(str,r.AuditModels.sourceUI_plantList.items)),
            'status':str(r.WFRoot.interactionsStatus()),'epoch':int(r.WFRoot.procEpoch)}
def assert_shared(rebind=True):
    got=snapshot(rebind);assert got['ids']==got['interaction_ids'],got
    assert len(got['model_items'])==len(got['interaction_items'])==len(got['nodes']),got
    return got
def publication_snapshot():
    root=r.WFRoot;owners=list(root.procPublishedOwners);sources=list(root.procPublishedSources)
    def labels(nodes):
        return [str(n.name) if r.isValidNode(n) else str(n) if isinstance(n,int) else '<missing>' for n in nodes]
    layers=[]
    for leaf in root.layerObjects:
        slot=next((i for i,owner in enumerate(owners) if owner==leaf),None)
        published=list(sources[slot]) if slot is not None and slot<len(sources) else []
        layers.append({'id':str(leaf.layerID),'amount':int(leaf.amount),'generated':int(leaf.generatedCount),
                       'preview_error':str(leaf.previewError),'authored_sources':labels(leaf.validSources()),
                       'published_sources':labels(published)})
    return {'membership_pending':bool(root.interactionsMembershipPending()),'epoch':int(root.procEpoch),
            'update_mode':int(root.updateMode),'interaction_error':str(root.interactionError),'layers':layers}
def source_bindings():
    leaf=r.WFCollider
    ids=list(map(str,leaf.sourceRowIDs));definition_ids=list(map(str,leaf.interactionSourceIDs))
    definitions=list(map(str,leaf.interactionDefinitions));proxy_ids=list(map(str,leaf.interactionProxySourceIDs))
    proxies=list(leaf.interactionProxyNodes)
    assert len(definition_ids)==len(definitions) and len(proxy_ids)==len(proxies)
    return {'ids':ids,'nodes':[int(n.handle) if r.isValidNode(n) else None for n in leaf.sources],
            'definitions':dict(zip(definition_ids,(hashlib.sha256(v.encode('utf-8')).hexdigest() for v in definitions))),
            'proxies':dict(zip(proxy_ids,(int(n.handle) if r.isValidNode(n) else None for n in proxies))),
            'weights':list(map(float,leaf.sourceWeights)),'scales':list(map(float,leaf.sourceScales)),
            'z_offsets':list(map(float,leaf.sourceZOffsetsWU)),
            'points':[bool(leaf.isPointSource(i+1)) for i in range(len(ids))],
            'empty':[bool(leaf.isEmptySource(i+1)) for i in range(len(ids))],
            'definition_revision':int(leaf.interactionDefinitionRevision),'collider_mode':int(leaf.interactionColliderMode),
            'collider':bool(leaf.interactionCollider),'react':bool(leaf.interactionReact)}
def replacement_fixture():
    return json.loads((out/'sources-replacement-state.json').read_text(encoding='utf-8'))
def assert_replacement(fixture):
    current=source_bindings();expected=fixture['before'];target=fixture['target_id'];untouched=fixture['untouched_id']
    assert current['ids']==expected['ids'],current
    target_row=current['ids'].index(target);other_row=current['ids'].index(untouched)
    assert current['nodes'][target_row]==fixture['replacement_handle'],current
    assert current['nodes'][other_row]==expected['nodes'][other_row],current
    assert target not in current['definitions'] and target not in current['proxies'],current
    assert current['definitions']=={k:v for k,v in expected['definitions'].items() if k!=target},current
    assert current['proxies']=={k:v for k,v in expected['proxies'].items() if k!=target},current
    for key in ('weights','scales','z_offsets','points','empty','definition_revision','collider_mode','collider','react'):
        assert current[key]==expected[key],(key,current,expected)
    return current
try:
    if phase=='sources-undo-control':
        r.execute('global AuditUndoProbe;undo "Owned Undo control" on (AuditUndoProbe=box name:"Owned Undo control")')
        report['handle']=int(r.AuditUndoProbe.handle)
    elif phase=='sources-undo-inspect':
        report.update(undo=list(map(str,r.theHold.getUndoNames())),redo=list(map(str,r.theHold.getRedoNames())),bindings=source_bindings(),
                      holding=bool(r.theHold.Holding()),suspended=bool(r.theHold.IsSuspended()),super_level=int(r.theHold.SuperLevel()),max_levels=int(r.theHold.getMaxUndoLevels()))
    elif phase=='sources-setup':
        prepare_owned_fixture(r,Path(__file__).resolve().parents[3],report,r.WFRoot)
        r.execute('global AuditModels,AuditInteractions,AuditStone,AuditOld,AuditMissing,AuditMissingID,AuditReplacement')
        r.WFRoot.updateMode=2;r.WFGrass.amount=10;r.WFCollider.amount=1
        nodes=[n for n in r.objects if r.isValidNode(n) and 'stone' in str(n.name).lower() and r.WFCollider.usableSource(n)]
        assert nodes,'Fixture has no stone source';r.AuditStone=nodes[0]
        r.WFRoot.refreshAll();r.CyrusPointSync();pump();bind();report['sources']=assert_shared()
    elif phase=='sources-remove-models':
        bind();count=len(r.WFCollider.sources)
        r.execute('AuditModels.sourceUI_plantList.selection=#{1..'+str(count)+'};AuditModels.sourceUI_removePlant.pressed()')
        pump();report['sources']=assert_shared();assert len(r.WFCollider.sources)==0 and not str(r.WFRoot.interactionError),report
    elif phase=='sources-add-models':
        bind();r.execute('AuditModels.sourceUI_addPlant.picked AuditStone');pump()
        report['sources']=assert_shared();assert len(r.WFCollider.sources)==1 and r.WFCollider.sources[0]==r.AuditStone
        assert r.AuditInteractions.interactionsUI_currentSource()==r.AuditStone and not str(r.WFRoot.interactionError),report
    elif phase=='sources-missing-row':
        bind();r.AuditMissing=r.copy(r.AuditStone);r.AuditMissing.name='Owned_missing_source_row'
        r.execute('AuditModels.sourceUI_addPlant.picked AuditMissing');pump();r.AuditMissingID=str(r.WFCollider.sourceRowIDs[-1])
        r.delete(r.AuditMissing);pump(65);bind();ids=list(map(str,r.WFCollider.sourceRowIDs));row=ids.index(str(r.AuditMissingID))+1
        r.AuditInteractions.interactionsUI_modelList.selection=row;r.AuditInteractions.interactionsUI_sourceState()
        assert r.AuditInteractions.interactionsUI_sourceRemoveButton.enabled
        assert r.AuditInteractions.interactionsUI_currentSource()==r.undefined
        r.execute('AuditInteractions.interactionsUI_sourceRemoveButton.pressed()');pump();report['sources']=assert_shared()
        assert str(r.AuditMissingID) not in report['sources']['ids'] and len(r.WFCollider.sources)==1
    elif phase=='sources-stale-selection':
        bind();r.AuditInteractions.interactionsUI_modelList.selection=1
        previous=str(r.WFCollider.sourceRowIDs[0]);r.WFCollider.removeModelSources(r.Array(1))
        r.AuditReplacement=r.copy(r.AuditStone);r.AuditReplacement.name='Owned_race_replacement';r.WFCollider.addModelSource(r.AuditReplacement)
        # Do not pump the deferred bind: the Interactions view still names the
        # removed ID. X must refresh it without removing the successor row.
        r.execute('AuditInteractions.interactionsUI_sourceRemoveButton.pressed()');pump();report['sources']=assert_shared()
        assert len(r.WFCollider.sources)==1 and r.WFCollider.sources[0]==r.AuditReplacement
        assert previous not in report['sources']['ids']
    elif phase=='sources-manual':
        bind();r.WFRoot.updateMode=1;before_epoch=int(r.WFRoot.procEpoch)
        previous_state=r.WFRoot.interactionState;published=int(r.WFGrass.generatedCount)
        r.WFGrass.amount=published+3
        r.execute('AuditModels.sourceUI_plantList.selection=#{1};AuditModels.sourceUI_removePlant.pressed()');pump();bind()
        r.execute('AuditModels.sourceUI_addPlant.picked AuditStone');pump();bind()
        assert r.WFRoot.interactionsEnsure()==previous_state and int(r.WFRoot.procEpoch)==before_epoch
        assert int(r.WFGrass.generatedCount)==published and int(r.WFGrass.amount)==published+3
        assert bool(r.WFRoot.interactionsMembershipPending()) and 'Update scatter' in str(r.WFRoot.interactionsStatus())
        report['pending']=assert_shared();r.WFRoot.refreshAll();r.CyrusPointSync();pump()
        report['after_update']=publication_snapshot();report['updated']=assert_shared()
        assert not r.WFRoot.interactionsMembershipPending() and int(r.WFGrass.generatedCount)==published+3,report
        assert not str(r.WFRoot.interactionError),report
    elif phase=='sources-manual-observe':
        report['publication']=publication_snapshot();report['sources']=assert_shared()
    elif phase in ('sources-placeholder-empty','sources-placeholder-point'):
        r.WFRoot.updateMode=2;r.WFRoot.refreshAll();r.CyrusPointSync();pump()
        before=assert_shared();assert not str(r.WFRoot.interactionError),publication_snapshot()
        roles=(bool(r.WFCollider.interactionCollider),bool(r.WFCollider.interactionReact))
        point=phase.endswith('-point');control='sourceUI_addPoint' if point else 'sourceUI_addEmpty'
        r.execute('AuditModels.'+control+'.pressed()');pump();added=assert_shared()
        new_ids=[source_id for source_id in added['ids'] if source_id not in before['ids']]
        assert len(new_ids)==1 and len(added['ids'])==len(before['ids'])+1,added
        row=added['ids'].index(new_ids[0])+1
        assert bool(r.WFCollider.isEmptySource(row)) and bool(r.WFCollider.isPointSource(row))==point
        r.AuditInteractions.interactionsUI_modelList.selection=row;r.AuditInteractions.interactionsUI_sourceState()
        assert r.AuditInteractions.interactionsUI_sourceRemoveButton.enabled
        assert r.AuditInteractions.interactionsUI_currentSource()==r.undefined
        assert ('Point' if point else 'Empty') in added['interaction_items'][row-1],added
        report['added']=added;report['added_publication']=publication_snapshot()
        # A Point/Empty row has no contact mesh. Regardless of whether Live
        # retains that unsupported successor, its authored row must stay usable
        # and X must remove exactly that identity from both source views.
        r.execute('AuditInteractions.interactionsUI_sourceRemoveButton.pressed()');pump()
        report['removed']=assert_shared();report['removed_publication']=publication_snapshot()
        assert report['removed']['ids']==before['ids'] and report['removed']['nodes']==before['nodes'],report
        assert roles==(bool(r.WFCollider.interactionCollider),bool(r.WFCollider.interactionReact))
        assert not str(r.WFRoot.interactionError),report
    elif phase=='sources-replacement-fixture':
        r.execute('global AuditPreparedA,AuditPreparedB,AuditProxyA,AuditProxyB,AuditReplacement')
        r.WFRoot.updateMode=2;r.WFGrass.amount=10;r.WFCollider.amount=1
        # The invalidation/Undo case owns an inactive layer: an intentionally
        # incomplete custom-proxy assignment cannot launch a contact solve.
        r.WFCollider.interactionCollider=False;r.WFCollider.interactionReact=False
        if len(r.WFCollider.sources):r.WFCollider.removeModelSources(r.Array(*range(1,len(r.WFCollider.sources)+1)))
        plant=next(n for n in r.WFGrass.validSources() if r.isValidNode(n))
        r.AuditPreparedA=r.copy(plant);r.AuditPreparedA.name='Owned_prepared_source_A'
        r.AuditPreparedB=r.copy(plant);r.AuditPreparedB.name='Owned_prepared_source_B'
        r.AuditReplacement=r.copy(r.AuditStone);r.AuditReplacement.name='Owned_source_replacement_stone'
        assert r.WFCollider.addModelSource(r.AuditPreparedA) and r.WFCollider.addModelSource(r.AuditPreparedB)
        for setting in ('interactionMinimumM','interactionFoliage','interactionConnectionM'):
            setattr(r.WFCollider,setting,getattr(r.WFGrass,setting))
        r.WFCollider.interactionUnitsPending=False
        r.execute('WFCollider.interactionsPrepare #(AuditPreparedA,AuditPreparedB) rebuild:true enable:false')
        size=float(r.units.decodeValue('10cm'))
        r.AuditProxyA=r.box(name='Owned_binding_proxy_A',length=size,width=size,height=size)
        r.AuditProxyB=r.box(name='Owned_binding_proxy_B',length=size,width=size,height=size)
        r.AuditProxyA.transform=r.AuditPreparedA.transform;r.AuditProxyB.transform=r.AuditPreparedB.transform
        r.WFCollider.interactionsSetProxy(r.AuditPreparedA,r.AuditProxyA)
        r.WFCollider.interactionsSetProxy(r.AuditPreparedB,r.AuditProxyB)
        r.WFRoot.refreshAll();r.CyrusPointSync();pump();report['sources']=assert_shared()
        before=source_bindings();assert len(before['ids'])==len(before['definitions'])==len(before['proxies'])==2,before
        fixture={'before':before,'target_id':before['ids'][0],'untouched_id':before['ids'][1],
                 'replacement_handle':int(r.AuditReplacement.handle),
                 'scope':'Two actual prepared grass source definitions and separately validated closed proxies; layer role off, binding/Undo only'}
        (out/'sources-replacement-state.json').write_text(json.dumps(fixture,indent=2),encoding='utf-8')
        report['fixture']=fixture
    elif phase=='sources-replace-model':
        fixture=replacement_fixture();bind();assert source_bindings()==fixture['before'],source_bindings()
        r.AuditReplacement=r.maxOps.getNodeByHandle(fixture['replacement_handle']);assert r.isValidNode(r.AuditReplacement)
        row=fixture['before']['ids'].index(fixture['target_id'])+1
        # The disposable setup and selection commands have their own history.
        # Isolate the artist command before testing one-step Undo/Redo.
        r.clearUndoBuffer()
        # The product command owns/joins its explicit native journal. An extra
        # Python undo context would test another hold boundary instead of the
        # one exercised by an artist using the picker.
        r.execute('AuditModels.sourceUI_plantList.selection=#{'+str(row)+'};AuditModels.sourceUI_replacePoint.picked AuditReplacement')
        report['undo_after_action']=list(map(str,r.theHold.getUndoNames()))
        pump();report['sources']=assert_shared(False);report['bindings']=assert_replacement(fixture)
        report['undo_after_pump']=list(map(str,r.theHold.getUndoNames()))
        report['next_event']='Dispatch standalone max undo, then sources-replace-undo-check; do not author anything between events.'
    elif phase=='sources-picker-ready':
        fixture=replacement_fixture();bind();assert source_bindings()==fixture['before']
        r.AuditReplacement=r.maxOps.getNodeByHandle(fixture['replacement_handle'])
        for node in r.objects:
            if node!=r.WFOwner and node!=r.AuditReplacement:r.hide(node)
        r.unhide(r.AuditReplacement);r.unhide(r.WFOwner)
        bounds=r.nodeGetBoundingBox(r.AuditReplacement,r.matrix3(1));centre=(bounds[0]+bounds[1])*.5
        extent=max(float(bounds[1][i]-bounds[0][i]) for i in range(3));eye=centre+r.Point3(extent*1.2,-extent*1.8,extent)
        back=r.normalize(eye-centre);right=r.normalize(r.cross(r.Point3(0,0,1),back));up=r.cross(back,right)
        r.viewport.setType(r.Name('view_persp_user'));r.viewport.setFOV(45);r.viewport.setTM(r.inverse(r.matrix3(right,up,back,eye)))
        r.execute('AuditModels.sourceUI_plantList.selection=#{1};AuditModels.sourceUI_showSelectedColor()')
        r.clearUndoBuffer();pump();report['fixture']=fixture
    elif phase=='sources-picker-check':
        report['bindings']=assert_replacement(replacement_fixture());report['sources']=assert_shared(False)
        report['undo']=list(map(str,r.theHold.getUndoNames()))
    elif phase=='sources-replace-undo-check':
        fixture=replacement_fixture();pump();report['sources']=assert_shared(False);report['bindings']=source_bindings()
        assert report['bindings']==fixture['before'],report
        report['next_event']='Dispatch standalone max redo, then sources-replace-redo-check; do not author anything between events.'
    elif phase=='sources-replace-redo-check':
        fixture=replacement_fixture();pump();report['sources']=assert_shared(False);report['bindings']=assert_replacement(fixture)
    else:raise ValueError(phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:
    (out/'source-workflow-history').mkdir(exist_ok=True)
    (out/'source-workflow-history'/(phase+'-'+str(time.time_ns())+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
    (out/(phase+'.json')).write_text(json.dumps(report,indent=2,default=str),encoding='utf-8')
