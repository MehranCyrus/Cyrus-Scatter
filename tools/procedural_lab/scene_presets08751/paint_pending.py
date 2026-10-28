"""Final installed pair: native Paint reference and pending Manual settings."""
from pathlib import Path
import json,traceback,time
from pymxs import runtime as r
O=Path(str(r.GardenRun));phase=str(r.CVProfileCase);report={'phase':phase,'status':'running'}
try:
    if phase=='paint-pending-setup':
        leaf=r.SPRoot.layerObjects[0];target=leaf.validSurfaces()[0];target.layer.isFrozen=False;target.layer.isHidden=False;target.isFrozen=False;target.isHidden=False;r.unfreeze(target);r.unhide(target);doc=r.cyrusBrushCreate(target);r.cyrusBrushSettings(doc,25.,False)
        bounds=r.nodeGetBoundingBox(target,target.objectTransform);center=(bounds[0]+bounds[1])*.5
        assert r.cyrusBrushDab(doc,center+r.Point3(0,0,1000),r.Point3(0,0,-1),True)
        leaf.paintDocument=doc;leaf.paintEnabled=False
        r.SPPaintExpected=str(r.cyrusBrushRecipeExport(doc)[0]);assert r.SPPaintExpected
        png=O/'owned-texture.png';hidden=O/'owned-texture-unavailable.png'
        if not png.exists() and hidden.exists():hidden.rename(png)
        r.SPPendingRows=int(leaf.generatedCount);r.SPPendingBefore=int(r.SPRoot.procEpoch);r.SPPendingAmount=int(leaf.amount)+1;leaf.amount=int(r.SPPendingAmount)
        report.update(published=int(r.SPPendingRows),pending=int(r.SPPendingAmount),paint_bytes=len(str(r.SPPaintExpected))//2)
    elif phase=='paint-pending-save':
        r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned Paint fixture frame";SPJob=CyrusScenePresetSave SPRoot "Paint and pending Manual setup" (CyrusRecipeObject #(#("category","Native tests"),#("tags",#()),#("description","Native Paint and pending settings"))) ""')
    elif phase=='paint-pending-check':
        assert str(r.CyrusSharedPollSave(r.SPJob))=='complete',str(r.SPJob.error);r.SPEntry=str(r.SPJob.result);r.SPExpected=r.cyrusRecipeInfo(str(r.SPEntry))[10]
        assert int(r.SPRoot.procEpoch)==int(r.SPPendingBefore) and int(r.SPRoot.layerObjects[0].generatedCount)==int(r.SPPendingRows)
        assert int(r.SPRoot.layerObjects[0].amount)==int(r.SPPendingAmount);r.SPOperation=r.CyrusSharedStore().PrepareScene(str(r.SPEntry),str(r.SPExpected));report['manual_retained']=True
    elif phase=='paint-pending-merge':
        assert r.SPOperation.Terminal and str(r.SPOperation.State)=='complete',str(r.SPOperation.Error)
        r.execute('for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned Paint import frame"')
        r.SPImported=r.CyrusScenePresetMerge(str(r.SPEntry),str(r.SPExpected),str(r.SPOperation.Result));r.CyrusSharedStore().DiscardSceneLoad(str(r.SPOperation.Result))
        leaf=r.SPImported.baseObject.layerObjects[0];assert str(r.cyrusBrushRecipeExport(leaf.paintDocument)[0])==str(r.SPPaintExpected)
        assert r.cyrusBrushTarget(leaf.paintDocument)==leaf.validSurfaces()[0] and r.cyrusBrushTarget(leaf.paintDocument)!=r.SPRoot.layerObjects[0].validSurfaces()[0]
        assert int(leaf.amount)==int(r.SPPendingAmount);report.update(paint_restored=True,independent_receiver=True,amount=int(leaf.amount))
    report['status']='passed'
except Exception:report.update(status='failed',error=traceback.format_exc());raise
finally:(O/(phase+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
