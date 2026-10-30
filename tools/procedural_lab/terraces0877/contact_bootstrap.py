from pathlib import Path
import json,traceback
from pymxs import runtime as r
root=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun))
try:
    r.execute('global MCPFixtureDir=GardenRun')
    r.fileIn(str(root/'tools/mcp/development_transport.ms'))
    r.loadMaxFile(str(out.parent/'Contact_Real_Tree_Fixture.max'),quiet=True,useFileUnits=True)
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFEdit,DGStone; for n in objects where classof n.baseObject==AminScatterObject and n.baseObject.overlapOwner==undefined do (WFOwner=n;WFRoot=n.baseObject); WFGrass=WFRoot.layerObjects[1];WFCollider=WFRoot.layerObjects[2];DGStone=getNodeByName "DG_Stone_Viewport_Test" exact:true')
    r.WFRoot.refreshAll();r.WFRoot.interactionsEnsure();r.CyrusPointSync()
    result=dict(status='ready',version=str(r.CyrusLibraryVersion()))
except Exception:result=dict(status='failed',error=traceback.format_exc())
(out/'ready.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
