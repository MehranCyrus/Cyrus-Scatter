"""Private, read-only tracing of recipe capture; no product function replacement."""
from pathlib import Path
import json
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.name.startswith('foundation-roadmap-recipes0825-')
source=(ROOT/'AminScatter/tools/ui/templates/recipes.ms').read_text(encoding='utf-8')
start=source.index('fn CyrusRecipeCapture root selected name = (');end=source.index('\nfn CyrusRecipeResolve',start)
lines=source[start:end].replace('fn CyrusRecipeCapture root','fn CyrusRecipeProbeCapture root',1).splitlines()
trace=['global CyrusRecipeProbeLine=0,CyrusRecipeProbeCapture']
for i,line in enumerate(lines):
    stripped=line.strip()
    if i and stripped and not stripped.startswith((')',')else',')catch')):trace.append('    CyrusRecipeProbeLine='+str(i+1))
    trace.append(line)
r.execute('\n'.join(trace))
result={}
try:r.CyrusRecipeProbeCapture(r.RecipeTestRoot,r.RecipeTestRoot.layerObjects,'Probe');result['passed']=True
except Exception as e:result={'passed':False,'line':int(r.CyrusRecipeProbeLine),'source':lines[int(r.CyrusRecipeProbeLine)-1],'error':str(e)}
(OUT/'recipe-trace.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
