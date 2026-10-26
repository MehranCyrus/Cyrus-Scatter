"""Read/copy the supplied scene in an owned Max 2027 profile; capture failing inputs."""
from pathlib import Path
import hashlib,json,time,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3]; O=Path(str(r.GardenRun)); report={'stage':'load'}
def save(): (O/'baseline.json').write_text(json.dumps(report,indent=2))
def capture(root,label):
    folder=O/label;folder.mkdir(exist_ok=True)
    fixture={'metres_per_unit':1/float(r.units.decodeValue('1m')),'layers':[],'instances':[],'audit':True}
    for li,leaf in enumerate(root.procPublishedOwners):
        role=(1 if leaf.interactionCollider else 0)+(2 if leaf.interactionReact else 0)
        values=leaf.interactionsSources(root.procPublishedSources[li],role);sources=[]
        for si,node in enumerate(root.procPublishedSources[li]):
            if not role: continue
            mesh=folder/f'source-{li}-{si}.bin';r.cyrusInteractionSourceSnapshot(values[si],str(mesh))
            entry={'kind':'plant' if role==2 else 'collider','mesh':str(mesh)}
            if role==2:
                slot=list(str(x) for x in leaf.interactionSourceIDs).index(str(leaf.sourceRowIDs[si]))
                path=folder/f'definition-{li}-{si}.json';path.write_text(str(leaf.interactionDefinitions[slot]));entry['definition']=str(path)
            sources.append(entry)
        fixture['layers'].append({'role':role,'cover':bool(leaf.interactionCoverRoots),'gap':float(leaf.interactionGapWU)*fixture['metres_per_unit'],'stiffness':float(leaf.interactionStiffness),'sources':sources})
        if role:
            rows=root.groupSnapshotRows[li];token=r.cyrusPlacementToken(rows);count=int(r.getProperty(rows,r.Name('count')))
            for first in range(0,count,500):
                for row in r.cyrusPlacementPage(rows,token,first,min(500,count-first)):
                    tm=row[0];fixture['instances'].append({'layer':li,'source':int(row[1])-1,'identity':str(row[2]),'transform':[float(x) for v in [tm.row1,tm.row2,tm.row3,tm.row4] for x in v]})
    (folder/'fixture.json').write_text(json.dumps(fixture,indent=2));return str(folder/'fixture.json')
try:
    r.execute('global MCPFixtureDir=GardenRun;fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/mcp/development_transport.ms"')
    r.execute('CyrusPerfHeadless=true;CyrusPointSuspended=true')
    r.AminScatterObject()
    scene=ROOT/'build/interactions0873-workflow-20261026-01/New Plants test.max'
    assert r.loadMaxFile(str(scene),quiet=True,useFileUnits=True,missingDLLsAction=r.Name('logmsg'))
    owner=next(n for n in r.objects if str(r.classOf(n.baseObject))=='AminScatterObject' and n.baseObject.overlapOwner==r.undefined)
    root=owner.baseObject;grass=root.layerObjects[0];collider=root.layerObjects[1];sphere=collider.validSources()[0]
    report.update(scene_sha256=hashlib.sha256(scene.read_bytes()).hexdigest(),native_capability=int(r.cyrusInteractionVersion()),metres_per_unit=1/float(r.units.decodeValue('1m')),layers=[])
    for leaf in root.layerObjects:
        report['layers'].append({'name':str(root.layerCaption(leaf)),'amount':int(leaf.amount),'collider':bool(leaf.interactionCollider),'react':bool(leaf.interactionReact),'shape':int(leaf.interactionColliderMode),'sources':[str(n.name) for n in leaf.validSources()],'proxies':[str(n) for n in leaf.interactionProxyNodes],'definitions':len(leaf.interactionDefinitions),'minimum_m':float(leaf.interactionMinimumM)})
    report['sphere_radius_wu']=float(sphere.radius);save()
    # Reproduce the incomplete custom-mode transition without destroying source data.
    oldmode=collider.interactionColliderMode;oldids=collider.interactionProxySourceIDs;oldnodes=collider.interactionProxyNodes
    collider.interactionColliderMode=3;collider.interactionProxySourceIDs=r.Array();collider.interactionProxyNodes=r.Array()
    try: collider.interactionsColliderValue(sphere)
    except Exception as e: report['missing_custom_error']=str(e)
    collider.interactionProxySourceIDs=oldids;collider.interactionProxyNodes=oldnodes;collider.interactionColliderMode=oldmode
    for leaf in root.layerObjects: leaf.interactionCollider=False;leaf.interactionReact=False
    grass.amount=50;grass.markInputDirty();root.refreshAll()
    assert not any(str(x.previewError) for x in root.layerObjects),[str(x.previewError) for x in root.layerObjects]
    grass.interactionMinimumM=.01;grass.interactionMinimumWU=float(r.units.decodeValue('1cm'));grass.interactionUnitsPending=False
    grass.interactionsAnalyze(grass.validSources()[0]);grass.interactionsAccept();grass.interactionReact=True;collider.interactionCollider=True;collider.interactionColliderMode=1
    report['fixture']=capture(root,'fifty-plants');report['stage']='fit 50 plants';save()
    start=time.perf_counter()
    try:root.interactionsEnsure();report['fit']={'ok':True,'statistics':json.loads(str(root.interactionsStatistics()))}
    except Exception as e:report['fit']={'ok':False,'error':str(e)}
    report['fit']['seconds']=time.perf_counter()-start;report['stage']='complete';save()
    r.execute('global WFRoot,WFOwner,WFGrass,WFCollider,WFSphere');r.WFRoot=root;r.WFOwner=owner;r.WFGrass=grass;r.WFCollider=collider;r.WFSphere=sphere
    r.execute('global MCPFixtureDir=GardenRun;fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/mcp/development_transport.ms"')
    (O/'ready.json').write_text('{"status":"ready"}')
except Exception:report['error']=traceback.format_exc();save();(O/'error.txt').write_text(report['error'])
