"""Inspect the actual owned import rollout; no desktop input or artist profile."""
from pathlib import Path
import ctypes as c,json,uuid
from ctypes import wintypes as w
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
operation=json.loads((OUT/'command.json').read_text(encoding='utf-8'))['operation']
if operation=='open':
 r.CyrusOpenAssetImport(r.GalleryExportRoot,(OUT/'portable-package-path.txt').read_text(encoding='utf-8-sig'))
elif operation=='verify':
 editor=r.CyrusAssetImportEditor
 assert not editor.progress.active and editor.package is not None
 hwnd=int(editor.hwnd);u=c.WinDLL('user32',use_last_error=True)
 u.GetClientRect.argtypes=[w.HWND,c.POINTER(w.RECT)];u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
 u.ScreenToClient.argtypes=[w.HWND,c.POINTER(w.POINT)];u.IsWindowVisible.argtypes=[w.HWND]
 u.GetWindowTextW.argtypes=[w.HWND,w.LPWSTR,c.c_int]
 callback=c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM)
 u.EnumChildWindows.argtypes=[w.HWND,callback,w.LPARAM]
 client=w.RECT();assert u.GetClientRect(hwnd,c.byref(client))
 children=[]
 @callback
 def inspect(child,_):
  if u.IsWindowVisible(child):
   rect=w.RECT();u.GetWindowRect(child,c.byref(rect));a=w.POINT(rect.left,rect.top);b=w.POINT(rect.right,rect.bottom)
   u.ScreenToClient(hwnd,c.byref(a));u.ScreenToClient(hwnd,c.byref(b));text=c.create_unicode_buffer(1024);u.GetWindowTextW(child,text,1024)
   children.append({'text':text.value,'rect':[a.x,a.y,b.x,b.y],'inside':a.x>=-2 and a.y>=-2 and b.x<=client.right+2 and b.y<=client.bottom+2})
  return True
 u.EnumChildWindows(hwnd,inspect,0)
 image=r.windows.snapshot(hwnd,captureScreenPixels=False,gammaCorrect=False);image.filename=str(OUT/'portable-import-layout.png');r.save(image);r.close(image)
 result={'scale':float(r.CustomControlsOptions.UIUserScaleFactor),'client':[client.right,client.bottom],'children':children,'passed':bool(children) and all(x['inside'] for x in children)}
 (OUT/f'import-layout-{uuid.uuid4().hex}.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
 assert result['passed'],[x for x in children if not x['inside']]
 editor.closeButton.pressed()
else:raise ValueError(operation)
