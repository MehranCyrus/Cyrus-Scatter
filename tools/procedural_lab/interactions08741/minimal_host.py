"""Ready a separate owned Max host for scenario-specific scene loading."""
from pathlib import Path
import json, traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));root=Path(__file__).resolve().parents[3]
try:
    instance=r.AminScatterObject()
    assert str(instance.uiVersion())=='0.87.4.1' and int(r.cyrusInteractionVersion())==9
    r.execute('global MCPFixtureDir=GardenRun;fileIn @"'+(root/'tools/mcp/development_transport.ms').as_posix()+'"')
    result={'status':'ready','version':str(instance.uiVersion()),'native_capability':9,'schema':int(instance.version)}
except Exception:
    result={'status':'failed','error':traceback.format_exc()}
(host/'ready.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
