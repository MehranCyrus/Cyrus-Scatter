"""Production-frame witness for the saved terraced garden."""
from pathlib import Path
import sys,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('final-render')
try:
    root=r.getNodeByName('CYRUS | Terraced garden 0.79.5').baseObject
    camera=r.getNodeByName('01 HERO | Terraced garden');before=fingerprint(root)
    target=ROOT/'Test Scene/Terraced_Garden_0795/Terraced_Garden_0795.png'
    root.autoRender=True;r.renderWidth=1600;r.renderHeight=900;r.renderers.current.progressive_passLimit=15
    started=time.perf_counter();frame=r.render(camera=camera,vfb=False,outputfile=str(target))
    rec.data['render_ms']=(time.perf_counter()-started)*1000;rec.data['image']=str(target)
    rec.check(frame is not None,'Corona returns the final terraced garden frame')
    r.close(frame);rec.check(not str(r.CyrusPFLastError),'Final render bridge completes without error')
    rec.check(fingerprint(root)==before,'Final render preserves all placements')
    rec.data['state']=state();rec.write()
except Exception:rec.error(traceback.format_exc())
