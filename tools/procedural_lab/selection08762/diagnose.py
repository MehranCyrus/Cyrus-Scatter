from pathlib import Path
from pymxs import runtime as r
out=Path(str(r.GardenRun))
queries=['#(PKRoot.viewportNavigationFaces,PKOther.viewportNavigationFaces)', 'CyrusSelectionUI.navigation.changed 444444', '#(PKRoot.viewportNavigationFaces,PKOther.viewportNavigationFaces)', 'max undo', '#(PKRoot.viewportNavigationFaces,PKOther.viewportNavigationFaces)', 'theHold.Holding()', 'getUndoNames()']
lines=[]
for q in queries:
    try:lines.append(q+' => '+str(r.execute(q)))
    except Exception as e:lines.append(q+' => '+str(e))
(out/'diagnose.txt').write_text('\n'.join(lines))
r.loadDllsFromDir(str(out.parent/'probe')+'/', 'SelectionProbe.dlx')
