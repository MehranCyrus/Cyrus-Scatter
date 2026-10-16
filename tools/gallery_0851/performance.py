"""Real Max gallery work counters, timed handlers and pending Manual/Live idle boundaries."""
from pathlib import Path
import json,time,statistics,traceback,sys,uuid
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
request=json.loads((OUT/'command.json').read_text());op=request['operation'];run=uuid.uuid4().hex
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
result={'operation':op,'checks':[],'status':'running'}
def save():
 data=json.dumps(result,indent=2);(OUT/('performance-'+op+'-'+run+'.json')).write_text(data);(OUT/('performance-'+op+'.json')).write_text(data)
def check(ok,label):result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def counters():
 root=r.GalleryTestRoot;node=r.CyrusRecipeOwnerNode(root);native=list(r.cyrusRetainedStats(r.CyrusPointOwner(node)))
 return {'epoch':int(root.procEpoch),'builds':int(root.groupBuilds),'prepared':[int(x.procPreparedBuilds) for x in root.layerObjects],
  'previews':[int(x.previewBuildCount) for x in root.layerObjects],'maps':[int(x.procDensityBakes) for x in root.layerObjects],
  'receivers':[[int(y) for y in x.receiverCacheStats()] for x in root.layerObjects],'mesh_density':list(r.cyrusMeshDensityStats()),
  'source_geometry':list(r.cyrusSourceGeometryStats()),'retained_prepare':int(native[3]),'uploads':int(native[5]),'upload_bytes':int(native[6])}
def state():return {'counters':counters(),'rows':[fingerprint(x) for x in r.GalleryTestRoot.groupSnapshotRows]}
try:
 browser=r.CyrusRecipeBrowser;root=r.GalleryTestRoot
 if op=='large_start':
  check(not browser.scanTimer.active,'Previous scan settled')
  count=request['count'];folder=ROOT/'build/gallery-0851-20261016-01/catalogs'/str(count)
  check(folder.is_dir(),'Owned prebuilt catalog exists')
  browser.directory=str(folder);browser.searchText.text='';browser.categoryFilter.selection=1
  r.CyrusPerfHeadless=False;r.CyrusPointSync();r.completeRedraw()
  before=state();start=time.perf_counter();browser.refresh();result['start_ms']=(time.perf_counter()-start)*1000
  result['count']=count;result['before']=before;result['started']=time.time();(OUT/'large-current.json').write_text(json.dumps(result))
 elif op=='large_verify':
  before=json.loads((OUT/'large-current.json').read_text());browser.showPage()
  check(str(browser.scanState)=='complete','Catalog scan complete')
  check(len(browser.entries)==128 and int(browser.recipes.ItemCount)==128,'128-entry page bound')
  check(state()==before['before'],'Scan and thumbnail loading preserve full rows and all work counters')
  times=[]
  for i in range(30):
   start=time.perf_counter();query='catalog '+str(i);browser.searchText.text=query;browser.searchText.changed(query);times.append((time.perf_counter()-start)*1000)
  result['count']=before['count'];result['search_ms']={'values':times,'median':statistics.median(times),'p95':sorted(times)[28],'max':max(times)}
  check(sorted(times)[28]<=100,'Cached search p95 <=100 ms')
  check(state()==before['before'],'Thirty actual search handlers preserve all work counters and rows')
  browser.searchText.text='';browser.searchText.changed('');result['decoded_bytes']=int(browser.recipes.DecodedBytes)
  check(int(browser.recipes.PendingJobs)<=2 and int(browser.recipes.DecodedBytes)<=64*1024*1024,'Image work bounds')
 elif op=='idle_start':
  mode=request['mode'];check(mode in ('manual','live'),'Declared idle mode')
  with pymxs.undo(False):
   root.updateMode=1;root.refreshAll()
   if mode=='manual':root.layerObjects[0].amount+=1
   else:root.updateMode=2
  result['mode']=mode;result['started']=time.time();result['before']=state();(OUT/('idle-'+mode+'-before.json')).write_text(json.dumps(result))
 elif op=='idle_verify':
  mode=request['mode'];before=json.loads((OUT/('idle-'+mode+'-before.json')).read_text());result['elapsed_seconds']=time.time()-before['started'];result['mode']=mode
  check(result['elapsed_seconds']>=120,'At least 120 seconds with event-loop processing')
  check(state()==before['before'],'Idle preserves complete publication and all work counters')
  check(not browser.scanTimer.active and not browser.recipes.IsLoading,'Catalog and image timers stopped after work')
 elif op=='snapshot':
  image=r.windows.snapshot(int(browser.hwnd),captureScreenPixels=False,gammaCorrect=False);image.filename=str(OUT/('gallery-settled-'+str(request.get('label','view'))+'.png'));r.save(image);r.close(image)
  result['gallery']={'scale':float(browser.recipes.UserScale),'tile_size':int(browser.recipes.TileSize),'size':[int(browser.recipes.Width),int(browser.recipes.Height)]}
 else:raise ValueError(op)
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
