"""Read Max's native Qt rollup properties inside a disposable fixture host.

No UI automation, resizing, pointer interaction or screenshot. This validates
page metadata/visibility only; it is not visual, DPI or input qualification.
"""
import json
from pathlib import Path
from PySide6 import QtCore,QtWidgets
from shiboken6 import getCppPointer
from pymxs import runtime as rt

folder=Path(str(rt.MCPFixtureDir)).resolve()
root=Path(__file__).resolve().parents[2]
assert folder.is_relative_to(root/'build/mcp-qualification')
owner=rt.P07Root
expected_visible=owner.mainUI.owner is not None
expected={str(page.title) for page in owner.mainUI.editors}
rows=[]
for widget in QtWidgets.QApplication.allWidgets():
    title=widget.property('title')
    if title is None or str(title) not in expected:continue
    parent=widget.parentWidget()
    ancestors=[];item=parent
    while item is not None and len(ancestors)<12:
        ancestors.append(dict(class_name=item.metaObject().className(),name=item.objectName(),width=item.width(),height=item.height()))
        item=item.parentWidget()
    rows.append(dict(title=str(title),class_name=widget.metaObject().className(),
                     category=widget.property('category'),open=widget.property('open'),
                     explicitly_hidden=widget.isHidden(),width=widget.width(),height=widget.height(),
                     x=widget.x(),y=widget.y(),parent_id=getCppPointer(parent)[0],
                     global_x=widget.mapToGlobal(QtCore.QPoint(0,0)).x(),ancestors=ancestors))
result=dict(schema='cyrus.private-native-rollup-inspection/1',rows=rows,expected_pages=16,
            artist_scene_opened=False,computer_use=False,pointer_test=False,visual_qualification=False)
(folder/('native-rollup-'+('selected' if expected_visible else 'empty')+'.json')).write_text(json.dumps(result,indent=2)+'\n')
assert len(rows)==len(expected)==16,'Native selected-layer page count differs'
assert len({row['category'] for row in rows})==16,'Native page categories are not unique'
assert set(row['category'] for row in rows)==set(range(50,210,10)),'Native categories differ from workflow order'
assert all(row['explicitly_hidden']==(not expected_visible) for row in rows),'Native layer-page visibility differs from ownership'
if expected_visible:
    for parent in {row['parent_id'] for row in rows}:
        column=sorted((row for row in rows if row['parent_id']==parent),key=lambda row:row['y'])
        assert [row['category'] for row in column]==sorted(row['category'] for row in column),'Native page order differs from workflow order'
