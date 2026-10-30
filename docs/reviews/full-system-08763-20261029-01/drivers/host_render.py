"""Small production render-path spot check, no renderer-wide certification."""
from pathlib import Path
from pymxs import runtime as r
import json,traceback,time
ROOT=Path(__file__).resolve().parents[4];OUT=Path(str(r.GardenRun));report={}
try:
 assert r.cyrusLicenseAllows()
 assert r.loadMaxFile(str(ROOT/'build/full-system-review-08763-20261029-01/host/Review_08763.max'),quiet=True,useFileUnits=True)
 r.execute('''CyrusSelectionTimer.Stop()
 global RVRoot=(getNodeByName "Review fixture" exact:true).baseObject
 RVRoot.layerObjects[1].autoRender=false;RVRoot.layerObjects[2].autoRender=true
 RVRoot.layerObjects[2].amount=8;RVRoot.autoRender=true;RVRoot.refreshAll();RVRoot.interactionsEnsure()
 for n in (RVRoot.layerObjects[2].validSources()) do (n.material=standardMaterial diffuse:(color 50 200 50) twoSided:true; n.renderable=false)
 global RVCamera=targetCamera pos:[.3,-.4,.25] target:(targetObject pos:[0,0,.035])
 renderers.current=Default_Scanline_Renderer()
 backgroundColor=color 40 40 40
 ''')
 for _ in range(8):r.CyrusPointSync();r.redrawViews();r.windows.processPostedMessages();time.sleep(.02)
 report['renderer']=str(r.classOf(r.renderers.current));report['stats']=json.loads(str(r.RVRoot.interactionsStatistics()))
 assert report['stats']['posed']>0
 image=r.render(camera=r.RVCamera,outputwidth=192,outputheight=192,vfb=False)
 assert image!=r.undefined;image.filename=str(OUT/'scanline.png');r.save(image);r.close(image)
 report['render_created']=True;report['scope']='Small current automatic-output render; image inspection separate. No external renderer, full material or GPU equivalence qualification.'
 report['status']='complete';(OUT/'completed.json').write_text(json.dumps(report,indent=2))
except Exception:
 report.update(status='failed',error=traceback.format_exc());(OUT/'error.txt').write_text(report['error'])
finally:(OUT/'render-host.json').write_text(json.dumps(report,indent=2))
