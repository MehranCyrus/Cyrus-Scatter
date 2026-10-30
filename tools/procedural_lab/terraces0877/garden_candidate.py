from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    start=time.perf_counter()
    assert r.loadMaxFile(str(out.parent/'Terraces_Garden_Resolved.max'),quiet=True,useFileUnits=True)
    r.execute('''global GardenNodes=#(),GardenSources=#(),GardenLayers=#(),TCBoulderCamera,TCOverview,TCLake,TCHouse
      for n in objects do (
        if matchPattern n.name pattern:"SOURCE | *" do append GardenSources n
        if classof n.baseObject==AminScatterObject and matchPattern n.name pattern:"GARDEN | *" do (append GardenNodes n;join GardenLayers n.baseObject.layerObjects))
      TCBoulderCamera=getNodeByName "GARDEN | 04 Boulder garden" exact:true
      TCOverview=getNodeByName "GARDEN | 01 Terraced estate" exact:true
      TCLake=getNodeByName "GARDEN | 02 Lake promenade" exact:true
      TCHouse=getNodeByName "GARDEN | 03 Meadow and house" exact:true
      clearSelection();viewport.setLayout #layout_1;viewport.setCamera TCBoulderCamera
      (getNodeByName "msh_water_surface" exact:true).renderable=true
      for n in GardenNodes do (n.baseObject.viewportFaces=6000000;n.baseObject.viewportNavigationFaces=1000000;n.baseObject.refreshAll())
      CyrusPointSync()''')
    for _ in range(15):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
    data['load_and_refresh_seconds']=time.perf_counter()-start
    data['controllers']=[dict(name=str(n.name),layers=[dict(name=str(n.baseObject.layerNames[i]),count=int(l.generatedCount),error=str(l.previewError)) for i,l in enumerate(n.baseObject.layerObjects)],frame=str(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(n))) if r.CyrusPointOwner(n) is not None else 'No published owner') for n in r.GardenNodes]
    data['memory']=list(r.cyrusViewportMemoryStats());data['version']=str(r.CyrusLibraryVersion())
    b=r.gw.getViewportDib();b.filename=str(out/'garden-candidate.png');r.save(b);r.close(b)
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-candidate.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
