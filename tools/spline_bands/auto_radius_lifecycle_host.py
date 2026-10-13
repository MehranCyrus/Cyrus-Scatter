"""Physical units, source animation and owner-bound Auto Radius controls."""
from pathlib import Path
import hashlib
import json
import math
import traceback
import uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent!=ROOT/'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
report={'checks':[], 'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'launch':json.loads((OUT/'launch.json').read_text())}
receipt=OUT/('auto-lifecycle-'+uuid.uuid4().hex+'.json')
old_units=(r.units.SystemType,r.units.SystemScale)
def save():receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(ok,label):
    report['checks'].append({'passed':bool(ok),'label':label});save()
    if not ok:raise AssertionError(label)
def ms(code):return r.execute('(\n'+code+'\n)')
def settle():ms('local end=timeStamp()+500;while timeStamp()<end do (windows.processPostedMessages();sleep .01);completeRedraw()')
def radii():return [[float(x) for x in p] for p in r.RLifeRoot.procPublishedRadii[0]]
def physical_radii():
    mm=float(r.units.decodeValue('1mm'))
    return [[v/mm for v in p] for p in radii()]
def current():ms('RLifeNode=getNodeByName "Radius lifecycle";RLifeRoot=RLifeNode.baseObject;RLifeLeaf=RLifeRoot.layerObjects[1];RLifeModel=RLifeLeaf.sources[1]')
def solve():
    r.RLifeRoot.procManualRevision+=1;r.RLifeRoot.evaluateProcedural()
def same_pairs(a,b,factor=1):
    return len(a)==len(b) and all(math.isclose(x,y*factor,rel_tol=2e-5,abs_tol=.001) for p,q in zip(a,b) for x,y in zip(p,q))
def fresh():ms('''
global RLifeModel=box width:(units.decodeValue "3mm") length:(units.decodeValue "4mm") height:(units.decodeValue "12mm")
global RLifeNode=AminScatterObject name:"Radius lifecycle"
global RLifeRoot=RLifeNode.baseObject
RLifeRoot.updateMode=1;RLifeRoot.autoRender=false;RLifeRoot.newLayer()
global RLifeLeaf=RLifeRoot.selectedLayer()
RLifeRoot.setLayerSurfaces RLifeLeaf #(plane width:(units.decodeValue "1000mm") length:(units.decodeValue "1000mm") widthsegs:1 lengthsegs:1)
RLifeLeaf.sources=#(RLifeModel);RLifeLeaf.amount=40
RLifeLeaf.advancedAxes=false;RLifeLeaf.scaleMinimum=2.;RLifeLeaf.scaleMaximum=2.;RLifeLeaf.sourceScales=#(3.);RLifeLeaf.tiltDegrees=0.
RLifeLeaf.sourceZOffsetsWU=#(units.decodeValue "40mm");RLifeLeaf.sourceRadiiWU=#(units.decodeValue "7mm");RLifeLeaf.sourceFollowScale=#(true)
RLifeLeaf.setSourceRadius #{1} true kind:4
RLifeRoot.setGroupDisplay 4;RLifeRoot.evaluateProcedural()
''')

try:
    r.resetMaxFile(r.Name('noPrompt'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256']=hashlib.sha256(script.read_bytes()).hexdigest();r.fileIn(str(script))
    expected=[[15.,6*math.sqrt(150.25)]]*40
    for unit in ('Millimeters','Centimeters','Meters','Inches'):
        r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name(unit);r.units.SystemScale=1.;fresh()
        report.setdefault('unit_pairs',{})[unit]=physical_radii()[:1]
        check(same_pairs(physical_radii(),expected),unit+': final source/layer scales and world-Z offset produce the expected physical pair')
    r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name('Millimeters');fresh()
    original=physical_radii()
    scene=OUT/('auto-units-'+uuid.uuid4().hex+'.max');r.saveMaxFile(str(scene),quiet=True)
    for unit in ('Centimeters','Meters','Inches'):
        r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name(unit)
        r.loadMaxFile(str(scene),quiet=True,useFileUnits=False);current();solve()
        mm=float(r.units.decodeValue('1mm'))
        check(same_pairs(physical_radii(),original) and math.isclose(float(r.RLifeLeaf.sourceRadiiWU[0])/mm,7.,rel_tol=1e-5) and
              math.isclose(float(r.RLifeLeaf.sourceZOffsetsWU[0])/mm,40.,rel_tol=1e-5),
              unit+': load conversion preserves Auto bounds and typed saved Manual radius/Z offset exactly once')
    r.rescaleWorldUnits(2.);solve()
    check(same_pairs(physical_radii(),original,2),'Explicit world rescale doubles Auto dimensions and saved physical distances')
    r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name('Centimeters')
    sentinel=r.box(name='Unrelated merge sentinel',width=7.,length=9.,height=11.)
    check(r.mergeMAXFile(str(scene),r.Name('autoRenameDups'),r.Name('renameMtlDups'),quiet=True),'Current-schema Auto scene merges successfully')
    current();solve()
    check(same_pairs(physical_radii(),original) and float(sentinel.width)==7. and float(sentinel.length)==9.,
          'Merge preserves physical Auto radius and leaves pre-existing geometry unchanged')
    ms('global RLifeCopy=RLifeRoot.copyLogicalLayer RLifeLeaf')
    check(bool(r.RLifeCopy.sourceUsesAuto(1)) and float(r.RLifeCopy.sourceRadius(1))==float(r.RLifeLeaf.sourceRadius(1)) and bool(r.RLifeCopy.sourceFollows(1)),
          'Layer copy preserves Auto and independently saved Manual settings')
    ms('RLifeCopy.setSourceRadius #{1} false kind:4;RLifeCopy.setSourceRadius #{1} 2.')
    check(bool(r.RLifeLeaf.sourceUsesAuto(1)) and not r.RLifeCopy.sourceUsesAuto(1) and float(r.RLifeLeaf.sourceRadius(1))!=2.,
          'Editing copied radius settings cannot change the original owner')

    r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name('Millimeters');fresh()
    ms('select RLifeNode;max modify mode;if not RLifeRoot.mainUI.controlsReady do RLifeRoot.mainUI.mountTimer.tick();RLifeRoot.mainUI.selectLayerView RLifeLeaf;RLifeRoot.modelsUI.open=true;RLifeRoot.mainUI.bindSection RLifeRoot.modelsUI')
    ui=r.RLifeRoot.modelsUI;ui.sourceUI_plantList.selection=ms('#{1}');ui.sourceUI_showSelectedColor()
    check(int(ui.sourceUI_radiusModeDrop.selection)==2 and not ui.sourceUI_radiusSourceSpin.enabled and not ui.sourceUI_followRadiusCheck.enabled,
          'Model controls show Auto and disable Manual radius/Follow Scale')
    epoch=int(r.RLifeRoot.procEpoch);saved=radii()
    r.RLifeLeaf.setSourceRadius(ms('#{1}'),False,kind=4);ui.sourceUI_showSelectedColor()
    check(not r.RLifeLeaf.sourceUsesAuto(1) and bool(ui.sourceUI_followRadiusCheck.enabled) and bool(ui.sourceUI_followRadiusCheck.checked) and
          float(ui.sourceUI_radiusSourceSpin.value)==7. and int(r.RLifeRoot.procEpoch)==epoch and radii()==saved,
          'Bound Manual controls restore saved values while Manual publication stays pending')
    r.RLifeLeaf.setSourceRadius(ms('#{1}'),True,kind=4);ui.sourceUI_showSelectedColor();solve()
    point_index=int(r.RLifeLeaf.addPointSource());ui.sourceUI_updateList();ui.sourceUI_plantList.selection=r.BitArray(point_index);ui.sourceUI_showSelectedColor()
    check(len(ui.sourceUI_radiusModeDrop.items)==1 and 'unavailable' in str(ui.sourceUI_radiusModeHelp.text).lower(),
          'Point placeholder exposes Manual only with an explicit Auto capability explanation')
    # Required source animation uses the normal dependency/idle path, not an
    # explicit call to the solver as a substitute for Live behavior.
    r.resetMaxFile(r.Name('noPrompt'));fresh()
    ms('with animate on (at time 0f RLifeModel.height=12.;at time 20f RLifeModel.height=24.);sliderTime=0f')
    solve();settle();epoch=int(r.RLifeRoot.procEpoch);saved=radii()
    r.sliderTime=10;settle()
    check(int(r.RLifeRoot.procEpoch)==epoch and radii()==saved,'Manual relevant source animation retains the published radius pair')
    r.RLifeRoot.refreshAll();settle()
    check(not same_pairs(radii(),saved),'Explicit Update consumes the relevant source animation')
    r.RLifeRoot.updateMode=2;settle();epoch=int(r.RLifeRoot.procEpoch);saved=radii()
    r.sliderTime=20;settle()
    check(int(r.RLifeRoot.procEpoch)>epoch and not same_pairs(radii(),saved),
          'Live relevant source animation republishes bounds/radii through the existing idle path')
    ms('global RLifeOther=box();with animate on (at time 0f RLifeOther.pos=[0,0,0];at time 20f RLifeOther.pos=[100,0,0])')
    # Freeze the relevant source at this time, leaving only unrelated animation.
    ms('deleteKeys RLifeModel.height.controller #allKeys;RLifeModel.height=24.;sliderTime=0f')
    r.RLifeRoot.refreshAll();settle();epoch=int(r.RLifeRoot.procEpoch);saved=radii();stats=list(r.cyrusSourceGeometryStats())
    r.sliderTime=10;settle()
    check(int(r.RLifeRoot.procEpoch)==epoch and radii()==saved and int(r.cyrusSourceGeometryStats()[1])==int(stats[1]),
          'Unrelated animation causes no static placement solve or source-bounds extraction')
    report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:
    r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType,r.units.SystemScale=old_units;save()
if not report['passed']:raise RuntimeError(report['error'])
