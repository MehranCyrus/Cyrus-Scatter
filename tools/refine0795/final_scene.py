"""Final art pass and editable delivery copy; never overwrites an artist original."""
from pathlib import Path
import sys, random, traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('final-scene');rng=random.Random(7955)
try:
    root=r.getNodeByName('CYRUS | Terraced garden 0.79.5').baseObject
    # Broader tussocks read as a coherent drift in the middle terrace.
    root.layerObjects[1].sourceScales=arr([1.65]);root.layerObjects[1].sourceRadii=arr([23.])
    root.layerObjects[1].densityMap=None;root.layerObjects[1].amount=20000
    root.layerObjects[2].densityMap=None;root.layerObjects[2].amount=20000
    rec.step('Refine grass and flower density',lambda:update(root))
    base=r.getNodeByName('GROUND | garden setting');base.width=15000.;base.length=15000.
    myrtle=r.getNodeByName('crp_MT_PM_V33_Myrtle_01_003')
    for row in range(2):
        for i in range(24):
            n=r.instance(myrtle);n.name='BACKGROUND | canopy enclosure'
            s=rng.uniform(2.3,3.5);n.scale=pt(s,s,s);n.pos=pt(-1900+i*165,2380+row*240,270)
            n.renderable=True;r.unhide(n);r.LayerManager.getLayerFromName('03 Trees and rocks').addNode(n)
    sun=r.getNodeByName('LIGHT | warm afternoon');sun.pos=pt(-1000,-400,5800);sun.sizeMultiplier=12.
    mx('local op=renderers.current.colorMap_pipeline;while op!=undefined do (if isProperty op #colorMappingOperator_simpleExposure do op.colorMappingOperator_simpleExposure=-2.6;op=op.colorMappingOperator_nextOperator)')
    camera=r.getNodeByName('01 HERO | Terraced garden');camera.pos=pt(600,-1060,1590);camera.target.pos=pt(-300,1030,150);camera.fov=46.
    r.viewport.setCamera(camera);r.renderWidth=1600;r.renderHeight=900;r.renderers.current.progressive_passLimit=15
    r.clearSelection();r.CyrusPointSync();r.completeRedraw()
    target=ROOT/'Test Scene/Terraced_Garden_0795';target.mkdir(exist_ok=False)
    rec.step('Save new artist scene',lambda:r.saveMaxFile(str(target/'Terraced_Garden_0795.max'),quiet=True),redraw=False)
    rec.data['scene']=str(target/'Terraced_Garden_0795.max');rec.data['final']=state();rec.write()
    fp=fingerprint(root)
    rec.step('Reopen final delivered scene',lambda:r.loadMaxFile(str(target/'Terraced_Garden_0795.max'),quiet=True,useFileUnits=True),redraw=False)
    root=r.getNodeByName('CYRUS | Terraced garden 0.79.5').baseObject;root.refreshAll()
    rec.check(fingerprint(root)==fp,'Final delivered scene restores exact placement fingerprints')
    rec.data['layers']=[dict(name=str(root.layerNames[i]),accepted=int(l.generatedCount),paint_areas=len(l.paintAreas),layout=int(l.diversityMode)) for i,l in enumerate(root.layerObjects)];rec.write()
except Exception:rec.error(traceback.format_exc())
