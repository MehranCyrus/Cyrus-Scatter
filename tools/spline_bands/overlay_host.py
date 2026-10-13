"""Owned Max witness for the numeric field-display bridge; no UI acceptance claim."""
from pathlib import Path
import hashlib
import json
import math
import time
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
destination = OUT / ('field-overlay-' + uuid.uuid4().hex + '.json')
report = {'checks': [], 'launch': json.loads((OUT / 'launch.json').read_text()),
          'fixture_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'qualification': 'Native bridge, receiver geometry, resource/failure retention and retained API; UI and captured-image acceptance are separate.'}


def save():
    destination.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')


def check(ok, label):
    report['checks'].append({'passed': bool(ok), 'label': label}); save()
    if not ok:
        raise AssertionError(label)


def ms(code):
    return r.execute('(\n' + code + '\n)')


def info(name, witnesses=0):
    value = list(r.cyrusFieldPreviewInfo(getattr(r, name), witnesses))
    return [float(x) for x in value[:14]], [
        {'position': list(map(float, x[0])), 'bary': list(map(float, x[1])),
         'receiver': int(x[2]), 'face': int(x[3]), 'value': float(x[4]), 'error': float(x[5])}
        for x in value[14]]


def vertices(name):
    return [(tuple(float(v) for v in row[0]), tuple(float(c) for c in (row[1].r, row[1].g, row[1].b)))
            for row in r.aminScatterPreviewPoints(getattr(r, name))]


def redraw():
    ms('for i=1 to 4 do (completeRedraw();windows.processPostedMessages();sleep .05)')


try:
    r.CyrusStopBrush();r.resetMaxFile(r.Name('noPrompt'))
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256'] = hashlib.sha256(script.read_bytes()).hexdigest()
    r.fileIn(str(script))
    for _ in range(16):
        if not r.isSceneRedrawDisabled():
            break
        r.enableSceneRedraw()
    ms('''
global FOPath=rectangle width:100 length:100 pos:[50,50,0]
global FOLower=plane width:140 length:140 widthsegs:2 lengthsegs:2 pos:[50,50,0]
global FOUpper=plane width:140 length:140 widthsegs:2 lengthsegs:2 pos:[50,50,17]
global FOVertical=plane width:140 length:140 widthsegs:2 lengthsegs:2 pos:[105,50,0]
rotate FOVertical (angleAxis 90 [0,1,0])
global FONodes=#(FOLower,FOUpper,FOVertical)
global FORecords=#(
 #(FOPath,1,1,false,0.,10.,1,.6,#(0.,1.),#(1),#("model-1"),#(false),1.,1.,#(1.,1.)),
 #(FOPath,1,2,false,0.,40.,1,.7,#(1.,1.),#(1),#("model-1"),#(false),1.,1.,#(1.,1.)))
global FOField=cyrusPrepareSplineField FORecords #(1.) 2 0.00001
global FOSource=box width:2 length:3 height:4 pos:[300,0,0]
global FOUnsupported=point pos:[300,20,0]
global FORootNode=AminScatterObject name:"Unchanged field display population"
global FORoot=FORootNode.baseObject
FORoot.updateMode=1;FORoot.autoRender=false;FORoot.newLayer()
global FOLeaf=FORoot.selectedLayer()
FORoot.setLayerSurfaces FOLeaf #(FOLower)
FOLeaf.sources=#(FOSource);FOLeaf.amount=20;FORoot.evaluateProcedural()
''')
    epoch = int(r.FORoot.procEpoch)
    fingerprint = str(r.cyrusEditFingerprint(r.FORoot.groupSnapshotRows[0], 'overlay'))
    source_tm = str(r.FOSource.transform)
    start = time.perf_counter()
    ms('global FOCombined=cyrusBuildFieldPreview FOField FONodes #(0,true,true,1000,0.)')
    report['first_prepare_seconds'] = time.perf_counter() - start
    combined, samples = info('FOCombined', 1000)
    report['combined_stats'] = combined
    check(combined[0] == 1 and combined[1] == 1000 and combined[6:8] == [3, 3],
          'Versioned display includes 1,000 samples across all three receivers')
    check(combined[3] > 0 and combined[2] > combined[3] and combined[4] == 24,
          'Boundary and field glyphs share one cache with checked receiver face counts')
    ids = {int(x.handle): kind for x, kind in ((r.FOLower, 'lower'), (r.FOUpper, 'upper'), (r.FOVertical, 'vertical'))}
    seen = set(); parity = True; surface = True
    for sample in samples:
        x, y, z = sample['position'];kind = ids[sample['receiver']];seen.add(kind)
        surface &= abs(z) < 1e-5 if kind == 'lower' else abs(z - 17) < 1e-5 if kind == 'upper' else abs(x - 105) < 1e-4
        q = math.hypot(max(0, -x, x - 100), max(0, -y, y - 100))
        a = .6*q/10 if 0 < q <= 10 else 0
        b = .7 if 0 < q <= 40 else 0
        parity &= abs(sample['value'] - min(1, a+b)) < 2e-5
    check(surface and len(seen) == 3, 'Diagnostic anchors lie on lower, upper and vertical receiver surfaces')
    check(parity, 'Combined density matches independent analytic Rounded probability')
    ms('global FOSelected=cyrusBuildFieldPreview FOField FONodes #(1,true,false,1000,0.)')
    selected, selected_samples = info('FOSelected', 1000)
    check(selected[3] == 0 and selected[2] == 3000, 'Falloff-only toggle produces glyphs without boundaries')
    parity = True
    for sample in selected_samples:
        x, y, _ = sample['position'];q=math.hypot(max(0,-x,x-100),max(0,-y,y-100))
        parity &= abs(sample['value'] - (.6*q/10 if 0<q<=10 else 0)) < 2e-5
    check(parity, 'Selected contribution uses the same evaluator before masks and spacing')
    original = vertices('FOSelected')
    check(len(original) == 6000 and any(max(abs(a-b) for a,b in zip(color,(0,0,255)))<.01 for _,color in original),
          'Zero density is visible blue rather than absent sample data')
    ms('global FOBoundaries=cyrusBuildFieldPreview FOField FONodes #(0,false,true,1000,0.)')
    boundary, _ = info('FOBoundaries')
    points = vertices('FOBoundaries')
    check(boundary[1] == 0 and boundary[2] == boundary[3] and len(points) == boundary[2]*2,
          'Boundaries-only output has no samples or plant count')
    check(any(abs(p[2])<1e-5 for p,_ in points) and any(abs(p[2]-17)<1e-5 for p,_ in points)
          and any(abs(p[0]-105)<1e-4 and abs(p[2])>20 for p,_ in points),
          'Boundary clipping reaches both elevations and vertical faces')
    ms('global FOOffset=cyrusBuildFieldPreview FOField FONodes #(1,true,false,1000,0.25)')
    shifted = vertices('FOOffset');shift_stats, shift_samples = info('FOOffset', 1000)
    check(shift_samples == selected_samples and len(shifted)==len(original)
          and all(abs(math.dist(a[0],b[0])-.25)<2e-5 for a,b in zip(original,shifted)),
          'Display offset moves only glyph positions, preserving evaluated anchors and probabilities')
    check(int(r.FORoot.procEpoch)==epoch and str(r.cyrusEditFingerprint(r.FORoot.groupSnapshotRows[0], 'overlay'))==fingerprint
          and str(r.FOSource.transform)==source_tm,
          'Field inspection never changes the active population, epoch or source transform')
    old = info('FOCombined', 1000)
    invalid = [
        ('FOField FONodes #(999,true,true,1000,0.)','Deleted selected Band'),
        ('FOField FONodes #(0,true,true,20001,0.)','Oversized sample request'),
        ('FOField FONodes #(0,true,true,1000,-1.)','Negative display offset'),
        ('FOField FONodes #(0,1,true,1000,0.)','Non-Boolean display toggle'),
        ('FOField FONodes #(0,true,true,1.5,0.)','Fractional sample request'),
        ('FOField #(FOLower,FOLower) #(0,true,true,1000,0.)','Duplicate receivers'),
        ('FOField #(FOUnsupported) #(0,true,true,1000,0.)','Non-mesh receiver'),
        ('undefined FONodes #(0,true,true,1000,0.)','Missing prepared field'),
    ]
    for arguments, label in invalid:
        before=int(r.cyrusPreviewResourceStats()[1]);failed=False
        try:
            ms('cyrusBuildFieldPreview ' + arguments)
        except Exception:
            failed=True
        check(failed and int(r.cyrusPreviewResourceStats()[1])==before and info('FOCombined',1000)==old,
              label + ' rejects without leaking reservations or changing the preceding cache')
    ms('global FOHidden=cyrusBuildFieldPreview FOField FONodes #(0,false,false,1000,0.)')
    hidden, _ = info('FOHidden');check(hidden[1:4] == [0,0,0], 'Both display toggles off produce an empty cache')
    ms('''
global FOController=box width:1 length:1 height:1 pos:[300,20,0]
global FOHelper=cyrusRetainedCreate()
global FOStyles=#(#(false,white))
hideByCategory.helpers=false
viewport.setType #view_top;viewport.ZoomToBounds false [-30,-30,-80] [130,130,80]
cyrusRetainedPublish FOHelper FOController #(FOCombined) FOStyles
''')
    redraw()
    check(bool(ms('cyrusRetainedMatches FOHelper #(FOCombined) FOStyles')),
          'Existing retained line pipeline consumes the immutable field cache')
    streams = list(map(int,r.cyrusRetainedStreamStats()));redraw()
    check(streams[1:4]==list(map(int,r.cyrusRetainedStreamStats()))[1:4],
          'Unchanged field redraw performs no geometry, transform or owner uploads')
    report['resources']=list(map(int,r.cyrusPreviewResourceStats()))
    check(report['resources'][1] < report['resources'][3], 'Point preview reservations remain within the unchanged process limit')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:
    save()
if not report['passed']:
    raise RuntimeError(report['error'])
