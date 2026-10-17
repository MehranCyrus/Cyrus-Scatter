"""Actual library default/explicit scale, passive resize/reopen and bound checks."""
from pathlib import Path
import ctypes as c,json
from ctypes import wintypes as w
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-presets0853-')
cmd=json.loads((OUT/'library-command.json').read_text());root=r.UI0852Root
def state():
 values=[int(root.procEpoch),int(root.groupBuilds)]
 for leaf in root.layerObjects:values.extend([int(leaf.procPreparedBuilds),int(leaf.procDensityBakes),*[int(x) for x in leaf.receiverCacheStats()]])
 return {'uploads':[int(x) for x in r.cyrusRetainedStreamStats()][1:4],'rows':str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows)),'work':values,'amount':[float(x.amount) for x in root.layerObjects],
  'undo':[str(x) for x in r.theHold.GetUndoNames()],'redo':[str(x) for x in r.theHold.GetRedoNames()]}
if cmd['operation']=='open':
 before=state()
 if r.CyrusRecipeBrowser is not None:r.destroyDialog(r.CyrusRecipeBrowser)
 r.CyrusOpenRecipeLibrary(root);browser=r.CyrusRecipeBrowser
 r.cyrusRecipeLibraryCancel(browser.scan);browser.scanTimer.active=False
 if cmd.get('installed'):
  browser.panel.SetNavigation(2,'',True);browser.action('library')
  assert Path(str(browser.directory)).resolve().is_relative_to(OUT)
 else:
  browser.directory=str(ROOT/'AminScatter/library');browser.customDirectory=browser.directory;browser.panel.SetNavigation(3,'',True);browser.refresh()
 if 'size' in cmd:r.setDialogSize(browser,r.Point2(*cmd['size']))
 assert state()==before
 (OUT/'library-before.json').write_text(json.dumps(before))
elif cmd['operation']=='verify':
 browser=r.CyrusRecipeBrowser;panel=browser.panel
 assert not browser.scanTimer.active and not panel.Gallery.IsLoading,'Allow asynchronous work to settle'
 before=json.loads((OUT/'library-before.json').read_text());assert state()==before
 raw=float(r.CustomControlsOptions.UIUserScaleFactor);expected=1. if raw==0 else raw
 assert abs(float(panel.UserScale)-expected)<.001 and abs(float(panel.Font.Size)-9*expected)<.001
 assert int(panel.Gallery.ItemCount)==6 and int(panel.TreeNodeCount)>=11
 u=c.WinDLL('user32');u.IsWindowVisible.argtypes=[w.HWND];u.GetClientRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
 u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)];u.ScreenToClient.argtypes=[w.HWND,c.POINTER(w.POINT)]
 callback=c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM);u.EnumChildWindows.argtypes=[w.HWND,callback,w.LPARAM]
 hwnd=int(browser.hwnd);client=w.RECT();assert u.GetClientRect(hwnd,c.byref(client));bounds=[]
 @callback
 def inspect(child,_):
  if u.IsWindowVisible(child):
   box=w.RECT();u.GetWindowRect(child,c.byref(box));a=w.POINT(box.left,box.top);z=w.POINT(box.right,box.bottom)
   u.ScreenToClient(hwnd,c.byref(a));u.ScreenToClient(hwnd,c.byref(z));bounds.append({'rect':[a.x,a.y,z.x,z.y],'inside':a.x>=-2 and a.y>=-2 and z.x<=client.right+2 and z.y<=client.bottom+2})
  return True
 u.EnumChildWindows(hwnd,inspect,0);assert bounds and all(x['inside'] for x in bounds),bounds
 pixels=panel.ClientSize;bitmap=r.dotNetObject('System.Drawing.Bitmap',int(pixels.Width),int(pixels.Height))
 try:
  panel.DrawToBitmap(bitmap,r.dotNetObject('System.Drawing.Rectangle',0,0,int(pixels.Width),int(pixels.Height)))
  bitmap.Save(str(OUT/(cmd['label']+'.png')),r.dotNetClass('System.Drawing.Imaging.ImageFormat').Png)
 finally:bitmap.Dispose()
 (OUT/(cmd['label']+'.json')).write_text(json.dumps({'status':'passed','raw_scale':raw,'effective_scale':float(r.GetUIScaleFactor()),
  'normalized_scale':float(panel.UserScale),'font_points':float(panel.Font.Size),'dpi':int(panel.DeviceDpi),'client':[client.right,client.bottom],
  'collections':int(panel.Gallery.ItemCount),'bounds':bounds,'passive':state()==before},indent=2))
elif cmd['operation']=='browse':
 before=state();browser=r.CyrusRecipeBrowser;panel=browser.panel
 panel.SetNavigation(panel.LibraryIndex,'',False);browser.action('collection');assert int(panel.Gallery.ItemCount)==8
 for text in ('mountain','garden',''):
  panel.SearchText=text
  assert state()==before
 for view in (1,0):panel.ViewIndex=view
 for zoom in (0,2,1):panel.ZoomIndex=zoom
 assert state()==before
 (OUT/(cmd['label']+'.json')).write_text(json.dumps({'status':'passed','passive':True,'recipes':int(panel.Gallery.ItemCount)},indent=2))
else:raise ValueError(cmd['operation'])
