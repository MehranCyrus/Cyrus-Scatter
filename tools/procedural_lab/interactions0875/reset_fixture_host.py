"""Initialize only an owned Max 2027 instance against copied 20-model fixtures."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3]
O=Path(str(r.GardenRun));RUN=ROOT/'build/interactions08741-20261027-01'
try:
    r.execute('global MCPFixtureDir=GardenRun;CyrusPerfHeadless=true;CyrusPointSuspended=true')
    capability=int(r.cyrusInteractionVersion());r.AminScatterObject()
    scene=RUN/'fixtures/New-Plants-input.max'
    assert scene.is_file() and r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    root=owner.baseObject;leaf=root.layerObjects[0];collider=root.layerObjects[1]
    for item in root.layerObjects:item.interactionCollider=False;item.interactionReact=False
    root.updateMode=1;leaf.amount=1;leaf.interactionFoliage=1.;leaf.interactionCoverRoots=False;root.refreshAll()
    if not any(r.classOf(m)==r.CyrusScatterEdit for m in owner.modifiers):r.addModifier(owner,r.CyrusScatterEdit())
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFSphere,WFSection,WFEdit,CVModel, CVMatrix, CVPoint, CVCurrent, CVTarget, CVKey, CVImported')
    r.CVImported=r.undefined
    r.WFOwner=owner;r.WFRoot=root;r.WFGrass=leaf;r.WFCollider=collider;r.WFSphere=collider.validSources()[0]
    r.WFEdit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    r.CyrusPerfHeadless=False;r.CyrusPointSuspended=False;r.select(owner)
    r.execute('max modify mode;modPanel.setCurrentObject WFRoot')
    until=time.monotonic()+5
    while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.02)
    assert root.mainUI.controlsReady
    root.selectLayer(1);panel=root.mainUI;panel.slots[12].open=True;panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12]
    r.CyrusPointSync();r.completeRedraw()
    manifest=json.loads((RUN/'fixture-manifest.json').read_text(encoding='utf-8'))
    names={str(n.name) for n in r.objects};scene_names=manifest['old_scene_model_names'];found=[n for n in scene_names if n in names]
    report={'status':'ready','version':str(root.uiVersion()),'native_capability':capability,'schema':int(root.version),'scene_sources_found':found,'scene_sources_missing':[n for n in scene_names if n not in names], 'units':str(r.units.SystemType),'unit_scale':float(r.units.SystemScale),'fixture_sha256':manifest['plant_scene']['sha256'],'sphere':str(r.WFSphere.name)}
    (O/'ready.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
except Exception:(O/'ready.json').write_text(json.dumps({'error':traceback.format_exc()},indent=2),encoding='utf-8')
