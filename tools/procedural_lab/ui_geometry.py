"""Read-only Qt geometry evidence inside the private Max fixture."""
import json
from pathlib import Path
import pymxs
from PySide6.QtWidgets import QWidget
rt=pymxs.runtime
folder=Path(str(rt.MCPFixtureDir))
assert '/procedural07-ui-' in folder.as_posix()
root=rt.P07Root
rows=[]
for rollout in [root.mainUI]+list(root.nativeEditors())+list(root.nativeLayerSlots()):
    handle=int(rollout.hwnd)
    parent=int(rt.windows.getParentHWND(handle))
    widget=QWidget.find(parent)
    chain=[]
    while widget is not None and len(chain)<5:
        rect=widget.geometry()
        chain.append({'class':widget.metaObject().className(),'name':widget.objectName(),
                      'title':widget.property('title'),'visible':widget.isVisible(),'hidden':widget.isHidden(),
                      'rect':[rect.x(),rect.y(),rect.width(),rect.height()]})
        widget=widget.parentWidget()
    rows.append({'title':str(rollout.title),'hwnd':handle,'open':bool(rollout.open),'chain':chain})
(folder/'ui-geometry.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
