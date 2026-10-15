"""Owned Max 2027 recipe capture/import and native Paint qualification."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from recipe_rows import fingerprint
import hashlib,json,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-recipes0825-')
data={'status':'started','checks':[],'timings_ms':{},'runtime':json.loads((OUT/('runtime.json' if (OUT/'runtime.json').exists() else 'launch.json')).read_text())}
def save():
    (OUT/'recipes-qualification.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    (OUT/('recipes-'+Path(str(r.MCPFixtureLast)).stem+'.json')).write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def check(value,label):
    data['checks'].append({'passed':bool(value),'label':label});save()
    if not value:raise AssertionError(label)
def stage(label):data['stage']=label;save()
def get(obj,key):return r.CyrusRecipeGet(obj,key)
def plain(v):
    if v is None or isinstance(v,(str,int,float,bool)):return v
    values=list(v)
    if len(values)==2 and str(values[0])=='recipeObject':return {str(x[0]):plain(x[1]) for x in values[1]}
    return [plain(x) for x in values]
def rejected(action,label,needle=''):
    message=''
    try:action()
    except Exception as e:message=str(e)
    check(bool(message) and (not needle or needle in message),label)
    data.setdefault('expected_errors',[]).append({'label':label,'message':message[:4000]});save()
def counters(root):return {'epoch':int(root.procEpoch),'builds':int(root.groupBuilds),'prepared':[int(x.procPreparedBuilds) for x in root.layerObjects],'receivers':[list(x.receiverCacheStats())[:2] for x in root.layerObjects],'mask':[int(x) for x in r.cyrusMeshDensityStats()]}
def row_hash(root,index):return fingerprint(root.groupSnapshotRows[index])
def solve(root):
    root.procManualRevision+=1;start=time.perf_counter();root.evaluateProcedural();return (time.perf_counter()-start)*1000
def channel(node):
    r.meshop.setNumMaps(node,3,keep=True);r.meshop.setMapSupport(node,2,True)
    r.meshop.setNumMapVerts(node,2,node.numverts);r.meshop.setNumMapFaces(node,2,node.numfaces)
    for i in range(1,int(node.numverts)+1):p=r.getVert(node,i);r.meshop.setMapVert(node,2,i,r.Point3((p.x+10)/20,0,1))
    for i in range(1,int(node.numfaces)+1):r.meshop.setMapFace(node,2,i,r.getFace(node,i))
    r.update(node)
def shape(name,loops):
    node=r.SplineShape(name=name)
    for index,loop in enumerate(loops,1):
        r.addNewSpline(node)
        for point in loop:r.addKnot(node,index,r.Name('corner'),r.Name('line'),r.Point3(*point))
        r.close(node,index)
    r.updateShape(node);return node
try:
    with pymxs.undo(False):
        stage('scene')
        with pymxs.undo(False):
            r.CyrusPerfHeadless=True;r.resetMaxFile(r.Name('noPrompt'));r.units.SystemType=r.Name('meters');r.units.SystemScale=1
            node=r.AminScatterObject(name='Recipe 0.82.5 source');root=node.baseObject;root.updateMode=1;root.autoRender=False
            terrain=r.Plane(name='Recipe terrain',width=20,length=20,widthsegs=8,lengthsegs=8);r.convertToMesh(terrain);channel(terrain)
            model=r.Pyramid(name='Recipe pyramid',width=.3,depth=.3,height=.7,pos=r.Point3(30,0,0))
            model2=r.Box(name='Recipe box',width=.2,length=.2,height=.45,pos=r.Point3(32,0,0))
            owners=[]
            for i,label in enumerate(['Canopy','Shrubs','Groundcover']):
                root.newLayer();owner=root.selectedLayer();root.layerNames[len(root.layerObjects)-1]=label
                root.setLayerSurfaces(owner,r.Array(terrain));owner.sources=r.Array(model,model2);owner.ensureSourceRows();owner.sourceWeights=r.Array(.7,.3)
                owner.amount=2000;owner.randomSeed=4101+i;owner.procLayerSelfEnabled=False;owner.alignNormal=i==2
                owner.sourceRadiiWU=r.Array(.2,.1);owner.sourceScales=r.Array(1.,.7);owner.sourceZOffsetsWU=r.Array(.01,.02)
                owner.meshMaskChannel=2;owner.meshMaskComponent=1;owner.meshMaskEnabled=i==0;owner.meshMaskSamples=r.Array(0.,.1,.5,1.)
                owner.slopeEnabled=True;owner.slopeMinimum=0;owner.slopeMaximum=55;owner.slopeUpperFade=10
                owners.append(owner)
            paint=root.addPaintArea(owners[1],target=terrain);paint.paintSetName='Islands with an Erase hole';paint.paintView=0;paint.paintDensity=.8
            border=shape('Recipe Paint input',[[(-8,-4,0),(-2,-4,0),(-2,3,0),(-8,3,0)],[(-6,-1,0),(-6,1,0),(-4,1,0),(-4,-1,0)],[(2,-3,0),(7,-3,0),(7,3,0),(2,3,0)]])
            root.importPaintSpline(paint,border,tolerance=.001)
            r.cyrusBrushSetFalloff(paint.paintDocument,r.Array(.5,.25,True,True,.2,1.4,r.Array(0.,.1,.5,1.),r.Array(0.,.25,.8,1.)))
            paint.fallDensityGraph='';paint.fallScaleGraph='';paint.publishPaint()
            disabled=root.addPaintArea(owners[1],target=terrain);disabled.paintSetEnabled=False;disabled.paintSetName='Disabled saved coverage';r.cyrusBrushFill(disabled.paintDocument,1.)
            empty=root.addPaintArea(owners[1],target=terrain);empty.paintSetEnabled=False;empty.paintSetName='Empty saved coverage'
            path=r.Rectangle(name='Recipe Band path',width=12,length=12);bands=owners[2];bands.diversityMode=3
            bands.addStroke(path,side=2);bands.patternWidths[0]=2.;bands.strokeStarts[0]=0.;bands.strokeEnds[0]=2.;bands.setStrokeSelection(1,2,r.Array(str(bands.sourceRowIDs[0])))
            bands.strokeCurveEnabled[0]=True;bands.strokeCurveSamples[0]='1,0.8,0.4,0.1';bands.strokeScaleModes[0]=3;bands.strokeScaleSamples[0]='0.3,0.7,1.2'
            root.procSetPair(2,owners[0],owners[1],False,1.,.2,True)
            r.RecipeTestNode=node;r.RecipeTestRoot=root;r.RecipeTestTerrain=terrain;r.RecipeTestPaint=paint
        check(str(root.uiVersion())=='0.82.5' and int(r.cyrusRecipeVersion())==1,'Matched 0.82.5 recipe capability')
        stage('baseline solve');data['timings_ms']['baseline']=solve(root);check(all(len(rows)>0 for rows in root.groupSnapshotRows),'All three source layers publish')
        hashes=[row_hash(root,i) for i in range(3)];before=counters(root)
        owners[0].amount=2100
        stage('complete capture')
        document=r.CyrusRecipeCapture(root,r.Array(*owners),'Complete hillside');captured=plain(document)
        check(counters(root)==before,'Save capture performs no placement/preview/mesh-mask work')
        check(captured['layers'][0]['settings']['amount']==2100,'Manual pending amount is saved')
        check(len(captured['layers'][1]['areas'])==3,'Paint active, disabled and empty documents are included')
        original_payloads=[str(r.cyrusBrushRecipeExport(a.paintDocument)[0]) for a in owners[1].paintAreas]
        check([a['paint']['payload'] for a in captured['layers'][1]['areas']]==original_payloads,'Native Paint bytes are captured exactly')
        directory=OUT/'library';directory.mkdir(exist_ok=True);file=directory/'complete.csrecipe.json'
        if file.exists():file=directory/('complete-'+str(r.CyrusNewLayerID())+'.csrecipe.json')
        r.cyrusRecipeWrite(str(file),document);loaded=r.cyrusRecipeRead(str(file))
        check(plain(loaded)==captured,'Manifest and Paint sidecars round-trip without loss')
        check([row_hash(root,i) for i in range(3)]==hashes,'Save and read retain the pending Manual publication')
        bindings=r.CyrusRecipeSuggestBindings(root,loaded);check(all(pair[1] is not None for pair in bindings),'Unique scene names can be explicitly suggested for review')
        stage('transactional Add')
        result=r.CyrusRecipeImport(root,loaded,bindings);imported=list(result[1]);check(len(root.layerObjects)==6,'Three layers append in saved order')
        check(int(root.updateMode)==1 and int(root.procEpoch)==before['epoch'],'Manual Add preserves mode and publication epoch')
        check([row_hash(root,i) for i in range(3)]==hashes,'Manual Add preserves existing full rows')
        check(all(str(a.layerID)!=str(b.layerID) for a,b in zip(owners,imported)),'Imported layers receive fresh scene identities')
        check([str(r.cyrusBrushRecipeExport(a.paintDocument)[0]) for a in imported[1].paintAreas]==original_payloads,'Add restores exact Paint payloads, holes and inactive records')
        check(str(imported[2].strokeSourceIDs[0])==str(imported[2].sourceRowIDs[0]) and str(imported[2].sourceRowIDs[0])!=str(owners[2].sourceRowIDs[0]),'Band membership follows remapped source row IDs')
        check(float(imported[1].paintAreas[0].paintDensity)==float(paint.paintDensity),'Per-area density survives')
        imported[0].amount=2000
        stage('calculate imported graph');data['timings_ms']['six_layers']=solve(root)
        check(all(len(rows)>0 for rows in root.groupSnapshotRows),'Imported graph calculates successfully')
        r.cyrusBrushFill(imported[1].paintAreas[0].paintDocument,0.)
        check(str(r.cyrusBrushRecipeExport(paint.paintDocument)[0])==original_payloads[0],'Imported Paint is independent from the source document')
        stage('binding rejection and rollback')
        count=len(root.layerObjects);epoch=int(root.procEpoch)
        rejected(lambda:r.CyrusRecipeImport(root,loaded,r.Array()),'Missing required roles reject before commit')
        check(len(root.layerObjects)==count and int(root.procEpoch)==epoch,'Missing bindings leave authored state and publication unchanged')
        bad=r.CyrusRecipeSuggestBindings(root,loaded)
        changed=r.copy(terrain);changed.name='Incompatible terrain';r.setVert(changed,1,r.Point3(-10,-10,2));r.update(changed)
        roles=list(get(loaded,'roles'))
        for i,role in enumerate(roles):
            if 'paintReceiver' in list(get(role,'purposes')):bad[i][1]=changed
        rejected(lambda:r.CyrusRecipeImport(root,loaded,bad),'Incompatible Paint receiver rejects with full rollback','preserved')
        check(len(root.layerObjects)==count and int(root.procEpoch)==epoch,'Late Paint staging failure rolls back all imported records')
        check([str(r.cyrusBrushRecipeExport(a.paintDocument)[0]) for a in owners[1].paintAreas]==original_payloads,'Failed import preserves source Paint')
        stage('new setup')
        fresh=r.CyrusRecipeImport(root,loaded,bindings,newSetup=True);fresh_root=fresh[0]
        check(len(fresh_root.layerObjects)==3 and int(fresh_root.updateMode)==1,'New setup restores three layers and saved Manual mode')
        check([str(r.cyrusBrushRecipeExport(a.paintDocument)[0]) for a in fresh_root.layerObjects[1].paintAreas]==original_payloads,'New setup preserves Paint bytes')
        data['timings_ms']['new_setup']=solve(fresh_root);check(all(len(rows)>0 for rows in fresh_root.groupSnapshotRows),'New setup calculates all saved owners')
        r.RecipeLoadedDocument=loaded;r.RecipeLoadedBindings=bindings;r.RecipeImportedRoot=fresh_root
        r.saveMaxFile(str(OUT/'recipe-qualified.max'),quiet=True)
        data['saved_scene']=str(OUT/'recipe-qualified.max');data['recipe_file']=str(file)
        data['counts']=[len(rows) for rows in fresh_root.groupSnapshotRows]
        data['fingerprints']=[row_hash(fresh_root,i) for i in range(3)]
        data['status']='passed';save()
except Exception:
    data['status']='failed';data['error']=traceback.format_exc();save();raise
