import json,traceback
from pathlib import Path
from pymxs import runtime as r
out={}
checks={
 'capture':'CyrusRecipeCapture', 'authored':'CyrusRecipeCaptureAuthored','context':'CyrusRecipeCaptureContext','binding':'WFGrass.procSourceEditBinding','nativeExport':'cyrusEditRecipeExport','field':'CyrusRecipeInteractionFields',
 'owners':'WFRoot.logicalLayers()',
 'spec':'WFGrass.procSourceEditBinding (WFGrass.validSources()) WFGrass.procPreparedRows',
 'contextCreate':'global CVTestContext=CyrusRecipeCaptureContext root:WFRoot node:WFOwner owners:(WFRoot.logicalLayers()) metres:((units.decodeValue "1m") as double)',
 'authCapture':'CyrusRecipeCaptureAuthored CVTestContext',
 'wholeCapture':'CyrusRecipeCapture WFRoot (WFRoot.logicalLayers()) "debug" bindingResult:CVBindings'}
for key,code in checks.items():
 try:out[key]=str(r.execute(code))[:1200]
 except Exception as e:out[key]=str(e)
(Path(str(r.GardenRun))/'debug-capture.json').write_text(json.dumps(out,indent=2))
