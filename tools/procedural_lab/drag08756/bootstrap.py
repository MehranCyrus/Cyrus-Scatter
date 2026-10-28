"""Owned Max 2027 viewport campaign; no artist profile or source scene writes."""
from pathlib import Path
import json, traceback
from pymxs import runtime as r
root=Path(__file__).resolve().parents[3]
out=Path(str(r.GardenRun))
try:
    assert int(r.maxVersion()[0]) == 29000
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFEdit;global MCPFixtureDir=GardenRun')
    r.execute('fileIn @"'+(root/'tools/mcp/development_transport.ms').as_posix()+'"')
    result={'status':'ready','version':str(r.CyrusLibraryVersion()),'interactions':int(r.cyrusInteractionVersion())}
except Exception: result={'status':'failed','error':traceback.format_exc()}
(out/'ready.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
