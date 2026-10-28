from pathlib import Path
import json,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));phase=str(r.CVProfileCase);report={'phase':phase}
try:
    if phase=='gallery-open':
        node=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
        r.CyrusOpenRecipeLibrary(node.baseObject);r.CyrusRecipeBrowser.panel.SetNavigation(1,'',False);r.CyrusRecipeBrowser.refresh()
    else:
        r.CyrusRecipeBrowser.showPage();entries=list(r.CyrusRecipeBrowser.entries);scenes=[str(x[1][0]) for x in entries if str(x[1][16])=='Scene preset'];assert scenes
        report.update(scene_cards=len(scenes),names=scenes[:5],native_version=int(r.cyrusScenePresetVersion()))
    report['status']='passed'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(O/(phase+'.json')).write_text(json.dumps(report,indent=2))
