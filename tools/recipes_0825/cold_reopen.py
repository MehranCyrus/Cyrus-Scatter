"""Cold scene reconstruction with the qualified recipe/native pair."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from recipe_rows import fingerprint
import json,traceback
import pymxs
from pymxs import runtime as r
OUT=Path(str(r.MCPFixtureDir)).resolve();assert OUT.name.startswith('foundation-roadmap-recipes0825-')
data={'status':'started','checks':[]}
def save():(OUT/'recipe-reopen.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def check(v,label):
    data['checks'].append({'passed':bool(v),'label':label});save()
    if not v:raise AssertionError(label)
try:
    with pymxs.undo(False):
        receipt=json.loads((OUT/'recipes-qualification.json').read_text())
        r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'));r.loadMaxFile(receipt['saved_scene'],quiet=True,useFileUnits=True)
        source=r.getNodeByName('Recipe 0.82.5 source').baseObject
        document=r.cyrusRecipeRead(receipt['recipe_file']);layers=r.CyrusRecipeGet(document,'layers')
        paint=r.CyrusRecipeGet(layers[1],'areas')
        expected=[str(r.CyrusRecipeGet(r.CyrusRecipeGet(a,'paint'),'payload')) for a in paint]
        check([str(r.cyrusBrushRecipeExport(a.paintDocument)[0]) for a in source.layerObjects[1].paintAreas]==expected,'Scene reopen retains active, disabled and empty Paint payloads exactly')
        fresh=r.getNodeByName(str(r.CyrusRecipeGet(document,'name'))).baseObject
        fresh.procManualRevision+=1;fresh.evaluateProcedural()
        check([len(rows) for rows in fresh.groupSnapshotRows]==receipt['counts'],'Reopened recipe setup restores exact accepted counts')
        check([fingerprint(rows) for rows in fresh.groupSnapshotRows]==receipt['fingerprints'],'Reopened setup restores full IDs, matrices, anchors and source correspondence')
        check(int(fresh.updateMode)==1 and str(fresh.uiVersion())=='0.82.5','Saved update mode and current implementation remain coherent')
        data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise
