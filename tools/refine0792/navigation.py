"""Product-only scripted navigation timing; no callback bypasses or UI input."""
from pathlib import Path
import hashlib,json,statistics,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('refine0791-layer0792-'):
    raise RuntimeError('Owned 0.79.2 host required')
report=dict(errors=[],measurements=[],assertions=[])
def write():(OUT/'navigation0792.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(value,label):
    report['assertions'].append(dict(passed=bool(value),label=label));write()
def nodes():return [n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject']
def state():
    return [dict(name=str(n.name),epoch=int(n.baseObject.procEpoch),
        groups=list(map(int,n.baseObject.groupCounters())),
        input_time=list(map(str,n.baseObject.inputTimeStats())),
        retained=list(map(str,r.cyrusRetainedStats(r.CyrusPointOwner(n)))) if r.CyrusPointOwner(n) else None,
        layers=[dict(id=str(l.layerID),builds=int(l.previewBuildCount),prepared=int(l.procPreparedBuilds),
            receivers=list(map(str,l.receiverCacheStats())),input_time=list(map(str,l.inputTimeStats())),shown=int(l.cachedPointCount),error=str(l.previewError))
            for l in n.baseObject.layerObjects]) for n in nodes()]
def stable(a,b):
    for x,y in zip(a,b):
        if any(x[k]!=y[k] for k in ['name','epoch','groups','layers','input_time']):return False
        # Retained stats: point count, groups, publication, prepares, realized
        # items, uploads, uploaded bytes. Draw counters intentionally advance.
        if x['retained'][:7]!=y['retained'][:7]:return False
    return len(a)==len(b)
def background():
    return dict(pf_builds=int(r.CyrusPFBuilds),live_events=int(r.CyrusLiveChangeCalls),
        analyzers={str(n.name):int(n.getAnalysisRuns()) for n in r.objects if str(r.classOf(n.baseObject))=='CyrusSurfaceAnalyzer'})
try:
    started=time.perf_counter();r.loadMaxFile(str(OUT/'input-examples.max'),quiet=True,useFileUnits=True)
    report['load_ms']=(time.perf_counter()-started)*1000
    report['input_sha256']=hashlib.sha256((OUT/'input-examples.max').read_bytes()).hexdigest()
    started=time.perf_counter()
    for n in nodes():n.baseObject.refreshAll()
    r.clearSelection();r.CyrusPointSync();r.completeRedraw();r.completeRedraw()
    report['update_all_ms']=(time.perf_counter()-started)*1000
    receivers=[]
    for n in nodes():
        for l in n.baseObject.layerObjects:
            for s in l.surfaceNodes:
                if s not in receivers:receivers.append(s)
    bounds=[r.nodeGetBoundingBox(n,r.matrix3(1)) for n in receivers]
    lo=r.Point3(*[min(float(b[0][i]) for b in bounds) for i in range(3)])
    hi=r.Point3(*[max(float(b[1][i]) for b in bounds) for i in range(3)])
    center=(lo+hi)*.5;span=float(r.length(hi-lo));eye=center+r.Point3(0,-span*.65,span*1.1)
    normal=r.normalize(eye-center);right=r.normalize(r.cross(r.Point3(0,0,1),normal));up=r.cross(normal,right)
    r.viewport.setType(r.Name('view_persp_user'));r.viewport.setTM(r.inverse(r.matrix3(right,up,normal,eye)))
    r.completeRedraw();r.completeRedraw()
    report['inventory']=[dict(name=str(n.name),shown=sum(int(l.cachedPointCount) for l in n.baseObject.layerObjects),
        rings=sum(int(l.radiusDisplayCount()) for l in n.baseObject.layerObjects),
        fingerprints=[str(r.cyrusEditFingerprint(rows,'areas')) for rows in n.baseObject.groupSnapshotRows]) for n in nodes()]
    check(sum(n['shown'] for n in report['inventory'])==18759,'All 18,759 displayed points retained')
    check(sum(n['rings'] for n in report['inventory'])==5546,'All 5,546 radius circles retained')
    # Each cache stores 24 closed line segments per ring. Export is diagnostic
    # only; normal display never expands these buffers back into script arrays.
    parity=[]
    for n in nodes():
        for l in n.baseObject.layerObjects:
            if int(l.radiusDisplayCount()):
                vertices=list(r.aminScatterPreviewPoints(l.radiusCache))
                expected=[]
                for ring in l.radiusPreview:
                    pts=list(ring[0]);color=ring[1]
                    expected.extend((str(p),str(color)) for pair in zip(pts,pts[1:]+pts[:1]) for p in pair)
                actual=[(str(row[0]),str(row[1])) for row in vertices]
                parity.append(sorted(actual)==sorted(expected))
    check(all(parity) and len(parity)==5,'Native line coordinates/colors exactly match all five scripted ring arrays')
    r.execute('''global N792View=viewport.getTM(),N792Measure
fn N792Measure motion held = (
 local previous=CyrusInteractionHeld
 if held do (global N792TestHeld;fn N792TestHeld=true;CyrusInteractionHeld=N792TestHeld)
 local samples=#(),clock=dotNetClass "System.Diagnostics.Stopwatch",frequency=(dotNetClass "System.Diagnostics.Stopwatch").Frequency as double
 try (
  viewport.setTM N792View;completeRedraw();completeRedraw()
  for i=1 to 12 do (
   local start=clock.GetTimestamp()
   case motion of (
    1: viewport.setTM ((rotateZMatrix (0.25*i))*N792View)
    2: (local tm=copy N792View;tm.row4+=[i*2.0,0,0];viewport.setTM tm)
    3: viewport.zoom (if mod i 2==0 then 1.01 else (1.0/1.01))
   )
   completeRedraw();append samples (((clock.GetTimestamp()-start) as double)*1000.0/frequency)
  )
 )catch(CyrusInteractionHeld=previous;throw())
 CyrusInteractionHeld=previous;viewport.setTM N792View;completeRedraw();samples
)''')
    for held in (False,True):
        for motion,label in [(1,'orbit'),(2,'pan'),(3,'zoom'),(0,'static'),(1,'orbit-repeat')]:
            before=state();bg_before=background();samples=list(map(float,r.N792Measure(motion,held)));after=state();bg_after=background()
            report['measurements'].append(dict(label=label,held=held,samples_ms=samples,
                median_ms=statistics.median(samples),before=before,after=after,background_before=bg_before,background_after=bg_after))
            check(stable(before,after),label+(' held' if held else '')+': no placement/preparation/publication/upload changes')
            check(bg_before==bg_after,label+(' held' if held else '')+': no Analyzer/render-bridge/live-event work')
    report['records']=len(r.CyrusViewportRecords);report['native_error']=str(r.CyrusPointLastError)
    check(report['records']==26 and not report['native_error'],'All 26 controllers cached without native error')
    image=r.gw.getViewportDib();image.filename=str(OUT/'navigation0792.png');r.save(image);r.close(image)
except Exception:report['errors'].append(traceback.format_exc())
finally:write()
