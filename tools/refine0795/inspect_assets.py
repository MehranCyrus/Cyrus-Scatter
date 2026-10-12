from pathlib import Path
import sys,json,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('assets')
try:
    r.resetMaxFile(r.Name('noPrompt'))
    rec.step('Merge preserved pavilion plant library',lambda:r.mergeMAXFile(str(ROOT/'Test Scene/Reference_Garden_075/Source_Plants.max'),r.Name('select'),r.Name('autoRenameDups'),quiet=True))
    rows=[]
    for n in r.objects:
        bb=r.nodeGetBoundingBox(n,r.matrix3(1))
        rows.append(dict(name=str(n.name),kind=str(r.classOf(n)),dimensions=[float(v) for v in bb[1]-bb[0]],position=[float(v) for v in n.pos]))
    rec.data['assets']=rows;rec.data['units']=str(r.units.SystemType);rec.data['unit_scale']=float(r.units.SystemScale);rec.write()
    rec.check(bool(r.cyrusLicenseAllows()),'Normal team authoring authority active')
except Exception:rec.error(traceback.format_exc())
