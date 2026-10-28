"""Initialize the exact installed patch in a disposable Max 2027 profile."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun));root=Path(__file__).resolve().parents[3]
try:
    # Do not create a temporary scripted scene object inside Python just to
    # inspect its caption. Runtime scene schema is checked by the fixture.
    assert str(r.CyrusLibraryVersion())=='0.87.5.3' and int(r.cyrusInteractionVersion())==13
    assert int(r.cyrusSourceCommandUndoVersion())==1 and int(r.cyrusSourceTransformVersion())==2
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFSphere,WFEdit,WFSection;global MCPFixtureDir=GardenRun')
    r.execute('fileIn @"'+(root/'tools/mcp/development_transport.ms').as_posix()+'"')
    result={'status':'ready','version':str(r.CyrusLibraryVersion()),'native_capability':13,'schema_expected':63,
            'source_transform_capability':2,'source_undo_capability':1}
except Exception:result={'status':'failed','error':traceback.format_exc()}
(host/'ready.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
