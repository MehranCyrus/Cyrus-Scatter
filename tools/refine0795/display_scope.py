"""Measure whether a local presentation edit rebuilds unrelated layer previews."""
from pathlib import Path
import sys,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('display-scope')
try:
    node=r.getNodeByName('CYRUS | Terraced garden 0.79.5');root=node.baseObject
    rec.step('Realize full Mesh preview',lambda:root.setGroupDisplay(3))
    initial=fingerprint(root);epoch=int(root.procEpoch);before=[int(l.previewBuildCount) for l in root.layerObjects]
    rec.step('Change only first-layer source identification color',lambda:root.layerObjects[0].setSourceIDColor(bits(1),r.color(212,95,185)))
    after=[int(l.previewBuildCount) for l in root.layerObjects]
    rec.data['local_color_rebuilds']=[b-a for a,b in zip(before,after)];rec.write()
    rec.check(fingerprint(root)==initial and int(root.procEpoch)==epoch,'Identification color preserves the placement publication')
    # Record the inefficiency without stopping the remaining witness.
    rec.data['assertions'].append(dict(passed=all(a==b for a,b in zip(before[1:],after[1:])),label='Local color edit reuses every other layer preview'))
    rec.write()
    before=[int(l.previewBuildCount) for l in root.layerObjects]
    rec.step('Repeat identical identification color',lambda:root.layerObjects[0].setSourceIDColor(bits(1),r.color(212,95,185)))
    rec.check(before==[int(l.previewBuildCount) for l in root.layerObjects],'Identical color performs no preview reconstruction')
    before=[int(l.previewBuildCount) for l in root.layerObjects]
    root.layerObjects[0].sourceShowRadius=arr([True,False]);root.radiusDisplayLimit=400
    rec.step('Show radius on first layer only',root.refreshDisplay)
    after=[int(l.previewBuildCount) for l in root.layerObjects]
    rec.data['radius_rebuilds']=[b-a for a,b in zip(before,after)];rec.write()
    rec.check(fingerprint(root)==initial and int(root.procEpoch)==epoch,'Radius visibility preserves the placement publication')
    before=state();rec.step('Unchanged display refresh',root.refreshDisplay);after=state()
    rec.check([l['preview_builds'] for l in before['controllers'][0]['layers']]==[l['preview_builds'] for l in after['controllers'][0]['layers']],'Unchanged display refresh retains all previews')
    root.layerObjects[0].sourceShowRadius=arr([False,False]);root.refreshDisplay()
    rec.step('Return to centres',lambda:root.setGroupDisplay(4))
except Exception:rec.error(traceback.format_exc())
