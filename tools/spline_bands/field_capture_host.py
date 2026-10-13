"""Capture the integrated field/radius bundle and its actual CPU fallback."""
from pathlib import Path
import hashlib
import json
import traceback
import uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
token=uuid.uuid4().hex
report={'images':[],'checks':[],'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'launch':json.loads((OUT/'launch.json').read_text())}
def ms(code):return r.execute('(\n'+code+'\n)')
def draw():ms('for i=1 to 4 do (completeRedraw();windows.processPostedMessages();sleep .05)')
def check(ok,label):
    report['checks'].append({'passed':bool(ok),'label':label})
    if not ok:raise AssertionError(label)
def capture(label):
    draw();bitmap=r.gw.getViewportDib();path=OUT/('field-image-'+label+'-'+token+'.png')
    bitmap.filename=str(path);r.save(bitmap);r.close(bitmap)
    report['images'].append({'label':label,'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})

try:
    r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms';report['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest();r.fileIn(str(script))
    ms('''
global FINode=AminScatterObject name:"Field image fixture"
global FIRoot=FINode.baseObject
FIRoot.updateMode=1;FIRoot.autoRender=false;FIRoot.newLayer()
global FILeaf=FIRoot.selectedLayer()
global FIReceiver=plane width:160 length:160 widthsegs:2 lengthsegs:2
global FIPath=rectangle width:60 length:60
global FISource=box width:2 length:2 height:4 pos:[300,0,0]
FIRoot.setLayerSurfaces FILeaf #(FIReceiver)
FILeaf.sources=#(FISource);FILeaf.amount=250;FILeaf.sourceRadiiWU=#(2.)
FILeaf.diversityMode=3;FILeaf.addStroke FIPath;FILeaf.patternWidths[1]=25.
FILeaf.setStrokeSelection 1 2 #(FISource);FILeaf.fieldSamples=4000
FILeaf.procSelfEnabled=false;FILeaf.procLayerSelfEnabled=false
FIRoot.setGroupDisplay 4;FIRoot.evaluateProcedural()
hide #(FIReceiver,FIPath,FISource);hideByCategory.helpers=false
viewport.setType #view_top;viewport.setGridVisibility #all false
viewport.ZoomToBounds false [-85,-85,-10] [85,85,30]
clearSelection();CyrusViewportRedraw()
''')
    before=str(r.cyrusEditFingerprint(r.FIRoot.groupSnapshotRows[0],'field-image'));epoch=int(r.FIRoot.procEpoch)
    capture('plants-only')
    ms('FILeaf.fieldFalloff=true;FIRoot.refreshDisplay()');capture('retained-field')
    ms('global FIMain=FILeaf.cachedPoints;global FIField=FILeaf.procFieldCache;global FIInspection=FILeaf.inspectionCache')
    r.CyrusPointSync();owner=r.CyrusPointOwner(r.FINode)
    check(int(r.cyrusRetainedStats(owner)[11])==1, 'Actual retained field generation is ready')
    streams=list(map(int,r.cyrusRetainedStreamStats()));draw()
    check(streams[1:4]==list(map(int,r.cyrusRetainedStreamStats()))[1:4], 'Unchanged integrated field redraw uploads no geometry, transforms or owner data')
    ms('FILeaf.fieldBoundaries=true;FIRoot.refreshDisplay()');capture('retained-boundaries')
    ms('FILeaf.sourceShowRadius=#(true);FIRoot.refreshDisplay()');capture('retained-bundle')
    check(ms('FILeaf.cachedPoints==FIMain and FILeaf.procFieldCache!=undefined and FILeaf.inspectionCache!=FILeaf.procFieldCache'),
          'Field and rings use one inspection cache while keeping the published plant geometry')
    check(int(r.FIRoot.procEpoch)==epoch and str(r.cyrusEditFingerprint(r.FIRoot.groupSnapshotRows[0],'field-image'))==before,
          'Image changes preserve the exact published placements and epoch')
    report['streams_before_idle']=streams;report['resources']=list(map(int,r.cyrusPreviewResourceStats()))
    ms('CyrusPointSuspended=true;CyrusPointBusy=true;CyrusReleaseTimer.Stop();hide (CyrusPointOwner FINode);CyrusMeshEnabled=false;CyrusPointEnabled=false')
    capture('fallback-bundle')
    ms('CyrusViewportRecords=#()');capture('empty-background')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:
    r.CyrusPointBusy=False;r.CyrusPointSuspended=False;r.CyrusMeshEnabled=True;r.CyrusPointEnabled=True
    r.resetMaxFile(r.Name('noPrompt'))
    (OUT/('field-images-'+token+'.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
if not report['passed']:raise RuntimeError(report['error'])
