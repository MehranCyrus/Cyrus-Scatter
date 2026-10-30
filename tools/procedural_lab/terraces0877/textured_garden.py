"""Retained display-only refresh; no placement changes."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data=[]
try:
    for node in r.GardenNodes:
        root=node.baseObject;before=int(root.procEpoch);start=time.perf_counter()
        root.identificationMode=4;root.setGroupDisplay(3)
        r.windows.processPostedMessages()
        data.append(dict(name=str(node.name),seconds=time.perf_counter()-start,epoch_before=before,epoch_after=int(root.procEpoch),status=str(root.allStatus()),errors=[str(l.previewError) for l in root.layerObjects]))
    r.execute('viewport.SetRenderLevel #smoothhighlights;viewport.SetShowEdgeFaces false;clearSelection()')
    for name,cam in [('overview',r.TCOverview),('lake',r.TCLake),('house',r.TCHouse)]:
        r.viewport.setCamera(cam)
        for _ in range(12):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
        b=r.gw.getViewportDib();b.filename=str(out/('garden-textured-'+name+'.png'));r.save(b);r.close(b)
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Textured.max'),quiet=True)
    result=dict(status='complete',controllers=data,memory=list(r.cyrusViewportMemoryStats()))
except Exception:result=dict(status='failed',error=traceback.format_exc(),controllers=data)
(out/'textured-garden.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
