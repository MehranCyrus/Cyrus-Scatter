"""Prepare the reported source with the generated button and one scatter copy."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={}
try:
    root=r.WFRoot;leaf=r.WFGrass;collider=r.WFCollider
    collider.interactionCollider=False;leaf.interactionReact=False;root.updateMode=1
    r.execute('subObjectLevel=0;select WFOwner;modPanel.setCurrentObject WFRoot')
    until=time.monotonic()+3
    while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
    source=next(n for n in r.objects if str(n.name)=='Outdoor_Plants_01_Neottopteris_Nidus_Bush_Decorative05_001')
    r.execute('global BroadleafSource');r.BroadleafSource=source
    leaf.removeModelSources(r.Array(*range(1,len(leaf.sources)+1)));leaf.addModelSource(source)
    leaf.amount=1;leaf.interactionFoliage=1.;leaf.interactionCoverRoots=False;leaf.interactionGapWU=0.;leaf.markInputDirty()
    root.refreshAll();r.CyrusPointSync();r.completeRedraw();root.selectLayer(1)
    panel=root.mainUI;panel.slots[12].open=True;panel.bindSection(panel.editors[12]);r.WFSection=panel.editors[12]
    r.execute('WFSection.interactionsUI_chooseRole 3')
    start=time.perf_counter();r.execute('WFSection.interactionsUI_prepareButton.pressed()');report['prepare_button_seconds']=time.perf_counter()-start
    assert leaf.interactionsReady(leaf.validSources()),str(r.WFSection.interactionsUI_info.text)
    assert not str(root.interactionError),str(root.interactionError)
    definition=json.loads(str(leaf.interactionDefinitions[-1]));report['definition_report']=definition['source']['report']
    assert report['definition_report']['crown_root_guides']==36
    assert report['definition_report']['fixed_parts']>0
    metadata=definition['source']['metadata']
    assert all(metadata['parts'][ci]['stem'] for ci in range(2043,2079)), 'A broad fern leaf was left as a rigid attachment'
    crown_guides=[g for g in metadata['guides'] if 2043<=g['component']<2079]
    assert len(crown_guides)==36 and all(.10<g['nodes'][0][1]<.17 for g in crown_guides), 'A drooping tip replaced its crown root'
    (O/'broadleaf-definition.json').write_text(json.dumps(definition),encoding='utf-8')
    info=json.loads(str(r.cyrusInteractionSourceInfo(leaf.interactionSourceCache[0][1])));report['source_info']=info
    assert info['delivered_preview_triangles']==50382
    r.execute('WFSection.interactionsUI_guideReviewButton.changed true')
    report['review_helpers']=len(leaf.interactionGuides);report['review_guides']=info['review_guides_shown']
    assert report['review_helpers']>0 and report['review_guides']==547
    assert float(r.distance(leaf.interactionGuides[-1].pos,source.pos))<1e-4
    r.execute('WFSection.interactionsUI_guideReviewButton.changed false')
    root.updateMode=2;r.WFSphere.radius=13.;root.refreshAll();r.CyrusPointSync();r.completeRedraw()
    r.execute('global WFBase,WFCurrent,WFTarget,WFContactStep')
    r.WFBase=r.cyrusPlacementTransformGroups(root.groupSnapshotRows[0])[0][0].row4
    r.execute('select WFOwner;max modify mode;modPanel.setCurrentObject WFEdit;subObjectLevel=1;max move')
    r.CyrusPointSync();r.completeRedraw();r.cyrusEditActiveLayers(r.WFEdit,r.Array(int(collider.editLayerKey)));r.cyrusEditSelect(r.WFEdit,r.Array(1))
    root.interactionsEnsure();r.WFCurrent=r.cyrusPlacementTransformGroups(r.cyrusInteractionRows(root.interactionState,2))[0][0].row4;r.WFTarget=r.WFBase+r.Point3(150,0,120)
    r.execute('undo "Place fern collider" on cyrusEditTransform WFEdit 0 (WFTarget-WFCurrent) (matrix3 1) false')
    collider.interactionColliderMode=1;collider.interactionCollider=True;root.interactionsEnsure();r.CyrusPointSync();r.completeRedraw()
    report['statistics']=json.loads(str(root.interactionsStatistics()));assert not report['statistics']['error']
    report['status']='ready'
except Exception:report['error']=traceback.format_exc()
(O/'broadleaf-setup.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
