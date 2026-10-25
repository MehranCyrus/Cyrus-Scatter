"""Incremental real-asset contact/performance campaign on an owned terraces copy."""
from pathlib import Path
import json, time, traceback, re, collections, struct
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(str(r.GardenRun))
LIB=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library/Models'
def arr(items):return r.Array(*items)
def p(x,y,z):return r.Point3(x,y,z)
def write(name,data):(OUT/name).write_text(json.dumps(data,indent=2),encoding='utf-8')
def memory():
    proc=r.execute('(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()');proc.Refresh()
    return {'private_bytes':int(proc.PrivateMemorySize64),'working_set_bytes':int(proc.WorkingSet64),'peak_working_set_bytes':int(proc.PeakWorkingSet64)}
def merge(path,label,color):
    before=set(int(r.getHandleByAnim(n)) for n in r.objects)
    assert r.mergeMaxFile(str(path),r.Name('select'),quiet=True)
    models=[n for n in r.selection if r.superClassOf(n)==r.GeometryClass];assert len(models)==1,(path,len(models))
    node=models[0];node.name=label;node.material=r.standardMaterial(name=label+' material',diffuse=r.color(*color));node.renderable=False;r.hide(node)
    node.pos=p(25000+len(before)*20,22000,0);return node
def capture_fixture(root,layers,assets,label):
    folder=OUT/(label+'-kernel');folder.mkdir()
    fixture={'metres_per_unit':1/float(r.units.decodeValue('1m')),'layers':[],'instances':[]}
    bins={'grass':'grass_small','bushy':'grass_bushy','lavender':'lavender','geranium':'geranium'}
    for li,(key,leaf) in enumerate(layers.items()):
        role=(1 if leaf.interactionCollider else 0)+(2 if leaf.interactionReact else 0);source=[]
        if role:
            path=folder/(key+'.bin')
            values=[entry[1] for entry in leaf.interactionSourceCache if entry[0]==assets[key]]
            assert len(values)==1,(key,len(values))
            fingerprint=str(r.cyrusInteractionSourceSnapshot(values[0],str(path)))
            if key in bins:
                definition=folder/(key+'-accepted.json');definition.write_text(str(leaf.interactionDefinitions[0]),encoding='utf-8')
                source=[{'kind':'plant','mesh':str(path),'definition':str(definition)}]
            else:source=[{'kind':'collider','mesh':str(path)}]
        fixture['layers'].append({'role':role,'cover':bool(leaf.interactionCoverRoots),'gap':float(leaf.interactionGapWU)*fixture['metres_per_unit'],'stiffness':float(leaf.interactionStiffness),'sources':source})
        if role:
            rows=root.groupSnapshotRows[li];token=r.cyrusPlacementToken(rows);count=int(r.getProperty(rows,r.Name('count')))
            for first in range(0,count,500):
                page=r.cyrusPlacementPage(rows,token,first,min(500,count-first))
                for row in page:
                    tm=row[0];fixture['instances'].append({'layer':li,'source':int(row[1])-1,'identity':str(row[2]),'transform':[float(v) for vec in [tm.row1,tm.row2,tm.row3,tm.row4] for v in vec]})
    (folder/'fixture.json').write_text(json.dumps(fixture),encoding='utf-8')
def main():
    started=time.perf_counter();assert r.loadMaxFile(str(ROOT/'build/interactions087-inputs-20261025-01/Terraces_Final.max'),quiet=True,useFileUnits=True)
    r.CyrusStopBrush();r.CyrusPFResume=False;r.CyrusPointSuspended=True
    write('loaded.json',{'seconds':time.perf_counter()-started,'nodes':len(list(r.objects)),**memory()})
    receivers=[n for n in r.objects if re.match(r'^PLANTING \| \d+ grass footprint$',str(n.name))];assert len(receivers)==11
    # A bounded foreground study patch within the first original planting tier.
    foreground=r.plane(name='087 Contact study receiver',width=350,length=350,widthsegs=1,lengthsegs=1,pos=p(-8000,-3100,-988.8409));foreground.renderable=False;r.hide(foreground)
    assets={
        'grass':merge(LIB/'Grasses/A069 - Grass - Small Clump/model.max','087 Source - small grass',(80,140,45)),
        'bushy':merge(LIB/'Grasses/A068 - Grass - Bushy Clump/model.max','087 Source - bushy grass',(95,130,45)),
        'lavender':merge(LIB/'Shrubs/A083 - Lavender - 01/model.max','087 Source - lavender',(160,110,180)),
        'geranium':merge(LIB/'Flowers/A066 - Herb Robert Geranium - 04/model.max','087 Source - geranium',(180,95,140)),
        'tree':merge(LIB/'Trees/A072 - Broadleaf Tree 01/model.max','087 Source - broadleaf tree',(65,110,40)),
        'rock':merge(ROOT/'Test Scene/Rock_Boulder_10/Rock_10.max','087 Source - supplied boulder',(120,115,100)),
    }
    # The file is a combined 13-rock set, including one open component. Select
    # a complete closed boulder from the supplied set and preserve its maps.
    combined=assets['rock'];r.convertToMesh(combined);nv=int(r.getNumVerts(combined));nf=int(r.getNumFaces(combined));parent=list(range(nv))
    def find(i):
        while parent[i]!=i:i=parent[i]
        return i
    faces=[tuple(int(x)-1 for x in r.getFace(combined,i)) for i in range(1,nf+1)]
    for face in faces:
        for vertex in face[1:]:parent[find(vertex)]=find(face[0])
    components={}
    for fi,face in enumerate(faces):components.setdefault(find(face[0]),[]).append(fi)
    candidates=[];component_report=[]
    for key,indices in components.items():
        edges=collections.Counter(tuple(sorted((faces[fi][k],faces[fi][(k+1)%3]))) for fi in indices for k in range(3));closed=all(v==2 for v in edges.values());verts=sorted({v for fi in indices for v in faces[fi]});points=[r.getVert(combined,v+1) for v in verts]
        extent=[max(v[k] for v in points)-min(v[k] for v in points) for k in range(3)];score=extent[0]*extent[1]*extent[2]
        component_report.append({'component':key,'faces':len(indices),'vertices':len(verts),'closed':closed,'extent_wu':extent})
        if closed:candidates.append((score,key,indices))
    assert candidates;_,selected,indices=max(candidates)
    bits=r.BitArray();bits.count=nf
    for fi in indices:bits[fi]=True
    data=r.meshop.detachFaces(combined,bits,delete=False,asMesh=True)
    rock=r.mesh(mesh=data,name='087 Source - closed supplied boulder');rock.material=combined.material;rock.renderable=False;r.hide(rock);assets['rock']=rock
    write('collider-selection.json',{'source':'Test Scene/Rock_Boulder_10/Rock_10.max','components':component_report,'selected_component':selected,'operation':'Detached the largest-volume closed connected boulder. Original file untouched; fixture material and original map channels preserved.'})
    # Explicit normalization for the unitless supplied boulder; keep its UVs.
    tm=rock.objectTransform
    vertices=[r.getVert(rock,i)*tm for i in range(1,int(r.getNumVerts(rock))+1)]
    lo=[min(v[k] for v in vertices) for k in range(3)];hi=[max(v[k] for v in vertices) for k in range(3)]
    factor=120/max(hi[k]-lo[k] for k in range(3));origin=p((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2])
    rock.transform=r.Matrix3(1);rock.objectOffsetPos=p(0,0,0);rock.objectOffsetRot=r.Quat(0,0,0,1);rock.objectOffsetScale=p(1,1,1)
    for i,vertex in enumerate(vertices,1):r.setVert(rock,i,(vertex-origin)*factor)
    r.update(rock);rock.pos=p(30000,22000,0)
    owner=r.AminScatterObject(name='CyrusScatter 0.87 - Terrace contact study');root=owner.baseObject;root.updateMode=1;root.viewportMode=3;root.identificationMode=2;root.autoRender=False
    layers={};prep=[]
    for key,label,count,react,collider in [('grass','Grass - React',1000,True,False),('bushy','Bushy grass - React',80,True,False),('lavender','Lavender - React',12,True,False),('geranium','Geranium - React',25,True,False),('tree','Trees - static',10,False,False),('rock','Stones - Collider',3,False,True)]:
        root.newLayer();leaf=root.layerObjects[-1];root.layerNames[-1]=label;leaf.addModelSource(assets[key]);root.setLayerSurfaces(leaf,arr([foreground]));leaf.amount=count;leaf.autoRender=False;leaf.randomSeed=87000+len(layers)
        if react:
            start=time.perf_counter();report=json.loads(str(leaf.interactionsAnalyze(assets[key])));leaf.interactionsAccept();prep.append({'source':key,'seconds':time.perf_counter()-start,'report':report});leaf.interactionReact=True
        leaf.interactionCollider=collider;layers[key]=leaf
        if key=='tree':leaf.sourceScales[0]=.35
    write('preparation.json',prep)
    r.addModifier(owner,r.CyrusScatterEdit());edit=owner.modifiers[0]
    stages=[];r.CyrusPointSuspended=False
    for label,grass,bushy,flowers,all_terraces in [('foreground',1000,80,12,False),('terraces-10000',10000,1000,100,True),('terraces-50000',50000,5000,500,True),('terraces-250000',250000,25000,2000,True)]:
        target=receivers if all_terraces else [foreground]
        for key,leaf in layers.items():root.setLayerSurfaces(leaf,arr([foreground] if key=='rock' else target))
        layers['grass'].amount=grass;layers['bushy'].amount=bushy;layers['lavender'].amount=flowers;layers['geranium'].amount=flowers*2
        layers['tree'].amount=10 if all_terraces else 1
        r.disableSceneRedraw();start=time.perf_counter()
        try:root.refreshAll();r.CyrusPointSync()
        finally:r.enableSceneRedraw()
        seconds=time.perf_counter()-start
        errors={key:str(leaf.previewError) for key,leaf in layers.items() if str(leaf.previewError)}
        if errors:write(label+'-failure.json',{'errors':errors,'point_error':str(r.CyrusPointLastError),**memory()});raise RuntimeError(errors)
        stats=json.loads(str(root.interactionsStatistics()));row={'stage':label,'seconds':seconds,'epoch':int(root.procEpoch),'statistics':stats,'generated':{k:int(v.generatedCount) for k,v in layers.items()},**memory()};stages.append(row);write('stages.json',stages)
        if label=='foreground':
            capture_fixture(root,layers,assets,label)
            r.saveMaxFile(str(OUT/'Terraces_Interactions_087_Foreground.max'),quiet=True)
    # Save a bounded artist trial first; dense tiers remain recorded separately.
    layers['grass'].amount=10000;layers['bushy'].amount=1000;layers['lavender'].amount=100;layers['geranium'].amount=200
    root.refreshAll();r.CyrusPointSync();r.saveMaxFile(str(OUT/'Terraces_Interactions_087_Test.max'),quiet=True)
    write('completed.json',{'status':'staged','stages':stages,'limitations':['No presented FPS claim','Standard diagnostic materials on newly merged sources','Tree layer remains rigid','Per-instance held drag, full mesh and renderer qualification follow separately']})
try:
    with pymxs.undo(False):main()
except Exception:(OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
