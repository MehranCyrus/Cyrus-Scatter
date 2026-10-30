"""Owned Max 2027 editor fixture using the exact Violet from the artist's scene copy."""
from pathlib import Path
from pymxs import runtime as r
from PySide6 import QtWidgets
import builtins,json,time,traceback
RUN=Path(__file__).resolve().parent;OUT=Path(str(r.GardenRun));started=time.monotonic();done=set()
assert r.loadMaxFile(str(RUN/'Terraces-owned.max'),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
r.execute('''global VSource=getNodeByName "SOURCE | A062 | Common Blue Violet - 04"
if VSource==undefined do throw "Exact supplied Violet is missing"
delete (for n in objects where n!=VSource collect n)
global VPlane=plane length:300 width:300 lengthsegs:1 widthsegs:1
global VNode=AminScatterObject name:"Owned Violet preparation 08767",VRoot=VNode.baseObject,VLayer
VRoot.surfaceNodes=#(VPlane);VRoot.newLayer();VLayer=VRoot.selectedLayer();VLayer.addModelSource VSource
VLayer.amount=3;VRoot.updateMode=1;VRoot.autoRender=false;VRoot.setGroupDisplay 3;VRoot.refreshAll()
CyrusOpenPreparationEditor VLayer VSource
''')
def tick():
 r.VOwnedTimer.Stop()
 try:
  state=json.loads(str(r.cyrusPreparationEditorInfo()))
  if state.get('ready') and not (OUT/'ui-ready.json').exists():(OUT/'ui-ready.json').write_text(json.dumps({'pid':int(r.sysInfo.getProcessID()) if False else 0,'state':state},indent=2))
  for path in sorted(OUT.glob('command-*.ms')):
   if path.name in done:continue
   done.add(path.name)
   try:value=r.execute(path.read_text(encoding='utf-8'));(OUT/(path.stem+'.json')).write_text(json.dumps({'status':'pass','result':str(value)}))
   except Exception:(OUT/(path.stem+'.json')).write_text(json.dumps({'status':'failed','error':traceback.format_exc()}))
  if (OUT/'stop').exists() or time.monotonic()-started>1800:
   r.cyrusPreparationEditorClose();(OUT/'completed.json').write_text(json.dumps({'status':'complete'}));r.execute('resetMaxFile #noPrompt;quitMax #noPrompt quiet:true exitCode:0');return
  r.VOwnedTimer.Start()
 except Exception:(OUT/'error.txt').write_text(traceback.format_exc());r.execute('quitMax #noPrompt quiet:true exitCode:1')
builtins._cyrus_violet_owned_tick=tick
r.execute('''global VOwnedTimer=dotNetObject "System.Windows.Forms.Timer"
VOwnedTimer.Interval=500
fn VOwnedTick sender args = (python.Execute "import builtins; builtins._cyrus_violet_owned_tick()")
dotNet.addEventHandler VOwnedTimer "Tick" VOwnedTick
VOwnedTimer.Start()''')
