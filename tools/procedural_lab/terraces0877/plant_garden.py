"""First moderate-density landscape, kept distinct from stress variants."""
from pathlib import Path
import json,time,traceback,re
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];out=Path(str(r.GardenRun))
def arr(v):return r.Array(*v)
def write(n,v):(out/n).write_text(json.dumps(v,indent=2),encoding='utf-8')
try:
    palette={str(n.name).split(' | ')[1]:n for n in r.GardenSources}
    receivers=sorted([n for n in r.objects if re.match(r'^PLANTING \| \d+ grass footprint$',str(n.name))],key=lambda n:n.name)
    assert len(receivers)==11
    r.execute('global GardenNodes=#(),GardenLayers=#(); CyrusPointSuspended=true')
    records=[]
    def group(name,faces,nav):
        n=r.AminScatterObject(name=name);root=n.baseObject
        root.updateMode=1;root.viewportMode=3;root.identificationMode=2;root.autoRender=False
        root.viewportFaces=faces;root.viewportNavigationFaces=nav
        r.append(r.GardenNodes,n)
        return root
    def layer(root,name,ids,targets,count,scale=1.,radius=0.):
        root.newLayer();leaf=root.layerObjects[-1];root.layerNames[-1]=name
        for id in ids:leaf.addModelSource(palette[id])
        leaf.sourceScales=arr([scale]*len(ids));leaf.amount=count;leaf.randomSeed=76100+len(records)
        root.setLayerSurfaces(leaf,arr(targets));leaf.autoRender=False
        leaf.scaleMinimum=.78;leaf.scaleMaximum=1.22
        if radius:
            leaf.sourceRadiiWU=arr([radius]*len(ids));leaf.sourceAutoRadius=arr([False]*len(ids))
            leaf.procLayerSelfEnabled=True;leaf.procLayerSelfPlanar=True
        r.append(r.GardenLayers,leaf)
        records.append(dict(name=name,ids=ids,requested=count,scale=scale,receivers=[str(n.name) for n in targets]))
        return leaf
    trees=group('GARDEN | Woodland framing',35000000,5000000)
    layer(trees,'Upper grove - rounded canopies',['A072','A078'],receivers[7:],44,1.,230)
    layer(trees,'Tea trees - eastern terraces',['A056'],receivers[3:9],54,1.35,170)
    layer(trees,'Slender garden trees',['A103'],receivers[1:5],16,6.,160)
    layer(trees,'Autumn maple accents',['A098'],receivers[3:7],18,1.6,150)
    layer(trees,'Cypress rhythm',['A075'],receivers[8:],13,1.15,180)
    layer(trees,'Flowering orchard',['A049'],receivers[5:8],12,1.,180)
    meadow=group('GARDEN | Terraced meadows',24000000,2000000)
    layer(meadow,'Fine meadow base',['A069'],receivers[:7],10000,5.8)
    layer(meadow,'Rough grass drifts',['A068'],receivers[3:],4500,6.5)
    layer(meadow,'Clover along the promenade',['A070'],receivers[:2],2200,7.)
    shrubs=group('GARDEN | Flower and shrub drifts',30000000,3000000)
    for id,label,colour,count in [('A083','Lavender ribbons','white',80),('A086','Rose pockets','pink',64),('A081','Elder accents','yellow',30),('A085','Myrtle structure','white',26)]:
        targets=[n for n in r.objects if str(n.name).startswith('PLANTING |') and colour+' drift' in str(n.name)]
        layer(shrubs,label,[id],targets[:14],count,1.3,50)
    flowers=group('GARDEN | Lake garden detail',15000000,2000000)
    layer(flowers,'Blue violet cushions',['A062'],receivers[:2],550,4.)
    layer(flowers,'Phlox and geranium',['A064','A066'],receivers[1:4],900,3.5)
    layer(flowers,'Deadnettle pockets',['A067'],receivers[:2],300,4.)
    layer(flowers,'White flowers and broad leaves',['A088','A090'],receivers[:3],300,1.)
    r.CyrusPointSuspended=False
    stages=[]
    for n in r.GardenNodes:
        (out/'stage.txt').write_text('publish '+str(n.name))
        t=time.perf_counter();n.baseObject.refreshAll();r.CyrusPointSync()
        errors=[str(l.previewError) for l in n.baseObject.layerObjects if str(l.previewError)]
        stages.append(dict(name=str(n.name),seconds=time.perf_counter()-t,
            accepted=[int(l.generatedCount) for l in n.baseObject.layerObjects],errors=errors))
        write('planting-stages.json',stages)
        if errors:raise RuntimeError(errors)
    write('planting-design.json',records)
    r.execute('viewport.SetRenderLevel #smoothhighlights;viewport.SetShowEdgeFaces false;viewport.setGridVisibility #all false;clearSelection();viewport.setCamera TCOverview')
    for name,cam in [('overview',r.TCOverview),('lake',r.TCLake),('house',r.TCHouse)]:
        r.viewport.setCamera(cam);r.completeRedraw();r.windows.processPostedMessages()
        b=r.gw.getViewportDib();b.filename=str(out/('garden-first-'+name+'.png'));r.save(b);r.close(b)
    (out/'stage.txt').write_text('save first landscape')
    r.saveMaxFile(str(out.parent/'Terraces_Garden_First.max'),quiet=True)
    write('garden-first.json',dict(status='complete',stages=stages))
except Exception:
    r.CyrusPointSuspended=False
    write('garden-first.json',dict(status='failed',error=traceback.format_exc()))
