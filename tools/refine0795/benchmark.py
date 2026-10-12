"""Equal-scene repeated presentation edits and unchanged navigation; serialize hosts."""
from pathlib import Path
import sys,traceback,statistics
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('benchmark')
try:
    node=r.getNodeByName('CYRUS | Terraced garden 0.79.5');root=node.baseObject
    root.layerObjects[0].sourceShowRadius=arr([False,False]);root.refreshDisplay();root.setGroupDisplay(3)
    r.clearSelection();r.viewport.setCamera(r.getNodeByName('01 HERO | Terraced garden'));r.CyrusPointSync();r.completeRedraw();r.completeRedraw()
    initial=fingerprint(root);epoch=int(root.procEpoch)
    for i in range(12):
        rec.step('local-color-'+str(i),lambda i=i:root.layerObjects[0].setSourceIDColor(bits(1),r.color(70+i*7,180-i*5,90+i*4)))
    for i in range(12):rec.step('unchanged-display-'+str(i),root.refreshDisplay)
    root.setGroupDisplay(4);r.CyrusPointSync();r.completeRedraw();r.completeRedraw()
    before=state();times=[];view=r.viewport.getTM();r.viewport.setType(r.Name('view_persp_user'));r.viewport.setTM(view)
    for i in range(40):
        started=time.perf_counter();r.viewport.setTM(r.rotateZMatrix(.15*i)*view);r.completeRedraw();times.append((time.perf_counter()-started)*1000)
    r.viewport.setTM(view);after=state()
    rec.data['navigation']=dict(samples_ms=times,median_ms=statistics.median(times),before=before,after=after)
    rec.check(fingerprint(root)==initial and int(root.procEpoch)==epoch,'Presentation and 40 navigation frames preserve all placements')
    a=before['controllers'][0];b=after['controllers'][0]
    rec.check(a['retained'][:7]==b['retained'][:7] and [l['preview_builds'] for l in a['layers']]==[l['preview_builds'] for l in b['layers']],'Navigation rebuilds and uploads nothing')
    for prefix in ('local-color','unchanged-display'):
        rows=[x for x in rec.data['checkpoints'] if x['label'].startswith(prefix)]
        rec.data[prefix]=dict(median_action_ms=statistics.median(x['action_ms'] for x in rows),median_total_ms=statistics.median(x['action_ms']+x['redraw_ms'] for x in rows),
            upload_counts=[int(x['after']['controllers'][0]['retained'][5])-int(x['before']['controllers'][0]['retained'][5]) for x in rows],
            upload_bytes=[int(x['after']['controllers'][0]['retained'][6])-int(x['before']['controllers'][0]['retained'][6]) for x in rows])
    rec.write()
except Exception:rec.error(traceback.format_exc())
