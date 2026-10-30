from pathlib import Path
from pymxs import runtime as r
import json,traceback
out=Path(str(r.GardenRun));report={}
try:
    assert json.loads((out/'violet-qualification.json').read_text())['status']=='complete'
    value=r.execute('global VRecipe=CyrusRecipeCapture VRoot #(VLayer) "Owned Violet profile recipe";CyrusRecipeGet (CyrusRecipeGet VRecipe "authored") "definitions"')
    definitions=[json.loads(str(x)) for x in value]
    assert len(definitions)==1
    d=definitions[0]
    assert d['format']==3 and d['source']['format']==3 and d['source']['authoring']['version']==2
    assert len(d['source']['metadata']['guides'])==74
    assert {x.get('profile') for x in d['source']['authoring']['parts']} >= {2,3}
    assert r.cyrusRecipeValidate(r.VRecipe)
    report={'status':'pass','checks':['full recipe capture accepts prepared envelope 3','captured source retains intent 2, Leaf and Flower head profiles, and all 74 guides','native recipe validation accepts the final serialized document'],'definition_format':d['format'],'guides':74}
except Exception:report={'status':'failed','error':traceback.format_exc()}
(out/'violet-recipe.json').write_text(json.dumps(report,indent=2))
