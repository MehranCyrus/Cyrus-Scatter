"""Read actual owned native/Qt ancestry and library scale; no desktop input."""
from pathlib import Path
import ctypes as c,json
from ctypes import wintypes as w
from pymxs import runtime as r
from PySide6 import QtWidgets
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
root=r.UI0852Root
if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
main=root.mainUI
for slot in main.slots:slot.open=True;slot.rolledUp(False)
r.CyrusOpenRecipeLibrary(root)
u=c.WinDLL('user32');u.GetClassNameW.argtypes=[w.HWND,w.LPWSTR,c.c_int];u.GetParent.argtypes=[w.HWND];u.GetParent.restype=w.HWND
callback=c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM);u.EnumChildWindows.argtypes=[w.HWND,callback,w.LPARAM]
def klass(handle):
 text=c.create_unicode_buffer(256);u.GetClassNameW(handle,text,256);return text.value
pages=[]
for i,(slot,editor) in enumerate(zip(main.slots,main.editors)):
 children=[]
 @callback
 def child(hwnd,_):children.append({'handle':int(hwnd),'class':klass(hwnd)});return True
 u.EnumChildWindows(int(slot.hwnd),child,0)
 ancestry=[];h=int(editor.hwnd)
 for _ in range(18):
  if not h:break
  widget=QtWidgets.QWidget.find(h);row={'handle':h,'class':klass(h)}
  if widget:
   row['qt_class']=widget.metaObject().className();row['qt_name']=widget.objectName()
   if isinstance(widget,QtWidgets.QAbstractScrollArea):
    bar=widget.verticalScrollBar();row['vertical']={'value':bar.value(),'maximum':bar.maximum()}
  ancestry.append(row);h=int(u.GetParent(h) or 0)
 pages.append({'index':i,'slot':int(slot.hwnd),'editor':int(editor.hwnd),'native_info':[int(x) for x in r.cyrusRolloutScrollInfo(slot.hwnd)],'children':children,'ancestry':ancestry})
p=r.CyrusRecipeBrowser.panel
(OUT/'inspection.json').write_text(json.dumps({'custom_scale':float(r.CustomControlsOptions.UIUserScaleFactor),'effective_scale':float(r.GetUIScaleFactor()),'library':{'dpi':int(p.DeviceDpi),'user_scale':float(p.UserScale),'font_points':float(p.Font.Size),'client':[int(p.ClientSize.Width),int(p.ClientSize.Height)]},'pages':pages},indent=2))
