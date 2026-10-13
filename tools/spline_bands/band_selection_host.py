"""Band membership and basic scale layout in an owned, matched Max host."""
from pathlib import Path
import hashlib,json,traceback,uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
receipt=OUT/('band-selection-'+uuid.uuid4().hex+'.json')
report={'checks':[],'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'launch':json.loads((OUT/'launch.json').read_text(encoding='utf-8'))}
def save():receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(value,label):
    report['checks'].append({'passed':bool(value),'label':label});save()
    if not value:raise AssertionError(label)
def ms(code):return r.execute('(\n'+code+'\n)')
def snapshot():return str(r.cyrusEditFingerprint(r.BandRoot.groupSnapshotRows[0],'selection'))
try:
    check(hashlib.sha256((ROOT/'AminScatter/scripts/AminScatterObject.ms').read_bytes()).hexdigest()==report['launch']['script_sha256'],'Matched generated script')
    r.resetMaxFile(r.Name('noPrompt'))
    ms('''
global BandNode=AminScatterObject name:"Band selection qualification"
global BandRoot=BandNode.baseObject
BandRoot.updateMode=1;BandRoot.autoRender=false;BandRoot.newLayer()
global BandLeaf=BandRoot.selectedLayer()
global BandModel=box width:3 length:3 height:8 pos:[700,0,0]
global BandPath=rectangle width:100 length:100
BandRoot.setLayerSurfaces BandLeaf #(plane width:400 length:400 widthsegs:1 lengthsegs:1)
BandLeaf.sources=#(BandModel);BandLeaf.addPointSource();BandLeaf.amount=2000;BandLeaf.diversityMode=3
BandLeaf.sourceColors=#(red,blue)
BandLeaf.procSelfOverride=true;BandLeaf.procSelfEnabled=false
BandLeaf.addStroke BandPath;BandLeaf.addStroke BandPath;BandLeaf.patternWidths=#(50.,50.)
BandLeaf.setStrokeSelection 1 2 #(BandModel)
BandLeaf.setStrokeSelection 2 2 #(BandLeaf.sourceRowIDs[2])
BandRoot.evaluateProcedural()
select BandNode;max modify mode
if not BandRoot.mainUI.controlsReady do BandRoot.mainUI.mountTimer.tick()
BandRoot.layoutUI.open=true;BandRoot.mainUI.bindSection BandRoot.layoutUI
global BandPage=BandRoot.layoutUI
BandPage.diversityUI_selectedBandID=BandLeaf.strokeIDs[1];BandPage.diversityUI_showStroke();BandPage.layout()
''')
    before=snapshot();epoch=int(r.BandRoot.procEpoch)
    widths=list(r.BandLeaf.patternWidths);ids=list(r.BandLeaf.strokeIDs)
    check(ms('BandPage.diversityUI_strokeChoices_colored.SelectionMode==(dotNetClass "System.Windows.Forms.SelectionMode").MultiSimple'),'Band membership uses native click-to-toggle selection')
    check(ms('not BandPage.advancedToggle.checked and BandPage.diversityUI_strokeScaleMin.visible and BandPage.diversityUI_bandScaleMode.visible and BandPage.diversityUI_bandScaleEdit.visible'),'Scale controls visible with Advanced collapsed')
    check(ms('BandPage.diversityUI_strokeScaleMin.pos.y>BandPage.diversityUI_bandCurveEdit.pos.y and BandPage.diversityUI_bandScaleEdit.pos.y<BandPage.diversityUI_bandColor.pos.y'),'Scale appears between density curve and Band color')
    ms('BandPage.diversityUI_strokeChoices_colored.SetSelected 0 false')
    check(ms('BandLeaf.bandAssignmentCount 1==0 and BandPage.diversityUI_strokeChoices_colored.SelectedIndices.Count==0'),'Deselecting the last model clears authored and visible selection')
    ms('BandPage.diversityUI_strokeChoices_colored.SetSelected 1 true')
    check(ms('BandLeaf.bandAssignmentCount 1==1 and (BandLeaf.sourceBandRows 2).count==2'),'Point row can be assigned independently')
    ms('BandPage.diversityUI_strokeChoices_colored.SetSelected 1 false')
    check(ms('BandLeaf.bandAssignmentCount 1==0 and (BandLeaf.sourceBandRows 2).count==1'),'Deselecting the last Point clears only this Band')
    ms('BandPage.diversityUI_strokeChoices_colored.SetSelected 0 true;BandPage.diversityUI_strokeChoices_colored.SetSelected 1 true')
    check(ms('BandLeaf.bandAssignmentCount 1==2'),'Multiple direct memberships remain supported')
    ms('BandPage.diversityUI_strokeChoices_colored.ClearSelected();BandPage.diversityUI_refreshGroups.pressed()')
    check(ms('BandLeaf.bandAssignmentCount 1==0 and BandPage.diversityUI_strokeChoices_colored.SelectedIndices.Count==0'),'Empty selection survives refresh without auto-filling')
    check(snapshot()==before and int(r.BandRoot.procEpoch)==epoch,'Manual deselection preserves published plants')
    check(list(r.BandLeaf.patternWidths)==widths and list(r.BandLeaf.strokeIDs)==ids and ms('BandLeaf.bandAssignmentCount 2==1'),'Clearing preserves Band widths, identities and neighboring assignment')
    r.BandRoot.procManualRevision+=1;r.BandRoot.evaluateProcedural()
    check(ms('BandRoot.groupSnapshotRows[1].count>0 and (for row in BandRoot.groupSnapshotRows[1] where row[2]!=2 collect row).count==0'),'Explicit Update removes the cleared Band while retaining neighboring Point output')
    ms('BandPage.diversityUI_strokeMode.state=1;BandPage.diversityUI_strokeMode.changed 1;BandPage.diversityUI_strokeChoices_colored.SetSelected 0 true')
    check(ms('BandLeaf.bandAssignmentCount 1==1'),'Assignment-group selection writes membership')
    ms('BandPage.diversityUI_strokeChoices_colored.SetSelected 0 false;BandPage.diversityUI_refreshGroups.pressed()')
    check(ms('BandLeaf.bandAssignmentCount 1==0 and BandPage.diversityUI_strokeChoices_colored.SelectedIndices.Count==0'),'Last assignment group clears and stays empty on refresh')
    # The linked-container view binds the same model but its own controls.
    ms('''global BandContainer=BandLeaf.containerCreate();BandLeaf.containerMode=1
select BandContainer;max modify mode
if not BandContainer.mainUI.controlsReady do BandContainer.mainUI.mountTimer.tick()
BandContainer.layoutUI.open=true;BandContainer.mainUI.bindSection BandContainer.layoutUI
BandPage=BandContainer.layoutUI
BandPage.diversityUI_selectedBandID=BandLeaf.strokeIDs[1];BandPage.diversityUI_showStroke();BandPage.layout()
''')
    check(ms('BandPage.diversityUI_strokeChoices_colored.SelectionMode==(dotNetClass "System.Windows.Forms.SelectionMode").MultiSimple and BandPage.diversityUI_strokeChoices_colored.SelectedIndices.Count==0'),'Container view preserves empty membership and toggle policy')
    check(ms('not BandPage.advancedToggle.checked and BandPage.diversityUI_bandScaleMode.visible and BandPage.diversityUI_strokeScaleMin.pos.y>BandPage.diversityUI_bandCurveEdit.pos.y and BandPage.diversityUI_bandScaleEdit.pos.y<BandPage.diversityUI_bandColor.pos.y'),'Container scale layout matches the main view')
    ms('BandPage.diversityUI_strokeMode.state=2;BandPage.diversityUI_strokeMode.changed 2;BandPage.diversityUI_strokeChoices_colored.SetSelected 1 true;BandPage.diversityUI_strokeChoices_colored.SetSelected 1 false')
    check(ms('BandLeaf.bandAssignmentCount 1==0 and BandPage.diversityUI_strokeChoices_colored.SelectedIndices.Count==0'),'Container Point deselection clears the same authored Band')
    ms('global BandCopy=BandRoot.copyLogicalLayer BandLeaf')
    check(ms('BandCopy.bandAssignmentCount 1==0 and BandCopy.bandAssignmentCount 2==1'),'Copy preserves empty and assigned Bands independently')
    scene=receipt.with_suffix('.max');r.saveMaxFile(str(scene),quiet=True);r.loadMaxFile(str(scene),quiet=True)
    ms('BandRoot=(getNodeByName "Band selection qualification").baseObject;BandLeaf=BandRoot.layerObjects[1]')
    check(ms('BandLeaf.bandAssignmentCount 1==0 and BandLeaf.bandAssignmentCount 2==1 and BandLeaf.strokeIDs.count==2'),'Save/reopen preserves an empty Band and its neighbor')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:save()
if not report['passed']:raise RuntimeError(report['error'])
