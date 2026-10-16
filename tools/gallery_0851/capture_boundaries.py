"""Capture/pending-state and revision-5 load boundaries in the owned Max profile."""
from pathlib import Path
import json,traceback,uuid
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
run=uuid.uuid4().hex;result={'status':'running','checks':[]}
def save():
 data=json.dumps(result,indent=2);(OUT/f'capture-boundaries-{run}.json').write_text(data,encoding='utf-8');(OUT/'capture-boundaries.json').write_text(data,encoding='utf-8')
def check(ok,label):result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def rejects(fn,label):
 try:fn()
 except Exception as e:result.setdefault('expected_errors',[]).append(str(e));check(True,label);return
 check(False,label)
try:
 for name in ('CyrusRecipeBrowser','CyrusRecipeSaveEditor','CyrusRecipeLoadEditor','CyrusRecipeDetailEditor'):
  window=getattr(r,name)
  if window is not None:r.destroyDialog(window)
 r.CyrusPerfHeadless=True;r.loadMaxFile(str(ROOT/'AminScatter/library/borders.max'),quiet=True,useFileUnits=True)
 root=next(n.baseObject for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject');root.updateMode=1;root.refreshAll()
 folder=OUT/f'capture-{run}';folder.mkdir();r.CyrusOpenRecipeSave(root,str(folder));b=r.CyrusRecipeSaveEditor
 before=int(root.procEpoch)
 with pymxs.undo(False):root.layerObjects[0].amount+=1
 rejects(lambda:b.capturePreview(False),'Pending Manual capture rejects without updating')
 check(int(root.procEpoch)==before and not list(folder.iterdir()),'Rejected capture retains publication and writes no entry')
 b.capturePreview(True);check(int(root.procEpoch)>before and b.thumbnailCapture is not None,'Explicit Update + capture publishes and records a preview')
 with pymxs.undo(False):root.layerObjects[0].amount+=1
 rejects(lambda:b.saveEntry(False),'Save rejects preview of different authored settings')
 check(not list(folder.glob('*.csrecipe.json')),'Stale capture cannot publish a mislabeled entry')
 b.clearThumbnail.pressed();path=str(b.saveEntry(False));check(Path(path).is_file(),'Clear preview allows authored pending settings to save')
 data=r.cyrusRecipeRead(path);expected=str(r.cyrusRecipeContentFingerprint(b.captureSelection()))
 check(str(r.cyrusRecipeContentFingerprint(data))==expected,'Hydrated saved content matches complete source settings and Paint')
 b.closeButton.pressed()
 # Python preparation has an implicit Undo context. Test product import/Undo in a
 # separate native MAXScript request after reloading this owned preparation file.
 r.execute('global GalleryCaptureRecipePath')
 r.GalleryCaptureRecipePath=path
 (OUT/'capture-recipe-path.txt').write_text(path,encoding='utf-8')
 check(r.saveMaxFile(str(OUT/'capture-source.max'),quiet=True,useNewFile=False),'Save owned preparation for native import/Undo witness')
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
