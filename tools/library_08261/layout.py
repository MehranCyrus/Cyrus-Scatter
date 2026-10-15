"""Measure and capture the actual Recipes dialog in an owned Max 2027 profile."""
from pathlib import Path
import ctypes as c
from ctypes import wintypes as w
import json,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-library08261-')
u=c.WinDLL('user32');u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
u.GetWindowTextW.argtypes=[w.HWND,w.LPWSTR,c.c_int]
def rect(handle):
 box=w.RECT();assert u.GetWindowRect(handle,c.byref(box));return [box.left,box.top,box.right,box.bottom]
result={'status':'running','scale':float(r.GetUIScaleFactor()),'controls':[],'clipped':[],'overlaps':[]}
label=json.loads((OUT/'command.json').read_text(encoding='utf-8')).get('label','browser')
try:
 page=r.CyrusRecipeBrowser;bounds=rect(int(page.hwnd));result['dialog']=bounds
 for control in page.controls:
  try:
   if not control.visible:continue
   handles=control.hwnd
   if isinstance(handles,int):handles=[handles]
   for handle in handles:
    handle=int(handle)
    if not handle:continue
    box=rect(handle)
    if box[2]<=box[0] or box[3]<=box[1]:continue
    item={'name':str(control),'rect':box,'class':str(r.windows.getHWNDData(handle)[3])}
    result['controls'].append(item)
    if box[0]<bounds[0]-2 or box[2]>bounds[2]+2 or box[1]<bounds[1]-2 or box[3]>bounds[3]+2:result['clipped'].append(item)
    if item['class']=='Static' or str(control).startswith('CheckBoxControl'):
     text=c.create_unicode_buffer(4096);u.GetWindowTextW(handle,text,4096)
     if text.value:
      width=box[2]-box[0]-(round(26*result['scale']) if str(control).startswith('CheckBoxControl') else 0)
      item['text_height']=int(r.cyrusMeasureWrappedText(handle,text.value,max(1,width)))
      if item['text_height']>box[3]-box[1]+2:result['clipped'].append(item)
  except AttributeError:pass
 for i,first in enumerate(result['controls']):
  for second in result['controls'][i+1:]:
   if first['name']==second['name']:continue
   a,b=first['rect'],second['rect']
   if min(a[2],b[2])-max(a[0],b[0])>3 and min(a[3],b[3])-max(a[1],b[1])>3:result['overlaps'].append([first['name'],second['name']])
 snapshot=r.windows.snapshot(int(page.hwnd),captureScreenPixels=False,gammaCorrect=False)
 snapshot.filename=str(OUT/('layout-'+label+'.png'));assert r.save(snapshot);r.close(snapshot)
 result['status']='passed' if result['controls'] and not result['clipped'] and not result['overlaps'] else 'failed'
except Exception:result['status']='failed';result['error']=traceback.format_exc();raise
finally:(OUT/('layout-'+label+'.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
