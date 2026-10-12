"""Cross-feature edits in the real landscape; restore every recipe afterward."""
from pathlib import Path
import sys,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('garden-checks')
try:
    node=r.getNodeByName('CYRUS | Terraced garden 0.79.5');root=node.baseObject
    update(root);initial=fingerprint(root);leaf=root.layerObjects[0];areas=list(leaf.paintAreas);surfaces=list(leaf.validSurfaces())
    counts=[list(map(str,r.cyrusBrushStats(a.paintDocument))) for a in areas]
    rec.step('Unlink middle painted receiver',lambda:root.setLayerSurfaces(leaf,arr([surfaces[0],surfaces[2]])))
    rec.step('Update missing receiver',lambda:update(root))
    rec.check(len(leaf.paintAreas)==3 and int(r.cyrusBrushStats(areas[1].paintDocument)[2])>0,'Missing receiver keeps its painted contours')
    rec.step('Restore exact receiver',lambda:root.setLayerSurfaces(leaf,arr(surfaces)))
    rec.step('Update restored receiver',lambda:update(root))
    rec.check(fingerprint(root)==initial,'Relinking restores every garden placement exactly')
    document=areas[0].paintDocument;cfg=r.cyrusBrushFalloff(document);saved=arr([arr(list(x)) if r.classOf(x)==r.Array else x for x in cfg])
    receiver_builds=int(leaf.receiverCacheStats()[0]);cfg[0]=70.;cfg[4]=.2
    rec.step('Widen painted feather and lower edge scale',lambda:r.cyrusBrushSetFalloff(document,cfg))
    rec.step('Update feathered garden',lambda:update(root))
    rec.check(int(leaf.receiverCacheStats()[0])==receiver_builds,'Paint feather edit reuses all base receiver candidates')
    rec.check(fingerprint(root)!=initial,'Feather edit changes the intended output')
    r.cyrusBrushSetFalloff(document,saved);update(root)
    rec.check(fingerprint(root)==initial,'Restoring paint settings restores exact garden')
    copied=rec.step('Copy painted layer',lambda:root.copyLogicalLayer(leaf))
    rec.check(len(copied.paintAreas)==3 and copied.paintAreas[0].paintDocument!=document,'Layer copy owns independent paint documents')
    r.cyrusBrushFill(copied.paintAreas[0].paintDocument,0.)
    rec.check(int(r.cyrusBrushStats(document)[2])>0,'Clearing copied area preserves original contours')
    root.removeLogicalLayer(copied);update(root);rec.check(fingerprint(root)==initial,'Removing copied layer preserves original garden')
    ground=root.layerObjects[6];amount=int(ground.amount);epoch=int(root.procEpoch)
    ground.amount=amount+2000;r.CyrusViewportRedraw();pump(350)
    rec.check(int(root.procEpoch)==epoch and fingerprint(root)==initial,'Manual density-layer edit stays pending during redraw')
    root.updateMode=2;root.markInputDirty();pump(1400)
    rec.check(int(root.procEpoch)>epoch and fingerprint(root)!=initial,'Live publishes the pending layer edit')
    root.updateMode=1;ground.amount=amount;update(root);rec.check(fingerprint(root)==initial,'Restored amount returns original garden')
    r.saveMaxFile(str(OUT/'Garden_Checked.max'),quiet=True);r.loadMaxFile(str(OUT/'Garden_Checked.max'),quiet=True,useFileUnits=True)
    root=r.getNodeByName('CYRUS | Terraced garden 0.79.5').baseObject;update(root)
    rec.check(fingerprint(root)==initial,'Garden, all paint regions and guides survive save/reopen')
except Exception:rec.error(traceback.format_exc())
