from pathlib import Path
import sys,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('garden-reopen')
try:
    source=ROOT/'build/mcp-qualification/refine0795-baseline-2027-01/Terraced_Garden.max'
    rec.step('Open baseline terraced scene',lambda:r.loadMaxFile(str(source),quiet=True,useFileUnits=True))
    root=r.getNodeByName('CYRUS | Terraced garden 0.79.5').baseObject
    rec.step('Rebuild saved terraced scene',lambda:update(root))
    import json
    expected=json.loads((source.parent/'garden-build.json').read_text())['final']['controllers'][0]['fingerprints']
    rec.check(fingerprint(root)==expected,'New build preserves every baseline landscape placement')
except Exception:rec.error(traceback.format_exc())
