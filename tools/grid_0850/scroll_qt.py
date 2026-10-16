"""Scroll only the owned Layout ancestry and record its actual Qt widgets."""
from pathlib import Path
import json
from pymxs import runtime as r
from PySide6 import QtWidgets
out=Path(str(r.MCPFixtureDir)).resolve()
assert out.name.startswith('foundation-roadmap-grid0850-')
page=r.OrientationRoot.mainUI.editors[4];records=[];handle=int(page.hwnd)
for _ in range(16):
 if not handle:break
 data=r.windows.getHWNDData(handle);widget=QtWidgets.QWidget.find(handle)
 item={'handle':handle,'class':str(data[3]),'qt':None}
 if widget:
  item['qt']=widget.metaObject().className();item['name']=widget.objectName()
  scrolls=widget.findChildren(QtWidgets.QAbstractScrollArea)
  if isinstance(widget,QtWidgets.QAbstractScrollArea):scrolls=[widget]+scrolls
  item['scrolls']=[]
  for scroll in scrolls:
   bar=scroll.verticalScrollBar()
   item['scrolls'].append({'class':scroll.metaObject().className(),'name':scroll.objectName(),'maximum':bar.maximum(),'before':bar.value()})
   # Only ancestor scroll areas containing this rollout's Qt widget qualify.
   if scroll is widget:bar.setValue(bar.maximum())
 records.append(item);handle=int(data[1])
r.redrawViews()
(out/'scroll-qt.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
