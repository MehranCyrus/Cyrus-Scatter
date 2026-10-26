"""Actual Max 2027 layer preparation/contact/Edit smoke, owned profile only."""
from pathlib import Path
import json, time, traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(str(r.GardenRun))

def write(name,data): (OUT/name).write_text(json.dumps(data,indent=2),encoding='utf-8')
def arr(values): return r.Array(*values)
def point(x,y,z): return r.Point3(x,y,z)
def settle(seconds=1):
    end=time.perf_counter()+seconds
    while time.perf_counter()<end:
        r.windows.processPostedMessages();r.execute('(dotNetClass "System.Windows.Forms.Application").DoEvents()');r.redrawViews()
def main():
    r.resetMaxFile(r.Name('noPrompt'))
    r.units.SystemType=r.Name('Centimeters');r.units.SystemScale=1
    r.CyrusPFResume=False
    sourcefile=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/Library/Models/Grasses/A069 - Grass - Small Clump/model.max'
    assert r.mergeMaxFile(str(sourcefile),r.Name('select'),quiet=True)
    candidates=list(r.selection);assert len(candidates)==1
    source=candidates[0];source.name='INTERACTION_Source_Grass';source.material=r.standardMaterial(diffuse=r.color(75,145,35))
    source.pos=point(1000,0,0);source.renderable=False;r.hide(source)
    stone=r.sphere(name='INTERACTION_Source_Sphere',radius=7,segs=16,pos=point(1100,0,0));stone.material=r.standardMaterial(diffuse=r.color(125,117,105));stone.renderable=False;r.hide(stone)
    receiver=r.plane(name='INTERACTION_Receiver',width=100,length=100,widthsegs=1,lengthsegs=1)
    owner=r.AminScatterObject(name='INTERACTION_Scatter_087');root=owner.baseObject
    root.updateMode=1;root.autoRender=False
    root.newLayer();grass=root.layerObjects[0];root.layerNames[0]='Grass - React'
    grass.addModelSource(source);root.setLayerSurfaces(grass,arr([receiver]));grass.amount=80;grass.autoRender=True
    root.newLayer();rocks=root.layerObjects[1];root.layerNames[1]='Stones - Collider'
    rocks.addModelSource(stone);root.setLayerSurfaces(rocks,arr([receiver]));rocks.amount=1;rocks.autoRender=True
    r.addModifier(owner,r.CyrusScatterEdit());edit=owner.modifiers[0]
    root.viewportMode=3;root.identificationMode=2
    started=time.perf_counter();report=json.loads(str(grass.interactionsAnalyze(source)));prepare=time.perf_counter()-started
    assert report['can_prepare'];grass.interactionsAccept()
    grass.interactionReact=True;rocks.interactionCollider=True
    started=time.perf_counter();root.refreshAll();r.CyrusPointSync();r.redrawViews();elapsed=time.perf_counter()-started
    assert str(grass.previewError)=='',str(grass.previewError)
    assert str(r.CyrusPointLastError)=='',str(r.CyrusPointLastError)
    assert root.interactionState is not None
    info=json.loads(str(root.interactionsStatistics()));assert info['plants']==80 and info['obstacles']==1,info
    write('initial.json',{'prepare_seconds':prepare,'update_seconds':elapsed,'source':report,'statistics':info})
    r.execute('global IOwner,IRoot,IGrass,IRocks,IEdit')
    r.IOwner=owner;r.IRoot=root;r.IGrass=grass;r.IRocks=rocks;r.IEdit=edit
    write('setup-complete.json',{'status':'ready','epoch':int(root.procEpoch)})
try:
    with pymxs.undo(False):
        main()
except Exception: (OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
