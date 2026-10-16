"""Owned-window wheel/drag reproduction. Never move the desktop pointer."""
from pathlib import Path
import ctypes as c,json,time
from ctypes import wintypes as w
from pymxs import runtime as r
from PySide6 import QtWidgets,QtCore,QtGui
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
cmd=json.loads((OUT/'navigation-command.json').read_text());root=r.UI0852Root;main=root.mainUI
u=c.WinDLL('user32');u.GetParent.argtypes=[w.HWND];u.GetParent.restype=w.HWND
u.SendMessageW.argtypes=[w.HWND,w.UINT,w.WPARAM,w.LPARAM];u.SendMessageW.restype=c.c_ssize_t
u.GetCapture.restype=w.HWND;u.ClientToScreen.argtypes=[w.HWND,c.POINTER(w.POINT)];u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
def ancestry(handle):
 for _ in range(20):
  if not handle:break
  widget=QtWidgets.QWidget.find(handle)
  if widget:yield widget
  handle=int(u.GetParent(handle) or 0)
def column(page):
 return next(widget for widget in ancestry(int(page.hwnd)) if widget.metaObject().className()=='CommandPanelRollupContainer')
def state():
 values=[int(root.procEpoch),int(root.groupBuilds)]
 for leaf in root.layerObjects:values.extend([int(leaf.procPreparedBuilds),int(leaf.procDensityBakes),*[int(x) for x in leaf.receiverCacheStats()]])
 return {'uploads':[int(x) for x in r.cyrusRetainedStreamStats()][1:4],'rows':str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows)),'work':values,'amount':[float(x.amount) for x in root.layerObjects],
  'undo':[str(x) for x in r.theHold.GetUndoNames()],'redo':[str(x) for x in r.theHold.GetRedoNames()]}
result={'command':cmd,'status':'observed','custom_scale':float(r.CustomControlsOptions.UIUserScaleFactor)}
if cmd['operation']=='configure':
 if r.CyrusRecipeBrowser is not None:r.destroyDialog(r.CyrusRecipeBrowser)
 widget=next(x for x in ancestry(int(main.hwnd)) if x.metaObject().className()=='CommandPanel')
 result['dock_type']=widget.metaObject().className();result['is_dock']=isinstance(widget,QtWidgets.QDockWidget)
 if isinstance(widget,QtWidgets.QDockWidget):
  parent=widget.parentWidget()
  while parent is not None and not isinstance(parent,QtWidgets.QMainWindow):parent=parent.parentWidget()
  assert parent is not None
  widget.setMinimumWidth(220);widget.setMaximumWidth(int(cmd.get('width',260)))
  parent.resizeDocks([widget],[int(cmd.get('width',260))],QtCore.Qt.Horizontal)
 else:widget.setFixedWidth(int(cmd.get('width',260)))
 for slot in main.slots:slot.open=True;slot.rolledUp(False)
 if cmd.get('publish'):root.refreshAll()
 result['state']=state()
elif cmd['operation'] in ('prepare_probe','probe'):
 QtWidgets.QApplication.processEvents()
 # A wider command panel can move a page into a column whose content fits.
 # Resolve the actual current column after queued layout, and exercise an
 # overflowing column rather than expecting a fitting column to scroll.
 candidates=[int(cmd['page'])] if 'page' in cmd else list(range(len(main.slots)))
 if cmd['direction']=='up' and 'page' not in cmd:candidates.reverse()
 index=next(i for i in candidates if column(main.editors[i]).verticalScrollBar().maximum()>0)
 slot=main.slots[index];page=main.editors[index];target=column(page);bar=target.verticalScrollBar()
 if cmd.get('bind'):result['bindings']=int(r.cyrusBindRolloutScroll(slot.hwnd))
 direction=cmd['direction']
 if cmd['operation']=='prepare_probe' or not cmd.get('settled'):
  bar.setValue(0 if direction=='down' else bar.maximum())
 QtWidgets.QApplication.processEvents()
 if column(page) is not target or bar.maximum()==0:
  index=next(i for i in candidates if column(main.editors[i]).verticalScrollBar().maximum()>0)
  slot=main.slots[index];page=main.editors[index];target=column(page);bar=target.verticalScrollBar()
  if cmd['operation']=='prepare_probe' or not cmd.get('settled'):bar.setValue(0 if direction=='down' else bar.maximum())
  QtWidgets.QApplication.processEvents()
 before=state();initial=bar.value();capture=int(u.GetCapture() or 0)
 rectangle=w.RECT();u.GetWindowRect(int(page.hwnd),c.byref(rectangle))
 viewport=target.viewport();origin=viewport.mapToGlobal(QtCore.QPoint(0,0))
 top=max(rectangle.top,origin.y());bottom=min(rectangle.bottom,origin.y()+viewport.height())
 if bottom<=top:
  # A small Max window can show only the setup header at the top. Bring the
  # requested nested page into view before delivering input to its background.
  delta=rectangle.top-origin.y() if direction=='down' else rectangle.bottom-origin.y()-viewport.height()
  bar.setValue(max(0,min(bar.maximum(),bar.value()+delta)))
  QtWidgets.QApplication.processEvents();u.GetWindowRect(int(page.hwnd),c.byref(rectangle))
  top=max(rectangle.top,origin.y());bottom=min(rectangle.bottom,origin.y()+viewport.height());initial=bar.value()
 if cmd['operation']=='prepare_probe':
  (OUT/'navigation-prepared.json').write_text(json.dumps({'page':index,'direction':direction,'scroll':bar.value(),'maximum':bar.maximum()}))
  (OUT/(cmd['label']+'.json')).write_text(json.dumps({'status':'prepared','page':index,'scroll':bar.value(),'maximum':bar.maximum()}))
  result={"status":"prepared","page":index,"scroll":bar.value(),"maximum":bar.maximum()}
 if cmd['operation']!='prepare_probe':
  assert bottom>top,{'error':'Fixture must target a visible page background','page':index,'rect':[rectangle.left,rectangle.top,rectangle.right,rectangle.bottom],
   'viewport':[origin.x(),origin.y(),viewport.width(),viewport.height()],'scroll':bar.value(),'maximum':bar.maximum()}
  start=(top+bottom)//2-rectangle.top
  if cmd['gesture']=='wheel':
   point=w.POINT(3,start);u.ClientToScreen(int(page.hwnd),c.byref(point));lp=(point.x&65535)|((point.y&65535)<<16)
   delta=-120 if direction=='down' else 120
   for _ in range(3):u.SendMessageW(int(page.hwnd),0x20A,(delta&65535)<<16,lp)
  elif cmd['gesture']=='qt_wheel':
   pos=QtCore.QPointF(8,80);global_pos=QtCore.QPointF(target.mapToGlobal(QtCore.QPoint(8,80)))
   event=QtGui.QWheelEvent(pos,global_pos,QtCore.QPoint(),QtCore.QPoint(0,-360 if direction=='down' else 360),QtCore.Qt.NoButton,QtCore.Qt.NoModifier,QtCore.Qt.NoScrollPhase,False)
   QtWidgets.QApplication.sendEvent(target.viewport(),event)
  elif cmd['gesture']=='drag':
   end=start+(-200 if direction=='down' else 200)
   u.SendMessageW(int(page.hwnd),0x201,1,3|((start&65535)<<16))
   for i in range(1,11):
    y=round(start+(end-start)*i/10);u.SendMessageW(int(page.hwnd),0x200,1,3|((y&65535)<<16))
   u.SendMessageW(int(page.hwnd),0x202,0,3|((end&65535)<<16))
  else:raise ValueError(cmd['gesture'])
  QtWidgets.QApplication.processEvents();after=state();final=bar.value()
  result.update({'initial':initial,'final':final,'maximum':bar.maximum(),'moved':final>initial if direction=='down' else final<initial,
   'passive':before==after,'state_before':before,'state_after':after,'capture_before':capture,'capture_after':int(u.GetCapture() or 0)})
  if cmd.get('require'):assert result['moved'] and result['passive'] and result['capture_before']==result['capture_after'],result
else:raise ValueError(cmd['operation'])
(OUT/(cmd['label']+'.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
