"""One reproducible real-source preparation and moving-collider Max campaign.

The dispatcher serializes runs in a private host. Each case persists its last
phase so failed/hung tests are distinguishable from successful contacts.
"""
from pathlib import Path
import json
import math
import time
import traceback
from pymxs import runtime as r

O = Path(str(r.GardenRun))
RUN = O.parent
key = str(r.CVKey)
model_key = key.split('-')[0]
options = key.split('-')[1:]
work_millions = next((int(x[4:]) for x in options if x.startswith('work') and x[4:].isdigit()), 256)
guide_limit = next((int(x[6:]) for x in options if x.startswith('guides') and x[6:].isdigit()), 8192)
if not 1 <= work_millions <= 2048 or not 1 <= guide_limit <= 32768:
    raise ValueError('Fixture preparation limits are outside the exposed UI bounds')
manifest = json.loads((RUN / 'fixture-manifest.json').read_text(encoding='utf-8'))
report = {'key': key, 'model_key': model_key, 'status': 'running', 'phase': 'start', 'attempts': []}
path = O / 'cases' / (key + '.json')

def save():
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(report, indent=2), encoding='utf-8')
    temp.replace(path)

def phase(text):
    report['phase'] = text
    save()

def settle(frames=18):
    for _ in range(frames):
        r.windows.processPostedMessages()
        time.sleep(.02)
        r.completeRedraw()

def to_xyz(point):
    return [float(point.x), float(point.y), float(point.z)]

def norm(vector):
    size = math.sqrt(sum(v*v for v in vector))
    return [v / size for v in vector] if size > 1e-12 else [1., 0., 0.]

def world_point(local_engine, plant_tm):
    # Prepared guide nodes use SI +Y up; the Max scene uses centimetres +Z up.
    r.CVPoint = r.Point3(local_engine[0]*100., -local_engine[2]*100., local_engine[1]*100.)
    r.CVMatrix = plant_tm
    return r.execute('CVPoint * CVMatrix')

def statistics(root):
    return json.loads(str(root.interactionsStatistics()))


def host_memory():
    process = r.execute('(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()')
    process.Refresh()
    return {'private_bytes': int(process.PrivateMemorySize64), 'working_set_bytes': int(process.WorkingSet64),
            'process_lifetime_peak_working_set_bytes': int(process.PeakWorkingSet64),
            'scope': 'Whole owned Max process; includes scene, plugins and prior test cases, not isolated Cyrus or GPU memory.'}

def move(root, target, audit=True):
    settle()
    row = r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState, 2))[0][0]
    r.CVCurrent = row.row4
    r.CVTarget = target
    start = time.perf_counter()
    r.execute('undo "20-model collider gesture" on cyrusEditTransform WFEdit 0 (CVTarget-CVCurrent) (matrix3 1) false')
    after_move = time.perf_counter()
    root.interactionsEnsure()
    after_ensure = time.perf_counter()
    r.CyrusPointSync()
    after_sync = time.perf_counter()
    r.completeRedraw()
    after_redraw = time.perf_counter()
    result = {'target_scene_units': to_xyz(target),
              'move_ms': (after_move-start)*1000.,
              'ensure_ms': (after_ensure-after_move)*1000.,
              'sync_ms': (after_sync-after_ensure)*1000.,
              'redraw_ms': (after_redraw-after_sync)*1000.,
              'command_ms': (after_redraw-start)*1000.,
              'statistics': statistics(root), 'interaction_error': str(root.interactionError)}
    if audit and not result['interaction_error'] and result['statistics']['fitted_guides'] > 0:
        result['audit'] = json.loads(str(r.cyrusInteractionValidate(root.interactionState, 4000000)[2]))
    return result

try:
    r.execute('global CVImported')
    report['host_memory_before'] = host_memory()
    root, leaf, collider = r.WFRoot, r.WFGrass, r.WFCollider
    phase('clear previous source')
    root.updateMode = 1
    collider.interactionCollider = False
    leaf.interactionReact = False
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFRoot')
    # Retire the old contact publication while its source node is still live.
    # The old geometry must remain available until the replacement is published.
    old_imported = r.CVImported
    root.interactionsEnsure()
    leaf.removeModelSources(r.Array(*range(1, len(leaf.sources)+1)))
    r.CVImported = r.undefined
    until = time.monotonic()+8
    while not bool(root.mainUI.controlsReady) and time.monotonic() < until:
        r.windows.processPostedMessages()
        time.sleep(.02)
    assert root.mainUI.controlsReady

    phase('resolve real source')
    if model_key.startswith('S'):
        name = manifest['old_scene_model_names'][int(model_key[1:])]
        node = r.getNodeByName(name)
        assert node != r.undefined and r.isValidNode(node), name
        report.update(name=name, category='New Plants scene', source_scene_sha256=manifest['plant_scene']['sha256'])
    else:
        entry = next(e for e in manifest['library_models'] if e['id'] == model_key)
        # Max may recycle an anim handle after transient preview nodes retire
        # during a merge. Compare the identity/name pair as well as using the
        # merge's explicit auto-rename, so a new source is not lost to reuse.
        before = {(int(r.getHandleByAnim(n)), str(n.name)) for n in r.objects}
        merged = r.mergeMaxFile(entry['fixture_path'], r.Array(entry['node_name']), r.Name('autoRenameDups'), r.Name('renameMtlDups'), r.Name('neverReparent'), quiet=True, missingDLLsAction=r.Name('logmsg'))
        assert merged, 'Library fixture could not be merged'
        created = [n for n in r.objects if (int(r.getHandleByAnim(n)), str(n.name)) not in before and str(n.name).startswith(entry['node_name'])]
        assert len(created) == 1, 'Expected one distinct merged source; got '+str(len(created))
        node = created[0]
        r.CVImported = node
        report.update(name=entry['name'], category=entry['category'], source_scene_sha256=entry['sha256'], node_name=str(node.name))
    r.CVModel = node
    leaf.addModelSource(node)
    leaf.amount = 1
    leaf.interactionMinimumM = .005
    leaf.interactionConnectionM = .15
    leaf.interactionStiffness = .5
    leaf.interactionFoliage = 1.
    leaf.interactionCoverRoots = False
    leaf.interactionGapWU = 0.
    leaf.interactionMaxVertices = 2000000
    leaf.interactionMaxTriangles = 4000000
    leaf.interactionMaxParts = 100000
    leaf.interactionMaxGuides = guide_limit
    leaf.interactionMaxPreview = 2000000
    leaf.interactionMemoryMiB = 2048
    leaf.interactionWorkMillions = work_millions
    leaf.markInputDirty()
    report['settings'] = {'minimum_m': .005, 'branch_connection_m': .15, 'stiffness': .5,
                          'preview_fraction': 1., 'hide_roots': False, 'contact_gap': 0.,
                          'limits': [int(x) for x in leaf.interactionsLimits()]}
    phase('prepare through generated UI')
    t = time.perf_counter()
    root.refreshAll()
    r.CyrusPointSync()
    r.completeRedraw()
    report['initial_scatter_ms'] = (time.perf_counter()-t)*1000.
    if old_imported != r.undefined and r.isValidNode(old_imported) and old_imported != node:
        r.delete(old_imported)
    root.selectLayer(1)
    panel = root.mainUI
    # selectLayer changes the model selection only. Rebind the mounted UI as a
    # real layer-selection action does, especially after a prior case left the
    # collider layer selected.
    panel.selectLayerView(leaf)
    panel = root.mainUI
    panel.slots[12].open = True
    panel.bindSection(panel.editors[12])
    r.WFSection = panel.editors[12]
    r.execute('WFSection.interactionsUI_chooseRole 3')
    t = time.perf_counter()
    r.execute('WFSection.interactionsUI_prepareButton.pressed()')
    report['prepare_seconds'] = time.perf_counter()-t
    report['ui_message'] = str(r.WFSection.interactionsUI_info.text)
    if '-- Runtime error' in report['ui_message'] or not bool(leaf.interactionReact) or not bool(leaf.interactionsReady(leaf.validSources())):
        raise RuntimeError('Preparation did not produce a ready definition: '+report['ui_message'])
    definition = json.loads(str(leaf.interactionDefinitions[-1]))
    source = definition['source']
    metadata, prep_report = source['metadata'], source['report']
    report.update(source_fingerprint=source['fingerprint'], source_vertices=metadata['vertices'],
                  source_triangles=metadata['triangles'], source_geometry_sha256=metadata.get('source_geometry_sha256'),
                  guides=len(metadata['guides']), parts=len(metadata['parts']), preparation_report=prep_report)
    if not metadata['guides']:
        raise RuntimeError('Preparation returned no stem guides')
    # Pick the longest unparented guide and probe the upper portion from three
    # sides. A genuine contact must report fitted guides; proximity is not it.
    eligible = [g for g in metadata['guides'] if g.get('parent', -1) < 0 and len(g['nodes']) >= 2]
    if not eligible:
        raise RuntimeError('No independently rooted guide was available for a repeatable contact probe')
    guide = max(eligible, key=lambda g: float(g['length_m']))
    nodes = guide['nodes']
    idx = max(1, int((len(nodes)-1)*.8))
    near = nodes[idx]
    tangent = norm([nodes[-1][i]-nodes[max(0,idx-1)][i] for i in range(3)])
    side = norm([-tangent[2], 0., tangent[0]])
    perpendicular = norm([tangent[1]*side[2]-tangent[2]*side[1],
                          tangent[2]*side[0]-tangent[0]*side[2],
                          tangent[0]*side[1]-tangent[1]*side[0]])
    radius_m = min(.2, max(.004, float(guide['length_m'])*.08))
    report['probe'] = {'guide_component': guide['component'], 'guide_length_m': guide['length_m'], 'radius_source_m': radius_m}
    phase('initialize collider outside plant')
    root.updateMode = 2
    plant_tm = r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0]
    plant_scale = float(r.length(plant_tm.row1))
    r.WFSphere.radius = radius_m*100.*plant_scale
    root.refreshAll()
    r.CyrusPointSync()
    r.completeRedraw()
    r.execute('subObjectLevel=0;select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    r.cyrusEditActiveLayers(r.WFEdit, r.Array(int(collider.editLayerKey)))
    r.cyrusEditSelect(r.WFEdit, r.Array(1))
    root.interactionsEnsure()
    base = plant_tm.row4
    far = base + r.Point3(10000,10000,10000)
    move(root, far, audit=False)
    collider.interactionColliderMode = 1
    collider.interactionCollider = True
    root.refreshAll()
    root.interactionsEnsure()
    r.CyrusPointSync()
    r.completeRedraw()
    report['baseline_statistics'] = statistics(root)
    report['baseline_error'] = str(root.interactionError)
    if report['baseline_error']:
        raise RuntimeError('Far collider setup failed: '+report['baseline_error'])
    directions = [side, [-v for v in side], perpendicular]
    for i, direction in enumerate(directions):
        phase('contact direction '+str(i+1))
        local = [near[k]+direction[k]*radius_m*.7 for k in range(3)]
        target = world_point(local, plant_tm)
        attempt = {'direction': i+1, 'local_centre_m': local}
        try:
            attempt.update(move(root, target))
            attempt['status'] = 'error' if attempt['interaction_error'] else ('contact' if attempt['statistics']['fitted_guides'] else 'no_contact')
        except Exception:
            attempt['status'] = 'exception'
            attempt['error'] = traceback.format_exc()
        report['attempts'].append(attempt)
        save()
    phase('move away and restore')
    try:
        report['away'] = move(root, far, audit=False)
    except Exception:
        report['away'] = {'error': traceback.format_exc()}
    contacts = [a for a in report['attempts'] if a['status'] == 'contact']
    report['contact_count'] = len(contacts)
    report['valid_audit_count'] = sum(bool(a.get('audit', {}).get('passed')) for a in contacts)
    report['away_restored'] = not report['away'].get('error') and not report['away'].get('interaction_error') and report['away'].get('statistics', {}).get('posed') == 0
    report['host_memory_after'] = host_memory()
    report['status'] = 'pass' if len(report['attempts']) == 3 and len(contacts) == 3 and report['valid_audit_count'] == 3 and report['away_restored'] else 'needs_review'
    report['phase'] = 'complete'
except Exception:
    report['status'] = 'failed'
    report['error'] = traceback.format_exc()
save()
