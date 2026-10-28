"""Initialize a disposable Max 2027 UI audit; never touches an artist scene."""
from pathlib import Path
import json, traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[3]
out = Path(str(r.GardenRun))
try:
    assert int(r.maxVersion()[0]) == 29000
    r.execute('global MCPFixtureDir=GardenRun')
    r.execute('fileIn @"' + (ROOT/'tools/mcp/development_transport.ms').as_posix() + '"')
    r.execute('global UINode,UIRoot,UILayer,UIPlane,UIModel; resetMaxFile #noPrompt; '
              'UIPlane=plane name:"UI audit receiver" length:100 width:100 lengthsegs:2 widthsegs:2; '
              'UIModel=box name:"UI audit model" width:1 length:1 height:3 pos:[80,0,0]; '
              'UINode=AminScatterObject();UIRoot=UINode.baseObject;')
    result={'status':'ready','version':str(r.CyrusLibraryVersion()),
            'interactions':int(r.cyrusInteractionVersion())}
except Exception:
    result={'status':'failed','error':traceback.format_exc()}
(out/'ready.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
