"""Invoke mounted generated handlers, inspect source review and publication boundaries."""
from pathlib import Path
import json,time,traceback
from pymxs import runtime as r
O=Path(str(r.GardenRun));report={'checks':[]}
def save():(O/'controls.json').write_text(json.dumps(report,indent=2))
def check(name,test):
    assert test,name;report['checks'].append(name);save()
def control(name):return r.getProperty(r.WFSection,r.Name('interactionsUI_'+name))
def event(name,method,value=None):
    if method=='selected':text='WFSection.interactionsUI_'+{'roleList':'chooseRole','proxyList':'chooseColliderMode'}[name]+' '+str(value)
    else:
        text='WFSection.interactionsUI_'+name+'.'+method
        if value is not None:text+=' '+str(value).lower()
        else:text+='()'
    r.execute(text)
def bind(index):
    r.WFRoot.mainUI.selectLayerView(r.WFRoot.layerObjects[index-1]);r.WFRoot.mainUI.bindSection(r.WFSection)
try:
    root=r.WFRoot;grass=r.WFGrass;collider=r.WFCollider;node=grass.validSources()[0];root.updateMode=1
    r.execute('select WFOwner;max modify mode;subObjectLevel=0;modPanel.setCurrentObject WFRoot')
    until=time.monotonic()+3
    while not bool(root.mainUI.controlsReady) and time.monotonic()<until:r.windows.processPostedMessages();time.sleep(.01)
    assert bool(root.mainUI.controlsReady),'Modify panel did not finish mounting'
    r.WFSection=root.mainUI.editors[12];root.mainUI.slots[12].open=True
    grass.interactionFoliage=.05;grass.interactionReact=False;grass.interactionDefinitions=r.Array();grass.interactionSourceIDs=r.Array();grass.interactionSourceCache=r.Array();grass.interactionsChanged()
    collider.interactionCollider=False;root.interactionsEnsure()
    bind(1);event('roleList','selected',3)
    check('React can be selected before preparation',bool(grass.interactionReact) and len(grass.interactionDefinitions)==0 and not str(root.interactionError))
    check('Preparation pending is explained','prepared' in str(control('workflowInfo').text))
    epoch=int(root.procEpoch);count=int(grass.generatedCount)
    start=time.perf_counter();event('analyzeButton','pressed');report['analyze_seconds']=time.perf_counter()-start
    check('Actual Analyze handler enables review',bool(control('guideReviewButton').checked) and bool(control('acceptButton').enabled))
    guides=[n for n in grass.interactionGuides if 'Guides' in str(n.name)]
    check('Guides are at original source, not an instance',len(guides)==1 and float(r.distance(guides[0].pos,node.pos))<.00001)
    check('Review did not rebuild placements',int(root.procEpoch)==epoch and int(grass.generatedCount)==count)
    event('guideReviewButton','changed',False);check('Guide toggle hides helpers',len(grass.interactionGuides)==0)
    event('guideReviewButton','changed',True);check('Guide toggle restores current review',bool(control('guideReviewButton').checked))
    event('acceptButton','pressed');check('Accept enables prepared layer automatically',bool(grass.interactionReact) and len(grass.interactionDefinitions)==1 and not str(root.interactionError))
    check('Accept closes review',not bool(control('guideReviewButton').checked) and len(grass.interactionGuides)==0)
    saved=str(grass.interactionDefinitions[0]);counts=[]
    for percent in [1,25,100]:
        event('foliageSpin','changed',float(percent))
        check(f'{percent}% preview retained source definition',abs(float(grass.interactionFoliage)-percent/100)<1e-6 and str(grass.interactionDefinitions[0])==saved and not str(root.interactionError))
        value=grass.interactionSourceCache[0][1];data=json.loads(str(r.cyrusInteractionSourceInfo(value)));counts.append(data['delivered_preview_triangles'])
        check(f'{percent}% reuses inference',data['guide_inference_reused'])
    report['preview_triangles']=counts;check('Increasing preview restores blade density',counts[0]<counts[1]<counts[2])
    event('guideReviewButton','changed',True);check('Saved guides can be reviewed again',bool(control('guideReviewButton').checked) and not bool(control('acceptButton').enabled));event('guideReviewButton','changed',False)
    bind(2);event('roleList','selected',2);check('Source sphere becomes collider without extra mesh',bool(collider.interactionCollider) and int(collider.interactionColliderMode)==1 and not str(root.interactionError))
    oldids=r.Array(*list(collider.interactionProxySourceIDs));oldnodes=r.Array(*list(collider.interactionProxyNodes));collider.interactionProxySourceIDs=r.Array();collider.interactionProxyNodes=r.Array()
    event('proxyList','selected',3);check('Incomplete custom selection keeps working shape',int(collider.interactionColliderMode)==1 and 'first' in str(control('info').text))
    check('Incomplete selection does not set runtime error',not str(root.interactionError))
    collider.interactionsSetProxy(r.WFSphere,r.WFSphere);check('Picking same sphere uses original closed geometry',int(collider.interactionColliderMode)==1)
    collider.interactionProxySourceIDs=oldids;collider.interactionProxyNodes=oldnodes
    event('reviewColliderButton','changed',True);check('Collider toggle shows source overlay',bool(control('reviewColliderButton').checked) and len(collider.interactionGuides)==1 and float(r.distance(collider.interactionGuides[0].pos,r.WFSphere.pos))<.00001)
    event('reviewColliderButton','changed',False);check('Collider toggle hides overlay',len(collider.interactionGuides)==0)
    for _ in range(12):
        event('reviewColliderButton','changed',True);r.completeRedraw();check('Repeated collider overlay is frozen',len(collider.interactionGuides)==1 and bool(collider.interactionGuides[0].isFrozen));event('reviewColliderButton','changed',False);r.completeRedraw()
    bind(1);event('foliageSpin','changed',100.0);epoch=int(root.procEpoch);oldamount=int(grass.amount)
    grass.amount=oldamount+5;grass.markInputDirty();event('gapSpin','changed',.01)
    report['manual']={'before_epoch':epoch,'after_epoch':int(root.procEpoch),'before_amount':oldamount,'published_count':int(grass.generatedCount),'pending_amount':int(grass.amount),'mode':int(root.updateMode)};save()
    check('Contact settings do not consume Manual amount edits',int(root.procEpoch)==epoch and int(grass.generatedCount)==oldamount)
    grass.amount=oldamount;grass.markInputDirty();event('gapSpin','changed',0)
    counters=(int(root.procEpoch),int(root.groupBuilds),str(root.interactionsStatistics()))
    for _ in range(3):bind(2);bind(1)
    check('Warm browsing does not fit or rebuild',counters==(int(root.procEpoch),int(root.groupBuilds),str(root.interactionsStatistics())))
    report['statistics']=json.loads(str(root.interactionsStatistics()));report['status']='pass';save()
except Exception:report['error']=traceback.format_exc();save()
