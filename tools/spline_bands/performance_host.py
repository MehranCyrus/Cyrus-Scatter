"""Bounded integrated workload measurements in an owned, matched Max process.

One cold and five warm explicit Updates; one cold and twenty warm display calls.
These synchronous timings are not presented frame times. Counters are checked
independently of timing; no historical performance comparison is inferred here.
"""
from pathlib import Path
import ctypes
import hashlib
import json
import math
import statistics
import time
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
destination = OUT / ('performance-' + uuid.uuid4().hex + '.json')
report = {'checks': [], 'workloads': [], 'fixture_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'launch': json.loads((OUT / 'launch.json').read_text()),
          'limits': 'Synchronous host call durations, not presented FPS. Payload reservations are not physical VRAM; process memory includes Max and loaded plugins.',
          'repetitions': {'update_warm': 5, 'display_warm': 20},
          'matrix': [[1, 1, 1000, 8, 1000], [1, 20, 10000, 8, 4000], [10, 20, 1000, 8, 500]],
          'matrix_columns': ['layers', 'shared_sources', 'candidates_per_layer', 'bands_per_layer', 'field_samples_per_layer']}


def save():
    destination.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')


def check(ok, label):
    report['checks'].append({'passed': bool(ok), 'label': label}); save()
    if not ok:
        raise AssertionError(label)


def ms(code):
    return r.execute('(\n' + code + '\n)')


def draw():
    ms('completeRedraw();windows.processPostedMessages()')


def counters():
    return {'streams': list(map(int, r.cyrusRetainedStreamStats())),
            'resources': list(map(int, r.cyrusPreviewResourceStats())),
            'source_geometry': list(map(int, r.cyrusSourceGeometryStats())),
            'epoch': int(r.PRoot.procEpoch),
            'prepared_builds': [int(x.procPreparedBuilds) for x in r.PRoot.layerObjects],
            'field_builds': [int(x.procSplineBuilds) for x in r.PRoot.layerObjects]}


def memory():
    class Counters(ctypes.Structure):
        _fields_ = [('cb', ctypes.c_ulong), ('faults', ctypes.c_ulong)] + [(name, ctypes.c_size_t) for name in
                    ('peak_working_set', 'working_set', 'peak_paged', 'paged', 'peak_nonpaged', 'nonpaged', 'pagefile', 'peak_pagefile')]
    value = Counters(); value.cb = ctypes.sizeof(value)
    ctypes.windll.kernel32.GetCurrentProcess.restype = ctypes.c_void_p
    ok = ctypes.windll.psapi.GetProcessMemoryInfo(ctypes.c_void_p(ctypes.windll.kernel32.GetCurrentProcess()), ctypes.byref(value), value.cb)
    return {name: int(getattr(value, name)) for name in ('working_set', 'peak_working_set', 'pagefile', 'peak_pagefile')} if ok else None


def measure(call, warm=20):
    samples = []
    for i in range(warm + 1):
        start = time.perf_counter(); call(i); samples.append((time.perf_counter() - start) * 1000)
    return {'cold_ms': samples[0], 'warm_median_ms': statistics.median(samples[1:]),
            'warm_p95_ms': sorted(samples[1:])[math.ceil(.95 * warm) - 1], 'samples_ms': samples}


try:
    r.CyrusStopBrush(); r.resetMaxFile(r.Name('noPrompt'))
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256'] = hashlib.sha256(script.read_bytes()).hexdigest(); r.fileIn(str(script))
    report['timer_floor'] = measure(lambda _: None, warm=1000)
    for layer_count, source_count, amount, bands, samples in report['matrix']:
        r.resetMaxFile(r.Name('noPrompt'))
        ms(f'''
global PNode=AminScatterObject name:"Spline workload {layer_count} layers {source_count} sources"
global PRoot=PNode.baseObject
PRoot.updateMode=1;PRoot.autoRender=false
global PSources=for i=1 to {source_count} collect (
    if i==1 then sphere radius:1.5 segments:32 pos:[500+i*5,0,0]
    else box width:2 length:3 height:4 pos:[500+i*5,0,0]
)
global PPath=rectangle width:100 length:100
global PReceivers=#(plane width:220 length:220 widthsegs:8 lengthsegs:8,
                    plane width:220 length:220 widthsegs:4 lengthsegs:4 pos:[0,0,12])
for n=1 to {layer_count} do (
    PRoot.newLayer();local leaf=PRoot.selectedLayer()
    PRoot.setLayerSurfaces leaf PReceivers
    leaf.sources=PSources;leaf.amount={amount};leaf.randomSeed=n*137
    leaf.sourceAutoRadius=for src in PSources collect true
    leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false;leaf.diversityMode=3
    for b=1 to {bands} do (leaf.addStroke PPath;leaf.setStrokeSelection b 2 PSources)
    leaf.bandArrangement=2
    leaf.strokeStarts=for b=1 to {bands} collect 0.
    leaf.strokeEnds=for b=1 to {bands} collect (15.+b*3.)
    leaf.strokeStrengths=for b=1 to {bands} collect (1./{bands})
    leaf.fieldSamples={samples};leaf.fieldCombined=true
)
PRoot.setGroupDisplay 4
hide (PSources+PReceivers+#(PPath));clearSelection()
viewport.setType #view_top;viewport.setGridVisibility #all false
viewport.ZoomToBounds false [-115,-115,-10] [115,115,40]
''')
        workload = {'layers': layer_count, 'sources': source_count, 'amount_per_layer': amount,
                    'bands': bands, 'field_samples': samples, 'memory_before': memory()}
        report['workloads'].append(workload); save()
        workload['updates'] = measure(lambda _: r.PRoot.evaluateProcedural(), warm=5)
        draw(); draw()
        workload['accepted_per_layer'] = [len(rows) for rows in r.PRoot.groupSnapshotRows]
        before = counters()
        workload['idle_redraw'] = measure(lambda _: draw())
        after = counters()
        check(before['streams'][1:4] == after['streams'][1:4] and before['epoch'] == after['epoch']
              and before['prepared_builds'] == after['prepared_builds'] and before['source_geometry'][1] == after['source_geometry'][1],
              f'{layer_count} layers/{source_count} sources: unchanged redraw solves/extracts/uploads zero')
        ms('for leaf in PRoot.layerObjects do (leaf.fieldFalloff=true;leaf.fieldBoundaries=true)')
        start = time.perf_counter(); r.PRoot.refreshDisplay(); draw(); draw()
        workload['field_first_host_ms'] = (time.perf_counter() - start) * 1000
        check(all(not str(x.previewError) and x.procFieldCache != r.undefined for x in r.PRoot.layerObjects),
              f'{layer_count} layers: integrated overlay admitted without hidden display errors')
        before = counters()
        workload['field_idle_redraw'] = measure(lambda _: draw())
        after = counters()
        check(before['streams'][1:4] == after['streams'][1:4] and before['source_geometry'][1] == after['source_geometry'][1]
              and before['epoch'] == after['epoch'] and before['field_builds'] == after['field_builds'],
              f'{layer_count} layers: unchanged overlay retains all field and GPU streams')
        ms('PRoot.identificationMode=3;PRoot.refreshIdentification()'); draw(); draw()
        before = counters()
        workload['palette_edit'] = measure(lambda i: ms(f'PRoot.layerObjects[1].strokeDisplayColors[1]=(color {20+i} 180 220);PRoot.refreshIdentification();completeRedraw()'))
        after = counters()
        check(before['streams'][1:4] == after['streams'][1:4] and before['epoch'] == after['epoch']
              and before['source_geometry'][1] == after['source_geometry'][1],
              f'{layer_count} layers: palette changes retain all geometry, transform and owner uploads')
        workload['palette_stream_delta'] = [b-a for a,b in zip(before['streams'], after['streams'])]
        before = counters()
        workload['pending_field_width'] = measure(lambda i: ms(f'PRoot.layerObjects[1].strokeEnds[1]={18.5+(i%2)};PRoot.refreshDisplay();completeRedraw()'))
        after = counters()
        check(before['epoch'] == after['epoch'] and before['prepared_builds'] == after['prepared_builds']
              and before['source_geometry'][1] == after['source_geometry'][1]
              and 'Pending field; plants from last Update' in str(r.PRoot.layerObjects[0].fieldPreviewStatus()),
              f'{layer_count} layers: authored field changes preserve Manual population and Auto bounds')
        workload['final_counters'] = after; workload['memory_after'] = memory()
        ms('''global PPreviousTrace=CyrusPerfTraceBegin;global PRefreshCalls=0
fn CyrusPerfTraceBegin owner label = (if label=="preview_rebuild" do PRefreshCalls+=1;undefined)''')
        try:
            ms('PRoot.layerObjects[1].strokeEnds[1]=20.25;PRoot.refreshDisplay()')
            workload['single_field_edit_refresh_calls'] = int(r.PRefreshCalls)
            check(int(r.PRefreshCalls) <= 2, f'{layer_count} layers: a field edit stages the controller at most twice, not once per sibling')
        finally:
            ms('CyrusPerfTraceBegin=PPreviousTrace')
        workload['retained_stats'] = [int(x) for x in list(r.cyrusRetainedStats(r.CyrusPointOwner(r.PNode)))[:12]]
        workload['field_counts'] = [[int(x) for x in list(r.cyrusFieldPreviewInfo(leaf.procFieldCache, 0))[:8]] for leaf in r.PRoot.layerObjects]
        check(workload['retained_stats'][11] == 1, f'{layer_count} layers: all retained groups are ready')
        save()
    # All ten layers use the same 20 sources: changing display mode must retain
    # the solved population and bounded source sharing, without duplicating each
    # source once per Band. Check actual retained source-face telemetry.
    before = counters()
    workload['mesh_switch'] = measure(lambda i: ms(f'PRoot.setGroupDisplay {3 if i%2==0 else 4};PRoot.refreshDisplay();completeRedraw()'), warm=5)
    ms('PRoot.setGroupDisplay 3;PRoot.refreshDisplay()'); draw(); draw()
    workload['mesh_stats'] = list(map(int, r.cyrusRetainedMeshStats(r.CyrusPointOwner(r.PNode))))
    check(int(r.PRoot.procEpoch) == before['epoch'], 'Ten-layer Mesh/Point switching preserves the publication epoch')
    workload['memory_mesh'] = memory(); workload['resources_mesh'] = list(map(int, r.cyrusPreviewResourceStats()))
    check(workload['mesh_stats'][2] <= 10 * (1984 + 19 * 12), 'Shared Mesh source faces are not multiplied by Band membership')
    report['passed'] = True
except Exception:
    report['passed'] = False; report['error'] = traceback.format_exc()
finally:
    # Leave the final disposable workload for externally sampled GPU/process
    # counters. The runner owns teardown after those measurements are recorded.
    save()
if not report['passed']:
    raise RuntimeError(report['error'])
