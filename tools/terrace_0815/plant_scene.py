"""Build editable Cyrus planting on the measured terrace copy and render a draft."""
from pathlib import Path
import json,time,traceback,math,random
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve();SCENES=ROOT/'Test Scene/Terraces_0815'
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-candidate')
data={'status':'started','steps':[],'layers':[]};run=1
while (OUT/('plant-scene-%02d.json'%run)).exists():run+=1
REPORT=OUT/('plant-scene-%02d.json'%run);rng=random.Random(815)
def save():REPORT.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def arr(v):return r.Array(*v)
def pt(*v):return r.Point3(*map(float,v))
def group(n,name):
    layer=r.LayerManager.getLayerFromName(name)
    if layer is None:layer=r.LayerManager.newLayerFromName(name)
    layer.addNode(n);return n
def step(label,fn):
    data['status']=label;save();t=time.perf_counter();res=fn();data['steps'].append({'label':label,'seconds':time.perf_counter()-t});save();return res
def material(name,color):return r.CoronaPhysicalMtl(name=name,baseColor=r.color(*color),baseRoughness=.85)
def clone_asset(original,name,color=None):
    n=r.copy(r.getNodeByName(original));n.name=name;n.parent=None;n.renderable=False;r.hide(n);group(n,'08 Cyrus source palettes')
    if color is not None:
        n.material=r.copy(n.material)
        for j in range(1,int(r.getNumSubMtls(n.material))+1):
            old=r.getSubMtl(n.material,j)
            if old is not None and ('flower' in str(old.name).lower() or 'petal' in str(old.name).lower()):
                m=r.copy(old);m.name=name+' | petals '+str(j)
                if r.isProperty(m,r.Name('baseColor')):
                    m.baseColor=r.color(*color);m.baseTexmapOn=False
                elif r.isProperty(m,r.Name('colorDiffuse')):
                    m.colorDiffuse=r.color(*color);m.texmapOnDiffuse=False
                else:raise RuntimeError('Unrecognized flower material '+str(m))
                r.setSubMtl(n.material,j,m)
    return n
try:
    r.CyrusPerfHeadless=True;r.clearSelection();r.loadMaxFile(str(SCENES/'Terraces_0815_Assets.max'),quiet=True,useFileUnits=True)
    old=r.getNodeByName('Cyrus Scatter001');old.baseObject.cyrusEnabled=False;old.baseObject.autoRender=False;old.name='BASELINE | original Scatter settings (disabled)'
    for n in list(r.objects):
        name=str(n.name)
        if name.startswith(('grass','leaf','clover','crp_','MT_PM_','tree','trees','palm','CGt_','GrowFX','stone01','soil')):
            n.renderable=False;r.hide(n);group(n,'09 Preserved original source models')
        if str(r.classOf(n.baseObject))=='CyrusSourceContainer':n.collectEnabled=False;group(n,'09 Preserved original source models')
    layout=json.loads((OUT/'planting-zones.json').read_text());receivers={}
    for zone in layout['zones']:
        n=r.mesh(name=zone['name'],vertices=arr([pt(*p) for p in zone['vertices']]),faces=arr([pt(*f) for f in zone['faces']]))
        n.renderable=False;r.hide(n);group(n,'06 Editable planting receivers')
        r.setUserProp(n,'TerraceOriginalSurface',zone['original']);r.setUserProp(n,'TerracePlantingAreaM2',zone['area_m2'])
        uv=r.UVWMap(maptype=0,width=1000.,length=1000.,mapChannel=1);r.addModifier(n,uv)
        receivers.setdefault(zone['kind'],[]).append(n)
    data['receiver_count']={k:len(v) for k,v in receivers.items()};save()
    # Ground underneath the planting and all curved walls receive material detail.
    turf=material('Terraces | deep green turf',(31,44,14));turf.baseTexmap=r.Noise(size=28,color1=r.color(17,29,7),color2=r.color(60,65,24));turf.baseTexmapOn=True
    stone=material('Terraces | rough mossy retaining stone',(45,43,29));stone.baseTexmap=r.Noise(size=60,color1=r.color(18,23,12),color2=r.color(80,70,45));stone.baseTexmapOn=True
    stone.baseBumpTexmap=r.Noise(size=7,color1=r.color(0,0,0),color2=r.color(255,255,255));stone.baseBumpTexmapOn=True;stone.baseBumpMapAmount=2
    for n in list(r.objects):
        if str(n.name).startswith('surf_'):n.material=turf
        if str(n.name).startswith(('spl_terrace_','coastal_cliff','rock-')):n.material=stone
    stepmats=[material('Path | weathered limestone '+str(i),(97+i*7,91+i*7,72+i*6)) for i in range(5)]
    for i,(x,y,z,a) in enumerate(layout['steps']):
        n=r.chamferbox(name='PATH | stepping stone %02d'%i,width=rng.uniform(105,145),length=rng.uniform(44,60),height=rng.uniform(8,13),fillet=3,filletSegments=2,pos=pt(x,y,z),material=stepmats[i%5])
        n.rotation=r.eulerAngles(rng.uniform(-2,2),rng.uniform(-2,2),a+rng.uniform(-8,8));group(n,'03 Garden stepping stones')
    path=r.splineShape(name='EXCLUDE | stepping path clearance');r.addNewSpline(path)
    for p in layout['path_outline']:r.addKnot(path,1,r.Name('corner'),r.Name('line'),pt(*p))
    r.close(path,1);r.updateShape(path);path.renderable=False;r.hide(path);group(path,'05 Editable planting guides')
    assets={
      'grass':[r.getNodeByName('grass_bush'),r.getNodeByName('grass_small'),r.getNodeByName('clover_pack_004')],
      'white':[clone_asset('crp_MT_PM_Rosa_rugosa_01_02','SOURCE | ivory terrace rose',(235,219,195)),clone_asset('MT_PM_V41_Arthropodium_01_01','SOURCE | white meadow lily')],
      'pink':[clone_asset('crp_Lavander_01','SOURCE | rose lavender',(173,77,83)),clone_asset('crp_Lavander_05','SOURCE | copper lavender',(148,65,53))],
      'yellow':[clone_asset('MT_PM_V41_Viola_sororia_01_05','SOURCE | golden woodland flowers',(233,180,43)),clone_asset('MT_PM_V41_Phlox_stolonifera_01_01','SOURCE | pale gold flower carpet',(235,203,92))],
      'shrubs':[r.getNodeByName('crp_MT_PM_V33_Myrtle_01_003'),r.getNodeByName('crp_MT_PM_V33_Glossy_abelia_01_006')],
      'palms':[r.getNodeByName('palm tree')],
      'trees':[r.getNodeByName('CGt_02_Acer platanoides-3'),r.getNodeByName('GrowFX001')]
    }
    if any(n is None for items in assets.values() for n in items):raise RuntimeError('A planting asset is unavailable')
    node=r.AminScatterObject(name='CYRUS | Terrace planting 0.81.5',pos=pt(-10000,9000,0));group(node,'01 Cyrus landscape controller')
    root=node.baseObject;root.updateMode=1;root.autoRender=False;root.previewBudget=70000;root.viewportInstances=3000;root.viewportFaces=2000000;root.pointsPerPlant=20;root.setGroupDisplay(1)
    specs=[('grass','01 Grass and clover matrix',220000,[3.3,3.8,6.],[0,0,0],[.5,.35,.15]),
           ('white','02 Ivory rose drifts',6000,[1.05,.65],[35,25],[.85,.15]),
           ('pink','03 Warm lavender ribbons',9000,[.8,.65],[25,26],[.55,.45]),
           ('yellow','04 Golden flower carpet',23000,[3.,3.2],[15,15],[.55,.45]),
           ('shrubs','05 Evergreen structure',900,[1.15,.65],[70,80],[.8,.2]),
           ('palms','06 Palm accents',220,[5.0],[105],[1.]),
           ('trees','07 Framing deciduous trees',120,[2.8,1.1],[500,500],[1.,0.]),
           ('background','08 Woodland backdrop',1000,[3.8,1.2],[330,400],[.65,.35])]
    palettes={};leaves=[]
    for index,(kind,label,count,scales,radii,weights) in enumerate(specs):
        root.newLayer();leaf=root.selectedLayer();leaves.append(leaf);root.layerNames[index]=label
        root.setLayerSurfaces(leaf,arr(receivers[kind]));models=assets['trees' if kind=='background' else kind]
        leaf.sources=arr(models);leaf.sourceScales=arr(scales);leaf.sourceWeights=arr(weights);leaf.sourceRadiiWU=arr(radii)
        leaf.amount=count;leaf.populationMode=1;leaf.distributionMode=1;leaf.randomSeed=815+index*103
        leaf.wholeScaleMin=.8;leaf.wholeScaleMax=1.2;leaf.alignNormal=kind not in ('trees','background','palms')
        leaf.procSelfOverride=True;leaf.procSelfEnabled=kind!='grass';leaf.procSelfMultiplier=.75;leaf.procSelfGap=0
        leaf.diversityMode=2 if kind in ('grass','white','pink','yellow') else 1;leaf.diversitySize=220.;leaf.diversitySeed=31+index
        if kind!='background':
            x=26000+index*2300;y=24000
            for j,n in enumerate(models):
                n.pos=pt(x+(j-(len(models)-1)/2)*500,y,0);n.renderable=False;r.hide(n);group(n,'08 Cyrus source palettes')
            rectangle=leaf.containerCreate(globalPool=kind=='trees');rectangle.width=max(800,len(models)*600);rectangle.length=1000.;rectangle.pos=pt(x,y,0)
            rectangle.name='CS PALETTE | '+label;rectangle.collectEnabled=True;group(rectangle,'08 Cyrus source palettes');palettes[kind]=rectangle
        leaf.containerMode=3 if kind in ('trees','background') else 4
        # Keep the path editable as an explicit shared exclusion as well as a bed boundary.
        leaf.areaNodes=arr([path]);leaf.areaModes=arr([2])
        leaf.markInputDirty()
    r.CyrusContainerRefreshAll()
    step('Publish complete eight-layer landscape',root.refreshAll)
    for i,l in enumerate(root.layerObjects):
        data['layers'].append({'name':str(root.layerNames[i]),'amount':int(l.amount),'generated':int(l.generatedCount),'sources':[str(n.name) for n in l.validSources()],'error':str(l.previewError),'fingerprint':str(r.cyrusEditFingerprint(root.groupSnapshotRows[i],'terrace815'))})
    save()
    if any(row['error'] for row in data['layers']):raise RuntimeError(str(data['layers']))
    if data['layers'][0]['generated']<=100000:raise RuntimeError('Ground cover did not cross the former cap')
    camera=r.getNodeByName('PhysCamera002');r.viewport.setCamera(camera);r.renderWidth=960;r.renderHeight=540;r.renderers.current.progressive_passLimit=4
    root.autoRender=True;r.CyrusPerfHeadless=False;r.CyrusPointSync();r.clearSelection();r.completeRedraw()
    step('Save planting draft',lambda:r.saveMaxFile(str(SCENES/'Terraces_0815_Planting_01.max'),quiet=True))
    bitmap=step('Render PhysCamera002 planting draft',lambda:r.render(camera=camera,vfb=False,outputfile=str(SCENES/'Terraces_0815_Planting_01.png')))
    r.close(bitmap);data['render_error']=str(r.CyrusPFLastError);data['render_bridge_builds']=int(r.CyrusPFBuilds)
    if data['render_error']:raise RuntimeError(data['render_error'])
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])
