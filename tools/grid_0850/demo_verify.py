"""Actual Save Everything / New setup / Undo and reopen checks for each example."""
from pathlib import Path
import json,sys,traceback,uuid
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
req=json.loads((OUT/'command.json').read_text());slug=req['demo'];op=req['operation']
source=ROOT/'build/mcp-qualification'/req.get('source_host',OUT.name)
assert source.parent==OUT.parent and source.name.startswith('foundation-roadmap-grid0850-')
spec=json.loads((source/('demo-'+slug+'.json')).read_text());assert spec['status']=='passed'
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
result={'status':'running','demo':slug,'operation':op,'checks':[]}
def save():(OUT/('demo-'+slug+'-'+op+'.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
def check(ok,label):result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def paints(root):return [[str(r.cyrusBrushRecipeExport(a.paintDocument)[0]) for a in leaf.paintAreas] for leaf in root.layerObjects]
def plain(value):
 if value is None or isinstance(value,(str,int,float,bool)):return value
 rows=list(value)
 if len(rows)==2 and str(rows[0])=='recipeObject':return {str(p[0]):plain(p[1]) for p in rows[1]}
 return [plain(x) for x in rows]
try:
 with pymxs.undo(False):
  if op=='prepare':
   if r.CyrusRecipeBrowser is not None:r.CyrusRecipeBrowser.closeButton.pressed()
   r.CyrusPerfHeadless=True
   check(r.loadMaxFile(spec['scene'],quiet=True,useFileUnits=True),'Matching editable demonstration scene reopens')
   r.execute('global VerifyNode,VerifyRoot,VerifyRows,VerifyEpoch,VerifyDemoSlug,VerifyScenePath,VerifyRecipePath,VerifyDemoTitle')
   r.VerifyDemoSlug=slug;r.VerifyScenePath=spec['scene'];r.VerifyDemoTitle=spec['title']
   r.VerifyNode=r.getNodeByName('CYRUS EXAMPLE | '+spec['title']);r.VerifyRoot=r.VerifyNode.baseObject;root=r.VerifyRoot
   root.refreshAll();r.CyrusPerfHeadless=False;r.CyrusPointSync();r.completeRedraw()
   check([fingerprint(rows) for rows in root.groupSnapshotRows]==spec['rows'],'Reopened scene reproduces every complete placement row')
   r.VerifyEpoch=root.procEpoch;r.VerifyRows=r.copy(root.groupSnapshotRows)
   r.CyrusOpenRecipeLibrary(root);browser=r.CyrusRecipeBrowser;r.cyrusRecipeLibraryCancel(browser.scan);browser.scanTimer.active=False
   browser.directory=str(OUT/('saved-'+slug+'-'+uuid.uuid4().hex[:8]));Path(str(browser.directory)).mkdir()
   browser.libraryLocation.selection=3
   browser.recipeName.text=spec['title'];browser.thumbnailFile=spec['thumbnail']
   # Use actual Save Everything, including the Paint-bearing border preset.
   browser.saveRecipe.pressed()
   files=list(Path(str(browser.directory)).glob('*.csrecipe.json'))
   check(len(files)==1,'Actual Save Everything creates exactly one complete recipe')
   r.VerifyRecipePath=str(files[0])
   expected=plain(r.cyrusRecipeRead(spec['recipe']));actual=plain(r.cyrusRecipeRead(str(files[0])))
   expected.pop('id');actual.pop('id')
   check(actual==expected,'Every saved authored field, role, Band and Paint byte survives scene reopen and UI save')
   check(int(root.procEpoch)==int(r.VerifyEpoch),'Save Everything does not calculate the pending Manual recipe')
  else:raise ValueError(op)
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
