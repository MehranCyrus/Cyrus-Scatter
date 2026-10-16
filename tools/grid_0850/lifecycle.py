"""Grid UI and event-loop qualification in an owned Max 2027 host."""
from pathlib import Path
import json,sys,time,traceback,ctypes as c
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
req=json.loads((OUT/'grid-command.json').read_text(encoding='utf-8'));op=req['operation']
result={'status':'running','operation':op,'checks':[]};target=OUT/('lifecycle-'+req['label']+'.json')
def save():target.write_text(json.dumps(result,indent=2),encoding='utf-8')
def check(ok,label):result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def snap():
 return {'seconds':time.monotonic(),'rows':[fingerprint(x) for x in root.groupSnapshotRows],
  'grid':list(r.cyrusGridStats()),'orientation':list(r.cyrusOrientationStats())[:3],'epoch':int(root.procEpoch),
  'receiver':[list(x.receiverCacheStats()) for x in root.layerObjects],
  'prepare':[int(x.procPreparedBuilds) for x in root.layerObjects],
  'preview':[int(x.previewBuildCount) for x in root.layerObjects],
  'display':list(r.cyrusRetainedStats(r.CyrusPointOwner(node)))}
def remember():
 data=snap();(OUT/'lifecycle-baseline.json').write_text(json.dumps(data,indent=2),encoding='utf-8');result['baseline']=data;return data
def prior():return json.loads((OUT/'lifecycle-baseline.json').read_text(encoding='utf-8'))
def unchanged(a,b):
 return all(a[k]==b[k] for k in ('rows','orientation','epoch','prepare','preview')) and a['grid'][:3]==b['grid'][:3] and a['display'][5]==b['display'][5] and a['display'][3]==b['display'][3] and all(x[0]==y[0] and x[2]==y[2] for x,y in zip(a['receiver'],b['receiver']))
def page(index):
 slot=root.mainUI.slots[index];slot.open=True;slot.rolledUp(False);return root.mainUI.editors[index]
def choose(control,index):
 u=c.windll.user32;u.GetParent.argtypes=[c.c_void_p];u.GetParent.restype=c.c_void_p
 u.SendMessageW.argtypes=[c.c_void_p,c.c_uint,c.c_size_t,c.c_ssize_t];u.SendMessageW.restype=c.c_ssize_t;u.GetDlgCtrlID.argtypes=[c.c_void_p]
 for value in control.hwnd:
  handle=int(value);name=c.create_unicode_buffer(256);u.GetClassNameW(c.c_void_p(handle),name,256)
  if name.value=='ComboBox':
   u.SendMessageW(handle,0x14e,index-1,0)
   for notice in (1,9):u.SendMessageW(u.GetParent(handle),0x111,u.GetDlgCtrlID(handle)|(notice<<16),handle)
   return
 raise RuntimeError('No owned ComboBox handle')
try:
 with pymxs.undo(False):
  if op=='ui':
   r.CyrusPerfHeadless=True;r.loadMaxFile(str(OUT/'grid-core.max'),quiet=True,useFileUnits=True)
  node=r.getNodeByName('Grid qualification');assert r.isValidNode(node)
  root=node.baseObject;leaf=root.layerObjects[0]
  if op=='ui':
   root.updateMode=1;r.CyrusPerfHeadless=False;r.select(node);r.execute('max modify mode');r.modPanel.setCurrentObject(root)
   if not root.mainUI.controlsReady:root.mainUI.mountTimer.tick()
   root.mainUI.selectLayerView(leaf);layout=page(4);amount=page(5)
   before=snap();choose(layout.placementUI_generatorList,4)
   check(leaf.placementMode==4 and not layout.placementUI_rowSpin.visible,'Actual dropdown selects Hexagonal and hides independent row pitch')
   check(not amount.distributionUI_countSpin.enabled and not amount.distributionUI_populationRadio.enabled,'Grid disables Count and density population controls')
   layout.placementUI_columnSpin.changed(6.);layout.placementUI_headingSpin.changed(15.)
   check(leaf.gridColumnWU==6. and leaf.gridHeading==15.,'Actual spinner handlers edit the selected layer')
   check(unchanged(before,snap()),'Manual placement handlers preserve all rows and calculation/upload counters')
   root.mainUI.updateNow.pressed();r.CyrusPointSync()
   check(snap()['rows'][0]!=before['rows'][0],'Actual Update publishes pending grid parameters')
   other=root.layerObjects[1];other.gridColumnWU=7.;root.mainUI.selectLayerView(other)
   check(layout.placementUI_columnSpin.value==7.,'Owner switch rebinds grid controls')
   layout.placementUI_columnSpin.changed(8.)
   check(other.gridColumnWU==8. and leaf.gridColumnWU==6.,'Callback captures the correct owner during rebinding')
   choose(layout.placementUI_generatorList,1)
   check(amount.distributionUI_countSpin.enabled and not layout.placementUI_columnSpin.visible,'Surface random restores population controls and hides grid settings')
   choose(layout.placementUI_generatorList,2);root.mainUI.selectLayerView(leaf)
   root.refreshAll();r.CyrusPointSync();r.completeRedraw();remember()
  elif op=='live_setup':
   root.mainUI.updateRadio.changed(2);root.refreshAll();r.CyrusPointSync();r.completeRedraw();remember()
  elif op=='edit':
   remember();leaf.gridHeading=22.
  elif op=='edit_check':
   before=prior();after=snap();result.update(before=before,after=after)
   check(after['rows'][0]!=before['rows'][0] and after['grid'][0]==before['grid'][0]+1,'Relevant Live grid edit projects only its receiver and publishes')
   check(after['rows'][1:]==before['rows'][1:],'Other layer populations remain identical');remember()
  elif op=='unrelated_step':
   remember();r.sliderTime=8;r.GridUnrelated=r.box(name='Unrelated grid test',pos=r.Point3(200,0,0));r.GridUnrelated.pos=r.Point3(300,0,0)
  elif op in ('idle_check','unrelated_check','inactive_check'):
   before=prior();after=snap();result.update(before=before,after=after,elapsed_seconds=after['seconds']-before['seconds'])
   check(unchanged(before,after),'No placement, projection, preparation or upload work for '+op)
  elif op=='animation_setup':
   r.sliderTime=0
   with pymxs.animate(True):
    with pymxs.attime(0):leaf.gridHeading=0.
    with pymxs.attime(10):leaf.gridHeading=30.
   root.refreshAll();r.CyrusPointSync();r.completeRedraw()
  elif op=='animation_step':remember();r.sliderTime=5
  elif op=='animation_check':
   before=prior();after=snap();result.update(before=before,after=after)
   check(after['rows'][0]!=before['rows'][0] and after['grid'][0]==before['grid'][0]+1,'Animated active grid heading updates Live once')
   check(after['rows'][1:]==before['rows'][1:],'Static layers remain identical during grid animation');remember()
  elif op=='inactive_setup':
   leaf.placementMode=1;root.refreshAll();r.CyrusPointSync();r.completeRedraw()
  elif op=='inactive_step':remember();r.sliderTime=7
  elif op=='grid_inactive_count_setup':
   r.deleteKeys(r.getPropertyController(leaf,r.Name('gridHeading')),r.Name('allKeys'));leaf.gridHeading=0.;leaf.placementMode=2;r.sliderTime=0
   with pymxs.animate(True):
    with pymxs.attime(0):leaf.amount=100
    with pymxs.attime(10):leaf.amount=300
   root.refreshAll();r.CyrusPointSync();r.completeRedraw()
  elif op=='grid_inactive_count_step':remember();r.sliderTime=5
  elif op=='grid_inactive_count_check':
   before=prior();after=snap();result.update(before=before,after=after)
   check(unchanged(before,after),'Animated inactive Count performs no grid/candidate/publication/upload work')
  elif op=='inactive_policy_step':
   remember();leaf.procPopulation=2;leaf.procAttemptFactor=5;leaf.procRounds=4;leaf.procRepair=True;leaf.plantsPerM2=20.;leaf.populationMode=2
  elif op=='inactive_policy_check':
   before=prior();after=snap();result.update(before=before,after=after)
   check(unchanged(before,after),'Inactive grid Density and refill edits perform no calculation or publication')
  elif op=='terrain_animation_setup':
   terrain=r.getNodeByName('Grid terrain');r.sliderTime=0
   with pymxs.animate(True):
    with pymxs.attime(0):terrain.pos=r.Point3(0,0,0)
    with pymxs.attime(10):terrain.pos=r.Point3(0,0,4)
   root.refreshAll();r.CyrusPointSync();r.completeRedraw()
  elif op=='terrain_animation_step':remember();r.sliderTime=5
  elif op=='terrain_animation_check':
   before=prior();after=snap();result.update(before=before,after=after)
   check(all(a!=b for a,b in zip(before['rows'],after['rows'])) and after['grid'][0]==before['grid'][0]+3,'Relevant animated receiver rebuilds each layer grid and publishes complete new heights');remember()
  else:raise ValueError(op)
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
