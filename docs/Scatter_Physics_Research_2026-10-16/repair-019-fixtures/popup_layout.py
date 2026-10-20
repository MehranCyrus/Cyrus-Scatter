"""Read popup/list geometry in the owned Max process; no OS input or pixels."""
import ctypes as c,json
from ctypes import wintypes as w
from pathlib import Path
from pymxs import runtime as r
out=Path(str(r.CPLTestDir));assert out.parent.name=='build' and out.name.startswith('physics-lab')
api=c.WinDLL('user32',use_last_error=True)
api.SendMessageW.argtypes=[w.HWND,w.UINT,w.WPARAM,w.LPARAM];api.SendMessageW.restype=w.LPARAM
api.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
api.SetWindowPos.argtypes=[w.HWND,w.HWND,c.c_int,c.c_int,c.c_int,c.c_int,w.UINT]
lab=r.CPLUILab;lab.collisionUI.open=True;lab.objectsUI.open=True;r.execute('CPLUILab.refreshBindings()');r.windows.processPostedMessages()
data=[]
for width in [140,180,225]:
    for page in [lab.collisionUI,lab.objectsUI]:
        rect=w.RECT();assert api.GetWindowRect(int(page.hwnd),c.byref(rect))
        assert api.SetWindowPos(int(page.hwnd),None,0,0,round(width*float(r.GetUIScaleFactor())),rect.bottom-rect.top,0x16)
    r.execute('CPLUILab.collisionUI.layout();CPLUILab.objectsUI.layout()');r.windows.processPostedMessages()
    for raw in lab.collisionUI.qualityList.hwnd:
        h=int(raw)
        if not h or str(r.windows.getHWNDData(h)[3]).lower()!='combobox':continue
        rect=w.RECT();collapsed=w.RECT();assert api.SendMessageW(h,0x0152,0,c.addressof(rect))
        assert api.GetWindowRect(h,c.byref(collapsed))
        item_height=int(api.SendMessageW(h,0x0154,0,0))
        count=int(api.SendMessageW(h,0x0146,0,0))
        record={'width':width,'actual_logical_width':float(lab.uiWidth(lab.collisionUI)),'scale':float(r.GetUIScaleFactor()),'items':count,'item_height':item_height,'popup_rect':[rect.left,rect.top,rect.right,rect.bottom],'collapsed_height':collapsed.bottom-collapsed.top}
        data.append(record)
        assert count==3 and item_height>0,record
        assert rect.bottom-rect.top>=collapsed.bottom-collapsed.top+3*item_height+2,record
    assert str(lab.objectsUI.sourcePick.text)=='+', 'Add must use compact glyph'
    assert str(lab.objectsUI.removeSourceButton.text)=='x', 'Remove must use compact glyph'
assert len(data)==3,data
(out/'popup-layout.json').write_text(json.dumps(data,indent=2))
