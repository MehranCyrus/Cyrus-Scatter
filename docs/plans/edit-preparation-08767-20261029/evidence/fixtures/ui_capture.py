from pathlib import Path
from pymxs import runtime as r
from PySide6 import QtWidgets
import json
out=Path(str(r.GardenRun));name=str(r.UICaptureName)
app=QtWidgets.QApplication.instance();screen=app.primaryScreen()
screen.grabWindow(int(r.windows.getMAXHWND())).save(str(out/(name+'.png')))
state={'epoch':int(r.URoot.procEpoch),'group':list(r.URoot.groupCounters()),'streams':list(r.cyrusRetainedStreamStats()),
       'pending_amount':int(r.ULayer.amount),'generated':int(r.ULayer.generatedCount),'enabled':str(r.URoot.managerUI.flow_layersUI_enabledCheck.text),
       'visible':str(r.URoot.managerUI.flow_layersUI_visibleCheck.text),'radio_labels':[str(r.windows.getHWNDData(int(h))[4]) for h in r.URoot.layoutUI.diversityUI_diversityRadio.hwnd]}
(out/(name+'.json')).write_text(json.dumps(state,indent=2))
