"""Owned copy-in-memory of delivered garden; never saves over artist data."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback,statistics
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));data={}
def save(): (out/'garden-pick.json').write_text(json.dumps(data,indent=2))
try:
    r.CyrusSelectionTimer.Stop();r.execute('subObjectLevel=0;clearSelection()')
    r.loadMaxFile(str(ROOT/'dist/CyrusScatter-0.87.6.1-20261029/Scenes/Terraces_Garden_0.87.6.1_Max2027.max'),quiet=True,useFileUnits=True)
    nodes=[n for n in r.objects if r.classOf(n.baseObject)==r.AminScatterObject]
    data['owners']=[str(n.name) for n in nodes];data['status']='loaded';save()
    for _ in range(25):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.04)
    data['epochs_before']=[int(n.baseObject.procEpoch) for n in nodes]
    data['streams_before']=list(r.cyrusRetainedStreamStats())
    data['placements']=[sum(int(l.generatedCount) for l in n.baseObject.layerObjects) for n in nodes]
    data['errors']=[str(n.baseObject.interactionError) for n in nodes]
    data['status']='ready';save()
    samples=[];w,h=int(r.gw.getWinSizeX()),int(r.gw.getWinSizeY())
    for iy in range(1,8):
        for ix in range(1,12):
            x,y=int(w*ix/12),int(h*iy/8);t=time.perf_counter();hits=[]
            for n in nodes:
                hit=r.cyrusViewportPickAt(n,x,y)
                if hit!=r.undefined:hits.append(str(n.name))
            samples.append(dict(x=x,y=y,owners=hits,ms=(time.perf_counter()-t)*1000))
    data['samples']=samples;data['median_ms']=statistics.median(s['ms'] for s in samples);data['max_ms']=max(s['ms'] for s in samples)
    data['epochs_after']=[int(n.baseObject.procEpoch) for n in nodes]
    data['streams_after']=list(r.cyrusRetainedStreamStats());data['status']='complete';save()
except Exception:data.update(status='failed',error=traceback.format_exc());save()
