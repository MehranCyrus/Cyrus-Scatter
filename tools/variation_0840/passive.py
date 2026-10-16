"""Actual passive choice/panel work; invocation is separated from Live activation."""
from pathlib import Path
import json,sys,time,statistics,traceback,ctypes as c
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-variation0840-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
root=r.getNodeByName('Variation heavy setup').baseObject;node=r.getNodeByName('Variation heavy setup')
result={'status':'running','checks':[]};target=OUT/('passive-'+str(time.time_ns())+'.json')
def snap():
 return {'observed_seconds':time.monotonic(),'rows':[fingerprint(x) for x in root.groupSnapshotRows],
  'orientation':list(r.cyrusOrientationStats())[:3],'epoch':int(root.procEpoch),
  'receiver':[list(x.receiverCacheStats()) for x in root.layerObjects],
  'prepare':[int(x.procPreparedBuilds) for x in root.layerObjects],
  'preview':[int(x.previewBuildCount) for x in root.layerObjects],
  'display':list(r.cyrusRetainedStats(r.CyrusPointOwner(node)))}
def choose(control,index):
 u=c.windll.user32;u.GetParent.argtypes=[c.c_void_p];u.GetParent.restype=c.c_void_p
 u.SendMessageW.argtypes=[c.c_void_p,c.c_uint,c.c_size_t,c.c_ssize_t];u.SendMessageW.restype=c.c_ssize_t;u.GetDlgCtrlID.argtypes=[c.c_void_p]
 for value in control.hwnd:
  handle=int(value);name=c.create_unicode_buffer(256);u.GetClassNameW(c.c_void_p(handle),name,256)
  if name.value=='ComboBox':
   u.SendMessageW(handle,0x14e,index-1,0)
   for notice in (1,9):u.SendMessageW(u.GetParent(handle),0x111,u.GetDlgCtrlID(handle)|(notice<<16),handle)
   assert int(control.selection)==index;return
 raise RuntimeError('No owned ComboBox handle')
def unchanged(a,b):
 keys=('rows','orientation','epoch','prepare','preview')
 return all(a[k]==b[k] for k in keys) and a['display'][5]==b['display'][5] and a['display'][3]==b['display'][3] and all(x[0]==y[0] and x[2]==y[2] for x,y in zip(a['receiver'],b['receiver']))
try:
 before=snap();slot=root.mainUI.slots[0];times=[]
 for i in range(30):
  start=time.perf_counter();slot.open=True;slot.rolledUp(False);page=root.mainUI.editors[0]
  choose(page.flow_layersUI_copyVariation,1+i%2)
  slot.open=False;slot.rolledUp(True);times.append((time.perf_counter()-start)*1000)
 result['manager_cycles']={'milliseconds':times,'median':statistics.median(times),'p95':sorted(times)[28]}
 r.CyrusOpenRecipeLibrary(root);browser=r.CyrusRecipeBrowser
 if int(browser.scan)!=0:r.cyrusRecipeLibraryCancel(browser.scan)
 browser.scanTimer.active=False
 for i in range(30):choose(browser.importVariation,1+i%2)
 browser.closeButton.pressed()
 r.CyrusOpenPresets(root,root.layerObjects[0],'population');browser=r.CyrusPresetBrowser
 for i in range(30):choose(browser.seedChoice,1+i%3)
 browser.closeButton.pressed()
 after=snap();result.update(before=before,after=after)
 same=unchanged(before,after);result['checks'].append({'passed':same,'assertion':'Actual layer, recipe and numeric seed choices leave 60000 complete rows and calculation/preparation/upload counters unchanged'});assert same
 (OUT/'passive-baseline.json').write_text(json.dumps(after,indent=2),encoding='utf-8')
 result['status']='passed'
except Exception:result['status']='failed';result['error']=traceback.format_exc();raise
finally:target.write_text(json.dumps(result,indent=2),encoding='utf-8')
