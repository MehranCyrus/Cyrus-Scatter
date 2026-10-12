"""Passive checkpoints for the owned 0.79.5 artist workflow campaign."""
from pathlib import Path
import json, time
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('refine0795-'):
    raise RuntimeError('Owned landscape host required')

def arr(values): return r.Array(*values)
def pt(x, y, z=0): return r.Point3(float(x), float(y), float(z))
def mx(code): return r.execute('(' + code + ')')
def pump(ms=200):
    mx(f'local finish=timeStamp()+{ms};while timeStamp()<finish do (windows.processPostedMessages();sleep .01)')
def activate(node, page):
    r.select(node); mx('max modify mode'); r.modPanel.setCurrentObject(node.baseObject); pump()
    root=node.baseObject
    if not root.mainUI.controlsReady: root.mainUI.mountTimer.tick()
    panel=getattr(root,page);panel.open=True;root.mainUI.bindSection(panel);panel.layout()
    return panel
def bits(*values): return mx('#{'+','.join(map(str,values))+'}')
def controllers(): return [n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject']
def fingerprint(root):
    return [str(r.cyrusEditFingerprint(rows,'terrace0795')) for rows in root.groupSnapshotRows]
def state():
    result=[]
    for node in controllers():
        root=node.baseObject;owner=r.CyrusPointOwner(node)
        result.append(dict(name=str(node.name),version=str(root.uiVersion()),epoch=int(root.procEpoch),
            fingerprints=fingerprint(root),groups=list(map(str,root.groupCounters())),
            retained=list(map(str,r.cyrusRetainedStats(owner))) if owner else [],
            mesh=list(map(str,r.cyrusRetainedMeshStats(owner))) if owner else [],
            layers=[dict(id=str(l.layerID),sources=[str(l.sourceLabel(i)) for i in range(1,len(l.sources)+1)],
                receivers=[str(n.name) for n in l.validSurfaces()],accepted=int(l.generatedCount),shown=int(l.cachedPointCount),
                prepared=int(l.procPreparedBuilds),preview_builds=int(l.previewBuildCount),preview_ms=float(l.previewBuildMs),
                receiver_cache=list(map(str,l.receiverCacheStats())),error=str(l.previewError),
                paint=[list(map(str,r.cyrusBrushStats(a.paintDocument))) if a.paintDocument else [] for a in l.paintAreas])
                for l in root.layerObjects]))
    process=r.dotNetClass('System.Diagnostics.Process').GetCurrentProcess();process.Refresh()
    return dict(controllers=result,memory=dict(private=int(process.PrivateMemorySize64),working=int(process.WorkingSet64)),
        render_bridge=int(r.CyrusPFBuilds),live_events=int(r.CyrusLiveChangeCalls),viewport_error=str(r.CyrusPointLastError))

class Recorder:
    def __init__(self,name):
        self.path=OUT/(name+'.json');self.data=dict(checkpoints=[],assertions=[],errors=[]);self.write()
    def write(self): self.path.write_text(json.dumps(self.data,indent=2)+'\n',encoding='utf-8')
    def check(self,ok,label,**details):
        self.data['assertions'].append(dict(passed=bool(ok),label=label,**details));self.write()
        if not ok: raise AssertionError(label)
    def step(self,label,action,redraw=True):
        before=state();started=time.perf_counter();value=action();action_ms=(time.perf_counter()-started)*1000
        started=time.perf_counter()
        if redraw:r.CyrusPointSync();r.completeRedraw()
        redraw_ms=(time.perf_counter()-started)*1000
        self.data['checkpoints'].append(dict(label=label,action_ms=action_ms,redraw_ms=redraw_ms,before=before,after=state()))
        self.write();return value
    def error(self,error):self.data['errors'].append(str(error));self.write()

def update(root):
    root.refreshAll()
    for leaf in root.layerObjects:
        if str(leaf.previewError):raise RuntimeError(str(leaf.previewError))
