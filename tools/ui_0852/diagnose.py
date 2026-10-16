from pathlib import Path
import ctypes as c,json
from ctypes import wintypes as w
from pymxs import runtime as r
from PySide6 import QtWidgets,QtCore
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
root=r.UI0852Root;values=[int(root.procEpoch),int(root.groupBuilds)]
for leaf in root.layerObjects:values.extend([int(leaf.procPreparedBuilds),int(leaf.procDensityBakes),*[int(x) for x in leaf.receiverCacheStats()]])
current={'uploads':[int(x) for x in r.cyrusRetainedStreamStats()][1:4],'rows':str(r.cyrusRecipePublicationFingerprint(root.groupSnapshotRows)),'work':values,
 'amount':[float(x.amount) for x in root.layerObjects],'undo':[str(x) for x in r.theHold.GetUndoNames()],'redo':[str(x) for x in r.theHold.GetRedoNames()]}
before=json.loads((OUT/'pending-state.json').read_text()) if (OUT/'pending-state.json').exists() else {}
u=c.WinDLL('user32');u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)];u.GetParent.argtypes=[w.HWND];u.GetParent.restype=w.HWND
pages=[]
for index in (0,len(root.mainUI.editors)-1):
 page=root.mainUI.editors[index];h=int(page.hwnd);box=w.RECT();u.GetWindowRect(h,c.byref(box));row={'page':index,'rect':[box.left,box.top,box.right,box.bottom]}
 while h:
  widget=QtWidgets.QWidget.find(h)
  if widget and widget.metaObject().className()=='CommandPanelRollupContainer':
   viewport=widget.viewport();origin=viewport.mapToGlobal(QtCore.QPoint(0,0));row['viewport']=[origin.x(),origin.y(),viewport.width(),viewport.height()];row['scroll']=[widget.verticalScrollBar().value(),widget.verticalScrollBar().maximum()];break
  h=int(u.GetParent(h) or 0)
 pages.append(row)
(OUT/'diagnosis.json').write_text(json.dumps({'before':before,'current':current,'different':[k for k in current if before.get(k)!=current[k]],'pages':pages},indent=2))
