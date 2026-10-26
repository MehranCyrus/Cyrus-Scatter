"""Read-only confirmation after physical Frame/Prepare/guide-toggle clicks."""
from pathlib import Path
import json,hashlib,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={}
try:
    leaf=r.WFGrass;source=leaf.validSources()[0];saved=json.loads((O/'fern-roundtrip.json').read_text())
    info=json.loads(str(r.cyrusInteractionSourceInfo(leaf.interactionReview)))
    current=hashlib.sha256(str(leaf.interactionDefinitions[0]).encode()).hexdigest()
    assert leaf.interactionsReady(leaf.validSources()) and not str(r.WFRoot.interactionError)
    assert info['crown_root_guides']==36 and info['guides']==547
    assert bool(leaf.interactionsReviewVisible(r.Name('guides'),source))
    report={'status':'pass','hwnd':int(r.windows.getMAXHWND()),'physical_actions':['Frame source','Prepare model','Show source guides'],'source_definition_changed_after_prepare':current!=saved['definition_sha256'],'guides':info['guides'],'crown_guides':info['crown_root_guides'],'review_helpers':len(leaf.interactionGuides),'interaction_error':str(r.WFRoot.interactionError)}
    assert report['source_definition_changed_after_prepare']
except Exception:report['error']=traceback.format_exc()
(O/'physical-ui.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
