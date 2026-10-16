"""Pending/Live, native control input, visibility and panel remount boundaries."""
from pathlib import Path
import ctypes as c,json,time,pymxs
from ctypes import wintypes as w
from pymxs import runtime as r
from PySide6 import QtWidgets
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
cmd=json.loads((OUT/'lifecycle-command.json').read_text());root=r.UI0852Root
u=c.WinDLL('user32');u.SendMessageW.argtypes=[w.HWND,w.UINT,w.WPARAM,w.LPARAM];u.SendMessageW.restype=c.c_ssize_t
u.GetCapture.restype=w.HWND;u.GetForegroundWindow.restype=w.HWND;u.ShowWindow.argtypes=[w.HWND,c.c_int]
u.GetClassNameW.argtypes=[w.HWND,w.LPWSTR,c.c_int]
u.SetWindowPos.argtypes=[w.HWND,w.HWND,c.c_int,c.c_int,c.c_int,c.c_int,w.UINT]
def state():
 values=[int(root.procEpoch),int(root.groupBuilds)]
 for leaf in root.layerObjects:values.extend([int(leaf.procPreparedBuilds),int(leaf.procDensityBakes),*[int(x) for x in leaf.receiverCacheStats()]])
 return {'uploads':[int(x) for x in r.cyrusRetainedStreamStats()][1:4],'rows':str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows)),'work':values,'amount':[float(x.amount) for x in root.layerObjects],
  'undo':[str(x) for x in r.theHold.GetUndoNames()],'redo':[str(x) for x in r.theHold.GetRedoNames()]}
op=cmd['operation'];result={'operation':op,'status':'passed'}
if op=='pending':
 with pymxs.undo(True,'UI pending amount'):root.layerObjects[0].amount+=1
 result['state']=state();(OUT/'pending-state.json').write_text(json.dumps(result['state']))
elif op=='clear':
 assert state()==json.loads((OUT/'pending-state.json').read_text())
 with pymxs.undo(False):r.clearSelection()
elif op=='mount':
 assert state()==json.loads((OUT/'pending-state.json').read_text())
 with pymxs.undo(False):r.select(r.UI0852Node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
elif op=='verify_pending':
 assert root.updateMode==1 and state()==json.loads((OUT/'pending-state.json').read_text())
 result['state']=state()
elif op=='warm':
 r.CyrusPointSync();r.completeRedraw();QtWidgets.QApplication.processEvents();result['state']=state()
elif op=='live':root.mainUI.updateRadio.changed(2)
elif op=='idle_start':
 result['started']=time.time();result['state']=state();result['mode']=int(root.updateMode)
 (OUT/('idle-'+cmd['label']+'-before.json')).write_text(json.dumps(result))
elif op=='idle_verify':
 before=json.loads((OUT/('idle-'+cmd['label']+'-before.json')).read_text());assert time.time()-before['started']>=120
 assert state()==before['state'];result['seconds']=time.time()-before['started'];result['state']=state()
elif op=='controls':
 # Only this owned Max is shown, without activation, then hidden again. This
 # permits real managed Visible/capture guards and native software screenshots.
 window=int(r.windows.getMAXHWND());foreground=int(u.GetForegroundWindow() or 0)
 u.ShowWindow(window,4);u.SetWindowPos(window,1,0,0,1600,1000,0x12)
 QtWidgets.QApplication.processEvents();r.completeRedraw();QtWidgets.QApplication.processEvents()
 try:
  main=root.mainUI;slot=main.slots[0];slot.open=True;slot.rolledUp(False);page=main.editors[0]
  before=state();toggle=page.advancedToggle;old=bool(toggle.checked);handles=[]
  for h in toggle.hwnd:
   text=c.create_unicode_buffer(256);u.GetClassNameW(int(h),text,256);handles.append((int(h),text.value))
  (OUT/'checkbox-handles.json').write_text(json.dumps(handles))
  handle=next(h for h,name in handles if name=='CustButton')
  for expected in (not old,old):
   u.SendMessageW(handle,0x201,1,4|(4<<16));u.SendMessageW(handle,0x202,0,4|(4<<16))
   assert bool(toggle.checked)==expected,'Native checkbutton input failed'
  grip=page.flow_layersUI_layerList_grip;target=page.flow_layersUI_layerList;old_height=int(target.height)
  assert grip.Visible and grip.Enabled
  handle=int(grip.Handle);u.SendMessageW(handle,0x201,1,3|(3<<16));assert grip.Capture
  u.SendMessageW(handle,0x200,1,3|(27<<16));assert int(target.height)>old_height,'List resize grip was intercepted'
  u.SendMessageW(handle,0x202,0,3|(27<<16));assert not grip.Capture
  target.height=old_height;page.layout();main.rememberViews();assert state()==before
  image=r.windows.snapshot(int(page.hwnd),captureScreenPixels=False,gammaCorrect=False)
  image.filename=str(OUT/'manager-visible.png');r.save(image);r.close(image)
  result.update({'checkbox':True,'grip':True,'capture_released':int(u.GetCapture() or 0)==0,'passive':True})
 finally:
  # Keep the owned window visible behind the artist so native/Qt geometry and
  # display callbacks can settle naturally during the following lifecycle test.
  u.SetWindowPos(window,1,0,0,0,0,0x13)
 result['foreground_preserved']=int(u.GetForegroundWindow() or 0)==foreground
 assert result['foreground_preserved']
else:raise ValueError(op)
(OUT/(cmd['label']+'.json')).write_text(json.dumps(result,indent=2))
