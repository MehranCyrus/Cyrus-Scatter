"""Read native rollout geometry only in a user-data-isolated owned Max process."""
from pathlib import Path
import ctypes as c
from ctypes import wintypes as w
import json
import os
from pymxs import runtime as r
from PySide6 import QtWidgets,QtCore

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.is_relative_to(ROOT/'build')
for key in ('ADSK_3DSMAX_APPDATA_DIR','ADSK_3DSMAX_USERSETTINGS_DIR','ADSK_3DSMAX_USERTOOLS_DIR'):
    assert Path(os.environ[key]).resolve().is_relative_to(OUT),key
u=c.WinDLL('user32');u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
u.GetParent.argtypes=[w.HWND];u.GetParent.restype=w.HWND
if str(r.QScenarioID)=='UI84-PREPARE':
    handle=int(r.QRoot.mainUI.hwnd)
    while handle:
        widget=QtWidgets.QWidget.find(handle)
        if widget and widget.metaObject().className()=='CommandPanel':
            parent=widget.parentWidget()
            while parent and not isinstance(parent,QtWidgets.QMainWindow):parent=parent.parentWidget()
            assert parent
            parent.showMaximized()
            widget.setMinimumWidth(660)
            parent.resizeDocks([widget],[660],QtCore.Qt.Horizontal)
            break
        handle=int(u.GetParent(handle) or 0)
    QtWidgets.QApplication.processEvents()
rows=[]
for index,slot in enumerate(r.QRoot.mainUI.slots,1):
    bounds=w.RECT();u.GetWindowRect(int(slot.hwnd),c.byref(bounds))
    rows.append({'index':index,'name':str(slot.name),'open':bool(slot.open),
                 'rect':[bounds.left,bounds.top,bounds.right,bounds.bottom]})
(OUT/('panels-'+str(r.QScenarioID)+'.json')).write_text(json.dumps({'panels':rows,
    'order':[int(i) for i in r.QPanelOrder()],'epoch':int(r.QRoot.procEpoch),
    'amount':float(r.QLayer.amount),'user_data':os.environ['ADSK_3DSMAX_APPDATA_DIR']},indent=2))
