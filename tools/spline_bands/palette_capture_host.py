"""Capture actual retained and GraphicsWindow Band colors in an owned host."""
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
report={'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'images':[],
        'launch':json.loads((OUT/'launch.json').read_text())}


def ms(code):return r.execute('(\n'+code+'\n)')
def draw():ms('for i=1 to 4 do (completeRedraw();windows.processPostedMessages();sleep .05)')
def capture(label):
    draw();bitmap=r.gw.getViewportDib();path=OUT/('palette-'+label+'-'+token+'.png')
    bitmap.filename=str(path);r.save(bitmap);r.close(bitmap)
    report['images'].append({'label':label,'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})


try:
    r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms';r.fileIn(str(script))
    report['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest()
    ms('''
CyrusPointSuspended=true;CyrusPointBusy=true;CyrusReleaseTimer.Stop()
global CaptureController=box name:"Palette image controller" pos:[1000,0,0]
global CaptureSource=box name:"One shared source" width:24 length:24 height:20 pos:[1200,0,0]
global CaptureRows=for i=1 to 3 collect #((transMatrix [(i-2)*45.,0,0]),1,(i as integer64),1,[1,0,0],#(17,25,0)[i],false,2)
global CapturePalette=#(1,3,#(white),#(#(17,red),#(25,blue)),false)
global CaptureCache=cyrusBuildGeometryPreview CaptureRows #(CaptureSource) CapturePalette 4 10 1000
global CaptureOwner=cyrusRetainedCreate()
CyrusViewportRecords=#(#(CaptureController,CaptureOwner,#(CaptureCache),#(#(false,white)),#()))
CyrusViewportRecordsDirty=false
cyrusRetainedPublish CaptureOwner CaptureController #(CaptureCache) #(#(false,white))
hideByCategory.helpers=false
viewport.setType #view_top;viewport.setGridVisibility #all false
viewport.ZoomToBounds false [-90,-45,-10] [90,45,40]
''')
    draw()
    if int(r.cyrusRetainedStats(r.CaptureOwner)[11])!=1:raise AssertionError('Retained shader was not ready')
    capture('retained-red-blue-unbanded')
    before=list(map(int,r.cyrusRetainedStreamStats()))
    ms('CaptureCache=cyrusRecolorPreview CaptureCache #(1,3,#(white),#(#(17,green),#(25,blue)),false);CyrusViewportRecords[1][3]=#(CaptureCache);cyrusRetainedPublish CaptureOwner CaptureController #(CaptureCache) #(#(false,white))')
    capture('retained-green-blue-unbanded')
    if report['images'][0]['sha256']==report['images'][1]['sha256']:
        raise AssertionError('Actual retained image did not change after recoloring')
    after=list(map(int,r.cyrusRetainedStreamStats()))
    if before[1:4]!=after[1:4]:raise AssertionError('Recolor uploaded geometry')
    ms('hide CaptureOwner;CyrusMeshEnabled=false;CyrusPointEnabled=false')
    capture('fallback-green-blue-unbanded')
    ms('''
unhide CaptureOwner;CyrusMeshEnabled=true;CyrusPointEnabled=true
local samples=#();for y=-10 to 10 do for x=-10 to 10 do append samples [x,y,0]
CaptureCache=aminScatterBuildPreview CaptureRows #(samples) CapturePalette 10000
CyrusViewportRecords[1][3]=#(CaptureCache)
cyrusRetainedPublish CaptureOwner CaptureController #(CaptureCache) #(#(false,white))
''')
    capture('retained-red-blue-unbanded-points')
    before=list(map(int,r.cyrusRetainedStreamStats()))
    ms('CaptureCache=cyrusRecolorPreview CaptureCache #(1,3,#(white),#(#(17,green),#(25,blue)),false);CyrusViewportRecords[1][3]=#(CaptureCache);cyrusRetainedPublish CaptureOwner CaptureController #(CaptureCache) #(#(false,white))')
    capture('retained-green-blue-unbanded-points')
    after=list(map(int,r.cyrusRetainedStreamStats()))
    if before[1:4]!=after[1:4]:raise AssertionError('Point recolor uploaded geometry')
    if report['images'][3]['sha256']==report['images'][4]['sha256']:
        raise AssertionError('Actual retained point image did not change after recoloring')
    ms('hide CaptureOwner;CyrusMeshEnabled=false;CyrusPointEnabled=false')
    capture('fallback-green-blue-unbanded-points')
    ms('CyrusViewportRecords=#()')
    capture('empty-background')
    report['passed']=True;report['scope']='Capture and upload checks only; run verify_palette_images.py for image-content acceptance.'
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:
    r.CyrusPointBusy=False;r.CyrusPointSuspended=False;r.CyrusMeshEnabled=True;r.CyrusPointEnabled=True
    r.resetMaxFile(r.Name('noPrompt'))
    ms('CaptureCache=undefined;CaptureOwner=undefined;CaptureSource=undefined;CaptureController=undefined;gc light:false')
    (OUT/('palette-images-'+token+'.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
if not report['passed']:raise RuntimeError(report['error'])
