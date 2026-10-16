"""Settled, owned-window bounds and direct-control rendering; never desktop input."""
from pathlib import Path
import ctypes as c,json,uuid
from ctypes import wintypes as w
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
request=json.loads((OUT/'command.json').read_text(encoding='utf-8'));op=request['operation']
if op=='prepare':
 r.CyrusPerfHeadless=True
 assert r.loadMaxFile(str(ROOT/'AminScatter/library/borders.max'),quiet=True,useFileUnits=True)
 r.execute('global GalleryTestRoot')
 r.GalleryTestRoot=next(n.baseObject for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject')
 r.GalleryTestRoot.refreshAll()
elif op=='open':
 root=r.GalleryTestRoot
 scale=float(request.get('scale',1));assert scale in (1.,1.5)
 r.CustomControlsOptions.UIUserScaleFactor=scale
 if r.CyrusRecipeBrowser is not None:r.destroyDialog(r.CyrusRecipeBrowser)
 r.CyrusOpenRecipeLibrary(root);b=r.CyrusRecipeBrowser
 r.cyrusRecipeLibraryCancel(b.scan);b.scanTimer.active=False
 b.directory=str(ROOT/'AminScatter/library');b.customDirectory=b.directory;b.panel.SetNavigation(3,'',True);b.refresh()
elif op=='resize':
 size=request['size'];assert size in ([850,620],[1000,680],[1120,760])
 r.setDialogSize(r.CyrusRecipeBrowser,r.Point2(*size))
elif op=='fit_probe':
 b=r.CyrusRecipeBrowser;size=r.getDialogSize(b);b.panel.width=int(size.x);b.panel.height=int(size.y)
 (OUT/'fit-probe.json').write_text(json.dumps({'dialog_size':[float(size.x),float(size.y)]}),encoding='utf-8')
elif op=='capture':
 b=r.CyrusRecipeBrowser;p=b.panel;assert not b.scanTimer.active and not p.Gallery.IsLoading
 label=request['label'];assert label.replace('-','').isalnum()
 hwnd=int(b.hwnd);u=c.WinDLL('user32',use_last_error=True)
 u.GetClientRect.argtypes=[w.HWND,c.POINTER(w.RECT)];u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
 u.ScreenToClient.argtypes=[w.HWND,c.POINTER(w.POINT)];u.IsWindowVisible.argtypes=[w.HWND]
 u.GetWindowTextW.argtypes=[w.HWND,w.LPWSTR,c.c_int]
 callback=c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM);u.EnumChildWindows.argtypes=[w.HWND,callback,w.LPARAM]
 client=w.RECT();assert u.GetClientRect(hwnd,c.byref(client));children=[]
 @callback
 def inspect(child,_):
  if u.IsWindowVisible(child):
   rect=w.RECT();u.GetWindowRect(child,c.byref(rect));a=w.POINT(rect.left,rect.top);z=w.POINT(rect.right,rect.bottom)
   u.ScreenToClient(hwnd,c.byref(a));u.ScreenToClient(hwnd,c.byref(z));text=c.create_unicode_buffer(1024);u.GetWindowTextW(child,text,1024)
   children.append({'text':text.value,'rect':[a.x,a.y,z.x,z.y],'inside':a.x>=-2 and a.y>=-2 and z.x<=client.right+2 and z.y<=client.bottom+2})
  return True
 u.EnumChildWindows(hwnd,inspect,0)
 image=r.windows.snapshot(hwnd,captureScreenPixels=False,gammaCorrect=False);image.filename=str(OUT/(label+'-window.png'));r.save(image);r.close(image)
 # dotNetControl.Width is Max's logical wrapper dimension. ClientSize is the
 # managed control's actual device-pixel size, including Max's scripted scale.
 pixels=p.ClientSize;image=r.dotNetObject('System.Drawing.Bitmap',int(pixels.Width),int(pixels.Height))
 try:
  p.DrawToBitmap(image,r.dotNetObject('System.Drawing.Rectangle',0,0,int(pixels.Width),int(pixels.Height)))
  image.Save(str(OUT/(label+'-control.png')),r.dotNetClass('System.Drawing.Imaging.ImageFormat').Png)
 finally:image.Dispose()
 result={'scale':float(r.CustomControlsOptions.UIUserScaleFactor),'client':[client.right,client.bottom],
  'panel':{'width':int(p.Width),'height':int(p.Height),'dpi':int(p.DeviceDpi),'font':str(p.Font.Name),'font_size':float(p.Font.Size),'font_unit':str(p.Font.Unit),'user_scale':float(p.UserScale)},
  'gallery':{'width':int(p.Gallery.Width),'height':int(p.Gallery.Height),'dpi':int(p.Gallery.DeviceDpi),'font':str(p.Gallery.Font.Name),'font_size':float(p.Gallery.Font.Size),'user_scale':float(p.Gallery.UserScale)},
  'children':children,'passed':bool(children) and all(x['inside'] for x in children)}
 (OUT/(label+'-layout.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
 assert result['passed'],[x for x in children if not x['inside']]
else:raise ValueError(op)
