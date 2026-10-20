"""Inspect the managed list's real child HWND, not the empty static host."""
from pathlib import Path
import ctypes as c,json
from ctypes import wintypes as w
from pymxs import runtime as r
out=Path(str(r.CPLTestDir)).resolve();assert out.parent.name=='build' and out.name.startswith('physics-lab')
lab=r.CPLUILab;lab.objectsUI.open=True;r.windows.processPostedMessages();view=lab.objectsUI.sourceList
raw=view.Handle
try:handle=int(raw.ToInt64())
except Exception:handle=int(raw)
api=c.WinDLL('user32',use_last_error=True);api.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)];api.GetClientRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
a=w.RECT();b=w.RECT();client=w.RECT();assert api.GetWindowRect(handle,c.byref(a));assert api.GetWindowRect(int(lab.objectsUI.hwnd),c.byref(b));assert api.GetClientRect(handle,c.byref(client))
record={'hwnd':handle,'rect':[a.left-b.left,a.top-b.top,a.right-b.left,a.bottom-b.top],'parent':[b.right-b.left,b.bottom-b.top],'client':[client.right,client.bottom],'item_height':int(view.ItemHeight),'item_count':int(view.Items.Count),'scale':float(r.GetUIScaleFactor())}
(out/'checked-list-layout.json').write_text(json.dumps(record,indent=2))
assert a.left>=b.left and a.top>=b.top and a.right<=b.right+1 and a.bottom<=b.bottom+1,record
assert client.right>=60 and client.bottom>=3*int(view.ItemHeight),record
