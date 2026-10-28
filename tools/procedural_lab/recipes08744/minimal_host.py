"""Initialize the exact installed patch in a disposable Max 2027 profile."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));root=Path(__file__).resolve().parents[3]
try:
    obj=r.AminScatterObject();assert str(obj.uiVersion())=='0.87.4.4' and int(r.cyrusInteractionVersion())==11 and int(r.cyrusRecipeVersion())==9 and int(r.cyrusEditVersion())==3
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFSphere,WFEdit,WFSection;global MCPFixtureDir=GardenRun')
    r.execute('fileIn @"'+(root/'tools/mcp/development_transport.ms').as_posix()+'"')
    result={'status':'ready','version':str(obj.uiVersion()),'native_capability':11,'schema':int(obj.version)}
except Exception:result={'status':'failed','error':traceback.format_exc()}
(host/'ready.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
