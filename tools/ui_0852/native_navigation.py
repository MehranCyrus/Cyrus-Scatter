"""Owned Win32 input; measure native content movement across event-loop turns."""
from pathlib import Path
import ctypes as c,json
from ctypes import wintypes as w
from pymxs import runtime as r
from PySide6 import QtWidgets,QtCore
from shiboken6 import isValid
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
cmd=json.loads((OUT/'navigation-command.json').read_text());root=r.UI0852Root;main=root.mainUI
u=c.WinDLL('user32');u.GetParent.argtypes=[w.HWND];u.GetParent.restype=w.HWND
u.SendMessageW.argtypes=[w.HWND,w.UINT,w.WPARAM,w.LPARAM];u.SendMessageW.restype=c.c_ssize_t
u.GetCapture.restype=w.HWND;u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
u.GetForegroundWindow.restype=w.HWND
u.SetWindowPos.argtypes=[w.HWND,w.HWND,c.c_int,c.c_int,c.c_int,c.c_int,w.UINT]
def rect(handle):
 box=w.RECT();assert u.GetWindowRect(handle,c.byref(box));return [box.left,box.top,box.right,box.bottom]
def state():
 values=[int(root.procEpoch),int(root.groupBuilds)]
 for leaf in root.layerObjects:values.extend([int(leaf.procPreparedBuilds),int(leaf.procDensityBakes),*[int(x) for x in leaf.receiverCacheStats()]])
 return {'uploads':[int(x) for x in r.cyrusRetainedStreamStats()][1:4],'rows':str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows)),'work':values,
  'amount':[float(x.amount) for x in root.layerObjects],'undo':[str(x) for x in r.theHold.GetUndoNames()],'redo':[str(x) for x in r.theHold.GetRedoNames()]}
def scroll_state(column):
 widget=QtWidgets.QWidget.find(column)
 if not widget or not isValid(widget) or not isinstance(widget,QtWidgets.QAbstractScrollArea):return None
 bar=widget.verticalScrollBar()
 if not isValid(bar):return None
 return {'value':bar.value(),'maximum':bar.maximum()}
def groups():
 result={}
 for index,(slot,page) in enumerate(zip(main.slots,main.editors)):
  if not page.isDisplayed or not slot.open:continue
  info=[int(x) for x in r.cyrusRolloutScrollInfo(slot.hwnd)];column=info[6]
  result.setdefault(column,{'column':column,'clip':rect(column),'scroll':scroll_state(column),'pages':[]})['pages'].append({'index':index,'handle':int(page.hwnd),'slot':int(slot.hwnd),'rect':rect(int(page.hwnd))})
 return list(result.values())
def wheel(handle,direction,clip):
 x=(clip[0]+clip[2])//2;y=(clip[1]+clip[3])//2;delta=-120 if direction=='down' else 120
 for _ in range(3):u.SendMessageW(handle,0x20A,(delta&65535)<<16,(x&65535)|((y&65535)<<16))
def choices_for(columns,direction):
 choices=[]
 for group in columns:
  clip=group['clip'];pages=group['pages'];lo=min(p['rect'][1] for p in pages);hi=max(p['rect'][3] for p in pages)
  scroll=group['scroll']
  if not scroll or scroll['maximum']<=0:continue
  room=scroll['value']<scroll['maximum'] if direction=='down' else scroll['value']>0
  for page in pages:
   top=max(page['rect'][1],clip[1]+2);bottom=min(page['rect'][3],clip[3]-2)
   if room and bottom-top>=8:choices.append({**page,'column':group['column'],'clip':clip,'top':top,'bottom':bottom})
 return choices
op=cmd['operation'];result={'command':cmd,'status':'passed'}
if op=='configure':
 if r.CyrusRecipeBrowser is not None:r.destroyDialog(r.CyrusRecipeBrowser)
 h=int(main.hwnd);widget=None
 while h:
  q=QtWidgets.QWidget.find(h)
  if q and q.metaObject().className()=='CommandPanel':widget=q;break
  h=int(u.GetParent(h) or 0)
 assert widget is not None and isinstance(widget,QtWidgets.QDockWidget)
 parent=widget.parentWidget()
 while parent is not None and not isinstance(parent,QtWidgets.QMainWindow):parent=parent.parentWidget()
 assert parent is not None
 width=int(cmd.get('width',260));widget.setMinimumWidth(220);widget.setMaximumWidth(width);parent.resizeDocks([widget],[width],QtCore.Qt.Horizontal)
 for slot in main.slots:slot.open=True;slot.rolledUp(False)
 if cmd.get('publish'):root.refreshAll()
 result['state']=state()
elif op=='columns':
 result['columns']=groups();(OUT/'native-columns-current.json').write_text(json.dumps(result['columns']))
elif op=='prepare_probe':
 direction=cmd['direction'];columns=groups();choices=choices_for(columns,direction)
 if choices:result.update(ready=True,choice=choices[0] if direction=='down' else choices[-1])
 else:
  overflow=next(g for g in columns if g['scroll'] and g['scroll']['maximum']>0)
  lo=min(p['rect'][1] for p in overflow['pages']);preparation='down' if lo>=overflow['clip'][1]-5 else 'up'
  wheel(overflow['column'],preparation,overflow['clip']);result.update(ready=False,preparation=preparation,columns=columns)
 (OUT/'navigation-prepared.json').write_text(json.dumps(result))
elif op=='probe':
 # A real wheel is hit-tested by Qt. Raise only the owned test window without
 # activation until the following event-loop turn; never move the pointer.
 foreground=int(u.GetForegroundWindow() or 0);owned_window=int(r.windows.getMAXHWND())
 u.SetWindowPos(owned_window,0,0,0,0,0,0x13);QtWidgets.QApplication.processEvents()
 choices=choices_for(groups(),cmd['direction']);assert choices,'No current visible overflowing page; allow layout to settle'
 choice=choices[0] if cmd['direction']=='down' else choices[-1];handle=choice['handle']
 box=rect(handle);clip=rect(choice['column']);top=max(box[1],clip[1]+2);bottom=min(box[3],clip[3]-2);assert bottom-top>=8,(box,clip)
 before=state();capture=int(u.GetCapture() or 0);start=(top+bottom)//2-box[1];scroll_before=scroll_state(choice['column']);assert scroll_before is not None
 if cmd.get('bind'):result['bindings']=int(r.cyrusBindRolloutScroll(choice['slot']))
 if cmd['gesture']=='wheel':wheel(handle,cmd['direction'],[box[0]+3,top,box[0]+4,bottom])
 elif cmd['gesture']=='drag':
  end=start+(-200 if cmd['direction']=='down' else 200)
  u.SendMessageW(handle,0x201,1,3|((start&65535)<<16))
  for i in range(1,11):
   y=round(start+(end-start)*i/10);u.SendMessageW(handle,0x200,1,3|((y&65535)<<16))
  u.SendMessageW(handle,0x202,0,3|((end&65535)<<16))
 else:raise ValueError(cmd['gesture'])
 result.update(foreground=foreground,owned_window=owned_window,choice=choice,rect_before=box,state_before=before,capture_before=capture,scroll_before=scroll_before)
 (OUT/'navigation-delivered.json').write_text(json.dumps(result))
elif op=='verify_probe':
 delivered=json.loads((OUT/'navigation-delivered.json').read_text())
 u.SetWindowPos(delivered['owned_window'],1,0,0,0,0,0x13)
 assert int(u.GetForegroundWindow() or 0)==delivered['foreground'],'Artist foreground changed'
 box=rect(int(main.editors[delivered['choice']['index']].hwnd));delta=box[1]-delivered['rect_before'][1]
 column=int(r.cyrusRolloutScrollInfo(main.slots[delivered['choice']['index']].hwnd)[6]);scroll_after=scroll_state(column);assert scroll_after is not None
 change=scroll_after['value']-delivered['scroll_before']['value']
 result.update(rect_before=delivered['rect_before'],rect_after=box,delta_y=delta,scroll_before=delivered['scroll_before'],scroll_after=scroll_after,moved=change>0 if cmd['direction']=='down' else change<0,
  state_before=delivered['state_before'],state_after=state(),capture_before=delivered['capture_before'],capture_after=int(u.GetCapture() or 0))
 result['passive']=result['state_before']==result['state_after']
 assert result['moved'] and result['passive'] and result['capture_before']==result['capture_after'],result
else:raise ValueError(op)
(OUT/(cmd['label']+'.json')).write_text(json.dumps(result,indent=2))
