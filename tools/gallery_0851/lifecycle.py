"""One non-blocking stage of the owned gallery lifecycle witness."""
from pathlib import Path
import ctypes as c,json,os,time,traceback,uuid
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
command=json.loads((OUT/'command.json').read_text(encoding='utf-8'));operation=command['operation'];cycle=command['cycle']
library=Path(str(r.CyrusRecipeBundledDirectory('0.85.1'))) if OUT.name.startswith('foundation-roadmap-gallery0851-recipient-') else ROOT/'AminScatter/library'
expected=len(json.loads((library/'inventory.json').read_text(encoding='utf-8'))['entries'])
result={'cycle':cycle,'operation':operation,'status':'running'}
def resources():
 k=c.WinDLL('kernel32');k.GetCurrentProcess.restype=c.c_void_p;handle=k.GetCurrentProcess()
 u=c.WinDLL('user32');u.GetGuiResources.argtypes=[c.c_void_p,c.c_uint];u.GetGuiResources.restype=c.c_uint
 return {'gdi':u.GetGuiResources(handle,0),'user':u.GetGuiResources(handle,1)}
try:
 root=r.GalleryTestRoot
 if operation=='begin':
  if r.CyrusRecipeBrowser is not None:r.destroyDialog(r.CyrusRecipeBrowser)
  r.CyrusOpenRecipeLibrary(root)
 elif operation=='catalog':
  b=r.CyrusRecipeBrowser
  if b.scanTimer.active:result['status']='waiting'
  else:
   if OUT.name.startswith('foundation-roadmap-gallery0851-recipient-'):
    b.panel.SetNavigation(2,'',False);b.action('library')
   else:b.directory=str(ROOT/'AminScatter/library');b.customDirectory=b.directory;b.panel.SetNavigation(3,'',False);b.refresh()
 elif operation=='finish':
  b=r.CyrusRecipeBrowser;g=b.panel.Gallery
  if b.scanTimer.active or g.IsLoading:result['status']='waiting'
  else:
   assert int(g.ItemCount)==expected and int(g.ImagesDecoded)>0
   if command.get('mixed'):
    b.panel.SearchText='mountain';assert len(b.entries)==1
    b.panel.SearchText='';b.panel.ViewIndex=cycle%2;b.panel.ZoomIndex=cycle%3
    assert int(g.ItemCount)==expected
   result['cache_bytes']=int(g.DecodedBytes);result['jobs']=int(g.JobsStarted)
   r.destroyDialog(b)
   assert not g.IsLoading and int(g.DecodedBytes)==0
   result['resources']=resources();result['epoch']=int(root.procEpoch);result['builds']=int(root.groupBuilds)
   result['fingerprint']=str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows))
   result['work']=[int(root.procEpoch),int(root.groupBuilds)]
   for leaf in root.layerObjects:
    result['work'].extend([int(leaf.procPreparedBuilds),int(leaf.procDensityBakes),*[int(x) for x in leaf.receiverCacheStats()]])
   result['private_bytes']=int(r.dotNetClass('System.Diagnostics.Process').GetCurrentProcess().PrivateMemorySize64)
 else:raise ValueError(operation)
 if result['status']=='running':result['status']='passed'
except Exception:result['status']='failed';result['error']=traceback.format_exc()
text=json.dumps(result,indent=2);(OUT/f'lifecycle-{cycle:02d}-{operation}-{uuid.uuid4().hex}.json').write_text(text,encoding='utf-8');(OUT/'lifecycle-current.json').write_text(text,encoding='utf-8')
