"""Bounded repeated display/layer lifecycle, recording allocation trends."""
from pathlib import Path
import sys,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('endurance')
try:
    r.resetMaxFile(r.Name('noPrompt'));surface=r.plane(width=600,length=600)
    source=r.sphere(radius=5,segs=12,pos=pt(1000,0));r.hide(source)
    node=r.AminScatterObject(name='Endurance');root=node.baseObject;root.updateMode=1;root.autoRender=False
    for i in range(4):
        root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces(leaf,arr([surface]));leaf.sources=arr([source]);leaf.amount=1500+i*100;leaf.sourceRadii=arr([6.]);leaf.sourceShowRadius=arr([True])
    root.setGroupDisplay(3);update(root);r.CyrusPointSync();r.completeRedraw();r.completeRedraw()
    original=fingerprint(root);epoch=int(root.procEpoch);failures=int(r.cyrusRetainedStats(r.CyrusPointOwner(node))[8])
    rec.data['cycles']=[]
    for i in range(48):
        root.layerObjects[i%4].setSourceIDColor(bits(1),r.color((i*31)%255,140,(i*17)%255))
        if i%8==0:
            root.layerVisible[3]=False;r.CyrusPointSync();r.completeRedraw();root.layerVisible[3]=True
        if i%12==0:
            temporary=root.copyLogicalLayer(root.layerObjects[0]);root.refreshDisplay();root.removeLogicalLayer(temporary);root.refreshDisplay()
        r.CyrusPointSync();r.completeRedraw();r.completeRedraw()
        rec.check(fingerprint(root)==original and int(root.procEpoch)==epoch,'Cycle '+str(i)+': original Manual publication preserved')
        rec.check(not str(r.CyrusPointLastError) and all(not str(l.previewError) for l in root.layerObjects),'Cycle '+str(i)+': no native fallback or layer error')
        if i%4==0:rec.data['cycles'].append(dict(cycle=i,state=state()));rec.write()
    rec.check(int(r.cyrusRetainedStats(r.CyrusPointOwner(node))[8])==failures,'48 cycles add no retained resource failures')
    root.setGroupDisplay(4);r.CyrusPointSync();r.completeRedraw();pump(500)
    saved=fingerprint(root);r.saveMaxFile(str(OUT/'Endurance.max'),quiet=True);r.loadMaxFile(str(OUT/'Endurance.max'),quiet=True,useFileUnits=True)
    root=r.getNodeByName('Endurance').baseObject;update(root)
    rec.check(fingerprint(root)==saved,'Repeated lifecycle result survives save/reopen exactly')
    rec.data['final']=state();rec.write()
except Exception:rec.error(traceback.format_exc())
