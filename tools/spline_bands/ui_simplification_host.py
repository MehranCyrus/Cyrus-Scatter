"""Scripted source conversion and Modify UI checks; no pointer/computer automation."""
from pathlib import Path
import hashlib,json,traceback,uuid
from pymxs import runtime as r

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-spline-ui-simplification-')
report={'checks':[],'launch':json.loads((OUT/'launch.json').read_text()),'fixture_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
receipt=OUT/('ui-simplification-'+uuid.uuid4().hex+'.json')
def save():receipt.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
def check(value,label):
    report['checks'].append({'passed':bool(value),'label':label});save()
    if not value:raise AssertionError(label)
def ms(code):return r.execute('(\n'+code+'\n)')
def snapshot():return str(r.cyrusEditFingerprint(r.SimpleRoot.groupSnapshotRows[0],'source-conversion'))

try:
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    check(hashlib.sha256(script.read_bytes()).hexdigest()==report['launch']['script_sha256'],'Current generated source matches isolated startup')
    check(ms('CyrusLayerEditor==undefined and CyrusOpenLayerEditor==undefined and CyrusFocusBand==undefined and CyrusShowSourceBands==undefined'),'Fresh session has no removed editor/navigation API')
    r.resetMaxFile(r.Name('noPrompt'))
    ms('''
global SimpleNode=AminScatterObject name:"Source conversion regression"
global SimpleRoot=SimpleNode.baseObject;SimpleRoot.updateMode=1;SimpleRoot.autoRender=false;SimpleRoot.newLayer()
global SimpleLeaf=SimpleRoot.selectedLayer()
global SimpleReceiver=plane width:500 length:500
global SimpleModel=box width:6 length:8 height:12 pos:[700,0,0]
global SimpleOther=sphere radius:4 pos:[750,0,0]
SimpleRoot.setLayerSurfaces SimpleLeaf #(SimpleReceiver)
SimpleLeaf.sources=#(SimpleModel,SimpleOther);SimpleLeaf.addPointSource();SimpleLeaf.amount=300
SimpleLeaf.sourceRadiiWU=#(7.,3.,5.);SimpleLeaf.sourceFollowScale=#(true,false,false)
SimpleLeaf.sourceWeights=#(.5,1.,.8);SimpleLeaf.sourceScales=#(1.2,1.,1.)
SimpleLeaf.setSourceLabel 1 "Retained row";SimpleLeaf.setSourceIDColor #{1} orange
SimpleLeaf.addStroke (rectangle width:100 length:100);SimpleLeaf.setStrokeSelection 1 2 #(SimpleModel)
SimpleLeaf.setSourceRadius #{1} true kind:4
SimpleRoot.evaluateProcedural()
global SimpleIDs=SimpleLeaf.sourceRowIDs as array
select SimpleNode;max modify mode
if not SimpleRoot.mainUI.controlsReady do SimpleRoot.mainUI.mountTimer.tick()
SimpleRoot.modelsUI.open=true;SimpleRoot.layoutUI.open=true
SimpleRoot.mainUI.bindSection SimpleRoot.modelsUI;SimpleRoot.mainUI.bindSection SimpleRoot.layoutUI
global SimpleModels=SimpleRoot.modelsUI,SimpleLayout=SimpleRoot.layoutUI
SimpleModels.sourceUI_plantList.selection=#{1};SimpleModels.sourceUI_focusedRow=1;SimpleModels.sourceUI_showSelectedColor();SimpleModels.layout()
''')
    retained=snapshot();epoch=int(r.SimpleRoot.procEpoch)
    check(ms('SimpleModels.sourceUI_makePoint.enabled and not SimpleModels.sourceUI_replacePoint.enabled'),'Model enables Make point and disables Pick object')
    check(ms('SimpleModels.sourceUI_makePoint.visible and SimpleModels.sourceUI_replacePoint.visible and SimpleModels.sourceUI_makePoint.pos.y==SimpleModels.sourceUI_replacePoint.pos.y'),'Both compact conversion buttons share one row')
    check(ms('SimpleModels.sourceUI_radiusModeDrop.items.count==2 and SimpleModels.sourceUI_radiusModeDrop.items[2]=="Auto" and SimpleModels.sourceUI_radiusModeDrop.selection==2'),'Supported geometry exposes Auto Radius')
    ms('SimpleModels.sourceUI_makePoint.pressed()')
    check(ms('SimpleLeaf.isPointSource 1 and SimpleLeaf.isEmptySource 1 and SimpleLeaf.sources.count==3 and SimpleLeaf.sources[1]==SimpleModel'),'Actual Make point handler retains the registered row without deleting the scene model')
    check(ms('SimpleLeaf.sourceRowIDs[1]==SimpleIDs[1] and SimpleLeaf.strokeSourceIDs[1]==SimpleIDs[1]'),'Conversion preserves source and direct Band identities')
    check(ms('(SimpleLeaf.sourceLabel 1)=="Retained row" and (SimpleLeaf.sourceIDColor 1)==orange and SimpleLeaf.sourceWeights[1]==.5 and SimpleLeaf.sourceScales[1]==1.2'),'Conversion preserves label, identification color, weight and scale')
    check(ms('SimpleModels.sourceUI_replacePoint.enabled and not SimpleModels.sourceUI_makePoint.enabled'),'Point enables Pick object and disables Make point')
    check(ms('SimpleModels.sourceUI_radiusModeDrop.items.count==1 and SimpleModels.sourceUI_radiusModeDrop.items[1]=="Manual" and not SimpleLeaf.sourceUsesAuto 1 and SimpleLeaf.sourceAutoRadius[1] and SimpleLeaf.sourceRadiiWU[1]==7.'),'Point has Manual radius while stored model Auto and Manual settings survive')
    check(ms('local denied=false;try(SimpleLeaf.setSourceRadius #{1} true kind:4)catch(denied=true);denied'),'Point cannot enable geometry-derived Auto Radius')
    check(snapshot()==retained and int(r.SimpleRoot.procEpoch)==epoch,'Conversion and selection retain the complete Manual publication')
    check(ms('not SimpleLeaf.replacePointSource 1 SimpleOther and SimpleLeaf.isPointSource 1'),'Picking an already registered different model is rejected')
    ms('SimpleModels.sourceUI_replacePoint.picked SimpleModel')
    check(ms('not SimpleLeaf.isPointSource 1 and not SimpleLeaf.isEmptySource 1 and SimpleLeaf.sourceUsesAuto 1'),'Pick object restores the same registered model and its Auto setting')
    check(snapshot()==retained and int(r.SimpleRoot.procEpoch)==epoch,'Restoring a model also preserves pending Manual publication')
    ms('SimpleLeaf.makePointSource 1;global SimpleContainer=SimpleLeaf.containerCreate();SimpleContainer.pos=SimpleModel.pos;SimpleContainer.width=100;SimpleContainer.length=100;SimpleContainer.collectEnabled=true;SimpleLeaf.containerConfigKey="";SimpleLeaf.containerScan=true;SimpleLeaf.containerRefresh()')
    check(ms('SimpleLeaf.sources.count==3 and SimpleLeaf.isPointSource 1 and not SimpleLeaf.containerRegister SimpleModel'),'Automatic source collection does not duplicate a model converted to Point')
    check(ms('SimpleLeaf.containerActive[1]'),'Converted Point remains eligible independently of rectangle membership')
    ms('SimpleLeaf.containerSetMode 1;SimpleLeaf.diversityMode=3;SimpleRoot.mainUI.bind();SimpleLayout.diversityUI_updatePattern();SimpleLayout.advancedToggle.checked=true;SimpleLayout.layout()')
    check(ms('SimpleLayout.diversityUI_strokeWidth.pos.y<SimpleLayout.diversityUI_bandAssignmentHelp.pos.y and SimpleLayout.diversityUI_refreshGroups.pos.y<SimpleLayout.diversityUI_bandStrength.pos.y'),'Band assignment controls precede density and follow width')
    check(ms('SimpleLayout.diversityUI_strokeScaleMin.pos.y==SimpleLayout.diversityUI_strokeScaleMax.pos.y and SimpleLayout.diversityUI_strokeScaleMin.pos.x<SimpleLayout.diversityUI_strokeScaleMax.pos.x'),'Advanced scale fields occupy one ordered row')
    check(ms('SimpleLayout.diversityUI_strokeScaleMin_caption.text=="Min:" and SimpleLayout.diversityUI_strokeScaleMax_caption.text=="Max:"'),'Band scale captions are compact Min and Max')
    check(ms('not isProperty SimpleModels #sourceUI_sourceBandButton and not isProperty SimpleRoot.managerUI #flow_layersUI_editButton and not isProperty SimpleContainer.containerUI #editLayer'),'Removed entry points are absent from actual rollouts')
    ms('SimpleLeaf.diversityMode=1;SimpleRoot.refreshAll()')
    check(ms('SimpleRoot.groupSnapshotRows[1].count>0 and SimpleLeaf.isPointSource 1'),'Explicit Update publishes a converted Point population')
    scene=OUT/'source-conversion.max';r.saveMaxFile(str(scene),quiet=True);r.resetMaxFile(r.Name('noPrompt'));r.loadMaxFile(str(scene),quiet=True)
    ms('SimpleNode=getNodeByName "Source conversion regression";SimpleRoot=SimpleNode.baseObject;SimpleLeaf=SimpleRoot.layerObjects[1]')
    check(ms('SimpleLeaf.isPointSource 1 and SimpleLeaf.sourceRowIDs[1]==SimpleIDs[1] and SimpleLeaf.strokeSourceIDs[1]==SimpleIDs[1] and isValidNode SimpleLeaf.sources[1]'),'Save/reopen preserves Point registration and Band assignment')
    ms('global SimpleCopy=SimpleRoot.copyLogicalLayer SimpleLeaf;SimpleCopy.replacePointSource 1 SimpleLeaf.sources[1]')
    check(ms('SimpleLeaf.isPointSource 1 and not SimpleCopy.isPointSource 1'),'Copied layer conversion does not modify the original layer')
    report['passed']=True
except Exception:report['passed']=False;report['error']=traceback.format_exc()
finally:save()
if not report['passed']:raise RuntimeError(report['error'])
