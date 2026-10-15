"""Qualify warm navigation on an isolated copy of the nine-layer terrace scene."""
from pathlib import Path
import json,time,traceback,math,statistics,hashlib,shutil
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-viewport0816-')
data={'status':'started','checks':[],'cases':[],'timings':{},'metric':'scripted redraw wall time; presented frame times require separate PresentMon capture'}
def save():(OUT/'terrace.json').write_text(json.dumps(data,indent=2)+'\n')
def check(ok,label):
    data['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def timed(label,fn):
    data['running']=label;save();start=time.perf_counter();v=fn();data['timings'][label]=time.perf_counter()-start;save();return v
def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(8*1024*1024),b''):h.update(b)
    return h.hexdigest()
def state():
    owner=r.CyrusPointOwner(node)
    return {'retained':[str(x) for x in r.cyrusRetainedStats(owner)],'policy':[int(x) for x in r.cyrusRetainedViewportStats(owner)],'mesh':[int(x) for x in r.cyrusRetainedMeshStats(owner)],'streams':[int(x) for x in r.cyrusRetainedStreamStats()], 'fallback':[int(x) for x in r.cyrusPreviewFallbackStats()],'resources':[int(x) for x in r.cyrusPreviewResourceStats()], 'epoch':int(root.procEpoch),'builds':[int(l.previewStats()[0]) for l in root.layerObjects],'prepared':[int(l.procPreparedBuilds) for l in root.layerObjects],'fingerprints':[str(r.cyrusEditFingerprint(rows,'garden-final815')) for rows in root.groupSnapshotRows],'accepted':[int(l.generatedCount) for l in root.layerObjects],'errors':[str(l.previewError) for l in root.layerObjects], 'native_error':str(r.CyrusPointLastError),'detail':str(r.CyrusPointDetailStatus)}
def settle():
    stop=time.perf_counter()+.8
    while time.perf_counter()<stop:r.windows.processPostedMessages();time.sleep(.02)
    r.completeRedraw();r.windows.processPostedMessages()
def capture(label):
    b=r.gw.getViewportDib();b.filename=str(OUT/(label+'.png'));r.save(b);r.close(b)
try:
    original=ROOT/'Test Scene/Terraces_0815/Terraces_0815_Final.max';copy=OUT/'Terrace_input.max'
    data['original_sha256']=digest(original);shutil.copy2(original,copy)
    check(digest(copy)==data['original_sha256']=='54b006f2cd40183bcdb048d3ab040eaee066ad67728d5e3b76b381685ab65801','Exact preserved terrace input copy')
    r.disableSceneRedraw()
    timed('load',lambda:r.loadMaxFile(str(copy),quiet=True,useFileUnits=True))
    node=r.getNodeByName('CYRUS | Terrace planting 0.81.5');root=node.baseObject
    root.autoRender=False;r.CyrusPFTimer.Stop();r.clearSelection();r.execute('max create mode')
    # Load the saved Point Cloud view before exercising the 2M Mesh setting.
    timed('initial_update',lambda:root.refreshAll());r.CyrusPointSync()
    r.viewport.setLayout(r.Name('layout_1'));r.viewport.setType(r.Name('view_persp_user'))
    camera=r.getNodeByName('PhysCamera002');base=r.inverse(camera.transform)
    r.viewport.setTM(base);r.viewport.setFOV(camera.fov);r.viewport.setRenderLevel(r.Name('smoothhighlights'))
    r.execute('(NitrousGraphicsManager.GetActiveViewportSetting()).AdaptiveDegradeNeverDegradeGeometry=true')
    r.enableSceneRedraw();timed('first_draw',lambda:r.completeRedraw());settle()
    initial=state();data['initial']=initial;save();capture('saved-initial')
    check(sum(initial['accepted'])==245664 and not any(initial['errors']) and not initial['native_error'],'Saved terrace publishes every accepted placement without preview errors')
    check(initial['retained'][11]=='1','Saved preview reaches ready GPU state')
    baseline=initial['fingerprints'];epoch=initial['epoch']
    root.previewBudget=20000;root.viewportNavigationPoints=10000
    root.viewportInstances=2000;root.viewportNavigationInstances=500
    root.viewportFaces=2000000;root.viewportNavigationFaces=500000
    for repeat in range(2):
        for mode in ([1,2,3] if repeat==0 else [3,2,1]):
            case={'mode':mode,'repeat':repeat};data['cases'].append(case);save()
            timed('switch_'+str(mode)+'_'+str(repeat),lambda:root.setGroupDisplay(mode));r.CyrusPointSync();r.completeRedraw();settle()
            before=state();case['before']=before;save()
            check(before['retained'][11]=='1' and not before['native_error'],'Ready GPU mode '+str(mode))
            check(before['fingerprints']==baseline and before['epoch']==epoch,'Mode switch preserves complete terrace publication')
            offset={1:1,2:3,3:5}[mode];caps={1:(20000,10000),2:(2000,500),3:(2000000,500000)}[mode]
            check(0<before['policy'][offset]<=caps[0] and 0<before['policy'][offset+1]<=caps[1],'Controller-wide draw quotas within both phase limits')
            case['begin_qpc_ms']=time.perf_counter()*1000;samples=[]
            for i in range(30):
                start=time.perf_counter();r.viewport.setTM(r.rotateZMatrix(1.5*math.sin((i+1)*.25))*base)
                r.completeRedraw();r.windows.processPostedMessages();samples.append((time.perf_counter()-start)*1000)
                if samples[-1]>2000:raise RuntimeError('Bounded stop: a navigation step exceeded two seconds')
            case['end_qpc_ms']=time.perf_counter()*1000;case['frame_ms']=samples;case['median_ms']=statistics.median(samples);case['p95_ms']=sorted(samples)[math.ceil(.95*len(samples))-1]
            moving=state();case['moving']=moving
            check(moving['policy'][11]>before['policy'][11],'Navigation automatically uses active draw path')
            settle();after=state();case['after']=after;save()
            check(after['policy'][10]>moving['policy'][10],'Settling automatically restores idle draw path')
            check(all(before[k]==after[k] for k in ['epoch','prepared','builds','fingerprints']),'Camera movement causes no solve or preview rebuild')
            check(all(before['retained'][i]==after['retained'][i] for i in [2,3,5,6,8,12]),'Warm retained preparation, upload and failure counters unchanged')
            check(before['fallback']==after['fallback'],'No CPU fallback during warm navigation')
            check(before['resources'][4]==after['resources'][4],'No warm Mesh memory growth')
            r.viewport.setTM(base);r.completeRedraw();settle()
            if repeat==0:capture({1:'points',2:'proxy',3:'mesh'}[mode])
    root.setGroupDisplay(3);r.CyrusPointSync();r.completeRedraw();settle();data['final']=state()
    data['viewport_pixels']=[int(r.gw.getWinSizeX()),int(r.gw.getWinSizeY())]
    check(digest(original)==data['original_sha256'],'Artist terrace file remains unchanged')
    data['status']='complete'
except Exception:
    data['status']='failed';data['error']=traceback.format_exc()
    try:r.enableSceneRedraw()
    except:pass
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])
