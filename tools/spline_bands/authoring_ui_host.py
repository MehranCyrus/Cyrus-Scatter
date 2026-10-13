"""Current Band authoring and captured UI owners in an owned matched Max host."""
from pathlib import Path
import hashlib
import json
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
receipt = OUT / ('spline-authoring-ui-' + uuid.uuid4().hex + '.json')
report = {'checks': [], 'fixture_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'launch': json.loads((OUT / 'launch.json').read_text(encoding='utf-8'))}

def save():
    receipt.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')

def check(value, label):
    report['checks'].append({'passed': bool(value), 'label': label}); save()
    if not value:
        raise AssertionError(label)

def ms(code):
    return r.execute('(\n' + code + '\n)')

def rows():
    return [[[[float(x) for x in v] for v in (row[0].row1,row[0].row2,row[0].row3,row[0].row4)],
             int(row[1]),str(row[2]),int(row[3]),list(map(float,row[4])),int(row[5]),bool(row[6]),int(row[7])]
            for row in r.UIRoot.groupSnapshotRows[0]]

try:
    r.resetMaxFile(r.Name('noPrompt'))
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256'] = hashlib.sha256(script.read_bytes()).hexdigest()
    r.fileIn(str(script))
    ms('''
global UINode=AminScatterObject name:"Spline authoring UI"
global UIRoot=UINode.baseObject
UIRoot.updateMode=1;UIRoot.autoRender=false;UIRoot.newLayer()
global UILeaf=UIRoot.selectedLayer()
global UIReceiver=plane width:500 length:500 widthsegs:1 lengthsegs:1
global UISources=#(box width:3 length:3 height:8 pos:[500,0,0],sphere radius:3 pos:[520,0,0])
global UIPaths=#(rectangle width:100 length:100 name:"Same Path",rectangle width:70 length:70 name:"Same Path" pos:[150,0,0])
UIRoot.setLayerSurfaces UILeaf #(UIReceiver)
UILeaf.sources=UISources;UILeaf.amount=2000;UILeaf.diversityMode=3
UILeaf.addStroke UIPaths[1];UILeaf.addStroke UIPaths[1];UILeaf.addStroke UIPaths[2]
UILeaf.patternWidths=#(20.,45.,30.)
UILeaf.setStrokeSelection 1 2 #(UISources[1]);UILeaf.setStrokeSelection 2 2 #(UISources[1]);UILeaf.setStrokeSelection 3 2 #(UISources[2])
UIRoot.evaluateProcedural()
global UIBandIDs=UILeaf.strokeIDs as array
''')
    check(ms('UILeaf.pathIDs.count==2 and UILeaf.pathIDs[1]!=UILeaf.pathIDs[2]'), 'Same-name Paths have independent identities')
    check(ms('(UILeaf.sourceBandLabel 1)=="2 Bands" and (UILeaf.sourceBandDetails 1).count>20'), 'Authored multiple membership has a compact label and qualified details')
    before = rows()
    ms('UILeaf.convertBandArrangement 2;UIRoot.evaluateProcedural()')
    check(list(map(float,r.UILeaf.strokeStarts)) == [0.,20.,0.] and list(map(float,r.UILeaf.strokeEnds)) == [20.,65.,30.], 'Consecutive-to-Independent preserves physical intervals per Path')
    independent = rows()
    ms('UILeaf.moveBand UIBandIDs[1] 3;UIRoot.evaluateProcedural()')
    check(rows() == independent, 'Independent reorder preserves full published rows and keyed choices')
    check(ms('(UILeaf.sourceBandRows 1).count==2 and UILeaf.strokeIDs[3]==UIBandIDs[1]'), 'Reorder keeps memberships attached to Band IDs')
    ms('UILeaf.moveBand UIBandIDs[1] 1;UILeaf.strokeStarts[2]=25.;UILeaf.strokeEnds[2]=70.')
    check(ms('not (UILeaf.consecutiveBandProposal())[1]'), 'A noncontiguous reverse conversion requires review')
    check(ms('local failed=false;try(UILeaf.convertBandArrangement 1)catch(failed=true);failed and UILeaf.bandArrangement==2'), 'Unconfirmed conversion preserves the authored arrangement')
    ms('UILeaf.convertBandArrangement 1 acceptChanges:true;UIRoot.evaluateProcedural()')
    check(rows() == before, 'Confirmed width-preserving conversion restores the original consecutive result')
    # Both Modify contexts bind the same authored model.
    ms('select UINode;max modify mode;if not UIRoot.mainUI.controlsReady do UIRoot.mainUI.mountTimer.tick();UIRoot.mainUI.selectLayerView UILeaf;UIRoot.layoutUI.open=true;UIRoot.mainUI.bindSection UIRoot.layoutUI')
    check(ms('UIRoot.layoutUI.diversityUI_pathsList.items.count==2'), 'Modify panel exposes both same-name Paths')
    ms('UIRoot.layoutUI.diversityUI_selectedPathID=UILeaf.strokePathIDs[findItem UILeaf.strokeIDs UIBandIDs[2]];UIRoot.layoutUI.diversityUI_selectedBandID=UIBandIDs[2];UIRoot.layoutUI.diversityUI_updatePattern()')
    check(ms('UIRoot.layoutUI.diversityUI_selectedBandID==UIBandIDs[2]'), 'Modify panel focuses a Band by ID')
    epoch = int(r.UIRoot.procEpoch); builds = int(r.UILeaf.procPreparedBuilds)
    key = str(r.UIRoot.procInputKey())
    ms('global UIPage=UIRoot.layoutUI')
    check(ms('UIPage!=undefined and UIPage.diversityUI_selectedBandID==UIBandIDs[2]'), 'Modify view retains its selected Band')
    check(ms('UIPage.diversityUI_strokesList_colored.Items.Count==2 and UIPage.diversityUI_strokeChoices_colored.Items.Count==2'), 'Band and assignment owner-drawn lists mirror their source controls')
    ms('UIPage.diversityUI_selectedPathID=UILeaf.strokePathIDs[findItem UILeaf.strokeIDs UIBandIDs[3]];UIPage.diversityUI_selectedBandID=UIBandIDs[3];UIPage.diversityUI_updatePattern();UIPage.diversityUI_selectedPathID=UILeaf.strokePathIDs[findItem UILeaf.strokeIDs UIBandIDs[1]];UIPage.diversityUI_selectedBandID=UIBandIDs[1];UIPage.diversityUI_updatePattern()')
    check(int(r.UIRoot.procEpoch) == epoch and int(r.UILeaf.procPreparedBuilds) == builds, 'Path/Band navigation performs zero placement solves')
    check(str(r.UIRoot.procInputKey()) == key, 'Path/Band navigation leaves the calculation input key unchanged')
    ms('UILeaf.strokeDisplayColors[1]=orange;UIPage.bind UILeaf;UIRoot.procEnsureDisplay()')
    check(int(r.UIRoot.procEpoch) == epoch and int(r.UILeaf.procPreparedBuilds) == builds, 'Band identification color is independent of placement preparation')
    check(str(r.UIRoot.procInputKey()) == key, 'Band color leaves the calculation input key unchanged')
    ms('global UIContainer=UILeaf.containerCreate();select UIContainer;max modify mode;if not UIContainer.mainUI.controlsReady do UIContainer.mainUI.mountTimer.tick();UIContainer.layoutUI.open=true;UIContainer.mainUI.bindSection UIContainer.layoutUI;UIContainer.layoutUI.diversityUI_selectedPathID=UILeaf.strokePathIDs[findItem UILeaf.strokeIDs UIBandIDs[2]];UIContainer.layoutUI.diversityUI_selectedBandID=UIBandIDs[2];UIContainer.layoutUI.diversityUI_updatePattern()')
    check(ms('UIContainer.layoutUI.diversityUI_obj==UILeaf and UIContainer.layoutUI.diversityUI_selectedBandID==UIBandIDs[2]'), 'Source Container Modify panel edits the same captured Band model')
    ms('UILeaf.containerMode=1;CyrusOpenFalloffGraph UILeaf undefined true bandID:UIBandIDs[2]')
    check(ms('CyrusFalloffGraph.bandTargetRow()==2'), 'Curve editor captures the requested stable Band')
    ms('UILeaf.moveBand UIBandIDs[2] 1')
    check(ms('CyrusFalloffGraph.bandTargetRow()==1'), 'Curve target resolves its identity after Band reorder')
    ms('global UISecond=UIRoot.copyLogicalLayer UILeaf;select UINode;max modify mode;if not UIRoot.mainUI.controlsReady do UIRoot.mainUI.mountTimer.tick();UIRoot.mainUI.selectLayerView UISecond')
    ms('local c=CyrusFalloffGraph.graph.curves[1],p=c.points[2];p.value.y=40.;c.points[2]=p;CyrusFalloffGraph.storeCurve()')
    check(ms('(CyrusFallUnpack UILeaf.strokeCurveSamples[1]).count==257 and UISecond.strokeCurveSamples[1]=="1,1"'), 'Switching layer views cannot redirect graph writes to the new owner')
    ms('UILeaf.removeStroke 1')
    check(ms('CyrusFalloffGraph.bandTargetRow()==0 and not CyrusFalloffGraph.applyButton.enabled'), 'Removing the captured Band invalidates the graph target')
    ms('destroyDialog CyrusFalloffGraph')
    check(ms('UISecond.strokeCurveSamples[1]=="1,1"'), 'Closing an invalidated graph performs no replacement-owner write')
    ms('local saved=UILeaf.strokeStrengths as array;deleteItem UILeaf.strokeStrengths 1;global UIBroken=false;try(UILeaf.syncStrokes())catch(UIBroken=true);UILeaf.strokeStrengths=saved')
    check(ms('UIBroken'), 'Incomplete current-schema Band records fail instead of being silently repaired')
    for statement in ['UISecond.convertBandArrangement 2','UISecond.pathJoins[1]=2',
                      'UISecond.strokeStrengths[1]=.25','UISecond.strokeCurveEnabled[1]=true',
                      'UISecond.strokeCurveSamples[1]="0,.5,1"','UISecond.setSourceLabel 1 "Stable presentation"',
                      'UISecond.setSourceIDColor #{1} (color 0 255 255)']:
        report['stage']=statement; save(); ms(statement)
    saved_ids = list(map(int,r.UISecond.strokeIDs))
    saved_colors = [list(map(float,(c.r,c.g,c.b))) for c in r.UISecond.strokeDisplayColors]
    saved_ranges = (list(map(float,r.UISecond.strokeStarts)),list(map(float,r.UISecond.strokeEnds)))
    scene = receipt.with_suffix('.max')
    report['stage']='saveMaxFile'; save(); r.saveMaxFile(str(scene),quiet=True)
    report['stage']='loadMaxFile'; save(); r.loadMaxFile(str(scene),quiet=True)
    ms('UIRoot=(getNodeByName "Spline authoring UI").baseObject;UISecond=UIRoot.layerObjects[2]')
    check(list(map(int,r.UISecond.strokeIDs)) == saved_ids and int(r.UISecond.bandArrangement)==2 and int(r.UISecond.pathJoins[0])==2, 'Save/reopen preserves authored mode, corners and stable Band IDs')
    check((list(map(float,r.UISecond.strokeStarts)),list(map(float,r.UISecond.strokeEnds))) == saved_ranges and [list(map(float,(c.r,c.g,c.b))) for c in r.UISecond.strokeDisplayColors] == saved_colors, 'Save/reopen preserves physical ranges and Band colors')
    check(ms('UISecond.strokeStrengths[1]==.25 and UISecond.strokeCurveEnabled[1] and UISecond.strokeCurveSamples[1]=="0,.5,1" and (UISecond.sourceLabel 1)=="Stable presentation" and (UISecond.sourceIDColor 1)==(color 0 255 255)'), 'Current identity-keyed source presentation and Band density survive save/reopen')
    check(ms('local failed=false;try(UISecond.setSourceIDColor #{1} undefined)catch(failed=true);failed and (UISecond.sourceIDColor 1)==(color 0 255 255)'), 'Invalid source colors fail before changing saved presentation')
    check(ms('local orphan=createInstance AminScatterObject;orphan.addStroke (rectangle width:5 length:5);local failed=false;try(CyrusOpenFalloffGraph orphan undefined true bandID:orphan.strokeIDs[1])catch(failed=true);failed and CyrusFalloffGraph==undefined'), 'A layer without a scene controller cannot leave a partial graph dialog')
    ms('CyrusOpenFalloffGraph UISecond undefined true bandID:UISecond.strokeIDs[1]')
    check(ms('CyrusFalloffGraph.ownerRoot==UIRoot and CyrusFalloffGraph.bandTargetRow()==1'), 'A reopened Band resolves its saved controller before transient preview binding')
    ms('resetMaxFile #noPrompt')
    check(ms('CyrusFalloffGraph==undefined or not CyrusFalloffGraph.storeCurve()'), 'Scene reset cannot write an old graph into a new owner')
    ms('if CyrusFalloffGraph!=undefined do destroyDialog CyrusFalloffGraph')
    report['passed'] = True
except Exception:
    report['passed'] = False; report['error'] = traceback.format_exc()
finally:
    save()
if not report['passed']:
    raise RuntimeError(report['error'])
