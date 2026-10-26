"""Owned Max 2027 diagnostic: revised 0.87.3 preparation/cache/limits; no artist writes."""
from pathlib import Path
import hashlib,json,time,traceback,struct
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];O=Path(str(r.GardenRun));report={'stage':'starting'}
def save():(O/'qualification.json').write_text(json.dumps(report,indent=2),encoding='utf8')
def stage(s):report['stage']=s;save()
def info(v):return json.loads(str(r.cyrusInteractionSourceInfo(v)))
def header(v,name):
    p=O/(name+'.bin');r.cyrusInteractionSourceSnapshot(v,str(p));h=struct.unpack('<4I',p.read_bytes()[:16]);return {'vertices':h[1],'triangles':h[2],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def settle(sec=.2):
    end=time.monotonic()+sec
    while time.monotonic()<end:r.windows.processPostedMessages();time.sleep(.01)
try:
    r.execute('CyrusPerfHeadless=true;CyrusPointSuspended=true')
    bootstrap=r.AminScatterObject()
    scene=ROOT/'build/new-plants-review-20261026-01/New Plants test.max'
    stage('load copied New Plants scene');assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined);root=owner.baseObject;grass=root.layerObjects[0];collider=root.layerObjects[1]
    assert int(r.cyrusInteractionVersion())==3 and str(root.uiVersion())=='0.87.3'
    report['version']='0.87.3';report['native_capability']=3;report['schema']=int(root.version);report['input_scene_sha256']=hashlib.sha256(scene.read_bytes()).hexdigest();report['limits']=[int(x) for x in grass.interactionsLimits()]
    report['plants']=[];values={}
    for node in list(r.objects):
        if str(r.classOf(node.baseObject))!='Editable_Poly':continue
        stage('prepare '+str(node.name));t=time.perf_counter();value=r.cyrusInteractionSource(node,r.undefined,grass.interactionsSettings(),1)
        entry={'name':str(node.name),'info':info(value),'capture_prepare_seconds':time.perf_counter()-t};report['plants'].append(entry);save();assert entry['info']['can_prepare'],entry
        accepted=r.cyrusInteractionAccept(value);serialized=str(r.cyrusInteractionSerialize(accepted));p=O/('prepared-'+str(int(r.getHandleByAnim(node)))+'.json');p.write_text(serialized,encoding='utf8');entry['definition']=str(p);values[str(node.name)]=value
        restored=r.cyrusInteractionSource(node,serialized,grass.interactionsSettings(),1);entry['definition_roundtrip']=info(restored)['fingerprint']==entry['info']['fingerprint'];assert entry['definition_roundtrip'];save()
    stage('distinct accepted definition cache identity')
    node=grass.validSources()[0];entry=next(e for e in report['plants'] if e['name']==str(node.name));saved=json.loads(Path(entry['definition']).read_text());first_saved=json.dumps(saved);first=r.cyrusInteractionSource(node,first_saved,grass.interactionsSettings(),1)
    saved['source']['metadata']['guides'][0]['nodes'][-1][0]+=.00001
    changed=r.cyrusInteractionSource(node,json.dumps(saved),grass.interactionsSettings(),1);returned=json.loads(str(r.cyrusInteractionSerialize(r.cyrusInteractionAccept(changed))))
    assert returned['source']['metadata']['guides'][0]['nodes'][-1][0]==saved['source']['metadata']['guides'][0]['nodes'][-1][0]
    report['distinct_accepted_definitions']=True
    stage('retained proxy and role cache transitions')
    sphere=r.getNodeByName('Sphere001');proxy=collider.interactionsProxy(sphere)
    custom=r.cyrusInteractionColliderSource(sphere,proxy,3);closed=r.cyrusInteractionColliderSource(sphere,r.undefined,1)
    report['custom_to_closed']={'custom':header(custom,'custom-sphere'),'closed':header(closed,'closed-sphere')};assert report['custom_to_closed']['closed']['triangles']==960
    box=r.cyrusInteractionColliderSource(sphere,r.undefined,2);closed_again=r.cyrusInteractionColliderSource(sphere,r.undefined,1);report['box_to_closed']=header(closed_again,'closed-after-box');assert report['box_to_closed']['triangles']==960
    node=grass.validSources()[0];before=r.cyrusInteractionSource(node,r.undefined,grass.interactionsSettings(),1);boxed=r.cyrusInteractionColliderSource(node,r.undefined,2);after=r.cyrusInteractionSource(node,r.undefined,grass.interactionsSettings(),1);report['collider_to_plant']=info(after);assert info(before)['fingerprint']==info(after)['fingerprint']
    stage('endpoint and limit controls');report['endpoints']=[]
    for percent in [1,25]:
        cfg=r.Array(float(grass.interactionMinimumM),percent/100,1,grass.interactionsLimits(),float(grass.interactionConnectionM));v=r.cyrusInteractionSource(node,r.undefined,cfg,1);report['endpoints'].append({'percent':percent,'can_prepare':info(v)['can_prepare']});assert info(v)['can_prepare']
    rejected=[]
    for slot,val in [(0,3),(2,1),(3,1),(5,64),(6,1)]:
        target=r.getNodeByName('Outdoor_Plants_01_Brainea_Insignis_Fern_Medium03_001');lim=[int(x) for x in grass.interactionsLimits()];lim[slot]=val
        try:r.cyrusInteractionSource(target,r.undefined,r.Array(.005,.05,1,r.Array(*lim),.15),1)
        except Exception as e:rejected.append({'slot':slot,'value':val,'error':str(e)})
    report['bounded_rejections']=rejected;assert len(rejected)==5,rejected
    try:r.cyrusInteractionBuildTrunk(sphere);report['sphere_trunk_rejected']=False
    except Exception as e:report['sphere_trunk_rejected']=True;report['sphere_trunk_message']=str(e)
    assert report['sphere_trunk_rejected']
    stage('source authoring and ready scene')
    grass.interactionReact=False;collider.interactionColliderMode=1
    try:grass.interactionsSources(grass.validSources(),2);report['unprepared_rejected']=False
    except Exception:report['unprepared_rejected']=True
    assert report['unprepared_rejected'];grass.interactionsAnalyze(node);assert grass.interactionsCanAccept();grass.interactionsAccept();grass.interactionReact=True
    root.refreshAll();report['layer_errors']=[str(l.previewError) for l in root.layerObjects];report['published_counts']=[int(l.generatedCount) for l in root.layerObjects];report['statistics']=json.loads(str(root.interactionsStatistics()));assert not any(report['layer_errors']);assert not report['statistics']['error']
    r.execute('global E873Owner,E873Root,E873Grass,E873Collider,E873Sphere');r.E873Owner=owner;r.E873Root=root;r.E873Grass=grass;r.E873Collider=collider;r.E873Sphere=sphere
    stage('ready for separately dispatched contact commands')
    r.execute('global MCPFixtureDir=GardenRun;fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/mcp/development_transport.ms"')
    (O/'ready.json').write_text('{"status":"ready"}')
except Exception:
    report['error']=traceback.format_exc();save();(O/'error.txt').write_text(report['error'],encoding='utf8')
