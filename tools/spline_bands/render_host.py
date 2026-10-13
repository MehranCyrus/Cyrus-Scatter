"""Compare actual PFlow render output to explicit instances of published rows.

Owned primitive scene, Scanline/Standard materials only. This does not qualify
Corona/V-Ray proxies, IR, arbitrary materials, motion blur or production scenes.
"""
from pathlib import Path
import hashlib
import json
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
token = uuid.uuid4().hex
report = {'checks': [], 'images': [], 'launch': json.loads((OUT / 'launch.json').read_text()),
          'fixture_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'scope': 'Actual Scanline render with Standard and Multi/Sub-Object materials versus explicit instances from published transforms; no production renderer/proxy certification.'}


def ms(code):
    return r.execute('(\n' + code + '\n)')


def check(ok, label):
    report['checks'].append({'passed': bool(ok), 'label': label})
    if not ok:
        raise AssertionError(label)


def render(label):
    path = OUT / ('render-' + label + '-' + token + '.png')
    bitmap = r.render(camera=r.RCamera, vfb=False, outputfile=str(path))
    check(bitmap != r.undefined and path.is_file(), label + ': actual renderer returned an image')
    r.close(bitmap)
    report['images'].append({'label': label, 'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})


try:
    r.CyrusStopBrush(); r.resetMaxFile(r.Name('noPrompt'))
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256'] = hashlib.sha256(script.read_bytes()).hexdigest(); r.fileIn(str(script))
    ms('''
global RNode=AminScatterObject name:"Band renderer boundary"
global RRoot=RNode.baseObject
RRoot.updateMode=1;RRoot.autoRender=true;RRoot.newLayer()
global RLeaf=RRoot.selectedLayer();RLeaf.autoRender=true
global RSurface=plane width:160 length:160 widthsegs:2 lengthsegs:2
global RPath=rectangle width:60 length:60
global RBox=box width:4 length:4 height:9 pos:[300,0,0]
global RSphere=sphere radius:3 segments:16 pos:[320,0,0]
global RMat1=standardMaterial name:"Preserved green" diffuse:(color 20 220 50) selfIllumAmount:100
global RMat2=standardMaterial name:"Preserved cyan" diffuse:(color 20 160 230) selfIllumAmount:100
global RMulti=multimaterial numsubs:2 name:"Preserved face materials"
RMulti[1]=RMat1;RMulti[2]=RMat2
RBox.material=RMulti;RSphere.material=RMat2
RRoot.setLayerSurfaces RLeaf #(RSurface);RLeaf.sources=#(RBox,RSphere)
RLeaf.sourceRadiiWU=#(3.,3.)
RLeaf.amount=240;RLeaf.diversityMode=3;RLeaf.procSelfEnabled=false;RLeaf.procLayerSelfEnabled=false
RLeaf.addStroke RPath;RLeaf.addStroke RPath;RLeaf.addStroke RPath
RLeaf.patternWidths=#(14.,16.,12.)
RLeaf.setStrokeSelection 1 2 #(RBox);RLeaf.setStrokeSelection 2 2 #(RBox);RLeaf.setStrokeSelection 3 2 #(RSphere)
RLeaf.strokeDisplayColors=#(red,blue,yellow)
RRoot.identificationMode=3;RRoot.evaluateProcedural()
hide #(RSurface,RPath,RBox,RSphere)
global RCamera=targetCamera name:"Render oracle" pos:[0,-150,190] target:(targetObject pos:[0,0,0])
RCamera.fov=65
renderers.current=Default_Scanline_Renderer()
renderWidth=384;renderHeight=384;backgroundColor=black
''')
    epoch = int(r.RRoot.procEpoch)
    signature = str(r.cyrusEditFingerprint(r.RRoot.groupSnapshotRows[0], 'renderer'))
    report['accepted'] = len(r.RRoot.groupSnapshotRows[0])
    report['renderer'] = str(r.classof(r.renderers.current))
    check(report['accepted'] > 25, 'Nonempty published fixture contains both source models')
    check(bool(r.CyrusPFBuild()), 'Production PFlow bridge builds from the current exact row format')
    report['pflow_instances'] = [len(rows) for rows in r.CyrusPFData]
    check(sum(report['pflow_instances']) == report['accepted'] and len(report['pflow_instances']) == 2,
          'PFlow groups by source, including shared-source Band owners')
    check(ms('for n in CyrusPFNodes where classof n==PF_Source do if n.material!=RMulti and n.material!=RMat2 do throw "Wrong render material";true'),
          'PFlow retains original source material identities')
    render('pflow')
    ms('RLeaf.fieldFalloff=true;RLeaf.fieldBoundaries=true;RLeaf.fieldSamples=1000;RLeaf.sourceShowRadius=#(true,true);RLeaf.strokeDisplayColors=#((color 255 0 255),orange,white);RRoot.refreshDisplay()')
    check(len(r.RLeaf.radiusPreview) > 0 and r.RLeaf.procFieldCache != r.undefined,
          'Render invariance includes actual prepared field and nonzero published radius overlays')
    render('with-overlays-and-palette')
    check(int(r.RRoot.procEpoch) == epoch and str(r.cyrusEditFingerprint(r.RRoot.groupSnapshotRows[0], 'renderer')) == signature,
          'Field, radius and identification changes preserve the exact rendered publication')
    check(r.RBox.material == r.RMulti and r.RSphere.material == r.RMat2,
          'Viewport identification leaves source and face material assignments intact')
    ms('''
RRoot.autoRender=false;RLeaf.autoRender=false;CyrusPFClear()
global RReference=for row in RRoot.groupSnapshotRows[1] collect (
    local src=RRoot.procPublishedSources[1][row[2]],node=instance src
    node.name="Independent row oracle";node.transform=row[1];node.renderable=true;unhide node;node
)
''')
    check(len(r.RReference) == report['accepted'], 'Independent reference creates exactly one source instance per published row')
    render('explicit-instances')
    check(len(r.CyrusPFNodes) == 0, 'Reference render contains no hidden duplicate PFlow output')
    report['passed'] = True
except Exception:
    report['passed'] = False; report['error'] = traceback.format_exc()
finally:
    report['bridge_error'] = str(r.CyrusPFLastError)
    (OUT / ('render-' + token + '.json')).write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
if not report['passed']:
    raise RuntimeError(report['error'])
