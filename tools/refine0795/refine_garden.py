"""Art direction after equal-scene benchmarking; preserved baseline remains untouched."""
from pathlib import Path
import sys,math,random,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('garden-refinement');rng=random.Random(7954)
def front(x,t):return t*590+100+130*math.sin((x+1450)/2400*math.pi)
try:
    root=r.getNodeByName('CYRUS | Terraced garden 0.79.5').baseObject
    receivers=list(root.layerObjects[0].validSurfaces())
    # Golden grass belongs in deliberate sweeps, white blooms in smaller pockets.
    for index in (1,2):
        leaf=root.layerObjects[index]
        for old in list(leaf.paintAreas):root.removePaintArea(leaf,old)
        leaf.amount=12000
        for tier,receiver in enumerate(receivers):
            area=root.addPaintArea(leaf,target=receiver);area.paintSetName=('Golden drift ' if index==1 else 'White flower pockets ')+str(tier+1)
            r.cyrusBrushSettings(area.paintDocument,110. if index==1 else 78.,False)
            coords=([(-1250+j*100,290+45*math.sin(j*.7)) for j in range(16)] if tier==1 else [(-1250,350),(-650,440),(120,360)]) if index==1 else [(-1400,460),(-1020,310),(-650,470),(-200,355),(220,470),(950,390)]
            for j,(x,offset) in enumerate(coords):
                r.cyrusBrushDab(area.paintDocument,pt(x,front(x,tier)+offset,1100),pt(0,0,-1),index==2 or tier!=1 or j==len(coords)-1)
            cfg=r.cyrusBrushFalloff(area.paintDocument);cfg[0]=20.;cfg[1]=18.;cfg[2]=True;cfg[3]=True;cfg[4]=.5;cfg[5]=1.;r.cyrusBrushSetFalloff(area.paintDocument,cfg)
    root.layerObjects[0].amount=25000;root.layerObjects[0].procSelfMultiplier=.67
    root.layerObjects[2].sourceScales=arr([.4,.31]);root.layerObjects[3].amount=4500
    leaf=root.layerObjects[4]
    for i in range(len(leaf.patternWidths)):leaf.patternWidths[i]=55.
    root.layerObjects[6].amount=19000
    rec.step('Publish intentional planting drifts',lambda:update(root))
    myrtle=r.getNodeByName('crp_MT_PM_V33_Myrtle_01_003');abelia=r.getNodeByName('crp_MT_PM_V33_Glossy_abelia_01_006')
    for i in range(44):
        n=r.instance(myrtle if i%3 else abelia);n.name='BACKGROUND | mixed evergreen enclosure'
        s=rng.uniform(1.0,1.7);n.scale=pt(s,s,s);n.pos=pt(-1750+i*70,2130+rng.uniform(-60,100),270);n.renderable=True;r.unhide(n)
        layer=r.LayerManager.getLayerFromName('03 Trees and rocks');layer.addNode(n)
    for n in list(r.objects):
        if str(n.name).startswith('TREE | adapted'):
            n.scale=n.scale*1.25
        if str(n.name).startswith('WALL |') and r.isProperty(n,'material') and n.material:
            material=n.material
            if r.isProperty(material,'baseColor'):
                color=material.baseColor;material.baseColor=r.color(100,91,75)
                if not material.baseTexmapOn:
                    material.baseTexmap=r.Noise(size=3.0,color1=r.color(67,63,54),color2=r.color(143,130,107));material.baseTexmapOn=True
    camera=r.getNodeByName('01 HERO | Terraced garden');camera.pos=pt(650,-1150,1600);camera.target.pos=pt(-310,1130,180);camera.fov=48.
    r.viewport.setCamera(camera);root.setGroupDisplay(4);r.clearSelection();r.CyrusPointSync();r.completeRedraw()
    rec.step('Save refined landscape',lambda:r.saveMaxFile(str(OUT/'Terraced_Garden_Refined.max'),quiet=True),redraw=False)
    rec.data['final']=state();rec.write()
except Exception:rec.error(traceback.format_exc())
