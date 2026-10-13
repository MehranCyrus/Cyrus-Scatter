"""Actual current Band field integration in an explicitly owned Max host."""
from pathlib import Path
import hashlib
import json
import traceback
import uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
receipt=OUT/('field-ui-'+uuid.uuid4().hex+'.json')
report={'checks':[],'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'launch':json.loads((OUT/'launch.json').read_text())}
def save():receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(ok,label):
    report['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def ms(code):return r.execute('(\n'+code+'\n)')
def fingerprint():return str(r.cyrusEditFingerprint(r.FUIRoot.groupSnapshotRows[0],'field-ui'))
def radii():return [tuple(map(float,pair)) for pair in r.FUIRoot.procPublishedRadii[0]]
def refresh():r.FUIRoot.refreshDisplay()
def settle():ms('for i=1 to 4 do (windows.processPostedMessages();completeRedraw();sleep .05)')
def metadata():return str(r.FUIRoot.procPublishedMetadata[0][4])
def field_values():return [float(row[4]) for row in r.cyrusFieldPreviewInfo(r.FUILeaf.procFieldCache,1000)[14]]

try:
    r.CyrusStopBrush();r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms';report['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest();r.fileIn(str(script))
    ms('''
global FUINode=AminScatterObject name:"Field UI fixture"
global FUIRoot=FUINode.baseObject
FUIRoot.updateMode=1;FUIRoot.autoRender=false;FUIRoot.newLayer()
global FUILeaf=FUIRoot.selectedLayer()
global FUIReceivers=#(plane width:200 length:200 widthsegs:1 lengthsegs:1,plane width:200 length:200 widthsegs:1 lengthsegs:1 pos:[0,0,15])
global FUIModel=box width:2 length:3 height:4 pos:[300,0,0]
global FUIPath=rectangle width:100 length:100
global FUIUnrelated=point pos:[500,0,0]
FUIRoot.setLayerSurfaces FUILeaf FUIReceivers
FUILeaf.sources=#(FUIModel);FUILeaf.sourceRadiiWU=#(2.);FUILeaf.amount=1000;FUILeaf.diversityMode=3
FUILeaf.procSelfEnabled=false;FUILeaf.procLayerSelfEnabled=false
FUILeaf.addStroke FUIPath;FUILeaf.addStroke FUIPath
FUILeaf.bandArrangement=2;FUILeaf.strokeStarts=#(0.,0.);FUILeaf.strokeEnds=#(10.,40.);FUILeaf.strokeStrengths=#(.6,.3)
FUILeaf.setStrokeSelection 1 2 #(FUIModel);FUILeaf.setStrokeSelection 2 2 #(FUIModel)
FUIRoot.setGroupDisplay 4;FUIRoot.evaluateProcedural()
global FUIIDs=FUILeaf.strokeIDs as array
global FUIMain=FUILeaf.cachedPoints
''')
    before=fingerprint();before_radii=radii();epoch=int(r.FUIRoot.procEpoch);builds=int(r.FUILeaf.procPreparedBuilds)
    published=metadata();key=str(r.FUIRoot.procInputKey())
    check(ms('FUILeaf.procFieldCache==undefined and FUILeaf.inspectionCache==undefined') and len(r.FUIRoot.procPublishedMetadata[0])==5 and bool(published),
          'Hidden defaults publish a frozen field revision without a display cache')
    check(ms('local a=cyrusFieldDependencyKey (FUIReceivers+#(FUIPath));a==(cyrusFieldDependencyKey (FUIReceivers+#(FUIPath)))'),
          'Unchanged field dependency queries return the same revision')
    ms('FUILeaf.fieldFalloff=true;FUILeaf.fieldBoundaries=true;FUILeaf.fieldSamples=1000');refresh()
    check(ms('FUILeaf.procFieldCache!=undefined and FUILeaf.inspectionCache==FUILeaf.procFieldCache and FUILeaf.cachedPoints==FUIMain'),
          'Field toggles reuse main geometry and use one inspection slot')
    check(str(r.FUIRoot.procInputKey())==key and fingerprint()==before and radii()==before_radii and int(r.FUIRoot.procEpoch)==epoch and int(r.FUILeaf.procPreparedBuilds)==builds,
          'Display toggles change no input recipe, solve, placement or published radius')
    check('Field from last Update' in str(r.FUILeaf.fieldPreviewStatus()), 'Published field has the completed-epoch label')
    ms('global FUIFieldCache=FUILeaf.procFieldCache;FUILeaf.sourceShowRadius=#(true)');refresh()
    check(ms('FUILeaf.procFieldCache==FUIFieldCache and FUILeaf.inspectionCache!=FUIFieldCache and FUILeaf.cachedPoints==FUIMain and FUILeaf.radiusPreview.count>0'),
          'Radius rings and field feedback bundle without rebuilding either field or plant geometry')
    check(str(r.FUIRoot.procInputKey())==key, 'Radius visibility is absent from the placement input key')
    ms('FUIRoot.updateMode=2;FUILeaf.sourceShowRadius=#(false)');refresh()
    check(int(r.FUIRoot.procEpoch)==epoch and fingerprint()==before and radii()==before_radii,
          'Live radius visibility performs no placement solve and preserves published values')
    ms('FUIRoot.updateMode=1;FUILeaf.sourceShowRadius=#(true)');refresh()
    ms('global FUIInspection=FUILeaf.inspectionCache');refresh();settle()
    check(ms('FUILeaf.procFieldCache==FUIFieldCache and FUILeaf.inspectionCache==FUIInspection and FUILeaf.cachedPoints==FUIMain'),
          'Unchanged refresh keeps every immutable display cache')
    ms('FUILeaf.fieldBandID=FUIIDs[2]');refresh()
    check(max(field_values())<=.30001 and any(v>.29 for v in field_values()) and ms('FUILeaf.cachedPoints==FUIMain'),
          'Selecting another Band displays its contribution and reuses plant geometry')
    ms('FUILeaf.fieldCombined=true');refresh();old_values=field_values()
    check(any(v>.89 for v in old_values) and 'Combined density' in str(r.FUILeaf.fieldPreviewStatus()),
          'Combined view displays the sum, with an explicit label')
    ms('global FUIFieldCache=FUILeaf.procFieldCache;FUILeaf.strokeStrengths[1]=.1');refresh()
    check(ms('FUILeaf.procFieldCache!=FUIFieldCache and FUILeaf.cachedPoints==FUIMain') and field_values()!=old_values,
          'Pending strength changes rebuild only field feedback')
    check(fingerprint()==before and radii()==before_radii and metadata()==published and int(r.FUIRoot.procEpoch)==epoch,
          'Manual field edits retain published plants, radii and field metadata')
    check('Pending field; plants from last Update' in str(r.FUILeaf.fieldPreviewStatus()), 'Pending field and published plants are explicitly distinguished')
    ms('global FUIFieldCache=FUILeaf.procFieldCache;global FUIInspection=FUILeaf.inspectionCache;FUIUnrelated.pos.x+=12');refresh()
    check(ms('FUILeaf.procFieldCache==FUIFieldCache and FUILeaf.inspectionCache==FUIInspection'),
          'An unrelated object transform leaves field and inspection geometry untouched')
    ms('FUIModel.height=20');refresh()
    check(ms('FUILeaf.procFieldCache==FUIFieldCache and FUILeaf.cachedPoints==FUIMain') and radii()==before_radii,
          'Pending source geometry does not enter the field cache or frozen radii')
    ms('FUILeaf.fieldSamples=20001');refresh()
    check(ms('FUILeaf.procFieldCache==FUIFieldCache and FUILeaf.inspectionCache==FUIInspection and FUILeaf.cachedPoints==FUIMain')
          and bool(str(r.FUILeaf.previewError)) and fingerprint()==before,
          'Invalid field budget preserves the complete preceding display and population')
    ms('FUILeaf.fieldSamples=1000');refresh()
    check(not str(r.FUILeaf.previewError) and ms('FUILeaf.procFieldCache==FUIFieldCache'),
          'Restoring the last valid display settings clears the display error without a solve')
    ms('FUIReceivers[2].pos.z=22');refresh()
    check(ms('FUILeaf.procFieldCache!=FUIFieldCache') and any(abs(float(row[0].z)-22)<1e-5 for row in r.cyrusFieldPreviewInfo(r.FUILeaf.procFieldCache,1000)[14]),
          'Manual receiver motion updates field anchors through synchronous dependency revisions')
    check(fingerprint()==before and metadata()==published and radii()==before_radii,
          'Receiver preview motion leaves the previous publication unchanged')
    ms('FUIRoot.evaluateProcedural()');refresh()
    check(int(r.FUIRoot.procEpoch)>epoch and metadata()!=published and 'Field from last Update' in str(r.FUILeaf.fieldPreviewStatus()),
          'Explicit Update publishes the successor field metadata with placements')
    # Bind the actual generated Modify panel; setters and programmatic controls
    # are witnesses here, not a substitute for later physical pointer/DPI tests.
    ms('select FUINode;max modify mode;if not FUIRoot.mainUI.controlsReady do FUIRoot.mainUI.mountTimer.tick();FUIRoot.mainUI.selectLayerView FUILeaf;FUIRoot.layoutUI.open=true;FUIRoot.mainUI.bindSection FUIRoot.layoutUI')
    check(ms('FUIRoot.layoutUI.diversityUI_fieldFalloffCheck.checked and FUIRoot.layoutUI.diversityUI_fieldBoundaryCheck.checked and FUIRoot.layoutUI.diversityUI_fieldView.selection==2'),
          'Generated Modify controls bind the shared display model')
    check('before masks/spacing/cleanup' in str(r.FUIRoot.layoutUI.diversityUI_fieldLegend.text),
          'Actual field legend identifies its stage and 0–100 percent colors')
    ms('FUIRoot.layoutUI.diversityUI_changeFieldDisplay #fieldBoundaries false')
    check(not bool(r.FUILeaf.fieldBoundaries) and int(r.cyrusFieldPreviewInfo(r.FUILeaf.procFieldCache,0)[3])==0,
          'The actual control handler independently disables boundary display')
    ms('global FUIPage=FUIRoot.layoutUI;FUIPage.diversityUI_selectedPathID=FUILeaf.strokePathIDs[1];FUIPage.diversityUI_selectedBandID=FUIIDs[1];FUIPage.diversityUI_updatePattern()')
    check(ms('FUIPage!=undefined and FUIPage.diversityUI_selectedBandID==FUIIDs[1]'), 'Modify view selects the stable Band identity')
    ms('FUIRoot.layoutUI.diversityUI_selectedPathID=FUILeaf.strokePathIDs[2];FUIRoot.layoutUI.diversityUI_selectedBandID=FUIIDs[2];FUIRoot.layoutUI.diversityUI_updatePattern();FUIPage.bind FUILeaf')
    check(ms('FUILeaf.fieldBandID==FUIIDs[2] and FUIPage.diversityUI_selectedBandID==FUIIDs[2]'),
          'Rebinding Modify preserves its preview selection')
    ms('FUILeaf.fieldCombined=false;FUILeaf.fieldBoundaries=true;FUILeaf.fieldSamples=750');refresh()
    scene=OUT/('field-settings-'+uuid.uuid4().hex+'.max');r.saveMaxFile(str(scene),quiet=True)
    r.resetMaxFile(r.Name('noPrompt'));r.loadMaxFile(str(scene),quiet=True)
    ms('FUINode=getNodeByName "Field UI fixture";FUIRoot=FUINode.baseObject;FUILeaf=FUIRoot.layerObjects[1];FUIRoot.evaluateProcedural();FUIRoot.refreshDisplay()')
    check(bool(r.FUILeaf.fieldFalloff) and bool(r.FUILeaf.fieldBoundaries) and not bool(r.FUILeaf.fieldCombined) and int(r.FUILeaf.fieldSamples)==750,
          'Current-schema save/reopen preserves display choices and reconstructs transient caches')
    check(r.FUILeaf.procFieldCache!=r.undefined and 'Field from last Update' in str(r.FUILeaf.fieldPreviewStatus()),
          'Reopened display is bound to its newly completed publication')
    ms('global FUICopy=FUIRoot.copyLogicalLayer FUILeaf')
    check(bool(r.FUICopy.fieldFalloff) and bool(r.FUICopy.fieldBoundaries) and int(r.FUICopy.fieldSamples)==750
          and int(r.FUICopy.fieldBandID)==int(r.FUILeaf.fieldBandID), 'Layer copy retains the display settings and local Band selection')
    ms('FUICopy.fieldSamples=250;FUICopy.fieldFalloff=false')
    check(int(r.FUILeaf.fieldSamples)==750 and bool(r.FUILeaf.fieldFalloff), 'Copied display settings remain independently owned')
    # Restore one saved owner before examining real timeline notifications.
    r.resetMaxFile(r.Name('noPrompt'));r.loadMaxFile(str(scene),quiet=True)
    ms('FUINode=getNodeByName "Field UI fixture";FUIRoot=FUINode.baseObject;FUILeaf=FUIRoot.layerObjects[1];FUIPath=FUILeaf.patternPaths[1];FUIReceivers=FUILeaf.validSurfaces();FUIModel=FUILeaf.sources[1]')
    ms('with animate on (at time 0f FUIPath.width=100.;at time 20f FUIPath.width=150.);sliderTime=0f;FUIRoot.evaluateProcedural();FUIRoot.refreshDisplay()');settle()
    before=fingerprint();epoch=int(r.FUIRoot.procEpoch);published=metadata()
    ms('global FUIFieldCache=FUILeaf.procFieldCache;global FUIMain=FUILeaf.cachedPoints')
    r.sliderTime=10;settle()
    check(ms('FUILeaf.procFieldCache!=FUIFieldCache and FUILeaf.cachedPoints==FUIMain') and fingerprint()==before
          and int(r.FUIRoot.procEpoch)==epoch and metadata()==published,
          'Manual relevant Path animation refreshes only field feedback through normal timeline notifications')
    check('Pending field; plants from last Update' in str(r.FUILeaf.fieldPreviewStatus()), 'Animated pending field retains its explicit Manual label')
    r.FUIRoot.updateMode=2;settle();epoch=int(r.FUIRoot.procEpoch)
    r.sliderTime=20;settle()
    check(int(r.FUIRoot.procEpoch)>epoch and 'Field from last Update' in str(r.FUILeaf.fieldPreviewStatus()),
          'Live Path animation republishes placements and field metadata together')
    ms('deleteKeys FUIPath.width.controller #allKeys;FUIPath.width=150.;global FUIUnrelated=point();with animate on (at time 0f FUIUnrelated.pos=[0,0,0];at time 20f FUIUnrelated.pos=[100,0,0]);sliderTime=0f;FUIRoot.refreshAll()');settle()
    before=fingerprint();epoch=int(r.FUIRoot.procEpoch);builds=int(r.FUILeaf.procSplineBuilds)
    ms('global FUIFieldCache=FUILeaf.procFieldCache;global FUIMain=FUILeaf.cachedPoints');r.sliderTime=10;settle()
    check(ms('FUILeaf.procFieldCache==FUIFieldCache and FUILeaf.cachedPoints==FUIMain') and fingerprint()==before
          and int(r.FUIRoot.procEpoch)==epoch and int(r.FUILeaf.procSplineBuilds)==builds,
          'Unrelated animation reuses both field and plants without a solve or field preparation')
    ms('FUIRoot.updateMode=1;FUIModel.height+=4;FUIRoot.setGroupDisplay 3');settle()
    check(ms('FUILeaf.cachedPoints==FUIMain and FUILeaf.procFieldCache==FUIFieldCache') and 'Source geometry is pending' in str(r.FUILeaf.previewError),
          'A pending source cannot enter an uncached Mesh representation alongside published radii')
    ms('FUIRoot.setGroupDisplay 4');settle()
    check(not str(r.FUILeaf.previewError) and ms('FUILeaf.cachedPoints==FUIMain'), 'Returning to the cached representation recovers without consuming pending source edits')
    # A missing selection hides only that selected preview; it is not guessed.
    ms('FUILeaf.fieldBandID=0;FUIRoot.refreshDisplay()')
    check(r.FUILeaf.procFieldCache==r.undefined and 'Select a Band' in str(r.FUILeaf.fieldPreviewStatus()),
          'No selected Band explicitly hides its contribution while preserving the publication')
    ms('FUILeaf.fieldCombined=true;FUIRoot.refreshDisplay()')
    check(r.FUILeaf.procFieldCache!=r.undefined and fingerprint()==before, 'Combined field remains available without an individual selection')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:save()
if not report['passed']:raise RuntimeError(report['error'])
