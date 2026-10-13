"""Actual SDK realization failure, complete production fallback and recovery."""
from pathlib import Path
import hashlib
import json
import traceback
import uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
report={'checks':[], 'cases':[], 'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'launch':json.loads((OUT/'launch.json').read_text())}
receipt=OUT/('gpu-failure-'+uuid.uuid4().hex+'.json')


def save(): receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(ok,label):
    report['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def ms(code):return r.execute('(\n'+code+'\n)')
def redraw():ms('for i=1 to 6 do (completeRedraw();windows.processPostedMessages();sleep .05)')
def memory():return list(map(int,r.cyrusPreviewResourceStats()))
def fallback():return list(map(int,r.cyrusPreviewFallbackStats()))
def signature(root):return [str(r.cyrusEditFingerprint(rows,'failure')) for rows in root.groupSnapshotRows]


try:
    check(r.cyrusOwnedPreviewFault is not None,'Explicit NEVER SHIP fault build is loaded')
    r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest();r.fileIn(str(script))
    ms('''
global FaultNode=AminScatterObject name:"GPU failure publication"
global FaultRoot=FaultNode.baseObject
FaultRoot.updateMode=1;FaultRoot.autoRender=false
global FaultSources=#(box width:8 length:8 height:12 pos:[400,0,0],box width:6 length:6 height:18 pos:[420,0,0])
local receiver=plane width:120 length:120
for i=1 to 3 do (
 FaultRoot.newLayer();local leaf=FaultRoot.selectedLayer()
 FaultRoot.setLayerSurfaces leaf #(receiver)
 leaf.sources=FaultSources;leaf.amount=40
)
FaultRoot.setGroupDisplay 4;FaultRoot.evaluateProcedural();CyrusViewportRedraw()
hideByCategory.helpers=false;viewport.setType #view_top
viewport.ZoomToBounds false [-80,-80,-10] [80,80,40]
''')
    redraw();root=r.FaultRoot;owner=r.CyrusPointOwner(r.FaultNode)
    check(int(r.cyrusRetainedStats(owner)[11])==1,'Complete initial generation realizes in the actual viewport')
    live_caches=[leaf.cachedPoints for leaf in root.layerObjects]
    ms('CyrusPointBeforeScene();CyrusPointAfterScene();CyrusViewportRedraw()');redraw()
    check(all(leaf.cachedPoints==cache for leaf,cache in zip(root.layerObjects,live_caches)),
          'An aborted scene transition preserves display caches on still-live controllers')
    owner=r.CyrusPointOwner(r.FaultNode)
    live_caches=[]
    report['memory_initial']=memory()
    for stage,mode,edit in ((1,4,'palette'),(2,4,'placements'),(3,3,'palette'),(4,3,'placements')):
        r.cyrusOwnedPreviewFault(0,0)
        root.setGroupDisplay(mode);r.CyrusViewportRedraw();redraw()
        check(int(r.cyrusRetainedStats(owner)[11])==1,f'Stage {stage}: pre-failure generation is ready')
        before=fallback();gpu_before=list(map(int,list(r.cyrusRetainedStreamStats())))
        old_caches=[leaf.cachedPoints for leaf in root.layerObjects]
        old_colors=[str(r.aminScatterPreviewPoints(cache)) if mode==4 else str(r.cyrusPreviewTriangles(cache,1)) for cache in old_caches]
        r.cyrusOwnedPreviewFault(stage,2)
        if edit=='palette':
            ms('FaultRoot.layerObjects[1].setSourceIDColor #{1,2} (if (FaultRoot.layerObjects[1].sourceIDColor 1)==green then red else green);FaultRoot.refreshIdentification()')
        else:
            root.layerObjects[0].amount+=1;root.evaluateProcedural();r.CyrusViewportRedraw()
        published=signature(root);epoch=int(root.procEpoch)
        redraw()
        after=fallback();native=list(r.cyrusRetainedStats(owner));resources=memory()
        case={'stage':stage,'mode':mode,'edit':edit,'before_fallback':before,'after_fallback':after,
              'native':[str(x) for x in native],'resources':resources,'gpu_before':gpu_before,
              'gpu_after':list(map(int,list(r.cyrusRetainedStreamStats())))}
        report['cases'].append(case);save()
        check(int(native[11])==2,f'Stage {stage}: later-group SDK failure is observable')
        expected=sum(int(r.aminScatterPreviewCount(leaf.cachedPoints)) if mode==4 else int(r.cyrusPreviewFaces(leaf.cachedPoints)) for leaf in root.layerObjects)
        check(after[1]>before[1] and after[2 if mode==4 else 3]-before[2 if mode==4 else 3]>=expected,
              f'Stage {stage}: the production redraw path draws the complete published CPU fallback')
        check(signature(root)==published and int(root.procEpoch)==epoch,
              f'Stage {stage}: fallback and redraw do not mutate placements or publish another epoch')
        check(old_colors==[str(r.aminScatterPreviewPoints(cache)) if mode==4 else str(r.cyrusPreviewTriangles(cache,1)) for cache in old_caches],
              f'Stage {stage}: prior CPU geometry and palette stay immutable')
        check(resources[1]<=resources[3] and resources[2]<=resources[3] and resources[4]<=resources[6] and resources[5]<=resources[6],
              f'Stage {stage}: old, staged, fallback and failed reservations stay within process admission')
        r.cyrusOwnedPreviewFault(0,0);r.CyrusViewportRedraw();redraw()
        check(int(r.cyrusRetainedStats(owner)[11])==1 and signature(root)==published and int(root.procEpoch)==epoch,
              f'Stage {stage}: same-input retry restores GPU display without another placement solve')
    ms('''
global FaultPath=rectangle width:60 length:60
for leaf in FaultRoot.layerObjects do (
 leaf.diversityMode=3;leaf.addStroke FaultPath;leaf.patternWidths[1]=30.
 leaf.setStrokeSelection 1 2 FaultSources
 leaf.fieldFalloff=true;leaf.fieldBoundaries=true;leaf.fieldSamples=250
 leaf.sourceRadiiWU=#(2.,3.);leaf.sourceShowRadius=#(true,true)
)
FaultRoot.setGroupDisplay 4;FaultRoot.evaluateProcedural();CyrusViewportRedraw()
''');redraw()
    for stage in (1,2):
        check(int(r.cyrusRetainedStats(owner)[11])==1,f'Field stage {stage}: complete integrated generation is ready')
        old_inspection=[leaf.inspectionCache for leaf in root.layerObjects]
        old_field=[str(r.cyrusFieldPreviewInfo(leaf.procFieldCache,64)) for leaf in root.layerObjects]
        published=signature(root);epoch=int(root.procEpoch);before=fallback()
        r.cyrusOwnedPreviewFault(stage,2)
        root.layerObjects[0].strokeStrengths= r.Array(.7 if stage==1 else .4)
        root.refreshDisplay();r.CyrusViewportRedraw();redraw()
        expected=sum(len(r.aminScatterPreviewPoints(leaf.cachedPoints))+len(r.aminScatterPreviewPoints(leaf.inspectionCache)) for leaf in root.layerObjects)
        after=fallback();resources=memory()
        report['cases'].append({'stage':stage,'mode':'integrated-field','before_fallback':before,'after_fallback':after,'expected_vertices':expected,'resources':resources});save()
        check(int(r.cyrusRetainedStats(owner)[11])==2 and after[2]-before[2]>=expected,
              f'Field stage {stage}: later-group GPU failure draws all published plants and complete inspection bundles through fallback')
        check(signature(root)==published and int(root.procEpoch)==epoch and 'Pending field' in str(root.layerObjects[0].procFieldStatus),
              f'Field stage {stage}: display failure leaves placements/radii epoch frozen and pending field labeled')
        check(old_field==[str(r.cyrusFieldPreviewInfo(cache,64)) for cache in old_inspection],
              f'Field stage {stage}: previous combined caches retain their immutable field evidence')
        check(resources[1]<=resources[3] and resources[2]<=resources[3],f'Field stage {stage}: concurrent old, staged and fallback payloads stay admitted')
        r.cyrusOwnedPreviewFault(0,0);r.CyrusViewportRedraw();redraw()
        check(int(r.cyrusRetainedStats(owner)[11])==1 and signature(root)==published and int(root.procEpoch)==epoch,
              f'Field stage {stage}: identical-input GPU retry recovers without a placement solve')
    old_inspection=[]
    # GC keeps cache lifetimes explicit. Release scene/global fixture references;
    # verify process reservations return rather than merely dropping GPU counters.
    old_caches=[];root=None;owner=None;r.resetMaxFile(r.Name('noPrompt'))
    ms('FaultNode=undefined;FaultRoot=undefined;FaultSources=undefined;FaultPath=undefined;CyrusPointClear();gc light:false')
    redraw();report['memory_released']=memory()
    check(report['memory_released'][1]<report['memory_initial'][1] and report['memory_released'][4]<report['memory_initial'][4]+1,
          'Releasing the owned scene and caches releases the retained resource reservations')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:
    try:r.cyrusOwnedPreviewFault(0,0)
    except Exception:pass
    save()
if not report['passed']:raise RuntimeError(report['error'])
