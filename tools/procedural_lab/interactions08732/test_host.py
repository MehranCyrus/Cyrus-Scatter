"""Owned Max 2027 setup for actual generated Interactions control tests."""
from pathlib import Path
import json,traceback,time
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));report={}
try:
    r.execute('global MCPFixtureDir=GardenRun;CyrusPerfHeadless=true;CyrusPointSuspended=true')
    assert int(r.cyrusInteractionVersion())==7
    r.AminScatterObject()
    scene=ROOT/'build/interactions08732-neottopteris-20261026-01/New Plants test.max'
    assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    root=owner.baseObject;grass=root.layerObjects[0];collider=root.layerObjects[1]
    if not any(r.classOf(m)==r.CyrusScatterEdit for m in owner.modifiers):r.addModifier(owner,r.CyrusScatterEdit())
    for leaf in root.layerObjects:leaf.interactionCollider=False;leaf.interactionReact=False
    # Use the source sphere, preserving its previously authored proxy node.
    collider.interactionColliderMode=1;grass.amount=50;grass.interactionCoverRoots=False;grass.markInputDirty()
    root.refreshAll();assert not any(str(x.previewError) for x in root.layerObjects)
    r.execute('global WFOwner,WFRoot,WFGrass,WFCollider,WFSphere,WFSection,WFEdit')
    r.WFOwner=owner;r.WFRoot=root;r.WFGrass=grass;r.WFCollider=collider;r.WFSphere=collider.validSources()[0]
    r.WFEdit=next(m for m in owner.modifiers if r.classOf(m)==r.CyrusScatterEdit)
    r.CyrusPerfHeadless=False;r.CyrusPointSuspended=False
    r.select(owner);r.execute('max modify mode;modPanel.setCurrentObject WFRoot')
    root.selectLayer(1);r.windows.processPostedMessages();panel=root.mainUI
    until=time.monotonic()+3
    while not bool(panel.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
    assert bool(panel.controlsReady),'Modify panel did not finish mounting'
    assert len(panel.editors)==13
    section=panel.editors[12];panel.slots[12].open=True;panel.bindSection(section);r.WFSection=section
    r.CyrusPointSync();r.completeRedraw()
    panel.bindSection(section)
    r.execute('WFSection.interactionsUI_chooseRole 3')
    report={'status':'ready','native_capability':int(r.cyrusInteractionVersion()),'schema':int(root.version),'version':str(root.uiVersion()),'source_count':len(list(r.objects))}
except Exception:report={'error':traceback.format_exc()}
(O/'ready.json').write_text(json.dumps(report,indent=2))
r.execute('fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/mcp/development_transport.ms"')
