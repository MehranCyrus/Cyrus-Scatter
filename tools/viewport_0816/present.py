"""Bounded camera and idle redraw windows for external PresentMon correlation."""
from pathlib import Path
import json,time,math,statistics,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-viewport0816-')
data={'status':'started','cases':[]}
def save():(OUT/'present-windows.json').write_text(json.dumps(data,indent=2)+'\n')
def settle():
    end=time.perf_counter()+.8
    while time.perf_counter()<end:r.windows.processPostedMessages();time.sleep(.02)
    r.completeRedraw()
try:
    node=r.getNodeByName('CYRUS | Terrace planting 0.81.5');root=node.baseObject;base=r.inverse(r.getNodeByName('PhysCamera002').transform)
    root.viewportFaces=2000000;root.viewportNavigationFaces=500000
    for label,mode,move in [('off',1,True),('points-nav',1,True),('proxy-nav',2,True),('mesh-nav',3,True),('mesh-idle',3,False)]:
        root.showPoints=label!='off';root.setGroupDisplay(mode);r.CyrusPointSync();r.viewport.setTM(base);r.completeRedraw();settle()
        case={'label':label,'begin_qpc_ms':time.perf_counter()*1000,'samples':[]};data['cases'].append(case);save()
        for i in range(80):
            start=time.perf_counter()
            if move:r.viewport.setTM(r.rotateZMatrix(1.5*math.sin((i+1)*.15))*base)
            r.completeRedraw();r.windows.processPostedMessages();case['samples'].append((time.perf_counter()-start)*1000)
            if case['samples'][-1]>2000:raise RuntimeError('Navigation frame exceeded two seconds')
        case['end_qpc_ms']=time.perf_counter()*1000;case['median_redraw_ms']=statistics.median(case['samples']);save()
    r.viewport.setTM(base);r.completeRedraw();settle();data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])
