from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));data={}
try:
    path=out.parent/'Terraces_Garden_Clean_Checkpoint.max'
    r.saveMaxFile(str(path),quiet=True)
    assert r.loadMaxFile(str(path),quiet=True,useFileUnits=True)
    r.execute('''global GardenNodes=#(),GardenSources=#(),TCGardenColliderNode,TCGardenColliderRoot,TCGardenEdit,TCGardenGrass,TCBoulderCamera,TCOverview,TCLake,TCHouse
    for n in objects do (
      if matchPattern n.name pattern:"SOURCE | *" do append GardenSources n
      if classof n.baseObject==AminScatterObject and matchPattern n.name pattern:"GARDEN | *" do append GardenNodes n)
    TCGardenColliderNode=getNodeByName "GARDEN | Lakeside boulders" exact:true;TCGardenColliderRoot=TCGardenColliderNode.baseObject
    TCGardenEdit=TCGardenColliderNode.modifiers[1];TCGardenGrass=TCGardenColliderRoot.layerObjects[4]
    TCBoulderCamera=getNodeByName "GARDEN | 04 Boulder garden" exact:true;TCOverview=getNodeByName "GARDEN | 01 Terraced estate" exact:true
    TCLake=getNodeByName "GARDEN | 02 Lake promenade" exact:true;TCHouse=getNodeByName "GARDEN | 03 Meadow and house" exact:true
    for n in GardenNodes do n.baseObject.refreshAll();CyrusPointSync()
    select TCGardenColliderNode;max modify mode;modPanel.setCurrentObject TCGardenEdit;subObjectLevel=1
    viewport.setCamera TCBoulderCamera''')
    for _ in range(20):r.completeRedraw();r.windows.processPostedMessages();time.sleep(.05)
    data['edit_inspect']=str(r.cyrusEditInspect(r.TCGardenEdit,0,3))
    data['frame']=str(r.cyrusRetainedPresentationStats(r.CyrusPointOwner(r.TCGardenColliderNode)))
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-reload.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
