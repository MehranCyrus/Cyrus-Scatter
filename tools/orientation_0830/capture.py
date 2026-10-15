"""Capture the owned Max fixture window without activating or touching artist UI."""
from pathlib import Path
import argparse
import ctypes as c
from ctypes import wintypes as w
import json
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('name');a=p.parse_args()
folder=a.profile.resolve()
assert folder.parent==ROOT/'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-orientation0830-')
assert Path(a.name).name==a.name and a.name.endswith('.png')
pid=json.loads((folder/'launch.json').read_text())['pid']
u=c.WinDLL('user32',use_last_error=True);g=c.WinDLL('gdi32',use_last_error=True)
u.GetWindowDC.argtypes=[w.HWND];u.GetWindowDC.restype=w.HDC
u.ReleaseDC.argtypes=[w.HWND,w.HDC]
g.CreateCompatibleDC.argtypes=[w.HDC];g.CreateCompatibleDC.restype=w.HDC
g.CreateCompatibleBitmap.argtypes=[w.HDC,c.c_int,c.c_int];g.CreateCompatibleBitmap.restype=w.HBITMAP
g.SelectObject.argtypes=[w.HDC,w.HANDLE];g.SelectObject.restype=w.HANDLE
g.GetDIBits.argtypes=[w.HDC,w.HBITMAP,w.UINT,w.UINT,w.LPVOID,w.LPVOID,w.UINT]
g.DeleteObject.argtypes=[w.HANDLE];g.DeleteDC.argtypes=[w.HDC]
u.PrintWindow.argtypes=[w.HWND,w.HDC,w.UINT]
u.GetWindowThreadProcessId.argtypes=[w.HWND,c.POINTER(w.DWORD)]
u.GetWindowTextW.argtypes=[w.HWND,w.LPWSTR,c.c_int]
u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
callback=c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM);windows=[]
@callback
def visit(hwnd,param):
    owner=w.DWORD();u.GetWindowThreadProcessId(hwnd,c.byref(owner))
    if owner.value==pid:
        title=c.create_unicode_buffer(512);u.GetWindowTextW(hwnd,title,512)
        if 'Autodesk 3ds Max 2027' in title.value:windows.append(hwnd)
    return True
u.EnumWindows(visit,0);assert len(windows)==1,windows
hwnd=windows[0];rect=w.RECT();assert u.GetWindowRect(hwnd,c.byref(rect))
width,height=rect.right-rect.left,rect.bottom-rect.top
assert 100<width<16000 and 100<height<16000
dc=u.GetWindowDC(hwnd);memory=g.CreateCompatibleDC(dc);bitmap=g.CreateCompatibleBitmap(dc,width,height)
old=g.SelectObject(memory,bitmap)
class Header(c.Structure):
    _fields_=[('size',w.DWORD),('width',w.LONG),('height',w.LONG),('planes',w.WORD),('bits',w.WORD),('compression',w.DWORD),('imageSize',w.DWORD),('x',w.LONG),('y',w.LONG),('used',w.DWORD),('important',w.DWORD)]
try:
    assert u.PrintWindow(hwnd,memory,2),'PrintWindow failed'
    header=Header(c.sizeof(Header),width,-height,1,32,0,width*height*4,0,0,0,0)
    data=c.create_string_buffer(width*height*4)
    g.SelectObject(memory,old)
    assert g.GetDIBits(memory,bitmap,0,height,data,c.byref(header),0)==height
    Image.frombuffer('RGB',(width,height),data,'raw','BGRX',0,1).save(folder/a.name)
    print(folder/a.name)
finally:
    g.DeleteObject(bitmap);g.DeleteDC(memory);u.ReleaseDC(hwnd,dc)
