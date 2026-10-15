"""Actual control handlers and event-loop boundaries for orientation."""
from pathlib import Path
import json,sys,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-orientation0830-')
sys.path.insert(0,str(ROOT/'tools/recipes_0825'));from recipe_rows import fingerprint
req=json.loads((OUT/'orientation-command.json').read_text(encoding='utf-8'));op=req['operation']
target=OUT/('lifecycle-'+req['label']+'.json');result={'status':'running','operation':op,'checks':[]}
def save():target.write_text(json.dumps(result,indent=2),encoding='utf-8')
def check(ok,label):result['checks'].append({'passed':bool(ok),'assertion':label});save();assert ok,label
def snap():
 root=r.OrientationRoot;leaf=r.OrientationLeaf;native=list(r.cyrusRetainedStats(r.CyrusPointOwner(r.OrientationNode)))
 orientation=[int(x) for x in r.cyrusOrientationStats()]
 return {'rows':fingerprint(root.groupSnapshotRows[0]),'orientation':orientation[:3],'normal_memory':orientation[3:],'observed_seconds':time.monotonic(),
  'receiver':[int(x) for x in leaf.receiverCacheStats()],'epoch':int(root.procEpoch),'prepare':int(leaf.procPreparedBuilds),
  'preview':int(leaf.previewBuildCount),'upload':int(native[5]),'retained':int(native[3]),'input_time':str(leaf.inputTimeStats())}
def baseline():return json.loads((OUT/'lifecycle-baseline.json').read_text(encoding='utf-8'))
def remember():
 data=snap();(OUT/'lifecycle-baseline.json').write_text(json.dumps(data,indent=2),encoding='utf-8');result['baseline']=data;return data
def mount():
 r.CyrusPerfHeadless=False;r.select(r.OrientationNode);r.execute('max modify mode');r.modPanel.setCurrentObject(r.OrientationRoot)
 if not r.OrientationRoot.mainUI.controlsReady:r.OrientationRoot.mainUI.mountTimer.tick()
 slot=r.OrientationRoot.mainUI.slots[8];slot.open=True;slot.rolledUp(False)
 return r.OrientationRoot.mainUI.editors[8]
def choose(control,index):
 import ctypes as c
 u=c.windll.user32;u.GetParent.argtypes=[c.c_void_p];u.GetParent.restype=c.c_void_p
 u.SendMessageW.argtypes=[c.c_void_p,c.c_uint,c.c_size_t,c.c_ssize_t];u.SendMessageW.restype=c.c_ssize_t;u.GetDlgCtrlID.argtypes=[c.c_void_p]
 for value in control.hwnd:
  handle=int(value);name=c.create_unicode_buffer(256);u.GetClassNameW(c.c_void_p(handle),name,256)
  if name.value=='ComboBox':
   u.SendMessageW(handle,0x14e,index-1,0)
   for notification in (1,9):u.SendMessageW(u.GetParent(handle),0x111,u.GetDlgCtrlID(handle)|(notification<<16),handle)
   return
 raise RuntimeError('No owned ComboBox handle')
try:
 with pymxs.undo(False):
  if op=='target_geometry_setup':
   r.CyrusPerfHeadless=True;r.loadMaxFile(str(sorted(OUT.glob('orientation-*.max'))[-1]),quiet=True,useFileUnits=True)
   r.OrientationNode=r.getNodeByName('Orientation qualification');r.OrientationRoot=r.OrientationNode.baseObject;r.OrientationLeaf=r.OrientationRoot.layerObjects[0]
  root=r.OrientationRoot;leaf=r.OrientationLeaf
  if op=='target_geometry_setup':
   r.OrientationTarget=r.box(name='Geometry-only target',height=2,width=2,length=2,pos=r.Point3(0,0,80));leaf.orientationTarget=r.OrientationTarget;leaf.orientationMode=3
   mount();root.mainUI.updateRadio.changed(2);root.refreshAll();r.CyrusPointSync();r.completeRedraw()
  elif op=='target_geometry_edit':
   remember();r.OrientationTarget.height=20
  elif op=='target_geometry_check':
   before=baseline();after=snap();result['before']=before;result['after']=after
   check(all(after[k]==before[k] for k in ('rows','orientation','epoch','prepare','preview','upload','retained')),'Target geometry changes with a fixed pivot perform no scattering work')
  elif op=='ui':
   leaf.alignNormal=False;leaf.orientationMode=1;root.refreshAll();r.CyrusPointSync()
   before=snap();page=mount();check(snap()['rows']==before['rows'],'Opening Transforms preserves publication')
   check(page.controlsReady and page.randomUI_controlsReady,'Lazy Transforms controls are bound')
   check(not page.randomUI_normalBlendSpin.enabled and not page.randomUI_directionXSpin.enabled,'Upright Random disables blend and fixed-vector controls')
   page.randomUI_alignCheck.changed(True);page.randomUI_normalBlendSpin.changed(35.);choose(page.randomUI_orientationList,2)
   page.randomUI_directionXSpin.changed(1.);page.randomUI_directionYSpin.changed(1.);page.randomUI_directionZSpin.changed(.25)
   check(leaf.alignNormal and abs(leaf.orientationBlend-35)<1e-5 and leaf.orientationMode==2,'Actual orientation handlers change the selected owner')
   r.completeRedraw();check(snap()['rows']==before['rows'] and snap()['epoch']==before['epoch'],'Manual handlers leave published placements unchanged')
   check(page.randomUI_normalBlendSpin.enabled and page.randomUI_directionXSpin.enabled and not page.randomUI_targetPickButton.enabled,'World mode and normal enabled states are correct')
   root.mainUI.updateNow.pressed();r.CyrusPointSync();check(snap()['rows']!=before['rows'],'Actual Update publishes pending orientation')
   root.newLayer();other=root.selectedLayer();other.orientationBlend=88.;root.mainUI.selectLayerView(other)
   check(abs(page.randomUI_normalBlendSpin.value-88)<1e-4,'Owner switching rebinds displayed blend')
   page.randomUI_normalBlendSpin.changed(77.);check(abs(other.orientationBlend-77)<1e-4 and abs(leaf.orientationBlend-35)<1e-4,'Owner switching isolates edits')
   root.mainUI.selectLayerView(leaf);remember()
  elif op=='live_setup':
   page=mount();r.OrientationTarget=r.getNodeByName('Aim target')
   if r.OrientationTarget is None:r.OrientationTarget=r.Point(name='Aim target',pos=r.Point3(0,20,60))
   leaf.orientationTarget=r.OrientationTarget;leaf.orientationMode=3;leaf.alignNormal=True
   r.execute('global OrientationParent; OrientationParent=Dummy name:"Orientation target parent"; OrientationTarget.parent=OrientationParent')
   r.sliderTime=0
   with pymxs.animate(True):
    with pymxs.attime(0):r.OrientationTarget.pos=r.Point3(0,20,60)
    with pymxs.attime(10):r.OrientationTarget.pos=r.Point3(40,-20,80)
   root.mainUI.updateRadio.changed(2);root.refreshAll();r.CyrusPointSync();r.completeRedraw();remember()
  elif op=='time_step':
   remember();r.sliderTime=5
  elif op=='time_check':
   before=baseline();after=snap();result['before']=before;result['after']=after
   check(after['rows']!=before['rows'],'Relevant target animation publishes in Live after the event loop')
   check(after['receiver'][0]==before['receiver'][0] and after['orientation'][0]==before['orientation'][0],'Animated target does not rebuild candidates or normals')
   remember()
  elif op=='idle_check':
   before=baseline();after=snap();result['before']=before;result['after']=after
   result['elapsed_seconds']=after['observed_seconds']-before['observed_seconds']
   check(all(after[k]==before[k] for k in ('rows','orientation','epoch','prepare','preview','upload','retained')),'Idle at an animated target frame performs no orientation/placement/preparation/upload work')
   check(after['input_time']==before['input_time'],'Idle animation frame does not repeatedly invalidate/query candidate validity')
  elif op=='parent_move':
   remember();r.OrientationParent.pos=r.Point3(20,0,0)
  elif op=='parent_check':
   before=baseline();after=snap();result['before']=before;result['after']=after
   check(after['rows']!=before['rows'],'Relevant target parent movement publishes in Live')
   check(after['receiver'][0]==before['receiver'][0] and after['orientation'][0]==before['orientation'][0],'Parent movement reuses candidates and normals');remember()
  elif op=='inactive_setup':
   leaf.orientationMode=1;root.refreshAll();r.CyrusPointSync();r.completeRedraw();remember();r.OrientationTarget.pos=r.Point3(-40,30,100);r.sliderTime=7
  elif op=='inactive_check':
   before=baseline();after=snap();result['before']=before;result['after']=after
   check(all(after[k]==before[k] for k in ('rows','orientation','epoch','prepare','preview','upload','retained')),'Inactive target and unrelated animation do not calculate or upload')
  elif op=='normal_animation_setup':
   leaf.orientationMode=1;leaf.alignNormal=True;r.sliderTime=0
   with pymxs.animate(True):
    with pymxs.attime(0):leaf.orientationBlend=0.
    with pymxs.attime(10):leaf.orientationBlend=100.
   root.refreshAll();r.CyrusPointSync();r.completeRedraw()
  elif op=='normal_animation_step':
   remember();r.sliderTime=5
  elif op=='normal_animation_check':
   before=baseline();after=snap();result['before']=before;result['after']=after
   check(after['rows']!=before['rows'],'Animated normal blend changes Live orientation')
   check(after['receiver'][0]==before['receiver'][0] and after['orientation'][0]==before['orientation'][0],'Animated normal blend reuses candidates and normals');remember()
  elif op=='target_delete_setup':
   leaf.orientationMode=3;leaf.orientationTarget=r.OrientationTarget;root.refreshAll();r.CyrusPointSync();r.completeRedraw()
  elif op=='target_delete':
   remember();r.delete(r.OrientationTarget)
  elif op=='target_delete_check':
   before=baseline();after=snap();result['before']=before;result['after']=after
   check(after['rows']==before['rows'] and after['epoch']==before['epoch'] and 'Look at target needs' in str(leaf.cacheSnapshot()[3]),'Live target deletion reports failure and retains complete publication')
  elif op=='pivot_rotation':
   remember();r.rotate(r.OrientationTarget,r.eulerAngles(0,0,40))
  elif op=='pivot_rotation_check':
   before=baseline();after=snap();result['before']=before;result['after']=after
   check(all(after[k]==before[k] for k in ('rows','orientation','epoch','prepare','preview','upload','retained')),'Target rotation about an unchanged pivot performs no scattering work')
  else:raise ValueError(op)
 result['status']='passed';save()
except Exception:result['status']='failed';result['error']=traceback.format_exc();save();raise
