"""Disposable Max 2027 UI reproduction with a task-local command queue."""
from pathlib import Path
from pymxs import runtime as r
from PySide6 import QtWidgets,QtCore
import builtins,json,traceback,time
OUT=Path(str(r.GardenRun));started=time.monotonic();done=set();prepared=False
assert OUT.parent.name=='edit-size-review-20261029-01'
r.execute('''resetMaxFile #noPrompt
global UPlane=plane length:1000 width:1000 lengthsegs:1 widthsegs:1
global UModel1=sphere radius:10 pos:[1500,0,0],UModel2=box width:20 length:20 height:30 pos:[1600,0,0],UModel3=cone radius1:12 height:40 pos:[1700,0,0]
global UNode=AminScatterObject name:"Owned 0877 panel repaint",URoot=UNode.baseObject,ULayer
URoot.surfaceNodes=#(UPlane);URoot.newLayer();ULayer=URoot.selectedLayer()
ULayer.addModelSource UModel1;ULayer.addModelSource UModel2;ULayer.addModelSource UModel3
ULayer.amount=200;ULayer.diversityMode=2;URoot.updateMode=1;URoot.autoRender=false;URoot.setGroupDisplay 3;URoot.refreshAll()
hide UModel1;hide UModel2;hide UModel3
select UNode;max modify mode
''')
r.saveMaxFile(str(OUT/'Owned-0877-UI.max'),quiet=True)
def tick():
 global prepared
 r.UITestTimer.Stop()
 try:
  if not prepared:
   if not r.URoot.mainUI.controlsReady or len(r.URoot.mainUI.mountQueue):
    r.UITestTimer.Start();return
   for slot in r.URoot.mainUI.slots:slot.open=str(slot.name) in ['managerUISlot','modelsUISlot','layoutUISlot']
   r.URoot.mainUI.bind()
   h=int(r.URoot.mainUI.hwnd)
   while h:
    widget=QtWidgets.QWidget.find(h)
    if widget and widget.metaObject().className()=='CommandPanel':
     parent=widget.parentWidget()
     while parent and not isinstance(parent,QtWidgets.QMainWindow):parent=parent.parentWidget()
     assert parent
     parent.showMaximized();widget.setMinimumWidth(660);parent.resizeDocks([widget],[660],QtCore.Qt.Horizontal)
     break
    h=int(r.windows.getHWNDData(h)[1])
   prepared=True;(OUT/'ui-ready.json').write_text(json.dumps({'status':'ready','hwnd':int(r.windows.getMAXHWND())}))
  for path in sorted(OUT.glob('command-*.ms')):
   if path.name in done:continue
   done.add(path.name)
   try:
    value=r.execute(path.read_text(encoding='utf-8'))
    (OUT/(path.stem+'.json')).write_text(json.dumps({'status':'pass','result':str(value)}))
   except Exception:(OUT/(path.stem+'.json')).write_text(json.dumps({'status':'failed','error':traceback.format_exc()}))
  if (OUT/'stop').exists() or time.monotonic()-started>1800:
   (OUT/'completed.json').write_text(json.dumps({'status':'complete'}));r.execute('quitMax #noPrompt quiet:true exitCode:0');return
 except Exception:
  (OUT/'ui-error.txt').write_text(traceback.format_exc())
 r.UITestTimer.Start()
builtins._cyrus_ui_tick=tick
r.execute('''global UITestTimer=dotNetObject "System.Windows.Forms.Timer"
UITestTimer.Interval=250
fn UITestTick sender args = (python.Execute "import builtins; builtins._cyrus_ui_tick()")
dotNet.addEventHandler UITestTimer "Tick" UITestTick
UITestTimer.Start()
''')
