"""Unchanged siblings, atomic failure recovery and GPU reuse on partial publication."""
from pathlib import Path
import sys,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('reuse-checks')
try:
    r.resetMaxFile(r.Name('noPrompt'))
    surface=r.plane(width=500,length=500)
    model=r.box(width=4,length=4,height=12,pos=pt(700,0));r.hide(model)
    node=r.AminScatterObject(name='Reuse witness');root=node.baseObject;root.updateMode=1;root.autoRender=False
    for i in range(3):
        root.newLayer();l=root.selectedLayer();root.setLayerSurfaces(l,arr([surface]));l.sources=arr([model]);l.amount=100+i*20;l.sourceRadii=arr([3.])
    root.setGroupDisplay(3);update(root);r.CyrusPointSync();r.completeRedraw();r.completeRedraw()
    initial=fingerprint(root);owners=list(root.layerObjects)
    rec.step('One-layer color edit',lambda:owners[0].setSourceIDColor(bits(1),r.color(50,60,70)))
    before=rec.data['checkpoints'][-1]['before']['controllers'][0];after=rec.data['checkpoints'][-1]['after']['controllers'][0]
    rec.check([b['preview_builds']-a['preview_builds'] for a,b in zip(before['layers'],after['layers'])]==[1,0,0],'Only edited layer reconstructs its CPU preview')
    uploads=int(after['retained'][5])-int(before['retained'][5])
    rec.data['mesh_color_uploads']=uploads;rec.write()
    rec.data['assertions'].append(dict(passed=uploads==4,label='One mesh group uploads four streams, unchanged siblings upload zero',actual=uploads));rec.write()
    root.setGroupDisplay(4);r.CyrusPointSync();r.completeRedraw();r.completeRedraw()
    rec.step('One-layer Point color edit',lambda:owners[1].setSourceIDColor(bits(1),r.color(200,60,70)))
    a=rec.data['checkpoints'][-1]['before']['controllers'][0]['retained'];b=rec.data['checkpoints'][-1]['after']['controllers'][0]['retained']
    rec.data['point_color_uploads']=int(b[5])-int(a[5]);rec.data['assertions'].append(dict(passed=int(b[5])-int(a[5])==1,label='Only changed Point group uploads',actual=int(b[5])-int(a[5])));rec.write()
    owners[1].sourceShowRadius=arr([True]);root.refreshDisplay();r.CyrusPointSync();r.completeRedraw()
    snapshots=[l.cachedPoints for l in owners];radii=[l.radiusCache for l in owners]
    # Local color keys change two layers. Fail the second stage after preparing the first.
    owners[0].visualSourceColors[0]=r.color(10,220,10)
    owners[1].visualSourceColors[0]=r.color(220,10,10)
    saved=root.procPublishedRadii[1][0];root.procPublishedRadii[1][0]='invalid radius witness'
    root.refreshDisplay()
    rec.check(all(l.cachedPoints==c and l.radiusCache==v for l,c,v in zip(owners,snapshots,radii)),'Failure in second changed layer retains every complete previous snapshot')
    rec.check(all(bool(str(l.previewError)) for l in owners),'Failure is reported across the controller')
    root.procPublishedRadii[1][0]=saved;root.refreshDisplay()
    rec.check(all(not str(l.previewError) for l in owners),'Successful retry clears errors on unchanged siblings too')
    rec.check(fingerprint(root)==initial,'Partial display publications never change plants')
    # A Manual recipe stays pending while one visible source is recolored.
    owners[2].amount=250;epoch=int(root.procEpoch)
    owners[0].setSourceIDColor(bits(1),r.color(70,70,220));root.refreshDisplay()
    rec.check(int(root.procEpoch)==epoch and fingerprint(root)==initial,'Local display change preserves pending Manual recipe')
    update(root);rec.check(len(root.groupSnapshotRows[2])==250,'Explicit Update applies the pending amount')
except Exception:rec.error(traceback.format_exc())
