"""Owned Max 2027 role, hiding, retained-budget and Edit regression fixture."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));report={}

def pump(n=4):
    for _ in range(n):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.02)
def stats():return json.loads(str(r.RKRoot.interactionsStatistics()))
def check():
    r.RKRoot.interactionsEnsure();pump()
    assert not str(r.RKRoot.interactionError),str(r.RKRoot.interactionError)
    s=stats();assert not s.get('error'),s
    assert int(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.RKOwner))[3])==2
    return s
def save(): (out/'host-regressions.json').write_text(json.dumps(report,indent=2))

try:
    assert str(r.CyrusLibraryVersion())=='0.87.6.3' and int(r.cyrusInteractionVersion())==16
    r.execute('resetMaxFile #noPrompt; units.SystemType=#Meters;units.SystemScale=1;global RKOwner,RKRoot,RKA,RKB,RKSource,RKPeer,RKStone,RKEdit')
    r.CyrusSelectionTimer.Stop()
    vertices=[];faces=[]
    for x in (-.03,.03):
        start=len(vertices)
        for ring in range(3):
            z=ring*.03
            vertices.extend((r.Point3(x,0,z),r.Point3(x-.001,.0002,z),r.Point3(x+.001,.0002,z)))
        vertices.append(r.Point3(x+.005,0,.075))
        for ring in range(2):
            a=start+3*ring;b=a+3
            faces.extend((r.Point3(a+1,a+2,b+1),r.Point3(a+2,b+2,b+1),r.Point3(a+3,a+1,b+1),r.Point3(a+3,b+1,b+3)))
        faces.extend((r.Point3(start+7,start+8,start+10),r.Point3(start+9,start+7,start+10)))
    r.RKSource=r.mesh(vertices=r.Array(*vertices),faces=r.Array(*faces),name='Two prepared blades',pos=r.Point3(1,0,0))
    r.execute('''(RKPeer=copy RKSource;RKPeer.name="Other blade source";RKPeer.pos=[2,0,0]
    RKStone=box name:"Closed proxy" width:.01 length:.01 height:.01 pos:[3,0,0]
    local surface=plane name:"Test receiver" length:.001 width:.001 lengthsegs:1 widthsegs:1
    RKOwner=AminScatterObject name:"Review fixture";RKRoot=RKOwner.baseObject;RKRoot.surfaceNodes=#(surface)
    RKRoot.newLayer();RKA=RKRoot.selectedLayer();RKA.addModelSource RKSource;RKA.amount=1
    RKRoot.newLayer();RKB=RKRoot.selectedLayer();RKB.addModelSource RKPeer;RKB.amount=1
    for leaf in #(RKA,RKB) do (leaf.interactionFoliage=1.;leaf.interactionsPrepare (leaf.validSources());leaf.interactionNeighbors=true;leaf.interactionResponse=2)
    RKRoot.updateMode=2;RKRoot.autoRender=false;RKRoot.viewportFaces=0;RKRoot.viewportNavigationFaces=0;RKRoot.setGroupDisplay 3
    RKRoot.refreshAll();RKRoot.interactionsEnsure();RKEdit=CyrusScatterEdit();addModifier RKOwner RKEdit;RKRoot.refreshAll()
    viewport.setLayout #layout_1;viewport.setType #view_top;select surface;max zoomext sel;clearSelection())
    ''')
    report['initial']=check();report['roles']=[];save()
    r.execute('RKA.interactionsSetProxy RKSource RKStone')
    for role in ('off','collider','react','off','react'):
        r.RKA.interactionReact=role=='react';r.RKA.interactionCollider=role=='collider'
        before=check()
        r.execute('cyrusEditActiveLayers RKEdit #(RKA.editLayerKey);cyrusEditCommand RKEdit 1 undefined;cyrusEditCommand RKEdit 4 (transMatrix [.2,0,0])')
        away=check()
        r.execute('cyrusEditCommand RKEdit 4 (transMatrix [-.2,0,0])')
        returned=check()
        report['roles'].append(dict(role=role,before=before,away=away,returned=returned));save()
    # Scene obstacles isolate physical hiding distances from scatter placement.
    r.RKA.interactionReact=False;r.RKA.interactionCollider=False;r.RKB.interactionNeighbors=False
    r.RKRoot.interactionSceneColliders=r.Array(r.RKStone)
    report['hiding']=[]
    for response in range(4):
        for under in (False,True):
            r.RKB.interactionResponse=response;r.RKB.interactionBendStrength=0.;r.RKB.interactionPruneAmount=0.
            r.RKB.interactionCoverRoots=True;r.RKB.interactionHideArea=2 if under else 1
            r.RKB.interactionHideMarginWU=0 if under else .30
            r.RKStone.pos=r.Point3(0,0,1) if under else r.Point3(.25,0,-.005)
            if under:r.RKStone.width=.1;r.RKStone.length=.1
            else:r.RKStone.width=.01;r.RKStone.length=.01
            r.RKRoot.interactionsChanged();s=check();assert s['hidden_roots']==2,s
            r.RKStone.pos=r.Point3(3,0,0);r.CyrusSceneColliderWatch();away=check();assert away['hidden_roots']==0,away
            report['hiding'].append(dict(response=response,under=under,covered=s['hidden_roots'],restored=away['hidden_roots']));save()
    # Draw-limit changes retain Manual placement edits and the solved result.
    r.RKB.interactionCoverRoots=False;r.RKB.interactionResponse=1;r.RKB.interactionBendStrength=1.
    r.RKB.amount=500;r.RKStone.width=.08;r.RKStone.length=.01;r.RKStone.height=.01;r.RKStone.pos=r.Point3(0,0,.04)
    r.RKRoot.refreshAll();r.RKRoot.interactionsChanged();s=check();assert s['posed']>0,s
    r.RKRoot.updateMode=1;r.RKB.amount=777;r.RKB.markInputDirty()
    epoch=int(r.RKRoot.procEpoch);generation=s['generation'];report['budgets']=[]
    for limit in (40,200,4000,0,40):
        r.RKRoot.viewportFaces=limit;r.RKRoot.viewportNavigationFaces=limit;r.RKRoot.refreshDisplay();pump();s=check()
        assert int(r.RKRoot.procEpoch)==epoch and int(r.RKB.generatedCount)==500
        assert s['generation']==generation,'Display limit unexpectedly solved contact again'
        report['budgets'].append(dict(limit=limit,epoch=epoch,generation=generation,stats=s,memory=str(r.cyrusViewportMemoryStats())));save()
    r.RKB.amount=500;r.RKB.markInputDirty();r.RKRoot.viewportFaces=0;r.RKRoot.viewportNavigationFaces=0;r.RKRoot.refreshDisplay();check()
    r.saveMaxFile(str(out/'Review_08763.max'),quiet=True)
    report['saved_scene']=str(out/'Review_08763.max');report['status']='complete'
except Exception:report.update(status='failed',error=traceback.format_exc())
save()
