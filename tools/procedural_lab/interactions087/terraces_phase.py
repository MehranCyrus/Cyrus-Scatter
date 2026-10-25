"""Fixed-identity terrace fixture and tier setup; owned Max 2027 only."""
from pathlib import Path
import json,re,time,traceback
import pymxs
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[3];OUT=Path(str(r.GardenRun))
try:
    count=int(r.TCount)
    with pymxs.undo(count==-1,'Build final interaction garden'):
        if count==0:
            r.loadMaxFile(str(ROOT/'build/interactions087-terraces-host-20261025-04/Terraces_Interactions_087_Foreground.max'),quiet=True,useFileUnits=True)
        node=r.getNodeByName('CyrusScatter 0.87 - Terrace contact study');root=node.baseObject
        r.CyrusPointSuspended=True;r.CyrusPFResume=False;r.CyrusPerfHeadless=False
        layers=list(root.layerObjects);receiver=r.getNodeByName('087 Contact study receiver')
        if count>0:
            receivers=[n for n in r.objects if re.match(r'^PLANTING \| \d+ grass footprint$',str(n.name))]
            for i,leaf in enumerate(layers):root.setLayerSurfaces(leaf,r.Array(*([receiver] if i==5 else receivers)))
            for leaf,n in zip(layers,[count,count//10,count//100,count//50,10,3]):leaf.amount=n
        if count==-1:
            for leaf,n in zip(layers,[10000,1000,100,200,10,3]):leaf.amount=n
            r.theHold.Begin()
            try:
                for i,n in enumerate([1000,80,12,24]):
                    old=layers[i];root.newLayer();leaf=root.layerObjects[-1];root.layerNames[-1]='Contact study - '+str(root.layerNames[i])
                    leaf.addModelSource(old.sources[0]);root.setLayerSurfaces(leaf,r.Array(receiver));leaf.amount=n;leaf.randomSeed=int(old.randomSeed)
                    leaf.interactionSourceIDs=r.Array(str(leaf.sourceRowIDs[0]));leaf.interactionDefinitions=r.Array(str(old.interactionDefinitions[0]));leaf.interactionDefinitionRevision=1;leaf.interactionReact=True
                r.theHold.Accept('Add dense foreground interaction layers')
            except Exception:r.theHold.Cancel();raise
            for leaf in root.layerObjects:leaf.autoRender=True
        root.viewportMode=3;root.identificationMode=2
        start=time.perf_counter();root.refreshAll();r.CyrusPointSuspended=False;r.CyrusPointSync();r.completeRedraw()
        seconds=time.perf_counter()-start
        errors=[str(leaf.previewError) for leaf in root.layerObjects if str(leaf.previewError)]
        if errors or str(r.CyrusPointLastError):raise RuntimeError((errors,str(r.CyrusPointLastError)))
        r.execute('global TOwner,TRoot,TEdit,TRocks');r.TOwner=node;r.TRoot=root;r.TEdit=node.modifiers[0];r.TRocks=root.layerObjects[5]
        proc=r.execute('(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()');proc.Refresh()
        data={'count_tier':count,'update_seconds':seconds,'statistics':json.loads(str(root.interactionsStatistics())),'private_bytes':int(proc.PrivateMemorySize64),'peak_working_set_bytes':int(proc.PeakWorkingSet64),'generated':[int(leaf.generatedCount) for leaf in root.layerObjects],'scope':'CPU update; no presented FPS claim'}
        (OUT/f'phase-{count}.json').write_text(json.dumps(data,indent=2))
        (OUT/f'phase-{count}-ok.txt').write_text('ready')
except Exception:(OUT/'error.txt').write_text(traceback.format_exc(),encoding='utf-8')
