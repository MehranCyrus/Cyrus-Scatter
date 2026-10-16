"""Exercise v5 save/capture through the actual dialog in an owned Max host."""
from pathlib import Path
import json, traceback, uuid, shutil
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
run=uuid.uuid4().hex;result={'status':'running','checks':[]}
def save():
 text=json.dumps(result,indent=2);(OUT/f'persistence-{run}.json').write_text(text,encoding='utf-8');(OUT/'persistence.json').write_text(text,encoding='utf-8')
def check(ok,label):
 result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
try:
 r.CyrusPerfHeadless=True
 check(r.loadMaxFile(str(ROOT/'AminScatter/library/borders.max'),quiet=True,useFileUnits=True),'Owned border example opens')
 root=next(n.baseObject for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject')
 root.refreshAll()
 folder=OUT/f'entry-{run}';folder.mkdir();r.CyrusOpenRecipeSave(root,str(folder));b=r.CyrusRecipeSaveEditor
 b.recipeName.text='Captured painted borders';b.recipeCategory.text='Borders';b.recipeDescription.text='Owned PG03/04 fixture'
 before=[int(root.procEpoch),*[int(l.procPreparedBuilds) for l in root.layerObjects]]
 result['before_capture']={'publication_key':str(root.groupSnapshotKey),'current_key':str(root.procInputKey()),'errors':[str(l.previewError) for l in root.layerObjects],'rows':[len(x) for x in root.groupSnapshotRows]};save()
 b.capturePreview(False)
 check(Path(str(b.thumbnailFile)).is_file(),'Explicit viewport capture creates PNG')
 check(b.thumbnailCapture is not None,'Capture includes authored/publication provenance')
 b.saveEntry(False)
 paths=list(folder.glob('*.csrecipe.json'));check(len(paths)==1,'One complete entry saved')
 path=paths[0];first=json.loads(path.read_text(encoding='utf-8'))
 check(first['revision']==1 and first['presentation']['capture']['method']=='viewport-published','Manifest holds revision and viewport witness')
 info=r.cyrusRecipeInfo(str(path));check(int(info[2])>0,'Paint attachment preserved')
 paint_before=[(str(p),p.read_bytes()) for p in folder.rglob('*.cspaint')]
 check(bool(paint_before),'Saved Paint payload exists')
 b.reviewPath=str(path);b.reviewHash=str(info[10]);b.recipeDescription.text='Updated details with same authored scene'
 b.saveEntry(True)
 second=json.loads(path.read_text(encoding='utf-8'))
 check(second['revision']==2 and second['id']==first['id'],'Update keeps identity and advances revision')
 check(all(Path(p).read_bytes()==data for p,data in paint_before),'Previous Paint payload remains intact')
 r.CyrusRecipeEditDetails(str(path),r.cyrusRecipeInfo(str(path))[10],root.uiVersion())
 d=r.CyrusRecipeDetailEditor;d.savedName.text='Renamed captured borders';d.commitDetails.pressed()
 third=json.loads(path.read_text(encoding='utf-8'))
 check(third['revision']==3 and third['name']=='Renamed captured borders','Separate metadata dialog commits revision')
 check(third['layers']==second['layers'],'Metadata-only edit preserves Paint descriptors and layer settings')
 check(before==[int(root.procEpoch),*[int(l.procPreparedBuilds) for l in root.layerObjects]],'Capture/save/update/details do not rebuild scatter')
 d.closeDetails.pressed();b.closeButton.pressed()
 result['status']='passed';save()
except Exception:
 result['status']='failed';result['error']=traceback.format_exc();save();raise
