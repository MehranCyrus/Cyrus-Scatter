from pathlib import Path
import ctypes as c,json
from ctypes import wintypes as w
from pymxs import runtime as r
from PySide6 import QtWidgets
from shiboken6 import isValid
OUT=Path(str(r.MCPFixtureDir)).resolve();assert OUT.name.startswith('foundation-ui0852-')
u=c.WinDLL('user32');u.GetParent.argtypes=[w.HWND];u.GetParent.restype=w.HWND;u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
rows=[]
for index,(slot,page) in enumerate(zip(r.UI0852Root.mainUI.slots,r.UI0852Root.mainUI.editors)):
 row={'page':index,'handle':int(page.hwnd),'slot':int(slot.hwnd),'info':[int(x) for x in r.cyrusRolloutScrollInfo(slot.hwnd)],'ancestors':[]}
 h=int(page.hwnd)
 for _ in range(10):
  if not h:break
  box=w.RECT();u.GetWindowRect(h,c.byref(box));item={'handle':h,'rect':[box.left,box.top,box.right,box.bottom]}
  widget=QtWidgets.QWidget.find(h)
  if widget and isValid(widget):
   item['qt']=widget.metaObject().className()
   if isinstance(widget,QtWidgets.QAbstractScrollArea):
    bar=widget.verticalScrollBar();item['bar_valid']=isValid(bar)
    if isValid(bar):item.update(value=bar.value(),maximum=bar.maximum())
  row['ancestors'].append(item);h=int(u.GetParent(h) or 0)
 rows.append(row)
(OUT/'columns.json').write_text(json.dumps(rows,indent=2))
