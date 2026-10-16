"""Exercise actual gallery handlers in the owned Max 2027 profile."""
from pathlib import Path
import json, traceback, uuid, ctypes as c
from ctypes import wintypes as w
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
request=json.loads((OUT/'command.json').read_text());operation=request['operation']
run_id=uuid.uuid4().hex
result={'operation':operation,'checks':[],'status':'running'}
def save():
 data=json.dumps(result,indent=2)
 (OUT/('gallery-'+operation+'-'+run_id+'.json')).write_text(data,encoding='utf-8')
 (OUT/('gallery-'+operation+'.json')).write_text(data,encoding='utf-8')
def check(ok,label):result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def counters(root):
 return [int(root.procEpoch),*[int(x) for leaf in root.layerObjects for x in [leaf.receiverCacheStats()[0],leaf.procPreparedBuilds,leaf.procDensityBakes]]]
def select_drop(control,index):
 control.selection=index
 api=c.WinDLL('user32');api.GetParent.argtypes=[w.HWND];api.GetParent.restype=w.HWND
 api.GetDlgCtrlID.argtypes=[w.HWND];api.GetClassNameW.argtypes=[w.HWND,w.LPWSTR,c.c_int]
 api.SendMessageW.argtypes=[w.HWND,w.UINT,w.WPARAM,w.LPARAM];api.SendMessageW.restype=w.LPARAM
 for raw in control.hwnd:
  handle=int(raw);name=c.create_unicode_buffer(256);api.GetClassNameW(handle,name,256)
  if name.value.lower()=='combobox':
   api.SendMessageW(api.GetParent(handle),0x111,api.GetDlgCtrlID(handle)|(9<<16),handle);return
 raise RuntimeError('Owned dropdown handle not found')
try:
 if operation=='open':
  if r.CyrusRecipeBrowser is not None:r.CyrusRecipeBrowser.closeButton.pressed()
  r.CyrusPerfHeadless=True
  check(r.loadMaxFile(str(ROOT/'AminScatter/library/borders.max'),quiet=True,useFileUnits=True),'Owned painted border example opens')
  r.execute('global GalleryTestRoot, GalleryTestCounters')
  r.GalleryTestRoot=next(n.baseObject for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject')
  root=r.GalleryTestRoot;root.refreshAll();r.GalleryTestCounters=r.Array(*counters(root))
  check(str(root.uiVersion())=='0.85.1','Loaded 0.85.1 script')
  r.CyrusOpenRecipeLibrary(root);browser=r.CyrusRecipeBrowser
  r.cyrusRecipeLibraryCancel(browser.scan);browser.scanTimer.active=False
  browser.directory=str(ROOT/'AminScatter/library');browser.libraryLocation.selection=3
  browser.refresh()
 elif operation=='verify':
  browser=r.CyrusRecipeBrowser;root=r.GalleryTestRoot
  check(str(browser.scanState)=='complete' and len(browser.entries)==6,'Six entries indexed by product service')
  gallery=browser.recipes
  check(int(gallery.ItemCount)==6,'Virtual gallery contains six recipes')
  check(int(gallery.ImagesDecoded)>0 and not gallery.IsLoading,'Visible thumbnails decode then timer stops')
  check(int(gallery.PendingJobs)==0 and int(gallery.DecodedBytes)<=64*1024*1024,'Worker and image-cache limits')
  check(counters(root)==list(r.GalleryTestCounters),'Opening/indexing/images do not evaluate or publish scatter')
  before=int(gallery.JobsStarted)
  select_drop(browser.galleryView,2);select_drop(browser.gallerySize,3)
  check(gallery.ListMode and gallery.TileSize==144,'Native dropdown notifications reach view handlers')
  gallery.SelectedIndex=3
  check(int(gallery.SelectedIndex)==3 and int(gallery.ItemCount)==6,'Actual list/size and selection handlers')
  browser.reviewButton.pressed()
  check(browser.document is not None and len(browser.bindings)>0,'Review selected recipe hydrates bindings only on request')
  browser.searchText.text='mountain';browser.searchText.changed('mountain')
  check(len(browser.entries)==1 and gallery.ItemCount==1,'Actual search changes gallery page')
  check(browser.document is None,'Search invalidates previous binding review')
  browser.searchText.text='';browser.searchText.changed('')
  select_drop(browser.galleryView,1);select_drop(browser.gallerySize,2)
  check(counters(root)==list(r.GalleryTestCounters),'Search, selection, binding review and views are passive')
  result['stats']={'decoded_bytes':int(gallery.DecodedBytes),'jobs_started':int(gallery.JobsStarted),'decoded':int(gallery.ImagesDecoded),'jobs_before_view_change':before}
  image=r.windows.snapshot(int(browser.hwnd),captureScreenPixels=False,gammaCorrect=False)
  image.filename=str(OUT/'gallery.png');r.save(image);r.close(image)
 else:raise ValueError(operation)
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
