from pathlib import Path
import ctypes as c,json
from ctypes import wintypes as w
from pymxs import runtime as r
from PySide6 import QtWidgets,QtCore,QtGui
from shiboken6 import isValid
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
u=c.WinDLL('user32');u.GetParent.argtypes=[w.HWND];u.GetParent.restype=w.HWND
u.SendMessageW.argtypes=[w.HWND,w.UINT,w.WPARAM,w.LPARAM];u.SendMessageW.restype=c.c_ssize_t;u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
u.GetForegroundWindow.restype=w.HWND;u.SetWindowPos.argtypes=[w.HWND,w.HWND,c.c_int,c.c_int,c.c_int,c.c_int,w.UINT]
window=int(r.windows.getMAXHWND());foreground=int(u.GetForegroundWindow() or 0)
u.SetWindowPos(window,0,0,0,0,0,0x13);QtWidgets.QApplication.processEvents()
result=[]
for index,(slot,page) in enumerate(zip(r.UI0852Root.mainUI.slots,r.UI0852Root.mainUI.editors)):
 info=[int(x) for x in r.cyrusRolloutScrollInfo(slot.hwnd)];widget=QtWidgets.QWidget.find(info[6])
 if not widget or not isValid(widget) or not isinstance(widget,QtWidgets.QAbstractScrollArea):continue
 bar=widget.verticalScrollBar()
 if not isValid(bar) or not 0<bar.maximum()<90:continue
 box=w.RECT();u.GetWindowRect(int(page.hwnd),c.byref(box));clip=w.RECT();u.GetWindowRect(info[6],c.byref(clip))
 x=box.left+3;y=(max(box.top,clip.top)+min(box.bottom,clip.bottom))//2
 for name,handle in [('nested',int(page.hwnd)),('header',info[5]),('column',info[6])]:
  bar.setValue(0)
  for _ in range(3):u.SendMessageW(handle,0x20A,((-120)&65535)<<16,(x&65535)|((y&65535)<<16))
  QtWidgets.QApplication.processEvents()
  result.append({'page':index,'target':name,'maximum':bar.maximum(),'value':bar.value()})
 bar.setValue(0);viewport=widget.viewport();pos=QtCore.QPointF(3,min(100,viewport.height()-2));global_pos=QtCore.QPointF(viewport.mapToGlobal(pos.toPoint()))
 event=QtGui.QWheelEvent(pos,global_pos,QtCore.QPoint(),QtCore.QPoint(0,-360),QtCore.Qt.NoButton,QtCore.Qt.NoModifier,QtCore.Qt.NoScrollPhase,False)
 QtWidgets.QApplication.sendEvent(viewport,event);result.append({'page':index,'target':'qt-viewport','maximum':bar.maximum(),'value':bar.value()});break
u.SetWindowPos(window,1,0,0,0,0,0x13)
assert int(u.GetForegroundWindow() or 0)==foreground
(OUT/'small-scroll-raised.json').write_text(json.dumps(result,indent=2))
