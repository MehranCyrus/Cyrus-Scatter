"""Trace the frozen draw function's polyline sink in a private host (not screen pixels)."""
from pathlib import Path
import sys,traceback,hashlib
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('create-visibility')
def traced(script):
    source=script.read_text(encoding='utf-8-sig')
    body=source[source.index('fn AminScatterObjectDraw = ('):source.index('registerRedrawViewsCallback AminScatterObjectDraw')]
    if body.count('gw.polyline path false')!=1:raise RuntimeError('Unexpected draw body')
    body=body.replace('fn AminScatterObjectDraw =','fn CyrusCreationDrawTrace =')
    body=body.replace('local held=CyrusInteractionHeld()','local held=true')
    body=body.replace('gw.polyline path false','(append CyrusCreationDrawPaths path[1].x;gw.polyline path false)')
    mx('global CyrusCreationDrawPaths=#(),CyrusCreationDrawTrace;'+body)
    r.CyrusCreationDrawTrace()
    return list(map(float,r.CyrusCreationDrawPaths))
try:
    rec.check(len(controllers())==1,'Creation witness contains one controller')
    node=controllers()[0];r.CyrusViewportRecords=r.Array();r.CyrusViewportRecordsDirty=False
    before=state()
    baseline=ROOT/'build/mcp-qualification/refine0795-create-baseline-2027-01/scripts/CyrusScatter.ms'
    fixed=OUT/'scripts/CyrusScatter.ms'
    rec.data['baseline_sha256']=hashlib.sha256(baseline.read_bytes()).hexdigest()
    rec.data['tested_sha256']=hashlib.sha256(fixed.read_bytes()).hexdigest()
    rec.check(len(traced(baseline))==0,'Old draw function reproduces missing new icon with an empty display cache')
    for size in (10,30,60):
        node.iconSize=size;paths=traced(fixed)
        rec.check(len(paths)==3,f'New icon submits all three polylines at size {size} while held')
        rec.check(abs(paths[0]-size)<.001,f'Drawn ring reflects size {size}')
        r.AminScatterObjectDraw()
    rec.check(before['controllers'][0]['epoch']==state()['controllers'][0]['epoch'],'Icon sizing does not publish placements')
    rec.check(len(r.CyrusViewportRecords)==0,'Drawing icons does not require a display publication')
    node.isHidden=True
    rec.check(len(traced(fixed))==0,'Hidden controller does not draw')
    node.isHidden=False
    rec.check(len(traced(fixed))==3,'Unhidden controller draws again')
    r.CyrusCreationNode=node
    mx('undo "Creation icon delete witness" on delete CyrusCreationNode')
    r.CyrusPruneTimeOwners()
    rec.check(len(traced(fixed))==0,'Deleted controller does not draw')
    mx('max undo');pump(150)
    rec.check(len(controllers())==1,'Undo restores the controller')
    rec.check(len(traced(fixed))==3,'Undo restores icon registration')
    mx('max redo');pump(150)
    rec.check(len(traced(fixed))==0,'Redo removes icon submission')
    mx('max undo');pump(150)
    path=OUT/'creation-roundtrip.max';r.saveMaxFile(str(path),quiet=True)
    r.loadMaxFile(str(path),quiet=True,useFileUnits=True);pump(150)
    rec.check(len(traced(fixed))==3,'Saved and reopened empty controller draws')
    rec.write()
except Exception:rec.error(traceback.format_exc())
