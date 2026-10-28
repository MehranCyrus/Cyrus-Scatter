"""Exact-payload initialization in an owned Max 2027 process."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
out=Path(str(r.GardenRun));root=Path(__file__).resolve().parents[3]
try:
    assert str(r.CyrusLibraryVersion())=='0.87.5.4'
    assert int(r.cyrusInteractionVersion())==14 and int(r.cyrusSourceCommandUndoVersion())==2
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFEdit,ADWall,ADBox,ADTree;global MCPFixtureDir=GardenRun')
    r.execute('fileIn @"'+(root/'tools/mcp/development_transport.ms').as_posix()+'"')
    result={'status':'ready','version':'0.87.5.4','interactions':14,'source_undo':2,'schema':64}
except Exception:result={'status':'failed','error':traceback.format_exc()}
(out/'ready.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
