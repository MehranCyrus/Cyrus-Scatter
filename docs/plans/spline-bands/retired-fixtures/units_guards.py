"""Qualify schema migration and the existing bound Paint/Edit rescale guard."""
from pathlib import Path
import json
import traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-'):
    raise RuntimeError('Owned foundation host required')
report = {'assertions': [], 'errors': []}

def write(): (OUT/'units-guards-results.json').write_text(json.dumps(report, indent=2)+'\n')
def check(ok, label):
    report['assertions'].append({'passed': bool(ok), 'label': label}); write()
    if not ok: raise AssertionError(label)
def arr(values): return r.Array(*values)
def root(): return r.getNodeByName('Bound units').baseObject
def fingerprint(): return [str(r.cyrusEditFingerprint(rows, 'units-guard')) for rows in root().groupSnapshotRows]
def history():
    stats=r.cyrusBrushStats(root().layerObjects[1].paintAreas[0].paintDocument)
    return [int(stats[1]), int(stats[2])]

try:
    r.CyrusStopBrush(); r.resetMaxFile(r.Name('noPrompt'))
    r.fileIn(str(OUT/'scripts/schema55.ms'))
    r.units.SystemType = r.Name('Inches'); r.units.SystemScale = 1
    surface = r.plane(width=200., length=200., widthsegs=4, lengthsegs=4)
    model = r.box(width=1., length=1., height=2., pos=r.Point3(500.,0.,0.)); r.hide(model)
    node = r.AminScatterObject(name='Bound units'); obj=node.baseObject
    obj.updateMode=1; obj.autoRender=False
    for i in range(2):
        obj.newLayer(); leaf=obj.selectedLayer()
        obj.setLayerSurfaces(leaf,arr([surface])); leaf.sources=arr([model]); leaf.amount=100
        # Match the authored UI's completed source row, including its saved color.
        # A raw sources-only assignment otherwise normalizes colors on reload.
        leaf.syncColors(); leaf.ensureSourceRows()
    painted=obj.layerObjects[1]; area=obj.addPaintArea(painted,target=surface)
    r.cyrusBrushSettings(area.paintDocument,55.,False)
    check(r.cyrusBrushDab(area.paintDocument,r.Point3(0,0,200),r.Point3(0,0,-1),True),'Schema 55 painted boundary created')
    modifier=r.CyrusScatterEdit(); r.addModifier(node,modifier); obj.evaluateProcedural()
    r.cyrusEditCommand(modifier,1,r.Matrix3(1)); r.cyrusEditCommand(modifier,4,r.transMatrix(r.Point3(0,0,2)))
    obj.evaluateProcedural(); obj.layerObjects[0].procSelectedRadius(1,3.); obj.evaluateProcedural()
    before=fingerprint(); strokes=history(); ids=list(map(str,obj.layerObjects[0].procRadiusIDs))
    check(len(ids)>0 and all(len(rows)>0 for rows in obj.groupSnapshotRows),'Edited/radius and painted populations are nonempty')
    scene=OUT/'schema55-bound-units.max'; r.saveMaxFile(str(scene),quiet=True)
    r.resetMaxFile(r.Name('noPrompt')); r.fileIn(str(OUT/'scripts/schema56.ms'))
    r.loadMaxFile(str(scene),quiet=True,useFileUnits=True); root().evaluateProcedural()
    check(fingerprint()==before,'Same-unit migration preserves edited matrices and painted identities')
    check(history()==strokes and list(map(str,root().layerObjects[0].procRadiusIDs))==ids,'Same-unit migration retains contour counts and bound radius IDs')
    check(max(root().procPublishedRadii[0])==3.,'Migrated absolute overrides reach the actual radius calculation')
    # This is deliberately a denial test, not an assertion of automatic native
    # document conversion: these bindings also describe receiver geometry.
    r.resetMaxFile(r.Name('noPrompt')); r.units.SystemType=r.Name('Centimeters'); r.units.SystemScale=1
    r.loadMaxFile(str(scene),quiet=True,useFileUnits=False)
    denied=''
    try: root().evaluateProcedural()
    except Exception as error: denied=str(error)
    report['rescale_denial']=denied
    check(bool(denied),'Unit conversion of bound native documents is explicitly rejected')
    check(history()==strokes and list(map(str,root().layerObjects[0].procRadiusIDs))==ids,'Denial preserves Paint contour counts and radius identities')
    r.loadMaxFile(str(scene),quiet=True,useFileUnits=True); root().evaluateProcedural()
    check(fingerprint()==before and history()==strokes,'Reopening with saved units recovers exact edited and painted publication')
    report['passed']=True
except Exception:
    report['passed']=False; report['errors'].append(traceback.format_exc())
finally: write()
if not report.get('passed'): raise RuntimeError(report['errors'][-1])
