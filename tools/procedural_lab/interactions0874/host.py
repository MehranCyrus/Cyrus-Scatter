"""Owned Max 2027 preparation-editor intake; native/script identity checked by launcher."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun))
try:
    r.execute('global MCPFixtureDir=GardenRun;CyrusPerfHeadless=true;CyrusPointSuspended=true')
    assert int(r.cyrusInteractionVersion())==8
    r.AminScatterObject()
    scene=ROOT/'Test Scene/New Plants test.max'
    assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    root=owner.baseObject;leaf=root.layerObjects[0];collider=root.layerObjects[1]
    for item in root.layerObjects:item.interactionCollider=False;item.interactionReact=False
    root.updateMode=1;leaf.amount=1;leaf.interactionFoliage=1.;leaf.interactionCoverRoots=False
    root.refreshAll()
    if not any(r.classOf(m)==r.CyrusScatterEdit for m in owner.modifiers):r.addModifier(owner,r.CyrusScatterEdit())
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFSphere,WFSection,WFEdit,PEFern,PEGrass')
    r.WFOwner=owner;r.WFRoot=root;r.WFGrass=leaf;r.WFCollider=collider;r.WFSphere=collider.validSources()[0]
    r.WFEdit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    r.PEFern=next(n for n in r.objects if str(n.name)=='Outdoor_Plants_01_Neottopteris_Nidus_Bush_Decorative05_001')
    r.PEGrass=next(n for n in r.objects if str(n.name).startswith('Outdoor_Plants_01_Grass'))
    r.CyrusPerfHeadless=False;r.CyrusPointSuspended=False;r.select(owner)
    r.execute('max modify mode;modPanel.setCurrentObject WFRoot')
    until=time.monotonic()+5
    while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.02)
    assert root.mainUI.controlsReady
    root.selectLayer(1);panel=root.mainUI;panel.slots[12].open=True;panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12]
    r.CyrusPointSync();r.completeRedraw()
    (O/'ready.json').write_text(json.dumps({'status':'ready','version':str(root.uiVersion()),'schema':int(root.version),'fern':str(r.PEFern.name),'grass':str(r.PEGrass.name)},indent=2))
except Exception:(O/'ready.json').write_text(json.dumps({'error':traceback.format_exc()},indent=2))
r.execute('fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/mcp/development_transport.ms"')
