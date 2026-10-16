"""Exercise the collection browser through product callbacks, with scene-work counters."""
from pathlib import Path
import json, traceback, uuid
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
LIBRARY=Path(str(r.CyrusRecipeBundledDirectory('0.85.1'))) if OUT.name.startswith('foundation-roadmap-gallery0851-recipient-') else ROOT/'AminScatter/library'
EXPECTED=len(json.loads((LIBRARY/'inventory.json').read_text(encoding='utf-8'))['entries'])
command=json.loads((OUT/'command.json').read_text(encoding='utf-8'));operation=command['operation'];run=uuid.uuid4().hex
result={'operation':operation,'status':'running','checks':[]}
def save():
 data=json.dumps(result,indent=2);(OUT/f'collections-{operation}-{run}.json').write_text(data,encoding='utf-8');(OUT/f'collections-{operation}.json').write_text(data,encoding='utf-8')
def check(ok,label):
 result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def counters(root):
 values=[int(root.procEpoch),int(root.groupBuilds)]
 for leaf in root.layerObjects:
  values.extend([int(leaf.procPreparedBuilds),int(leaf.procDensityBakes),*[int(x) for x in leaf.receiverCacheStats()]])
 return values
def snap(b,name):
 image=r.windows.snapshot(int(b.hwnd),captureScreenPixels=False,gammaCorrect=False);image.filename=str(OUT/(name+'.png'));r.save(image);r.close(image)
try:
 if operation=='open':
  if r.CyrusRecipeBrowser is not None:r.destroyDialog(r.CyrusRecipeBrowser)
  r.CyrusPerfHeadless=True
  if command.get('current_scene'):
   expected_rows=2*int((OUT/'heavy-count.txt').read_text(encoding='utf-8')) if (OUT/'heavy-count.txt').exists() else 60000
   check(sum(len(rows) for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' for rows in n.baseObject.groupSnapshotRows)==expected_rows,f'Owned heavy scene has {expected_rows} published rows')
   result['scene_rows']=expected_rows
  else:check(r.loadMaxFile(str(LIBRARY/'borders.max'),quiet=True,useFileUnits=True),'Owned painted borders opens')
  r.execute('global GalleryTestRoot, GalleryTestCounters')
  root=next(n.baseObject for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject');r.GalleryTestRoot=root
  if not command.get('current_scene'):root.refreshAll()
  check(len(root.groupSnapshotRows)>0,'Current native/script pair publishes plants')
  r.GalleryTestCounters=r.Array(*counters(root));r.CyrusOpenRecipeLibrary(root);b=r.CyrusRecipeBrowser
  r.cyrusRecipeLibraryCancel(b.scan);b.scanTimer.active=False
  # Empty My recipes completes immediately; start() rejects any active predecessor.
  if OUT.name.startswith('foundation-roadmap-gallery0851-recipient-'):
   b.panel.SetNavigation(2,'',True);b.action('library')
   check(Path(str(b.directory)).resolve()==LIBRARY.resolve(),'Actual Bundled library action resolves the installed release')
  else:b.directory=str(LIBRARY);b.customDirectory=b.directory;b.panel.SetNavigation(3,'',True);b.refresh()
 elif operation=='verify':
  b=r.CyrusRecipeBrowser;root=r.GalleryTestRoot;p=b.panel;g=p.Gallery
  result['catalog']={'state':str(b.scanState),'entries':len(b.entries),'expected':EXPECTED,'status':str(p.StatusText),'directory':str(b.directory),'search':str(p.SearchText),'category':str(p.Category)};save()
  check(str(b.scanState)=='complete' and len(b.entries)==EXPECTED,'Complete inventoried recipe catalog indexed')
  check(p.CollectionsView and g.ItemCount>0 and p.TreeNodeCount<=390,'Bounded collection tree and overview tiles')
  check(g.ImagesDecoded>0 and not g.IsLoading,'Visible collection previews decode and workers settle')
  snap(b,'collection-browser')
  b.loadSelected();check(not p.CollectionsView and len(b.entries)>0,'Open Collection enters its recipes')
  b.loadSelected();d=r.CyrusRecipeLoadEditor
  check(d is not None and len(d.bindings)>0,'Load Selected opens a separate binding review')
  retained=str(d.reviewPath);b.navigate('',False);p.SearchText='mountain'
  check(str(d.reviewPath)==retained,'Search cannot redirect an open binding review')
  check(len(b.entries)==1,'Search selects matching recipe metadata')
  d.closeButton.pressed()
  p.SearchText='';b.navigate('',False)
  p.ZoomIndex=2;p.ViewIndex=1;check(g.ListMode and g.TileSize==224,'Toolbar view and size events operate')
  p.ViewIndex=0;p.ZoomIndex=1
  r.setDialogSize(b,r.Point2(1120,760));snap(b,'collection-browser-wide')
  check(p.Width>1000 and p.Height>680,'Gallery grows with resizable Max dialog')
  r.setDialogSize(b,r.Point2(850,620));snap(b,'collection-browser-compact')
  check(p.Width<1000 and p.Height<680,'Gallery shrinks with dialog')
  check(counters(root)==list(r.GalleryTestCounters),'Browsing/search/navigation/dialogs/resize leave scene-work counters unchanged')
  result['stats']={'cache_bytes':int(g.DecodedBytes),'pending':int(g.PendingJobs),'jobs_started':int(g.JobsStarted),'nodes':int(p.TreeNodeCount),'width':int(p.Width),'height':int(p.Height)}
 elif operation=='snapshot':snap(r.CyrusRecipeBrowser,'collection-browser-latest')
 else:raise ValueError(operation)
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
