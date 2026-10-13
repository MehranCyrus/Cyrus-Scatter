"""Run inside the owned Max host; inject faults into a recorded script copy only."""
from pathlib import Path
import hashlib
import json
import traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-'):
    raise RuntimeError('Owned foundation host required')

report = {'assertions': [], 'errors': [], 'scope': 'Actual generated methods and native Edit transaction in Max; faults are inserted into an isolated copy.'}
def write():
    (OUT / 'publication-results.json').write_text(json.dumps(report, indent=2) + '\n')
def check(condition, label):
    report['assertions'].append({'passed': bool(condition), 'label': label}); write()
    if not condition:
        raise AssertionError(label)
def arr(values):
    return r.Array(*values)
def rows(root):
    return [[(tuple(tuple(float(v) for v in axis) for axis in (row[0].row1, row[0].row2, row[0].row3, row[0].row4)), int(row[1]), str(row[2]), int(row[3]), tuple(map(float, row[4])), int(row[5]), bool(row[6]), int(row[7])) for row in layer] for layer in root.groupSnapshotRows]
def state(root, modifier):
    return dict(rows=rows(root), epoch=int(root.procEpoch), builds=int(root.groupBuilds),
        key=str(root.groupSnapshotKey), display_key=str(root.procPublishedDisplayKey),
        metadata=str(r.execute('with printAllElements on ((for entry in (getNodeByName "Foundation publication").baseObject.procPublishedMetadata collect entry) as string)')),
        visible=int(r.cyrusEditVisibleCount(modifier)),
        owner_ids=[str(x.layerID) for x in root.procPublishedOwners],
        source_ids=[[int(r.getHandleByAnim(n)) for n in group] for group in root.procPublishedSources],
        final_keep=[list(map(bool, group)) for group in root.procPublishedFinalKeep],
        radii=[[list(map(float, pair)) for pair in group] for group in root.procPublishedRadii],
        layers=[dict(epoch=int(x.procEpoch), stats=list(map(str, x.procLastStats)), rounds=list(map(str, x.procLastRounds)),
            group_stats=list(map(int, x.groupStats())), overlap=(int(x.overlapBefore), int(x.overlapAfter)),
            requested=int(x.requestedCount), generated=int(x.generatedCount), shown=int(x.cachedPointCount),
            previews=int(x.previewBuildCount), display_key=str(x.procPreviewDisplayKey), geometry_key=str(x.procPreviewGeometryKey),
            inspection_key=str(x.procPreviewInspectionKey), field_key=str(x.procFieldCacheKey), field_status=str(x.procFieldStatus),
            observed=str(x.inputTimeObserved), pending=bool(x.dirty)) for x in root.layerObjects])

try:
    r.CyrusStopBrush(); r.resetMaxFile(r.Name('noPrompt'))
    source = (ROOT / 'AminScatter/scripts/AminScatterObject.ms').read_text(encoding='utf-8-sig')
    replacements = {
        'edit-publish': '            this.publishGroupEdits accepted',
        'leaf-install': '                leaf.procInstallPreview display[i] false',
        'root-install': '            procPublishedRadii=radii;procPublishedInfo=publicationInfo',
        'before-commit': '            groupSnapshotRows=accepted;groupSnapshotKey=finishedKey;procPublishedDisplayKey=displayKey;groupBuilds+=1',
        'display-install': '                for i=1 to layerObjects.count where stage[i]!=undefined do layerObjects[i].procInstallPreview stage[i] pending',
    }
    instrumented = source
    for label, line in replacements.items():
        check(source.count(line) == 1, 'Unique production fault site: ' + label)
        if label == 'display-install':
            replacement = '                for i=1 to layerObjects.count where stage[i]!=undefined do (layerObjects[i].procInstallPreview stage[i] pending;CyrusFoundationCheckpoint "display-install")'
        else:
            replacement = line + '\n                CyrusFoundationCheckpoint "' + label + '"'
        instrumented = instrumented.replace(line, replacement)
    prefix = '''global CyrusFoundationTarget="",CyrusFoundationHit=0,CyrusFoundationAt=1
fn CyrusFoundationCheckpoint label = (
 if label==CyrusFoundationTarget do (
  CyrusFoundationHit+=1
  if CyrusFoundationHit==CyrusFoundationAt do throw ("Injected foundation failure: "+label)
 )
)
'''
    path = OUT / 'scripts/publication-faults.ms'
    path.write_text(prefix + instrumented, encoding='utf-8-sig')
    report['source_sha256'] = hashlib.sha256(source.encode()).hexdigest()
    report['fault_copy_sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
    report['fault_sites'] = replacements
    r.fileIn(str(path))
    surface = r.plane(width=500., length=500.)
    model = r.box(width=4., length=4., height=12., pos=r.Point3(700., 0., 0.)); r.hide(model)
    node = r.AminScatterObject(name='Foundation publication')
    root = node.baseObject; root.updateMode=1; root.autoRender=False
    for i in range(3):
        root.newLayer(); leaf=root.selectedLayer()
        root.setLayerSurfaces(leaf, arr([surface])); leaf.sources=arr([model]); leaf.amount=100+i*20
        leaf.sourceRadiiWU=arr([3.])
    modifier = r.CyrusScatterEdit(); r.addModifier(node, modifier)
    root.setGroupDisplay(4); root.evaluateProcedural()
    r.CyrusPointSync(); r.completeRedraw(); r.completeRedraw()
    check(not str(r.CyrusPointLastError), 'Baseline retained publication is available')
    check([len(x) for x in root.groupSnapshotRows] == [100, 120, 140], 'Three complete initial populations')
    for target, occurrence in [('edit-publish', 1), ('leaf-install', 1), ('leaf-install', 2), ('leaf-install', 3), ('root-install', 1), ('before-commit', 1)]:
        root.layerObjects[0].amount += 7
        before=state(root, modifier)
        caches=[(x.cachedPoints,x.inspectionCache) for x in root.layerObjects]
        r.CyrusFoundationTarget=target; r.CyrusFoundationAt=occurrence; r.CyrusFoundationHit=0
        failed=False
        try:
            root.evaluateProcedural()
        except Exception as error:
            failed='Injected foundation failure' in str(error)
        r.CyrusFoundationTarget=''
        check(failed, f'{target}/{occurrence}: fault reached actual method')
        check(state(root, modifier)==before, f'{target}/{occurrence}: complete previous publication and Edit visibility retained')
        check(all(x.cachedPoints==a and x.inspectionCache==b for x,(a,b) in zip(root.layerObjects,caches)), f'{target}/{occurrence}: cache objects retained')
        check(not root.groupSolving, f'{target}/{occurrence}: solve guard released')
        root.evaluateProcedural()
        check(int(root.procEpoch)==before['epoch']+1 and len(root.groupSnapshotRows[0])==int(root.layerObjects[0].amount), f'{target}/{occurrence}: same-input retry commits once')
    # Two display-only owners change while a third recipe remains pending.
    root.layerObjects[2].amount += 20
    root.layerObjects[0].solidPointColor=r.color(10,220,10)
    root.layerObjects[1].solidPointColor=r.color(220,10,10)
    # Redraw callbacks may eagerly install color changes. Explicitly invalidate
    # these two transient display keys so the fault tests the multi-owner tail.
    root.procPublishedDisplayKey='fixture: invalidated display'
    root.layerObjects[0].procPreviewDisplayKey='fixture: invalidated owner'
    root.layerObjects[1].procPreviewDisplayKey='fixture: invalidated owner'
    before=state(root, modifier); caches=[(x.cachedPoints,x.inspectionCache) for x in root.layerObjects]
    r.CyrusFoundationTarget='display-install'; r.CyrusFoundationAt=2; r.CyrusFoundationHit=0
    failed=False
    try:
        root.procEnsureDisplay(pending=True)
    except Exception as error:
        report['display_exception']=str(error)
        failed='Injected foundation failure' in str(error)
    r.CyrusFoundationTarget=''
    report['display_hits']=int(r.CyrusFoundationHit)
    check(failed, 'Display fault occurs after second actual owner install')
    check(state(root, modifier)==before, 'Display rollback restores all owners and root display key')
    check(all(x.cachedPoints==a and x.inspectionCache==b for x,(a,b) in zip(root.layerObjects,caches)), 'Display rollback preserves cache objects')
    root.procEnsureDisplay(pending=True)
    check(rows(root)==before['rows'] and int(root.procEpoch)==before['epoch'], 'Display recovery does not consume pending Manual recipe')
    root.evaluateProcedural()
    check(len(root.groupSnapshotRows[2])==int(root.layerObjects[2].amount), 'Explicit Update consumes pending recipe')
    # Exercise the same publication tail with the new inspection bundle active.
    path_node=r.rectangle(width=400.,length=400.)
    for leaf in root.layerObjects:
        leaf.diversityMode=3;leaf.addStroke(path_node);leaf.setStrokeSelection(1,2,arr([model]))
        leaf.patternWidths=arr([60.]);leaf.fieldFalloff=True;leaf.fieldBoundaries=True
        leaf.fieldSamples=250;leaf.sourceShowRadius=arr([True])
    # This owned fixture intentionally changes the generation binding from
    # ordinary random scattering to Bands, so explicitly reset its Edit map.
    r.cyrusEditCommand(modifier,0,r.Matrix3(1))
    root.evaluateProcedural()
    def inspection_caches():
        return [(x.cachedPoints,x.inspectionCache,x.procFieldCache) for x in root.layerObjects]
    def same_caches(saved):
        return all(x.cachedPoints==a and x.inspectionCache==b and x.procFieldCache==c for x,(a,b,c) in zip(root.layerObjects,saved))
    check(all(x.procFieldCache!=r.undefined and x.inspectionCache!=x.procFieldCache for x in root.layerObjects),
          'Three populations have complete field and radius inspection bundles')
    root.layerObjects[0].strokeStrengths=arr([.7]);root.layerObjects[1].strokeStrengths=arr([.8])
    root.procPublishedDisplayKey='fixture: field display pending'
    for leaf in root.layerObjects:leaf.procPreviewDisplayKey='fixture: field display pending'
    before=state(root,modifier);caches=inspection_caches()
    r.CyrusFoundationTarget='display-install';r.CyrusFoundationAt=2;r.CyrusFoundationHit=0
    failed=False
    try:root.procEnsureDisplay(pending=True)
    except Exception as error:failed='Injected foundation failure' in str(error)
    r.CyrusFoundationTarget=''
    check(failed and int(r.CyrusFoundationHit)==2, 'Field display failure reaches the second installed owner')
    check(state(root,modifier)==before and same_caches(caches), 'Field display rollback restores all caches, keys, labels and published metadata')
    root.procEnsureDisplay(pending=True)
    check(rows(root)==before['rows'] and int(root.procEpoch)==before['epoch']
          and all('Pending field' in str(x.procFieldStatus) for x in list(root.layerObjects)[:2]),
          'Field display retry publishes feedback only and keeps pending labels')
    root.layerObjects[2].fieldSamples=20001
    before=state(root,modifier);caches=inspection_caches();failed=False
    try:root.procEnsureDisplay(pending=True)
    except Exception as error:failed='Field sample limit' in str(error)
    check(failed and state(root,modifier)==before and same_caches(caches),
          'A later field preparation rejection retains the complete preceding display')
    root.layerObjects[2].fieldSamples=250
    # Density edits deliberately replace this binding. Reset the disposable
    # Edit map before testing the new generation's installation boundary.
    r.cyrusEditCommand(modifier,0,r.Matrix3(1))
    before=state(root,modifier);caches=inspection_caches()
    r.CyrusFoundationTarget='leaf-install';r.CyrusFoundationAt=2;r.CyrusFoundationHit=0;failed=False
    try:root.evaluateProcedural()
    except Exception as error:
        report['field_publication_exception']=str(error)
        failed='Injected foundation failure' in str(error)
    r.CyrusFoundationTarget=''
    after=state(root,modifier)
    report['field_publication_differences']={key:{'before':before[key],'after':after[key]} for key in before if before[key]!=after[key]}
    report['field_publication_caches_retained']=same_caches(caches)
    check(failed and state(root,modifier)==before and same_caches(caches),
          'Failed plant successor also restores its paired field/inspection metadata and caches')
    root.evaluateProcedural()
    check(int(root.procEpoch)==before['epoch']+1 and all('Field from last Update' in str(x.procFieldStatus) for x in root.layerObjects),
          'Successful retry publishes plants, radii and field metadata as one epoch')
    report['passed']=True
except Exception:
    report['errors'].append(traceback.format_exc()); report['passed']=False
finally:
    r.CyrusFoundationTarget=''
    write()
if not report.get('passed'):
    raise RuntimeError(report['errors'][-1])
