"""Separate-request bounds/captures for the actual recipe dialogs in an owned host."""
from pathlib import Path
import ctypes as c,json
from ctypes import wintypes as w
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
request=json.loads((OUT/'command.json').read_text(encoding='utf-8'));op=request['operation'];kind=request['kind']
names={'save':'CyrusRecipeSaveEditor','details':'CyrusRecipeDetailEditor','load':'CyrusRecipeLoadEditor','style':'CyrusStyleEditor'}
assert kind in names
root=r.GalleryTestRoot
def state():
 return {'publication':str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows)),
  'work':[int(root.procEpoch),int(root.groupBuilds),*[int(v) for leaf in root.layerObjects for v in [leaf.procPreparedBuilds,leaf.procDensityBakes,*leaf.receiverCacheStats()]]]}
if op=='open':
 scale=float(request['scale']);assert scale in (1.,1.5);r.CustomControlsOptions.UIUserScaleFactor=scale
 for name in names.values():
  editor=getattr(r,name)
  if editor is not None:r.destroyDialog(editor)
 before=state();(OUT/'dialog-layout-before.json').write_text(json.dumps(before),encoding='utf-8')
 path=ROOT/'AminScatter/library/borders.csrecipe.json';digest=r.cyrusRecipeInfo(str(path))[10]
 if kind=='save':
  folder=OUT/'layout-recipes';folder.mkdir(exist_ok=True);r.CyrusOpenRecipeSave(root,str(folder))
 elif kind=='details':r.CyrusRecipeEditDetails(str(path),digest,'0.85.1')
 elif kind=='load':r.CyrusOpenRecipeLoad(root,str(path),digest)
 elif kind=='style':r.CyrusOpenRecipeStyle(root,str(path),digest)
elif op=='verify':
 editor=getattr(r,names[kind]);hwnd=int(editor.hwnd);u=c.WinDLL('user32',use_last_error=True)
 u.GetClientRect.argtypes=[w.HWND,c.POINTER(w.RECT)];u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
 u.ScreenToClient.argtypes=[w.HWND,c.POINTER(w.POINT)];u.IsWindowVisible.argtypes=[w.HWND];u.GetWindowTextW.argtypes=[w.HWND,w.LPWSTR,c.c_int]
 callback=c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM);u.EnumChildWindows.argtypes=[w.HWND,callback,w.LPARAM]
 client=w.RECT();assert u.GetClientRect(hwnd,c.byref(client));children=[]
 @callback
 def inspect(child,_):
  if u.IsWindowVisible(child):
   rect=w.RECT();u.GetWindowRect(child,c.byref(rect));a=w.POINT(rect.left,rect.top);z=w.POINT(rect.right,rect.bottom)
   u.ScreenToClient(hwnd,c.byref(a));u.ScreenToClient(hwnd,c.byref(z));text=c.create_unicode_buffer(1024);u.GetWindowTextW(child,text,1024)
   children.append({'text':text.value,'rect':[a.x,a.y,z.x,z.y],'inside':a.x>=-2 and a.y>=-2 and z.x<=client.right+2 and z.y<=client.bottom+2})
  return True
 u.EnumChildWindows(hwnd,inspect,0);scale=float(r.CustomControlsOptions.UIUserScaleFactor);label=f'dialog-{kind}-{int(scale*100)}'
 image=r.windows.snapshot(hwnd,captureScreenPixels=False,gammaCorrect=False);image.filename=str(OUT/(label+'.png'));r.save(image);r.close(image)
 result={'scale':scale,'kind':kind,'client':[client.right,client.bottom],'children':children,'passed':bool(children) and all(x['inside'] for x in children),
  'passive':state()==json.loads((OUT/'dialog-layout-before.json').read_text(encoding='utf-8'))}
 (OUT/(label+'.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
 assert result['passed'],[x for x in children if not x['inside']]
 assert result['passive'],'Opening/reviewing a dialog changed placement work'
 r.destroyDialog(editor)
else:raise ValueError(op)
