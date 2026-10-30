"""Art-directed boulder pockets and a useful lake camera; original scene untouched."""
from pathlib import Path
import json,traceback,math
from pymxs import runtime as r
root=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun));data={}
try:
    before={int(r.getHandleByAnim(n)) for n in r.objects}
    r.mergeMAXFile(str(root/'Test Scene/Rock_Boulder_10/Rock_10.max'),r.Name('select'),r.Name('autoRenameDups'),r.Name('useSceneMtlDups'),quiet=True)
    imported=[n for n in r.geometry if int(r.getHandleByAnim(n)) not in before]
    data['imported']=[dict(name=str(n.name),faces=int(r.getPolygonCount(n)[0])) for n in imported]
    assert imported
    src=imported[0];src.name='SOURCE | ROCK10 | Lakeside boulder'
    lo,hi=r.nodeGetBoundingBox(src,r.matrix3(1));extent=hi-lo
    data['original_dimensions_cm']=[float(extent.x),float(extent.y),float(extent.z)]
    # Normalize the source's horizontal extent to a useful 2.4 m hero stone.
    scale=240/max(float(extent.x),float(extent.y))
    r.execute('global TCStoneSource,TCStoneController,TCPockets=#(),TCBoulderCamera')
    r.TCStoneSource=src
    src.pos=r.Point3(22000,21200,0);src.isHidden=True;src.renderable=False
    # Resolve only supplied stone maps, within this owned scene.
    for clsname in ['Bitmaptexture','CoronaBitmap']:
        cls=getattr(r,clsname,None)
        if cls is None:continue
        for tex in r.getClassInstances(cls):
            for prop in ['filename']:
                try:
                    old=str(r.getProperty(tex,r.Name(prop)));candidate=root/'Test Scene/Rock_Boulder_10'/Path(old).name
                    if candidate.is_file():r.setProperty(tex,r.Name(prop),str(candidate))
                except Exception:pass
    receiver=next(n for n in r.objects if str(n.name)=='PLANTING | 01 grass footprint')
    pockets=[]
    for i,(x,y) in enumerate([(-8700,-3500),(-7850,-3370),(-6600,-3200),(-5350,-2860),(-4100,-2640)]):
        hit=r.intersectRay(receiver,r.Ray(r.Point3(x,y,5000),r.Point3(0,0,-1)))
        if hit is None:continue
        plane=r.Plane(name='GARDEN receiver | boulder pocket '+str(i+1),length=220,width=300,lengthsegs=1,widthsegs=1,pos=hit.pos)
        plane.isHidden=True;plane.renderable=False;pockets.append(plane);r.append(r.TCPockets,plane)
    assert pockets,'No ground hits for the planned lake pockets'
    node=r.AminScatterObject(name='GARDEN | Lakeside boulders');r.TCStoneController=node;controller=node.baseObject
    controller.updateMode=1;controller.autoRender=False;controller.viewportMode=3;controller.identificationMode=4;controller.viewportFaces=1000000;controller.viewportNavigationFaces=500000
    for name,count,factor,targets in [('Hero boulder',1,1.,pockets[:1]),('Stone companions',8,.45,pockets),('Shore fragments',22,.18,pockets)]:
        controller.newLayer();leaf=controller.selectedLayer();controller.layerNames[-1]=name
        leaf.addModelSource(src);leaf.sourceScales=r.Array(scale*factor);leaf.amount=count;leaf.randomSeed=76120+count
        leaf.scaleMinimum=.7;leaf.scaleMaximum=1.3;controller.setLayerSurfaces(leaf,r.Array(*targets));leaf.autoRender=False
    controller.refreshAll();r.CyrusPointSync();r.append(r.GardenNodes,node)
    data['accepted']=[int(l.generatedCount) for l in controller.layerObjects]
    r.execute('''TCOverview=getNodeByName "GARDEN | 01 Terraced estate" exact:true;TCLake=getNodeByName "GARDEN | 02 Lake promenade" exact:true;TCHouse=getNodeByName "GARDEN | 03 Meadow and house" exact:true
    TCBoulderCamera=targetCamera name:"GARDEN | 04 Boulder garden" pos:[-9650,-4300,-700] target:(targetObject pos:[-7400,-3100,-750]) fov:55
    viewport.setCamera TCBoulderCamera;clearSelection();completeRedraw()''')
    b=r.gw.getViewportDib();b.filename=str(out/'garden-boulders.png');r.save(b);r.close(b)
    r.saveMaxFile(str(out.parent/'Terraces_Garden_Boulders.max'),quiet=True)
    data['pockets']=[dict(name=str(n.name),position=[float(v) for v in n.pos]) for n in pockets]
    data['status']='complete'
except Exception:data.update(status='failed',error=traceback.format_exc())
(out/'garden-boulders.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
