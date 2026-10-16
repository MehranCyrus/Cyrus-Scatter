"""Expose the owned Layers section for a full-body capture; never target artist UI."""
from pathlib import Path
import json
from pymxs import runtime as r
from PySide6 import QtWidgets
out=Path(str(r.MCPFixtureDir)).resolve()
assert out.parent==Path(__file__).resolve().parents[2]/'build/mcp-qualification'
assert out.name.startswith('foundation-roadmap-variation0840-')
root=r.getNodeByName('Variation heavy setup').baseObject
slot=root.mainUI.slots[0];slot.open=True;slot.rolledUp(False)
page=root.mainUI.editors[0];records=[];handle=int(page.hwnd)
for _ in range(16):
 if not handle:break
 data=r.windows.getHWNDData(handle);widget=QtWidgets.QWidget.find(handle)
 item={'handle':handle,'class':str(data[3]),'qt':None}
 if widget:
  item['qt']=widget.metaObject().className();item['name']=widget.objectName()
  if isinstance(widget,QtWidgets.QAbstractScrollArea):
   bar=widget.verticalScrollBar();item.update(before=bar.value(),maximum=bar.maximum());bar.setValue(0)
 records.append(item);handle=int(data[1])
r.redrawViews()
(out/'scroll-manager.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
