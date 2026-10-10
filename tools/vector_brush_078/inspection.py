"""Run with Max's Python interpreter, after extended.ms, in an owned host."""
import json
from pathlib import Path
import sys
from pymxs import runtime as rt

ROOT=Path(__file__).resolve().parents[2]
folder=Path(str(rt.MCPFixtureDir)).resolve()
if folder.parent!=ROOT/'build/vector-brush-078':raise RuntimeError('Private vector host required')
sys.path.insert(0,str(ROOT/'CyrusMCP'))
from cyrus_mcp.max_host import MaxHost

node=rt.getNodeByName('V_Controller')
host=MaxHost();host.controllers['vector_test']=node
before=list(rt.cyrusBrushStats(rt.VD))
configuration=host.configuration('vector_test')
checks=[]
def check(value,label):
    if not value:raise AssertionError(label)
    checks.append(label)
check(configuration['configuration_schema']=='cyrus.configuration/2.0','Current inspection schema')
paint=configuration['layers'][0]['paint']
check(paint['representation']=='vector_regions' and len(paint['areas'])>0,'Reports receiver-bound vector areas')
check(paint['areas'][0]['revision']==int(before[0]),'Reads native area revision')
check(paint['areas'][0]['contour_count']==int(before[1]),'Reports contours instead of obsolete strokes')
state=host.controller_state(node)
check(state['layers'][0]['vector_paint']['areas'][0]['revision']==int(before[0]),'Freshness includes area revision')
after=list(rt.cyrusBrushStats(rt.VD))
check(before[7:10]==after[7:10],'Inspection does not prepare or query the paint field')
(folder/'inspection.json').write_text(json.dumps({'checks':checks,'configuration':configuration},indent=2))
