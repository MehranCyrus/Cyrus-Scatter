"""Owned Max 2027 baseline: existing Scatter, static footprint masks, no integration."""
from pathlib import Path
import json, math, time, traceback
from pymxs import runtime as rt

ROOT = Path(r'F:/Cursor/_Cyrus_Apps/CyrusScatter')
HERE = Path(__file__).parent
OUT = Path(str(rt.GardenRun))

def write(name, data):
    (OUT / name).write_text(json.dumps(data, indent=2), encoding='utf-8')

def stage(text):
    (OUT / 'stage.txt').write_text(text, encoding='utf-8')

def xyz(p):
    return [float(p.x), float(p.y), float(p.z)]

def arr(values):
    return rt.Array(*values)

def bounds(n):
    return [xyz(p) for p in rt.nodeGetBoundingBox(n, rt.Matrix3(1))]

def hull(points):
    points = sorted(set((p[0], p[1]) for p in points))
    def cross(o, a, b):
        return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    lower, upper = [], []
    for p in points:
        while len(lower)>1 and cross(lower[-2], lower[-1], p)<=0: lower.pop()
        lower.append(p)
    for p in reversed(points):
        while len(upper)>1 and cross(upper[-2], upper[-1], p)<=0: upper.pop()
        upper.append(p)
    return lower[:-1]+upper[:-1]

def transform(p, rows):
    return [p[0]*rows[0][k]+p[1]*rows[1][k]+p[2]*rows[2][k]+rows[3][k] for k in range(3)]

def canonical(n, name, factor=1.0, longest=None, tilt=0):
    # Only merged derivatives are edited. Bake transforms before preparing pivots.
    rt.convertToMesh(n)
    if tilt: rt.rotate(n, rt.EulerAngles(tilt, 0, 0))
    rt.resetXForm(n); rt.collapseStack(n)
    b = bounds(n)
    if longest: factor = longest/max(b[1][i]-b[0][i] for i in range(3))
    rt.scale(n, rt.Point3(factor, factor, factor))
    rt.resetXForm(n); rt.collapseStack(n)
    b = bounds(n)
    n.pivot = rt.Point3((b[0][0]+b[1][0])/2, (b[0][1]+b[1][1])/2, b[0][2])
    n.pos = rt.Point3(0, 0, 0)
    n.name = 'SOURCE | '+name
    n.renderable = False
    rt.hide(n)
    return n

def receiver(name, x, y, w, l):
    n = rt.Plane(name='RECEIVER | '+name, width=w, length=l, widthsegs=1, lengthsegs=1, pos=rt.Point3(x,y,0))
    n.renderable = False; rt.hide(n)
    return n

def read_rows(root):
    result=[]
    for i, rows in enumerate(root.groupSnapshotRows):
        token=rt.cyrusPlacementToken(rows)
        entries=[]
        for first in range(0, int(rows.count), 500):
            for row in rt.cyrusPlacementPage(rows,token,first,min(500,int(rows.count)-first)):
                tm=row[0]
                entries.append({'source':int(row[1]), 'id':str(row[2]),
                                'tm':[xyz(tm.row1),xyz(tm.row2),xyz(tm.row3),xyz(tm.row4)]})
        result.append({'layer':i, 'name':str(root.layerNames[i]), 'rows':entries})
    return result

def main():
    rt.resetMaxFile(rt.Name('noPrompt'))
    rt.units.SystemType=rt.Name('centimeters'); rt.units.SystemScale=1
    rt.execute('CyrusPerfHeadless=true; CyrusPointSuspended=true')
    inputs=json.loads((HERE/'asset-inputs.json').read_text())
    sources={}; texture_report=[]
    library_maps=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library/Maps'
    rocks=ROOT/'Test Scene/Rock_Boulder_10'
    for asset in inputs:
        if asset['id']=='phlox': continue
        stage('merge '+asset['id'])
        if Path(asset['path']).suffix.lower()=='.max':
            assert rt.mergeMAXFile(asset['path'], rt.Name('autoRenameDups'), rt.Name('renameMtlDups'), quiet=True)
            nodes=list(rt.getLastMergedNodes())
        else:
            before=set(int(rt.getHandleByAnim(n)) for n in rt.objects)
            rt.importFile(asset['path'],rt.Name('noPrompt'))
            nodes=[n for n in rt.geometry if int(rt.getHandleByAnim(n)) not in before]
        for n in nodes:
            if asset['id']=='rock_main': canonical(n,'Hero Rock 10',longest=175,tilt=35)
            elif asset['id']=='rock_small': canonical(n,'Small '+str(n.name),longest=34)
            else:
                factors={'grass_small':2.4,'grass_bushy':2.3,'lavender':0.62,'geranium':2.1,'tree':0.45}
                canonical(n,asset['id'],factor=factors[asset['id']])
        sources[asset['id']]=nodes
        for n in nodes:
            if not n.material: continue
            for b in rt.getClassInstances(rt.Bitmaptexture,target=n.material):
                original=str(b.filename); basename=Path(original.replace('\\','/')).name
                candidates=[library_maps/basename,rocks/basename,rocks/'Stones 1/Textures'/basename]
                target=next((p for p in candidates if p.exists()),None)
                if target: b.filename=str(target)
                texture_report.append({'source':asset['id'],'original':original,'resolved':str(target) if target else None})
    write('textures.json',texture_report)
    stage('controller')
    meadow=receiver('5.2m x 4.2m meadow',0,0,520,420)
    hero_rcv=receiver('hero anchor',-25,-5,0.1,0.1)
    tree_rcv=receiver('tree anchor',105,105,0.1,0.1)
    small_rcv=[receiver('stone pocket '+str(i),x,y,24,20) for i,(x,y) in enumerate([(-120,-70),(78,-62),(-115,45),(35,78),(132,12),(-62,100)])]
    lavender_rcv=[receiver('lavender drift '+str(i),x,y,55,80) for i,(x,y) in enumerate([(-115,-5),(75,28),(-65,105)])]
    flower_rcv=[receiver('geranium drift '+str(i),x,y,70,55) for i,(x,y) in enumerate([(-125,-105),(100,-78),(40,92),(-160,40)])]
    controller=rt.AminScatterObject(name='CYRUS | Garden interaction investigation',pos=rt.Point3(-310,-240,0))
    root=controller.baseObject
    root.updateMode=1; root.autoRender=True; root.surfaceNodes=arr([meadow])
    root.viewportMode=3; root.identificationMode=2; root.viewportInstances=5000; root.viewportFaces=24000000
    root.viewportNavigationInstances=800; root.viewportNavigationFaces=3000000; root.previewBudget=100000
    root.showCenters=False
    specs=[('01 Hero stone',sources['rock_main'],[hero_rcv],1,1,1),
           ('02 Small stones',sources['rock_small'],small_rcv,11,0.6,1.4),
           ('03 Small grass',sources['grass_small'],[meadow],1700,0.72,1.3),
           ('04 Bushy grass',sources['grass_bushy'],[meadow],700,0.7,1.3),
           ('05 Lavender',sources['lavender'],lavender_rcv,9,0.8,1.12),
           ('06 Geranium',sources['geranium'],flower_rcv,100,0.8,1.2),
           ('07 Small tree',sources['tree'],[tree_rcv],1,1,1)]
    layers=[]
    for i,(name,models,receivers,count,smin,smax) in enumerate(specs):
        root.newLayer(); layer=root.selectedLayer(); layers.append(layer)
        root.setLayerSurfaces(layer,arr(receivers))
        for n in models: assert layer.addModelSource(n)
        layer.amount=count; layer.scaleMinimum=smin; layer.scaleMaximum=smax
        layer.randomSeed=251025+i*113; layer.yawMinimum=0; layer.yawMaximum=360
        layer.procSelfOverride=True; layer.procSelfEnabled=False; layer.procLayerSelfEnabled=False
        layer.paintEnabled=False
        palette=[(128,119,103),(152,145,127),(71,115,42),(94,134,54),(143,111,180),(216,160,191),(65,107,42)]
        layer.layerIDColor=rt.Color(*palette[i])
    root.layerNames=arr([s[0] for s in specs])
    stage('initial placement')
    start=time.perf_counter(); root.evaluateProcedural(); initial_seconds=time.perf_counter()-start
    before=read_rows(root); write('placements-before-masks.json',before)
    # Existing Area masks approximate a ground footprint. They do not follow a moving rock.
    masks=[]; footprints=[]
    for index in [0,1]:
        for j,entry in enumerate(before[index]['rows']):
            source=specs[index][1][entry['source']-1]
            mesh=rt.snapshotAsMesh(source)
            offset=source.objectTransform*rt.inverse(source.transform)
            offset_rows=[xyz(offset.row1),xyz(offset.row2),xyz(offset.row3),xyz(offset.row4)]
            vertices=[transform(transform(xyz(rt.getVert(mesh,k)),offset_rows),entry['tm']) for k in range(1,int(rt.getNumVerts(mesh))+1)]
            polygon=hull(vertices)
            spline=rt.SplineShape(name='STATIC FOOTPRINT | '+str(index)+'-'+str(j))
            rt.addNewSpline(spline)
            for x,y in polygon: rt.addKnot(spline,1,rt.Name('corner'),rt.Name('line'),rt.Point3(x,y,0.05))
            rt.close(spline,1); rt.updateShape(spline); rt.hide(spline); spline.renderable=False
            masks.append(spline); footprints.append({'name':str(spline.name),'polygon_cm':polygon,'stone_layer':index,'stone_id':entry['id']})
    for layer in layers[2:6]:
        layer.areaNodes=arr(masks); layer.areaModes=arr([2]*len(masks))
    stage('masked placement')
    start=time.perf_counter(); root.evaluateProcedural(); masked_seconds=time.perf_counter()-start
    after=read_rows(root); write('placements.json',after); write('footprints.json',footprints)
    source_metrics=[]
    for i,spec in enumerate(specs):
        for source in spec[1]:
            b=bounds(source); poly=rt.getPolygonCount(source)
            source_metrics.append({'layer':i,'name':str(source.name),'triangles':int(poly[0]),'vertices':int(poly[1]),'min_cm':b[0],'max_cm':b[1]})
    write('source-metrics.json',source_metrics)
    stage('presentation')
    ground=rt.Plane(name='GROUND | display only',width=1400,length=1400,widthsegs=1,lengthsegs=1,pos=rt.Point3(0,0,-0.4))
    ground.material=rt.Standardmaterial(name='Garden soil',diffuse=rt.Color(81,69,46))
    rt.ambientColor=rt.Color(70,70,70); rt.backgroundColor=rt.Color(176,190,195)
    rt.Omnilight(name='Key',pos=rt.Point3(-350,-400,750),multiplier=1.1)
    rt.Omnilight(name='Fill',pos=rt.Point3(350,100,550),multiplier=0.5)
    aim=rt.Targetobject(name='CAMERA | aim',pos=rt.Point3(0,20,95))
    cam=rt.Targetcamera(name='CAMERA | Garden overview',pos=rt.Point3(490,-720,410),target=aim,fov=48)
    rt.viewport.setCamera(cam)
    rt.execute('CyrusPointSuspended=false')
    stage('retained display')
    start=time.perf_counter(); root.refreshDisplay(); rt.completeRedraw(); display_seconds=time.perf_counter()-start
    rt.select(controller)
    scene=OUT/'Cyrus_Garden_Baseline_Max2027.max'
    stage('save'); rt.saveMaxFile(str(scene),quiet=True)
    stats={'status':'baseline_saved','scene':str(scene),'scatter_version':str(root.version),
           'counts':[len(x['rows']) for x in after], 'requested':[s[3] for s in specs],
           'initial_placement_seconds':initial_seconds,'masked_placement_seconds':masked_seconds,
           'retained_display_seconds':display_seconds,'preview_errors':[str(x.previewError) for x in layers],
           'scope':'Existing Scatter plus STATIC convex-hull XY masks. No live mesh-rock contact or integrated bending.',
           'reference':'AI concept composition; geranium replaces absent white daisies.'}
    write('scene-report.json',stats)
    stage('capture diagnostic mesh preview')
    try:
        image=rt.gw.getViewportDib()
        image.filename=str(OUT/'garden-baseline-viewport.png'); rt.save(image); rt.close(image)
        stats.update(preview='garden-baseline-viewport.png',preview_style='Actual Scatter meshes, diagnostic layer colors; not a beauty render.')
    except Exception: stats['preview_error']=traceback.format_exc()
    process=rt.execute('(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()')
    stats.update(host_working_set_bytes=int(process.WorkingSet64),host_private_bytes=int(process.PrivateMemorySize64),host_peak_working_set_bytes=int(process.PeakWorkingSet64))
    write('scene-report.json',stats)
    write('completed.json',{'status':'complete','scene':str(scene)})

try: main()
except Exception: (OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
rt.quitMax(rt.Name('noPrompt'))
