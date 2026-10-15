"""Actual library UI and passive-host qualification in an owned Max 2027 process."""
from pathlib import Path
import json,hashlib,time,statistics,sys,traceback,shutil
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-library08261-')
assert json.loads((OUT/'launch.json').read_text(encoding='utf-8'))['max_year']==2027
req=json.loads((OUT/'command.json').read_text(encoding='utf-8'));op=req['operation'];target=OUT/('qualification-'+req.get('label',op)+'.json')
result={'operation':op,'checks':[],'status':'running'}
def save():target.write_text(json.dumps(result,indent=2),encoding='utf-8')
def check(value,label):
 result['checks'].append({'passed':bool(value),'assertion':label});save();assert value,label
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
def counters():
 root=r.LibraryRoot
 native=list(r.cyrusRetainedStats(r.CyrusPointOwner(r.LibraryNode)))
 return {'epoch':int(root.procEpoch),'builds':int(root.groupBuilds),
         'prepared':[int(x.procPreparedBuilds) for x in root.layerObjects],
         'previews':[int(x.previewBuildCount) for x in root.layerObjects],
         'map_bakes':[int(x.procDensityBakes) for x in root.layerObjects],
         'receiver_cache':[[int(y) for y in x.receiverCacheStats()] for x in root.layerObjects],
         'mesh_density':[int(x) for x in r.cyrusMeshDensityStats()],
         'source_geometry':[int(x) for x in r.cyrusSourceGeometryStats()],
         'retained_prepare':int(native[3]),'uploads':int(native[5]),'upload_bytes':int(native[6])}
def rows():return [fingerprint(x) for x in r.LibraryRoot.groupSnapshotRows]
def choose(control,index):
 import ctypes
 user=ctypes.windll.user32
 user.GetParent.argtypes=[ctypes.c_void_p];user.GetParent.restype=ctypes.c_void_p
 user.SendMessageW.argtypes=[ctypes.c_void_p,ctypes.c_uint,ctypes.c_size_t,ctypes.c_ssize_t];user.SendMessageW.restype=ctypes.c_ssize_t
 user.GetDlgCtrlID.argtypes=[ctypes.c_void_p]
 for value in control.hwnd:
  handle=int(value);name=ctypes.create_unicode_buffer(256);user.GetClassNameW(ctypes.c_void_p(handle),name,256)
  if name.value=='ComboBox':
   user.SendMessageW(handle,0x14e,index-1,0)
   for notification in (1,9): # CBN_SELCHANGE followed by committed CBN_SELENDOK.
    user.SendMessageW(user.GetParent(handle),0x111,user.GetDlgCtrlID(handle)|(notification<<16),handle)
   return
 raise RuntimeError('No owned ComboBox control')
try:
 if op=='setup':
  with pymxs.undo(False):
   r.execute('global LibraryNode,LibraryRoot,LibraryReceiver,LibrarySource')
   r.resetMaxFile(r.Name('noPrompt'));r.CyrusPerfHeadless=True;r.disableSceneRedraw()
   r.LibraryNode=r.AminScatterObject(name='Library owned fixture');r.LibraryRoot=r.LibraryNode.baseObject;root=r.LibraryRoot;root.updateMode=1
   r.LibraryReceiver=r.plane(name='Library terrain',length=1000,width=1000,lengthsegs=12,widthsegs=12)
   r.LibrarySource=r.pyramid(name='Library pyramid',width=4,depth=4,height=12,pos=r.Point3(-2000,0,0))
   for i in range(3):
    root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,r.Array(r.LibraryReceiver));leaf.sources=r.Array(r.LibrarySource);leaf.containerMode=1;leaf.amount=2000;leaf.procSelfOverride=True;leaf.procSelfEnabled=False
   root.autoRender=False;root.pointsPerPlant=1;root.setGroupDisplay(1);root.refreshAll();r.enableSceneRedraw();r.CyrusPointSync();r.completeRedraw();r.CyrusPerfHeadless=False
   check(str(root.uiVersion())=='0.82.6.1','Exact current source version loaded')
   r.CyrusOpenRecipeLibrary(root);browser=r.CyrusRecipeBrowser
   check(browser is not None,'Actual Recipes dialog opens')
   r.cyrusRecipeLibraryCancel(browser.scan);browser.scanTimer.active=False
   result['baseline_counters']=counters();result['baseline_rows']=rows()
   (OUT/'baseline.json').write_text(json.dumps(result),encoding='utf-8')
 elif op=='save':
  browser=r.CyrusRecipeBrowser
  browser.libraryLocation.selection=3
  browser.directory=str(OUT/'library');(OUT/'library').mkdir(exist_ok=True)
  browser.recipeName.text='Woodland fixture';browser.recipeCategory.text='Woodland';browser.recipeTags.text='trees, hillside';browser.recipeDescription.text='Three procedural tree layers for testing.'
  browser.saveRecipe.pressed()
  paths=list((OUT/'library').glob('*.csrecipe.json'))
  check(len(paths)==1,'Actual Save Everything writes one recipe')
  check(Path(str(paths[0])+'.library.json').exists(),'Actual Save creates presentation metadata')
  check('not saved' not in str(browser.status.text),'No partial metadata save warning')
  result['path']=str(paths[0]);result['message']=str(browser.status.text)
 elif op=='browse':
  browser=r.CyrusRecipeBrowser;browser.showPage()
  check(str(browser.scanState)=='complete','Asynchronous scan completed')
  check(len(browser.entries)==1,'One valid recipe visible')
  browser.searchText.text='HILLSIDE';browser.searchText.changed('HILLSIDE');check(len(browser.entries)==1,'Case-insensitive tag search uses indexed metadata')
  browser.searchText.text='missing';browser.searchText.changed('missing');check(len(browser.entries)==0,'Search with no matches is empty')
  browser.searchText.text='';browser.searchText.changed('');choose(browser.categoryFilter,2);check(len(browser.entries)==1,'Category filter finds woodland')
  browser.reviewButton.pressed();check(browser.document is not None,'Actual Review hydrates the selected recipe')
  browser.suggestButton.pressed();check(all(x[1] is not None for x in browser.bindings),'Explicit unique-name suggestions bind roles')
  before=counters();full=rows();browser.newSetupCheck.checked=False
  with pymxs.undo(False):browser.importButton.pressed()
  check(len(r.LibraryRoot.layerObjects)==6,'Actual Add imports three layers')
  check(counters()['epoch']==before['epoch'] and rows()[:3]==full[:3],'Manual import preserves prior published rows')
 elif op=='large_setup':
  browser=r.CyrusRecipeBrowser
  if browser.scanTimer.active:r.cyrusRecipeLibraryCancel(browser.scan)
  count=req.get('count',10000)
  source=next((OUT/'library').glob('*.csrecipe.json'));base=json.loads(source.read_text(encoding='utf-8'));folder=OUT/('large-'+str(count));folder.mkdir(exist_ok=True)
  for i in range(count):
   data=dict(base);data['id']='catalog-'+str(i);data['name']='Tree catalog '+str(i);(folder/(str(i)+'.csrecipe.json')).write_text(json.dumps(data),encoding='utf-8')
  (folder/'invalid.csrecipe.json').write_text('{',encoding='utf-8')
  browser.directory=str(folder);browser.searchText.text='';browser.categoryFilter.selection=1
  t=time.perf_counter();browser.refresh();result['start_ms']=(time.perf_counter()-t)*1000;result['count']=count
  result['before']=counters();result['rows']=rows();(OUT/'large-before.json').write_text(json.dumps(result),encoding='utf-8')
 elif op=='large_observe':
  browser=r.CyrusRecipeBrowser;browser.showPage();check(str(browser.scanState)=='complete','Large library scan finished')
  before=json.loads((OUT/'large-before.json').read_text(encoding='utf-8'));check(counters()==before['before'] and rows()==before['rows'],'Large filesystem scan preserves all placement/preparation/upload counters and complete rows')
  check(len(browser.entries)<=128,'Visible page bounded to 128 rows')
  result['page_info']=str(browser.pageInfo.text);result['status_text']=str(browser.status.text);result['count']=before['count'];result['start_ms']=before['start_ms']
  times=[]
  for i in range(30):
   t=time.perf_counter();browser.searchText.text='catalog '+str(i);browser.searchText.changed(str(browser.searchText.text));times.append((time.perf_counter()-t)*1000)
  result['search_ms']={'values':times,'median':statistics.median(times),'p95':sorted(times)[28]}
  check(counters()==before['before'] and rows()==before['rows'],'Thirty search changes do not calculate or upload scatter')
  check(not browser.scanTimer.active,'No library polling remains when scan is complete')
 elif op=='cancel_start':
  browser=r.CyrusRecipeBrowser;browser.directory=str(OUT/'large-10000');browser.searchText.text=''
  browser.refresh();t=time.perf_counter();browser.cancelButton.pressed();result['cancel_ms']=(time.perf_counter()-t)*1000
  result['before']=counters();result['rows']=rows();(OUT/'cancel-before.json').write_text(json.dumps(result),encoding='utf-8')
 elif op=='cancel_observe':
  browser=r.CyrusRecipeBrowser;browser.showPage();before=json.loads((OUT/'cancel-before.json').read_text(encoding='utf-8'))
  check(str(browser.scanState)=='cancelled' and not browser.scanTimer.active,'Actual Cancel stops scan and its timer')
  check(counters()==before['before'] and rows()==before['rows'],'Cancellation preserves scatter work and full rows')
  browser.directory=str(OUT/'library');browser.refresh()
 elif op=='thumbnail_save':
  # Render temporary geometry from the exact accepted transforms. These nodes
  # never enter the saved recipe or editable demonstration scene.
  with pymxs.undo(False):
   r.LibraryThumbnailPath=str(OUT/'actual-preset.png')
   r.execute('''(
    local temporary=#()
    try (
     for layerIndex=1 to LibraryRoot.groupSnapshotRows.count do (
      local leaf=LibraryRoot.layerObjects[layerIndex],vertices=#(),faces=#(),sourceMeshes=#()
      for source in leaf.sources do (
       local atOrigin=copy source;atOrigin.transform=matrix3 1
       append sourceMeshes (snapshotAsMesh atOrigin);delete atOrigin
      )
      for row in LibraryRoot.groupSnapshotRows[layerIndex] do (
       local sourceMesh=sourceMeshes[row[2]],offset=vertices.count
       for i=1 to sourceMesh.numverts do append vertices ((getVert sourceMesh i)*row[1])
       for i=1 to sourceMesh.numfaces do append faces ((getFace sourceMesh i)+[offset,offset,offset])
      )
      if vertices.count>0 do (
       local snapshot=mesh name:"TEMP library render" vertices:vertices faces:faces
       snapshot.material=standardMaterial diffuse:(color 50 (110+layerIndex*20) 65)
       append temporary snapshot
      )
     )
     local target=targetObject pos:[0,0,0],camera=targetCamera pos:[850,-1250,1300] target:target
     append temporary target;append temporary camera;camera.fov=55
     local light=omniLight pos:[-700,-600,1600] multiplier:1.;append temporary light
     renderers.current=Default_Scanline_Renderer();renderWidth=512;renderHeight=320
     local frame=render camera:camera vfb:false outputFile:LibraryThumbnailPath
     close frame
    )catch(delete temporary;throw())
    delete temporary
   )''')
  browser=r.CyrusRecipeBrowser;browser.directory=str(OUT/'thumbnails');Path(str(browser.directory)).mkdir(exist_ok=True)
  browser.libraryLocation.selection=3
  browser.thumbnailFile=str(OUT/'actual-preset.png');browser.recipeName.text='Woodland with actual thumbnail';browser.saveRecipe.pressed()
  result['files']=[str(x) for x in Path(str(browser.directory)).glob('*.csrecipe.json')]
  check(len(result['files'])==1,'Actual Save publishes recipe and stored render')
 elif op=='thumbnail_observe':
  browser=r.CyrusRecipeBrowser;browser.showPage()
  check(str(browser.scanState)=='complete' and len(browser.entries)==1,'Thumbnail recipe indexed')
  check(browser.thumbnailView.Image is not None and int(browser.thumbnailView.Image.Width)==512,'Actual PictureBox decodes saved 512-pixel PNG')
  before=counters();full=rows();image=browser.thumbnailView.Image
  for _ in range(20):browser.showSelected()
  check(image.Equals(browser.thumbnailView.Image),'Repeated selection retains the decoded image')
  check(counters()==before and rows()==full,'Thumbnail selection does not calculate or upload scatter')
  recipe=Path(str(browser.entries[0][0]));thumbnail=Path(str(r.cyrusRecipeThumbnail(str(recipe))));original=thumbnail.read_bytes()
  try:
   thumbnail.write_bytes(b'corrupt');browser.clearImage();browser.showSelected()
   check(str(browser.previewTitle.text)=='Thumbnail unavailable','Corrupt thumbnail reports a fallback without losing recipe')
   check(len(browser.entries)==1,'Corrupt thumbnail does not remove authored recipe')
  finally:thumbnail.write_bytes(original);browser.clearImage();browser.showSelected()
  result['thumbnail']=str(thumbnail)
 elif op=='close_scan':
  browser=r.CyrusRecipeBrowser;browser.directory=str(OUT/'large-10000');browser.refresh();t=time.perf_counter();browser.closeButton.pressed()
  result['close_ms']=(time.perf_counter()-t)*1000;check(r.CyrusRecipeBrowser is None,'Closing during scan disposes dialog and cancels worker')
 elif op=='reopen':
  r.CyrusOpenRecipeLibrary(r.LibraryRoot);browser=r.CyrusRecipeBrowser
  check(browser is not None,'Library reopens after cancellation');r.cyrusRecipeLibraryCancel(browser.scan);browser.scanTimer.active=False
 elif op=='failures':
  browser=r.CyrusRecipeBrowser;owner=browser.owners[0];saved=r.getPropertyController(owner,r.Name('rotZMin'))
  before=counters();full=rows()
  try:
   r.setPropertyController(owner,r.Name('rotZMin'),r.float_expression());browser.preflightButton.pressed()
   message=str(browser.status.text)
   check('rotZMin' in message and str(r.LibraryRoot.layerCaption(owner)) in message,'Preflight names both unsupported controller and owning layer')
  finally:r.setPropertyController(owner,r.Name('rotZMin'),saved)
  check(counters()==before and rows()==full,'Unsupported-save preflight preserves all publication/work counters')
  browser.reviewButton.pressed();check(browser.document is not None,'Review still works after rejected preflight')
  count=len(r.LibraryRoot.layerObjects)
  with pymxs.undo(False):browser.importButton.pressed()
  check('Missing dependency: Library pyramid' in str(browser.status.text),'Actual Import explains missing bindings')
  check(len(r.LibraryRoot.layerObjects)==count and rows()==full,'Missing bindings preserve authored graph and published rows')
  result['preflight_message']=message;result['import_message']=str(browser.status.text)
 elif op=='owner_deleted':
  browser=r.CyrusRecipeBrowser
  with pymxs.undo(False):r.delete(r.LibraryNode)
  browser.preflightButton.pressed();message=str(browser.status.text)
  check('controller was removed or replaced' in message.lower(),'Open browser detects deleted destination')
  result['message']=message;browser.closeButton.pressed()
 elif op=='bundled_prepare':
  browser=r.CyrusRecipeBrowser;source=ROOT/'AminScatter/library';destination=Path(str(r.CyrusRecipeBundledDirectory(str(r.LibraryRoot.uiVersion())))).resolve()
  check(destination.is_relative_to(OUT),'Bundled fixture destination stays inside the owned profile')
  inventory=json.loads((source/'inventory.json').read_text())
  for name,digest in inventory['files'].items():check(hashlib.sha256((source/name).read_bytes()).hexdigest()==digest,'Qualified bundled file: '+name)
  shutil.copytree(source,destination,dirs_exist_ok=True);result['directory']=str(destination)
  browser.showPage();before=counters();full=rows();choose(browser.libraryLocation,2)
  result['actual_directory']=str(browser.directory)
  check(Path(str(browser.directory)).resolve()==destination,'Actual Bundled examples selector uses the installed version directory')
  result['before']=before;result['rows']=full;(OUT/'bundled-before.json').write_text(json.dumps(result),encoding='utf-8')
 elif op=='bundled_observe':
  browser=r.CyrusRecipeBrowser;browser.showPage();before=json.loads((OUT/'bundled-before.json').read_text())
  check(str(browser.scanState)=='complete' and len(browser.entries)==4,'All four shipped recipes are discoverable')
  check(browser.thumbnailView.Image is not None,'Bundled recipe thumbnail displays')
  check(counters()==before['before'] and rows()==before['rows'],'Bundled navigation preserves terrain/scatter/preparation/upload counters and full rows')
  categories=[str(x) for x in browser.categoryFilter.items];choose(browser.categoryFilter,categories.index('Gardens')+1)
  check(len(browser.entries)==1 and 'Painted garden' in str(browser.entries[0][1][0]),'Actual committed category selection filters a mixed library')
  choose(browser.categoryFilter,1);check(len(browser.entries)==4,'All categories restores the mixed library')
  # Missing Paint must not make passive listing hydrate every attachment.
  recipe=Path(str(browser.directory))/'borders.csrecipe.json';data=json.loads(recipe.read_text());paint=data['layers'][0]['areas'][0]['paint']['payload'];file=(recipe.parent/paint['file']).resolve()
  check(file.is_relative_to(OUT),'Paint corruption fixture remains owned')
  original=file.read_bytes()
  try:
   file.write_bytes(b'corrupt')
   check(int(r.cyrusRecipeInfo(str(recipe))[2])==1,'Passive summary lists Paint without reading its damaged attachment')
   failure=''
   try:r.cyrusRecipeRead(str(recipe))
   except Exception as e:failure=str(e)
   check(bool(failure),'Explicit Review/full read rejects the corrupt Paint attachment')
  finally:file.write_bytes(original)
  result['library_dir']=str(browser.directory)
 elif op=='offline_start':
  browser=r.CyrusRecipeBrowser;browser.libraryLocation.selection=3
  browser.directory=r'\\127.0.0.1\CyrusScatter_qualification_missing_share_08261'
  before=counters();full=rows();t=time.perf_counter();browser.refresh();browser.cancelButton.pressed()
  result['request_ms']=(time.perf_counter()-t)*1000;result['before']=before;result['rows']=full
  (OUT/'offline-before.json').write_text(json.dumps(result),encoding='utf-8')
 elif op=='offline_observe':
  browser=r.CyrusRecipeBrowser;browser.showPage();before=json.loads((OUT/'offline-before.json').read_text())
  result['state']=str(browser.scanState);result['message']=str(browser.status.text)
  check(str(browser.scanState) in ('cancelled','complete') and not browser.scanTimer.active,'Unavailable localhost share settles after explicit cancellation')
  check(counters()==before['before'] and rows()==before['rows'],'Offline root/cancellation leaves scatter work and rows unchanged')
 elif op=='unicode_prepare':
  source=next((OUT/'library').glob('*.csrecipe.json'));data=json.loads(source.read_text());folder=OUT/'unicode';folder.mkdir(exist_ok=True)
  data['name']='Caf\u00e9 \u0628\u0627\u063a';data['id']='unicode-one';(folder/'one.csrecipe.json').write_text(json.dumps(data,ensure_ascii=False),encoding='utf-8')
  data['id']='unicode-two';(folder/'two.CSRECIPE.JSON').write_text(json.dumps(data,ensure_ascii=False),encoding='utf-8')
  browser=r.CyrusRecipeBrowser;browser.directory=str(folder);browser.searchText.text='';browser.categoryFilter.selection=1;browser.refresh()
 elif op=='unicode_observe':
  browser=r.CyrusRecipeBrowser;browser.showPage();check(len(browser.entries)==2,'Duplicate Unicode names and uppercase recipe suffix remain separate entries')
  before=counters();full=rows();browser.searchText.text='CAF\u00c9';browser.searchText.changed(str(browser.searchText.text))
  check(len(browser.entries)==2,'Unicode case-insensitive query matches accented names')
  browser.searchText.text='\u0628\u0627\u063a';browser.searchText.changed(str(browser.searchText.text));check(len(browser.entries)==2,'Farsi name search matches both distinct entries')
  check(counters()==before and rows()==full,'Unicode queries preserve scatter work and complete rows')
 elif op=='readonly_prepare':
  folder=OUT/'readonly-library';folder.mkdir(exist_ok=False)
  shutil.copy2(ROOT/'AminScatter/library/woodland.csrecipe.json',folder/'woodland.csrecipe.json')
  browser=r.CyrusRecipeBrowser;browser.libraryLocation.selection=3;browser.directory=str(folder);browser.refresh()
 elif op=='readonly_observe':
  browser=r.CyrusRecipeBrowser;browser.showPage();check(len(browser.entries)==1,'Read-only folder remains browseable')
  before=counters();full=rows();browser.recipeName.text='Read-only rejection';browser.saveRecipe.pressed()
  check('cannot create staged file' in str(browser.status.text),'Denied write reports a staged-file creation error')
  check(counters()==before and rows()==full,'Read-only save failure preserves complete scene and work counters')
  result['message']=str(browser.status.text)
 elif op=='readonly_finalize':
  check(len(list((OUT/'readonly-library').glob('*.csrecipe.json')))==1,'After ACL restoration, failed save has published no recipe')
  check(hashlib.sha256((OUT/'readonly-library/woodland.csrecipe.json').read_bytes()).hexdigest()==hashlib.sha256((ROOT/'AminScatter/library/woodland.csrecipe.json').read_bytes()).hexdigest(),'Existing recipe bytes preserved after denied save')
 elif op=='lifecycle':
  import ctypes
  process=r.dotNetClass('System.Diagnostics.Process').GetCurrentProcess()
  user=ctypes.windll.user32;user.GetGuiResources.argtypes=[ctypes.c_void_p,ctypes.c_uint];user.GetGuiResources.restype=ctypes.c_ulong
  def resources():
   r.gc(light=True);r.dotNetClass('System.GC').Collect();r.dotNetClass('System.GC').WaitForPendingFinalizers();process.Refresh()
   return {'private_bytes':int(process.PrivateMemorySize64),'handles':int(process.HandleCount),'gdi':int(user.GetGuiResources(int(process.Handle),0)),'user':int(user.GetGuiResources(int(process.Handle),1))}
  root=r.LibraryRoot;root.updateMode=2;root.refreshAll();r.CyrusPointSync();r.completeRedraw()
  if r.CyrusRecipeBrowser is not None:r.CyrusRecipeBrowser.closeButton.pressed()
  before=counters();full=rows();samples=[];timings=[]
  for cycle in range(60):
   started=time.perf_counter();r.CyrusOpenRecipeLibrary(root);browser=r.CyrusRecipeBrowser
   deadline=time.monotonic()+5
   while str(browser.scanState)=='scanning' and time.monotonic()<deadline:
    time.sleep(.01);browser.showPage()
   check(str(browser.scanState)!='scanning','Owned local scan settles for cycle '+str(cycle))
   browser.directory=str(r.CyrusRecipeBundledDirectory(str(root.uiVersion())));browser.refresh()
   while browser.scanTimer.active and time.monotonic()<deadline:time.sleep(.01);browser.showPage()
   check(len(browser.entries)==4 and browser.thumbnailView.Image is not None,'Four examples and a decoded thumbnail for cycle '+str(cycle))
   browser.closeButton.pressed();timings.append((time.perf_counter()-started)*1000)
   if cycle in (9,29,59):samples.append({'cycles':cycle+1,**resources()})
  result['samples']=samples;result['open_scan_close_ms']={'median':statistics.median(timings),'p95':sorted(timings)[56]}
  check(counters()==before and rows()==full,'Sixty Live browser open/scan/thumbnail/close cycles preserve work counters and complete rows')
  check(samples[-1]['gdi']-samples[0]['gdi']<=4 and samples[-1]['user']-samples[0]['user']<=4,'No sustained GDI/USER handle growth across the final fifty cycles')
  check(samples[-1]['private_bytes']-samples[0]['private_bytes']<32*1024*1024,'Final fifty cycles remain within 32 MiB transient memory budget after collection')
  r.CyrusOpenRecipeLibrary(root);browser=r.CyrusRecipeBrowser;r.cyrusRecipeLibraryCancel(browser.scan);browser.scanTimer.active=False
  result['before']=counters();result['rows']=rows();result['idle_started']=time.time();(OUT/'idle-before.json').write_text(json.dumps(result),encoding='utf-8')
 elif op=='idle_observe':
  before=json.loads((OUT/'idle-before.json').read_text());result['seconds']=time.time()-before['idle_started']
  check(result['seconds']>=30,'Live idle observation spans at least thirty seconds')
  check(counters()==before['before'] and rows()==before['rows'],'Live idle preserves all recorded work counters and full placement rows')
  check(not r.CyrusRecipeBrowser.scanTimer.active,'No recipe scan timer runs during idle')
 elif op=='inspect':
  browser=r.CyrusRecipeBrowser;result['status_text']=str(browser.status.text);result['scan_state']=str(browser.scanState);result['entries']=len(browser.entries);result['counters']=counters();result['layers']=len(r.LibraryRoot.layerObjects)
 else:raise ValueError(op)
 result['status']='passed';save()
except Exception:
 result['status']='failed';result['error']=traceback.format_exc();save();raise
