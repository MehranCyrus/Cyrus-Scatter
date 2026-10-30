"""Panel reflow and assignment badge checks in the owned Max test profile."""
from pathlib import Path
from pymxs import runtime as r
from PySide6 import QtWidgets,QtCore,QtGui
import builtins,json,traceback
OUT=Path(str(r.GardenRun));RUN=Path(__file__).resolve().parent;report={'passed':[]}
def write(): (OUT/'ui-qualification.json').write_text(json.dumps(report,indent=2))
def check(value,label):
 assert value,label
 report['passed'].append(label);write()
def colors(value):return [[int(c.r),int(c.g),int(c.b)] for c in value]
def work():return [int(r.URoot.procEpoch),*[int(x) for x in r.URoot.groupCounters()],*[int(x) for x in r.cyrusRetainedStreamStats()][1:4]]
def dock():
 h=int(r.URoot.mainUI.hwnd)
 while h:
  widget=QtWidgets.QWidget.find(h)
  if widget and widget.metaObject().className()=='CommandPanel':return widget
  h=int(r.windows.getHWNDData(h)[1])
 raise AssertionError('No owned command panel')
def capture(name):
 r.UICaptureName=name;r.python.ExecuteFile(str(RUN/'ui_capture.py'))
 image=QtGui.QImage(str(OUT/(name+'.png')))
 result={}
 for label,(x0,y0,x1,y1) in {'radio':(1103,331,1230,407),'checks':(885,433,1000,452)}.items():
  result[label]=sum(1 for y in range(y0,y1) for x in range(x0,x1) if min(image.pixelColor(x,y).red(),image.pixelColor(x,y).green(),image.pixelColor(x,y).blue())>175 and max(image.pixelColor(x,y).red(),image.pixelColor(x,y).green(),image.pixelColor(x,y).blue())-min(image.pixelColor(x,y).red(),image.pixelColor(x,y).green(),image.pixelColor(x,y).blue())<35)
 return result
def campaign():
 try:
  r.execute('URoot.mainUI.open=false;URoot.modelsUISlot.open=false;URoot.modelsUISlot.rolledUp true;URoot.layoutUISlot.open=true;URoot.layoutUISlot.rolledUp false')
  yield
  before=work();amount=int(r.ULayer.generatedCount);r.ULayer.amount=amount+17;r.ULayer.markInputDirty()
  for i in range(8):
   r.URoot.displayUISlot.open=i%2==0;r.URoot.displayUISlot.rolledUp(i%2!=0);yield
   check(work()==before,f'rollout change {i+1} preserves placement/preparation/upload work')
  widget=dock();parent=widget.parentWidget()
  while parent and not isinstance(parent,QtWidgets.QMainWindow):parent=parent.parentWidget()
  for width in [880,440,660]:
   widget.setMinimumWidth(width);widget.setMaximumWidth(width);parent.resizeDocks([widget],[width],QtCore.Qt.Horizontal);yield
   check(work()==before,f'column resize {width} preserves cached scatter work')
  r.URoot.displayUISlot.open=True;r.URoot.displayUISlot.rolledUp(False);yield
  check(int(r.ULayer.generatedCount)==amount and int(r.ULayer.amount)==amount+17,'panel reflow leaves Manual population pending')
  check(not r.URoot.mainUI.repaintTimer.active,'deferred repaint timer retires while idle')
  report['label_pixels']=capture('labels-after-reflow');write()
  r.execute('''global UPath=rectangle length:600 width:600
ULayer.diversityMode=3
ULayer.addStroke UPath;ULayer.addStroke UPath;ULayer.addStroke UPath
ULayer.setStrokeSelection 1 2 #(ULayer.sourceRowIDs[1])
ULayer.setStrokeSelection 2 2 #(ULayer.sourceRowIDs[1],ULayer.sourceRowIDs[2])
URoot.mainUI.bind()
''');yield
  ui=r.URoot.layoutUI
  check(colors(ui.diversityUI_bandAssignmentPalette(1))==colors(r.Array(r.ULayer.sourceIDColor(1))),'single-model band uses that model badge')
  check(colors(ui.diversityUI_bandAssignmentPalette(2))==colors(r.Array(r.ULayer.sourceIDColor(1),r.ULayer.sourceIDColor(2))),'mixed-model band uses split model colours')
  check(len(ui.diversityUI_bandAssignmentPalette(3))==0,'unassigned band has no arbitrary badge')
  saved=list(r.ULayer.strokeDisplayColors)
  r.ULayer.setSourceIDColor(r.Array(1),r.Color(201,54,117));yield
  check(colors(ui.diversityUI_bandAssignmentPalette(1))==[[201,54,117]],'band follows a changed model identification colour')
  check(colors(r.ULayer.strokeDisplayColors)==colors(saved),'badge refresh preserves authored viewport Band colours')
  r.execute('ULayer.strokeModes[3]=1;ULayer.setStrokeSelection 3 1 #(ULayer.colorKey (ULayer.sourceColor 1));URoot.mainUI.bind()');yield
  check(colors(ui.diversityUI_bandAssignmentPalette(3))==[[201,54,117]],'assignment-group band also uses the model badge')
  r.execute('ULayer.setStrokeSelection 3 1 #();URoot.mainUI.bind()');yield
  check(len(ui.diversityUI_bandAssignmentPalette(3))==0,'clearing a group assignment removes the badge')
  report['palettes']=[colors(ui.diversityUI_bandAssignmentPalette(i)) for i in range(1,4)]
  check(int(r.ULayer.generatedCount)==amount,'band authoring still leaves Manual placements pending')
  report['status']='complete';write()
 except Exception:
  report.update(status='failed',error=traceback.format_exc());write()
_campaign=campaign()
def tick():
 r.UICampaignTimer.Stop()
 try:next(_campaign);r.UICampaignTimer.Start()
 except StopIteration:pass
builtins._cyrus_ui_campaign_tick=tick
r.execute('''global UICampaignTimer=dotNetObject "System.Windows.Forms.Timer"
UICampaignTimer.Interval=350
fn UICampaignTick sender args = (python.Execute "import builtins; builtins._cyrus_ui_campaign_tick()")
dotNet.addEventHandler UICampaignTimer "Tick" UICampaignTick
UICampaignTimer.Start()
''')
