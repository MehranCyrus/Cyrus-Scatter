from pathlib import Path
from pymxs import runtime as r
import json
out=Path(str(r.GardenRun))
data={'keys':[int(r.RKA.editLayerKey),int(r.RKB.editLayerKey)],'edit':str(r.RKEdit),'inspect':str(r.cyrusEditInspect(r.RKEdit,0,3)), 'undo_names':str(r.execute('theHold.getUndoNames()')), 'redo_names':str(r.execute('theHold.getRedoNames()'))}
r.execute('cyrusEditActiveLayers RKEdit #(RKB.editLayerKey);cyrusEditSelect RKEdit #(1)')
data['selected']=str(r.cyrusEditInspect(r.RKEdit,0,3))
(out/'persistence-debug.json').write_text(json.dumps(data,indent=2))
