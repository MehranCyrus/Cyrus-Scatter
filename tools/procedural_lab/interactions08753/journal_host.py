"""Bounded authored source commands, real standalone host Undo/Redo events.

Historical Python-wrapper diagnostic; use journal_native.ms/run_journal.py for
qualification so a Python bridge/preflight cannot supply the tested hold.

Run after the source replacement fixture. Each action writes before/after
authored evidence. Dispatch max undo and max redo separately; the check phases
read only and never author or clear history.
"""
from pathlib import Path
import hashlib,json,time,traceback
from pymxs import runtime as r

out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running'}
state=out/'journal-action-state.json'

def pump():
    for _ in range(25):r.windows.processPostedMessages();time.sleep(.02)

def authored():
    leaf=r.WFCollider
    return {'ids':list(map(str,leaf.sourceRowIDs)),
            'nodes':[int(n.handle) if r.isValidNode(n) else None for n in leaf.sources],
            'points':list(map(bool,leaf.sourcePoint)),'empty':list(map(bool,leaf.sourceEmpty)),
            'scales':list(map(float,leaf.sourceScales)),'offsets':list(map(float,leaf.sourceZOffsetsWU)),
            'definitions':list(zip(map(str,leaf.interactionSourceIDs),
                                  (hashlib.sha256(str(v).encode()).hexdigest() for v in leaf.interactionDefinitions))),
            'proxies':list(zip(map(str,leaf.interactionProxySourceIDs),
                              (int(n.handle) if r.isValidNode(n) else None for n in leaf.interactionProxyNodes))),
            'navigation':int(r.WFRoot.viewportNavigationFaces)}

def normalized(value):return json.loads(json.dumps(value))

def check_views():
    root=r.WFRoot;models=root.modelsUI;interactions=root.interactionsUI
    ids=list(map(str,r.WFCollider.sourceRowIDs))
    assert ids==list(map(str,interactions.interactionsUI_modelIDs))
    assert len(models.sourceUI_plantList.items)==len(interactions.interactionsUI_modelList.items)==len(ids)

try:
    assert int(r.cyrusSourceCommandUndoVersion())==1
    if phase.startswith('journal-action-'):
        kind=phase.removeprefix('journal-action-')
        # Source fixture setup already binds the page. Re-selecting nodes and
        # command-panel modes here would introduce unrelated Max tool holds.
        root=r.WFRoot
        r.AuditModels=root.modelsUI;r.AuditInteractions=root.interactionsUI
        r.clearUndoBuffer();assert not r.theHold.Holding()
        before=normalized(authored())
        if kind=='empty':r.execute('AuditModels.sourceUI_addEmpty.pressed()')
        elif kind=='point':r.execute('AuditModels.sourceUI_addPoint.pressed()')
        elif kind=='model':r.execute('AuditModels.sourceUI_addPlant.picked AuditStone')
        elif kind=='remove':r.execute('AuditModels.sourceUI_plantList.selection=#{1};AuditModels.sourceUI_removePlant.pressed()')
        elif kind=='scale':r.execute('AuditModels.sourceUI_plantList.selection=#{1};AuditModels.sourceUI_sourceScaleSpin.changed 0.731')
        elif kind=='offset':r.execute('WFCollider.assignSourceTransform #(1) 1.2345')
        elif kind=='fast':
            root.displayUISlot.open=True;root.mainUI.bindSection(root.displayUI)
            r.execute('WFRoot.displayUI.flow_previewUI_fastNavigationButton.pressed()')
        else:raise ValueError(kind)
        pump();after=normalized(authored());check_views()
        assert before!=after,(kind,before,after)
        assert not r.theHold.Holding()
        report.update(kind=kind,before=before,after=after,undo=list(map(str,r.theHold.getUndoNames())))
        assert report['undo'],report
        state.write_text(json.dumps(report,indent=2),encoding='utf-8')
    elif phase in ('journal-undo-check','journal-redo-check'):
        expected=json.loads(state.read_text());pump();got=normalized(authored());check_views()
        target=expected['before' if phase=='journal-undo-check' else 'after']
        assert got==target,(got,target)
        assert not r.theHold.Holding() and not r.theHold.IsSuspended()
        report.update(kind=expected['kind'],authored=got,undo=list(map(str,r.theHold.getUndoNames())),redo=list(map(str,r.theHold.getRedoNames())))
    elif phase=='journal-cancel':
        before=normalized(authored());suspended=bool(r.CyrusPointSuspended)
        r.execute('local command=WFCollider.sourceCommandBegin "Owned cancelled source" 2;try(WFCollider.sourceScales[1]=0.123;cyrusSourceCommandSeal undefined)catch(WFCollider.sourceCommandCancel command)')
        pump();assert normalized(authored())==before and bool(r.CyrusPointSuspended)==suspended
        assert not r.theHold.Holding() and not r.theHold.IsSuspended();report['restored']=before
    elif phase=='journal-nested-cancel':
        before=normalized(authored());suspended=bool(r.CyrusPointSuspended)
        r.execute('theHold.Begin();try(WFCollider.addEmptySource();theHold.Cancel())catch(theHold.Cancel();throw())')
        pump();assert normalized(authored())==before and bool(r.CyrusPointSuspended)==suspended
        assert not r.theHold.Holding();report['restored']=before
    else:raise ValueError(phase)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:
    (out/'journal-history').mkdir(exist_ok=True)
    (out/'journal-history'/(phase+'-'+str(time.time_ns())+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
    (out/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
