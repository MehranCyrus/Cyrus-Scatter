"""Construct a new terraced landscape using real Scatter layers and library assets."""
from pathlib import Path
import sys,math,random,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('garden-build');rng=random.Random(795)

def group(node,name):
    layer=r.LayerManager.getLayerFromName(name)
    if layer is None:layer=r.LayerManager.newLayerFromName(name)
    layer.addNode(node);return node
def mat(name,color,rough=.8):return r.CoronaPhysicalMtl(name=name,baseColor=r.color(*color),baseRoughness=rough)
def curve(name,points):
    node=r.splineShape(name=name);r.addNewSpline(node)
    for p in points:r.addKnot(node,1,r.Name('corner'),r.Name('line'),pt(*p))
    r.close(node,1);r.updateShape(node);node.renderable=False
    return group(node,'04 Editable planting guides')
def mesh(name,vertices,faces,material,category='01 Terraces and steps'):
    return group(r.mesh(name=name,vertices=arr([pt(*p) for p in vertices]),faces=arr([pt(*f) for f in faces]),material=material),category)
def block(name,p,w,d,h,material,angle=0):
    n=r.chamferbox(name=name,width=w,length=d,height=h,fillet=1.1,filletSegments=1,pos=pt(*p),material=material)
    n.rotation=r.eulerangles(0,0,angle);return group(n,'01 Terraces and steps')
def yfront(x,tier):return tier*590+100+130*math.sin((x+1450)/2400*math.pi)
def pathx(y):return 550+150*math.sin(y/680)
def level(y):
    # Landings rise by 90 cm; seven short risers join each planting level.
    for tier in range(3):
        base=yfront(pathx(y),tier)
        if y<base-175:return tier*90
        if y<base:return tier*90+min(7,max(0,int((y-(base-175))/25)+1))*90/7
    return 270

try:
    r.CyrusStopBrush();r.resetMaxFile(r.Name('noPrompt'))
    r.loadMaxFile(str(ROOT/'Test Scene/Reference_Garden_075/Source_Plants.max'),quiet=True,useFileUnits=True)
    centimetre=float(r.units.decodeValue('1cm'))
    r.rescaleWorldUnits(1/centimetre)
    r.units.SystemType=r.Name('Centimeters');r.units.SystemScale=1;r.units.DisplayType=r.Name('Metric');r.units.MetricType=r.Name('Meters')
    names=['crp_MT_PM_V33_Myrtle_01_003','crp_MT_PM_Rosa_rugosa_01_02','crp_MT_PM_Sambucus_nigra_02_01',
        'MT_PM_V41_Arthropodium_01_01','MT_PM_V41_Arthropodium_01_04','crp_Lavander_01','crp_Lavander_05',
        'crp_MT_PM_V33_Glossy_abelia_01_006','MT_PM_V41_Geranium_robertianum_01_04','MT_PM_V41_Lamium_maculatum_01_04',
        'MT_PM_V41_Phlox_stolonifera_01_01','MT_PM_V41_Viola_sororia_01_05','clover_pack_004','grass_bush','grass_small']
    sources=[r.getNodeByName(name) for name in names]
    rec.check(all(r.isValidNode(n) for n in sources),'All 15 preserved library sources available')
    for i,n in enumerate(sources):
        n.pos=pt(4500+(i%5)*260,(i//5)*300);n.renderable=False;group(n,'07 Source library');r.hide(n)
    soil=mat('Terrace | cultivated earth',(54,45,31));gravel=mat('Path | limestone gravel',(157,144,120))
    gravel.baseTexmap=r.Noise(size=.65,color1=r.color(101,93,78),color2=r.color(195,183,157));gravel.baseTexmapOn=True
    stones=[mat('Limestone '+str(i),(161+i*4,150+i*4,127+i*4)) for i in range(7)]
    bark=mat('Olive-like tree | textured bark',(71,66,47));gold=mat('Stipa | warm dry blades',(161,128,66))
    receivers=[];borders=[]
    r.disableSceneRedraw()
    try:
        for tier in range(3):
            vertices=[];faces=[]
            for j in range(9):
                for i in range(61):
                    x=-1550+2600*i/60;y=yfront(x,tier)+30+j*525/8
                    z=(tier+1)*90+(8*math.sin(i*.14)*math.sin(j*math.pi/8) if tier==1 else 0)
                    vertices.append((x,y,z))
            for j in range(8):
                for i in range(60):
                    a=j*61+i+1;faces.extend([(a,a+1,a+62),(a,a+62,a+61)])
            receivers.append(mesh('RECEIVER | terrace '+str(tier+1),vertices,faces,soil))
            outline=[vertices[i] for i in range(61)]+[vertices[8*61+i] for i in range(60,-1,-1)]
            borders.append(curve('INCLUDE + BAND | terrace '+str(tier+1),outline))
            # Individual masonry courses reveal the curve without a monolithic wall.
            for course in range(6):
                for i in range(62):
                    x=-1530+i*42+(course%2)*21;y=yfront(x,tier)
                    if abs(x-pathx(y))<110:continue
                    dy=130*math.pi/2400*math.cos((x+1450)/2400*math.pi)
                    block('WALL | limestone block',(x,y,tier*90+course*15),40,38,14,stones[rng.randrange(7)],math.degrees(math.atan(dy)))
            for i in range(53):
                x=-1530+i*49;y=yfront(x,tier)
                if abs(x-pathx(y))>115:block('WALL | coping',(x,y,(tier+1)*90),48,46,8,stones[4],math.degrees(math.atan(130*math.pi/2400*math.cos((x+1450)/2400*math.pi))))
        ys=[-200+i*25 for i in range(94)]
        pathpoints=[(pathx(y)-105,y,0) for y in ys]+[(pathx(y)+105,y,0) for y in reversed(ys)]
        pathguide=curve('EXCLUDE | stair and path clearance',pathpoints)
        for y in ys[:-1]:
            h=level(y);block('PATH | gravel landing',(pathx(y),y+12.5,h-6),208,26,6,gravel)
            if abs(level(y+25)-h)>1:block('STAIR | limestone tread',(pathx(y+25),y+23,level(y+25)-13),212,29,13,stones[5])
        base=r.plane(name='GROUND | garden setting',width=4200,length=3600,pos=pt(-150,1100,-10),material=soil);group(base,'01 Terraces and steps')
        # A small efficient source supplements the library's low ground grasses.
        verts=[];faces=[]
        for k in range(90):
            a=rng.uniform(0,2*math.pi);reach=rng.uniform(16,47);height=rng.uniform(40,92)
            ox=rng.uniform(-8,8);oy=rng.uniform(-8,8);start=len(verts)+1
            for j in range(5):
                t=j/4;cx=ox+math.cos(a)*reach*t*t;cy=oy+math.sin(a)*reach*t*t;z=height*(t-.18*t*t);w=(1-t)*.7+.06
                verts.extend([(cx-math.sin(a)*w,cy+math.cos(a)*w,z),(cx+math.sin(a)*w,cy-math.cos(a)*w,z)])
            for j in range(4):
                v=start+j*2;faces.extend([(v,v+1,v+2),(v+1,v+3,v+2)])
        grass=mesh('SOURCE | golden ornamental grass',verts,faces,gold,'07 Source library');grass.pos=pt(5900,0);grass.renderable=False;r.hide(grass)
        for x,y,tier,size in [(-1320,540,0,1),(-300,1570,2,1.2),(-1150,1810,2,1.25),(1030,1450,2,1.0)]:
            z=(tier+1)*90
            trunk=r.cone(name='TREE | branching trunk',radius1=12*size,radius2=5*size,height=280*size,sides=12,pos=pt(x,y,z),material=bark);group(trunk,'03 Trees and rocks')
            for k in range(6):
                a=k*math.pi/3;tip=pt(x+95*math.cos(a)*size,y+80*math.sin(a)*size,z+300*size)
                limb=r.cone(name='TREE | branch',radius1=6,radius2=2,height=float(r.distance(pt(x,y,z+120),tip)),pos=pt(x,y,z+120),dir=r.normalize(tip-pt(x,y,z+120)),material=bark,sides=8);group(limb,'03 Trees and rocks')
                canopy=r.instance(sources[0]);canopy.name='TREE | adapted myrtle canopy';canopy.scale=pt(1.6*size,1.6*size,1.35*size);canopy.pos=tip;canopy.renderable=True;r.unhide(canopy);group(canopy,'03 Trees and rocks')
        for x,y,z in [(930,370,90),(820,1080,180),(910,1920,270)]:
            n=r.instance(sources[0]);n.name='ACCENT | columnar evergreen';n.scale=pt(.6,.6,3.2);n.pos=pt(x,y,z);n.renderable=True;r.unhide(n);group(n,'03 Trees and rocks')
        for i in range(12):
            y=60+i*167;x=pathx(y)+(145 if i%2 else -150)
            n=r.geosphere(name='ROCK | path edge',radius=rng.uniform(30,57),segs=2,pos=pt(x,y,level(y)+20),material=stones[i%7]);n.scale=pt(.7,1,1.15);n.rotation=r.eulerangles(10,20,i*37);group(n,'03 Trees and rocks')
    finally:r.enableSceneRedraw()
    node=rec.step('Create landscape Scatter',lambda:r.AminScatterObject(name='CYRUS | Terraced garden 0.79.5',pos=pt(-1800,0)))
    root=node.baseObject;root.updateMode=1;root.autoRender=True;root.viewportInstances=8000;root.viewportFaces=2000000;root.previewBudget=160000;root.setGroupDisplay(4)
    specs=[('01 Lavender painted ribbons',[sources[5],sources[6]],10000,[.65,.52],[36,34],1),
        ('02 Golden grass drifts',[grass],6500,[1.05],[30],2),
        ('03 White flower matrix',[sources[3],sources[4]],7000,[.48,.37],[32,35],2),
        ('04 Evergreen structure',[sources[0],sources[7]],1800,[.8,.65],[60,63],2),
        ('05 Spline edge flowers',[sources[10],sources[9]],12000,[2.4,2.4],[14,14],3),
        ('06 Painted pink accents',[sources[1],sources[8]],6000,[.7,2.8],[37,17],1),
        ('07 Ground cover',[sources[12],sources[14]],15000,[3.0,2.4],[9,10],1)]
    leaves=[]
    for i,(name,models,amount,scales,radii,mode) in enumerate(specs):
        rec.step('Add '+name,root.newLayer);leaf=root.selectedLayer();leaves.append(leaf);root.layerNames[i]=name
        root.setLayerSurfaces(leaf,arr(receivers));leaf.sources=arr(models);leaf.sourceScales=arr(scales);leaf.sourceRadii=arr(radii);leaf.sourceWeights=arr([1.]*len(models))
        leaf.amount=amount;leaf.randomSeed=795+i*71;leaf.diversityMode=mode;leaf.diversitySize=230.;leaf.wholeScaleMin=.8;leaf.wholeScaleMax=1.2
        leaf.procSelfOverride=True;leaf.procSelfEnabled=True;leaf.procSelfMultiplier=.85;leaf.procSelfGap=3.;leaf.alignNormal=True
        leaf.areaNodes=arr(borders+[pathguide]);leaf.areaModes=arr([1,1,1,2])
        if i in (1,2):
            leaf.densityMap=r.Noise(size=190,color1=r.color(0,0,0),color2=r.color(255,255,255));leaf.invertDensity=i==2
        if i==4:
            for border in borders:
                leaf.addStroke(border,side=2);k=len(leaf.patternWidths);leaf.patternWidths[k-1]=95.;leaf.strokeModes[k-1]=2;leaf.setStrokeSelection(k,2,arr(models));leaf.strokeMin[k-1]=.6;leaf.strokeMax[k-1]=1.1
        if i in (0,5):
            for tier,receiver in enumerate(receivers):
                area=root.addPaintArea(leaf,target=receiver);area.paintSetName=('Lavender sweep ' if i==0 else 'Rose pocket ')+str(tier+1)
                r.cyrusBrushSettings(area.paintDocument,95. if i==0 else 110.,False)
                for j in range(16 if i==0 else 4):
                    x=(-1400+j*110) if i==0 else (-1000+j*480)
                    y=yfront(x,tier)+(175+45*math.sin(j*.7) if i==0 else 420)
                    r.cyrusBrushDab(area.paintDocument,pt(x,y,1000),pt(0,0,-1),j==(15 if i==0 else 3))
                cfg=r.cyrusBrushFalloff(area.paintDocument);cfg[0]=25.;cfg[1]=20.;cfg[2]=True;cfg[3]=True;cfg[4]=.35;cfg[5]=1.;r.cyrusBrushSetFalloff(area.paintDocument,cfg)
        leaf.setFallConfig(pathguide,arr([True,18.,True,90.,arr([.4,1.]),True,70.,arr([0.,1.])]))
        rec.step('Publish '+name,lambda:update(root))
    # Analyzer uses a real elevated receiver; its boundary supplies a distinct row.
    analyzer=r.CyrusSurfaceAnalyzer(name='ANALYZER | upper terrace edge',surface=receivers[2]);analyzer.updateMode=1;analyzer.resolution=64;analyzer.relaxIterations=0
    rec.step('Analyze upper terrace',analyzer.runAnalysis)
    rec.step('Add Analyzer edging layer',root.newLayer);leaf=root.selectedLayer();root.layerNames[7]='08 Analyzer edging';root.setLayerSurfaces(leaf,arr([receivers[2]]))
    leaf.sources=arr([sources[10]]);leaf.sourceScales=arr([1.5]);leaf.sourceRadii=arr([8.]);leaf.amount=3000;leaf.diversityMode=4;leaf.analyzerNode=analyzer
    leaf.addStroke(analyzer,side=7);leaf.patternWidths[0]=24.;leaf.edgeOffsets[0]=25.;leaf.edgeAlong[0]=30.;leaf.edgeAcross[0]=1;leaf.strokeModes[0]=2;leaf.setStrokeSelection(1,2,arr([sources[10]]))
    leaf.areaNodes=arr([pathguide]);leaf.areaModes=arr([2]);rec.step('Publish Analyzer row',lambda:update(root))
    for a,b in [(0,1),(0,2),(3,0),(3,2),(5,2)]:root.procSetPair(2,leaves[a],leaves[b],True,.45,2.,True)
    rec.step('Publish inter-layer spacing',lambda:update(root))
    r.renderers.current=r.Corona();r.renderers.current.system_numThreads=12;r.renderers.current.progressive_passLimit=5;r.renderers.current.denoise_filterType=2;r.renderers.current.renderstamp_use=False
    sun=r.CoronaSun(name='LIGHT | warm afternoon');sun.targeted=True;sun.target.pos=pt(0,1000,0);sun.pos=pt(-2500,-2000,4000);sun.sizeMultiplier=4.;sun.intensity=.8
    sky=r.CoronaSky();sky.selectedSun=sun;sky.sunSelectionMode=1;r.environmentMap=sky;r.useEnvironmentMap=True
    mx('local op=renderers.current.colorMap_pipeline;while op!=undefined do (if classof op==AcesOtOperatorPlugin do op.colorMappingOperator_enabled=true;if isProperty op #colorMappingOperator_simpleExposure do op.colorMappingOperator_simpleExposure=-3.0;op=op.colorMappingOperator_nextOperator)')
    camera=r.TargetCamera(name='01 HERO | Terraced garden',pos=pt(200,-2300,2550),target=r.Targetobject(pos=pt(-160,980,130)),fov=55.)
    r.TargetCamera(name='02 OVERVIEW | planting layout',pos=pt(0,900,4500),target=r.Targetobject(pos=pt(0,901,0)),fov=51.)
    r.renderWidth=1280;r.renderHeight=720;r.viewport.setLayout(r.Name('layout_1'));r.viewport.setCamera(camera)
    rec.step('Final point preview',lambda:r.clearSelection())
    rec.step('Save editable terraced scene',lambda:r.saveMaxFile(str(OUT/'Terraced_Garden.max'),quiet=True),redraw=False)
    rec.data['final']=state();rec.write()
except Exception:rec.error(traceback.format_exc())
