"""Read a copied artist fixture in a verified disposable Max profile."""
from pathlib import Path
import json,sys,time,traceback
from pymxs import runtime as r
helper_dir=str(Path(__file__).resolve().parent)
if helper_dir not in sys.path:sys.path.insert(0,helper_dir)
from fixture_assets import load_owned_fixture
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));phase=str(r.CVProfileCase)
report={'phase':phase,'status':'running'}
def names(nodes):return [str(n.name) if r.isValidNode(n) else '<missing>' for n in nodes]
def vec(v):return [float(v.x),float(v.y),float(v.z)]
try:
    if phase=='inspect':
        scene=ROOT/'build/interactions08753-20261028-01/fixtures/New-Plants-22-input.max'
        load_owned_fixture(r,scene,ROOT,report)
        r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFSphere,WFEdit,WFSection;global CVPoint,CVMatrix,CVTarget,CVCurrent,CVHeight')
        r.WFOwner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
        r.WFRoot=r.WFOwner.baseObject;r.WFGrass=r.WFRoot.layerObjects[0];r.WFCollider=r.WFRoot.layerObjects[1]
        r.WFEdit=next(m for m in r.WFOwner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
        report['units']={'type':str(r.units.SystemType),'scale':float(r.units.SystemScale),'metres_per_unit':1/float(r.units.decodeValue('1m'))}
        report['nodes']=[{'name':str(n.name),'class':str(r.classOf(n.baseObject)),'scale':vec(n.scale),'position':vec(n.pos)} for n in r.objects if 'stone' in str(n.name).lower() or 'sphere' in str(n.name).lower()]
        report['layers']=[]
        for item in r.WFRoot.layerObjects:
            entry={'name':str(item.layerID),'sources':names(item.sources),'valid':names(item.validSources()),'source_ids':list(map(str,item.sourceRowIDs)),
                   'scale':list(item.sourceScales),'collider':bool(item.interactionCollider),'react':bool(item.interactionReact),'amount':int(item.amount),
                   'generated':int(item.generatedCount),'preview_error':str(item.previewError),'minimum':float(item.interactionMinimumM),'foliage':float(item.interactionFoliage)}
            report['layers'].append(entry)
        report['root_error']=str(r.WFRoot.interactionError)
        (out/'window-identity.json').write_text(json.dumps({'hwnd':int(r.windows.getMAXHWND())}),encoding='utf-8')
    elif phase=='reproduce-update':
        started=time.perf_counter();error=''
        try:r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
        except Exception as e:error=str(e)
        report.update(seconds=time.perf_counter()-started,error=error,root_error=str(r.WFRoot.interactionError),layer_errors=[str(x.previewError) for x in r.WFRoot.layerObjects])
        try:report['statistics']=json.loads(str(r.WFRoot.interactionsStatistics()))
        except Exception as e:report['statistics_error']=str(e)
    report['status']='pass'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:
    (out/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
