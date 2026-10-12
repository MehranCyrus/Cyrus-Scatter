"""Render the actual Scatter result without controlling the artist session."""
from pathlib import Path
import sys,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('render')
try:
    root=r.getNodeByName('CYRUS | Terraced garden 0.79.5').baseObject
    camera=r.getNodeByName('01 HERO | Terraced garden');before=fingerprint(root)
    root.autoRender=True;r.renderWidth=1100;r.renderHeight=619;r.renderers.current.progressive_passLimit=5
    started=time.perf_counter();frame=r.render(camera=camera,vfb=False,outputfile=str(OUT/'Terraced_Garden_Draft.png'))
    rec.data['render_ms']=(time.perf_counter()-started)*1000
    rec.check(frame is not None,'Corona returns the actual garden frame')
    r.close(frame);rec.check(not str(r.CyrusPFLastError),'Automatic scatter render bridge completes without error')
    rec.check(fingerprint(root)==before,'Rendering preserves placements')
    rec.data['state']=state();rec.write()
except Exception:rec.error(traceback.format_exc())
