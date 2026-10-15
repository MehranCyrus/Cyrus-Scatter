"""Add foreground rose pockets, a dense woodland backdrop and restrained warm haze."""
from pathlib import Path
import json,time,traceback,math
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve();SCENES=ROOT/'Test Scene/Terraces_0815'
assert OUT.name.startswith('foundation-terrace0815-candidate2027-')
data={'status':'started'};report=OUT/'polish-04.json'
def save():report.write_text(json.dumps(data,indent=2)+'\n')
def arr(v):return r.Array(*v)
def group(n,name):
    layer=r.LayerManager.getLayerFromName(name)
    if layer is None:layer=r.LayerManager.newLayerFromName(name)
    layer.addNode(n);return n
def pt(x,y,z):return r.Point3(float(x),float(y),float(z))
try:
    r.CyrusPerfHeadless=True;root=r.getNodeByName('CYRUS | Terrace planting 0.81.5').baseObject;root.autoRender=False
    camera=r.getNodeByName('PhysCamera002');tm=camera.transform;forward=-tm.row3;right=tm.row1
    for n in list(r.objects):
        if str(n.name) in ['msh_water_surface','spl_water_master','spl-exclude-midground']:n.renderable=False
    background=root.layerObjects[7]
    root.setLayerSurfaces(background,arr([r.getNodeByName('PLANTING | 11 grass footprint')]))
    background.amount=5000;background.sourceRadiiWU=arr([340.,440.]);background.sourceScales=arr([4.0,1.3]);background.markInputDirty()
    frame=root.layerObjects[6]
    for n in frame.validSurfaces():
        box=r.nodeGetBoundingBox(n,r.matrix3(1));center=(box[0]+box[1])*.5;lateral=float(r.dot(center-tm.row4,right))
        if float(r.dot(center-tm.row4,forward))<3000:n.pos+=right*(-.3*lateral)
    frame.markInputDirty();root.layerObjects[5].sourceScales=arr([5.])
    # Put the actual stepping stones visibly above the original ground.
    stones=[]
    for n in r.objects:
        if str(n.name).startswith('PATH | stepping stone'):
            n.renderable=True;r.unhide(n);stones.append(n)
    data['stepping_stones']=len(stones)
    foreground=r.getNodeByName('surf_foreground');beds=[]
    for i,(depth,lateral,radius) in enumerate([(900,-230,190),(1350,-440,230),(1900,540,210),(2700,780,220)]):
        center=tm.row4+forward*depth+right*lateral;hit=r.intersectRay(foreground,r.ray(pt(center.x,center.y,5000),pt(0,0,-1)))
        if hit is None:continue
        vertices=[pt(center.x,center.y,hit.pos.z)]
        for k in range(16):vertices.append(pt(center.x+radius*math.cos(k*math.pi/8),center.y+radius*math.sin(k*math.pi/8),hit.pos.z))
        faces=[pt(1,k+2,(k+1)%16+2) for k in range(16)]
        n=r.mesh(name='PLANTING | foreground rose pocket %02d'%i,vertices=arr(vertices),faces=arr(faces));n.renderable=False;r.hide(n);group(n,'06 Editable planting receivers');beds.append(n)
    root.newLayer();l=root.selectedLayer();root.layerNames[len(root.layerObjects)-1]='09 Foreground ivory roses'
    root.setLayerSurfaces(l,arr(beds));l.sources=arr([r.getNodeByName('SOURCE | ivory terrace rose')]);l.sourceScales=arr([1.25]);l.sourceRadiiWU=arr([40.]);l.sourceWeights=arr([1.])
    l.containerMode=1;l.amount=400;l.procSelfOverride=True;l.procSelfEnabled=True;l.procSelfMultiplier=.75;l.wholeScaleMin=.85;l.wholeScaleMax=1.2
    l.areaNodes=arr([r.getNodeByName('EXCLUDE | stepping path clearance')]);l.areaModes=arr([2])
    root.refreshAll();data['layers']=[{'name':str(root.layerNames[i]),'count':int(l.generatedCount),'error':str(l.previewError)} for i,l in enumerate(root.layerObjects)]
    if any(l['error'] for l in data['layers']):raise RuntimeError(str(data['layers']))
    haze=r.CoronaVolumeMtl(name='Terraces | warm distance haze',absorptionColor=r.color(190,190,190),absorptionDist=25000.,scatteringColor=r.color(100,91,73),scatteringDirectionality=.25,singleBounce=True)
    r.renderers.current.globalVolumeMtl=haze;r.renderers.current.globalVolumeMtl_use=True
    op=r.renderers.current.colorMap_pipeline
    while op is not None:
        if r.isProperty(op,r.Name('colorMappingOperator_colorTemperature')):op.colorMappingOperator_colorTemperature=7600
        if r.isProperty(op,r.Name('colorMappingOperator_simpleExposure')):op.colorMappingOperator_simpleExposure=-2.3
        op=op.colorMappingOperator_nextOperator
    root.autoRender=True;r.CyrusPerfHeadless=False;r.CyrusPointSync();r.clearSelection();r.completeRedraw()
    r.renderWidth=1100;r.renderHeight=619;r.renderers.current.progressive_passLimit=6
    data['status']='saving';save();r.saveMaxFile(str(SCENES/'Terraces_0815_Planting_04.max'),quiet=True)
    data['status']='rendering';save();start=time.perf_counter()
    frame=r.render(camera=camera,vfb=False,outputfile=str(SCENES/'Terraces_0815_Planting_04.png'));r.close(frame)
    data['render_seconds']=time.perf_counter()-start;data['render_error']=str(r.CyrusPFLastError);data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:save()
if data['status']!='complete':raise RuntimeError(data['error'])
