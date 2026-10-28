"""Initialize the exact installed patch in a disposable Max 2027 profile."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));root=Path(__file__).resolve().parents[3]
try:
    obj=r.AminScatterObject();assert str(obj.uiVersion())=='0.87.5.1' and int(r.cyrusInteractionVersion())==12
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFSphere,WFEdit,WFSection;global MCPFixtureDir=GardenRun')
    r.execute('fileIn @"'+(root/'tools/mcp/development_transport.ms').as_posix()+'"')
    result={'status':'ready','version':str(obj.uiVersion()),'native_capability':12,'schema':int(obj.version)}
except Exception:result={'status':'failed','error':traceback.format_exc()}
(host/'ready.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
