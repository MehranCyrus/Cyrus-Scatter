from pathlib import Path
from pymxs import runtime as r
import json
out=Path(str(r.GardenRun));info=json.loads(str(r.cyrusPreparationEditorInfo()));d=json.loads(str(r.cyrusPreparationEditorDefinition()));m=d['source']['metadata']
assert info['ready'] and not info['busy']
assert all(len(m['guides'][m['parts'][p]['guide']]['nodes'])==16 for p in range(15,77))
assert len(m['guides'][m['parts'][1]['guide']]['nodes'])==16
assert len(m['guides'][m['parts'][2]['guide']]['nodes'])==3
(out/'physical-detail.json').write_text(json.dumps({'status':'pass','action':'Computer Use chose Guide points 16 for 62 selected Leaf pieces','all_selected_leaf_guides':16,'untouched_stem_points':3,'already_edited_stem_points':16,'ready':True},indent=2))
