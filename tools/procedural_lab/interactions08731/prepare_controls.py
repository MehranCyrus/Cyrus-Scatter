"""Exercise generated one-step preparation and automatic settings in owned Max."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={'checks':[]}
def save():(O/'prepare-controls.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
def check(name,value):
    assert value,name;report['checks'].append(name);save()
def control(name):return r.getProperty(r.WFSection,r.Name('interactionsUI_'+name))
def event(name,method,value=None):
    text='WFSection.interactionsUI_'+name+'.'+method
    r.execute(text+('()' if value is None else ' '+str(value).lower()))
def bind(index):
    r.WFRoot.mainUI.selectLayerView(r.WFRoot.layerObjects[index-1]);r.WFRoot.mainUI.bindSection(r.WFSection)
try:
    root=r.WFRoot;grass=r.WFGrass;collider=r.WFCollider;node=grass.validSources()[0];root.updateMode=1
    check('Current script loads with native capability 6',int(r.cyrusInteractionVersion())==6 and str(root.uiVersion())=='0.87.3.1')
    before_epoch=int(root.procEpoch);start=time.perf_counter();event('prepareButton','pressed');report['prepare_seconds']=time.perf_counter()-start
    check('Actual Prepare button creates a source definition',len(grass.interactionDefinitions)==1 and len(grass.interactionSourceIDs)==1 and not str(root.interactionError))
    check('Prepared state has no second acceptance step',grass.interactionsReady(grass.validSources()) and bool(grass.interactionReact) and not r.isProperty(r.WFSection,r.Name('interactionsUI_acceptButton')))
    check('Preparation does not rebuild placements',int(root.procEpoch)==before_epoch and int(grass.generatedCount)==50)
    report['definition_keys']=list(json.loads(str(grass.interactionDefinitions[0])))
    source_id=str(grass.interactionSourceIDs[0]);event('prepareButton','pressed')
    check('Reprepare retains one stable source binding',len(grass.interactionDefinitions)==1 and str(grass.interactionSourceIDs[0])==source_id and not str(root.interactionError))
    event('guideReviewButton','changed',True)
    check('Optional review appears at original source',len(grass.interactionGuides)>0 and float(r.distance(grass.interactionGuides[-1].pos,node.pos))<1e-4)
    event('guideReviewButton','changed',False);check('Optional review toggles off',len(grass.interactionGuides)==0)
    saved=str(grass.interactionDefinitions[0]);counts=[]
    for percent in [1.,25.,100.]:
        event('foliageSpin','changed',percent);data=json.loads(str(r.cyrusInteractionSourceInfo(grass.interactionSourceCache[0][1])));counts.append(data['delivered_preview_triangles'])
        check(f'{percent}% updates without inference',abs(float(grass.interactionFoliage)-percent/100)<1e-6 and str(grass.interactionDefinitions[0])==saved and not str(root.interactionError) and data.get('guide_inference_reused',False))
    report['preview_triangles']=counts;check('Full blade preview restores all source triangles',counts[0]<counts[1]<counts[2] and counts[2]==27501)
    event('minimumSpin','changed',1.0)
    data=json.loads(str(grass.interactionDefinitions[0]));report['minimum_definition_settings']=data.get('settings')
    check('Minimum stem automatically rebuilds prepared definition',abs(float(grass.interactionMinimumM)-.01)<1e-6 and str(grass.interactionDefinitions[0])!=saved and grass.interactionsReady(grass.validSources()) and not str(root.interactionError))
    current=str(grass.interactionDefinitions[0]);event('connectionSpin','changed',10.0)
    check('Branch connection automatically rebuilds prepared definition',abs(float(grass.interactionConnectionM)-.1)<1e-6 and str(grass.interactionDefinitions[0])!=current and not str(root.interactionError))
    for name,value in [('verticesLimitSpin',3000000),('trianglesLimitSpin',6000000),('partsLimitSpin',110000),('guidesLimitSpin',10000),('previewLimitSpin',600000),('memoryLimitSpin',3072),('workLimitSpin',300)]:
        event(name,'changed',value);check(name+' updates prepared realization',len(grass.interactionDefinitions)==1 and str(grass.interactionSourceIDs[0])==source_id and not str(root.interactionError))
    event('stiffnessSpin','changed',.7);event('gapSpin','changed',.01)
    check('Contact controls update without source analysis',not str(root.interactionError) and abs(float(grass.interactionStiffness)-.7)<1e-6)
    grass.amount=55;grass.markInputDirty();epoch=int(root.procEpoch);event('minimumSpin','changed',.5)
    check('Automatic preparation preserves Manual pending amount',int(root.updateMode)==1 and int(grass.amount)==55 and int(grass.generatedCount)==50 and int(root.procEpoch)==epoch)
    grass.amount=50;grass.markInputDirty();event('gapSpin','changed',0.0)
    report['status']='pass';save()
except Exception:report['error']=traceback.format_exc();report['ui_text']=str(control('info').text);report['root_error']=str(r.WFRoot.interactionError);save()
