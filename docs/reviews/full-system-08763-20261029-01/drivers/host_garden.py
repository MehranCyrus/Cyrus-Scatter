"""Replay existing garden checks on a copied scene in an owned Max host."""
from pathlib import Path
from pymxs import runtime as r
import json,time,traceback,hashlib,shutil,__main__
ROOT=Path(__file__).resolve().parents[4];OUT=Path(str(r.GardenRun));report={}
try:
 assert r.cyrusLicenseAllows()
 source=ROOT/'dist/CyrusScatter-0.87.6.1-20261029/Scenes/Terraces_Garden_0.87.6.1_Max2027.max'
 destination=OUT/'garden-input.max';shutil.copy2(source,destination)
 report['input']={'path':str(source),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'copy_sha256':hashlib.sha256(destination.read_bytes()).hexdigest()}
 assert report['input']['sha256']==report['input']['copy_sha256']
 scripts=[('selection08762/garden_pick.py','garden-pick.json'),('selection08762/garden_navigation.py','navigation.json'),('review08763/garden_drag.py','garden-drag.json')]
 for relative,receipt in scripts:
  path=ROOT/'tools/procedural_lab'/relative;code=path.read_text()
  if relative.endswith('garden_pick.py'):code=code.replace("ROOT/'dist/CyrusScatter-0.87.6.1-20261029/Scenes/Terraces_Garden_0.87.6.1_Max2027.max'",repr(str(destination)))
  __main__.__dict__['__file__']=str(path);exec(compile(code,str(path),'exec'),__main__.__dict__)
  if relative.endswith('garden_drag.py'):
   end=time.monotonic()+60
   while time.monotonic()<end:
    r.windows.processPostedMessages();time.sleep(.025)
    if json.loads((OUT/receipt).read_text())['status']!='running':break
   finish=ROOT/'tools/procedural_lab/review08763/garden_finish.py';exec(compile(finish.read_text(),str(finish),'exec'),__main__.__dict__)
  data=json.loads((OUT/receipt).read_text());assert data['status']=='complete',data
  if relative.endswith('garden_drag.py'):assert data['verification']=='passed',data
  report[relative]='complete'
 report['original_unchanged']=hashlib.sha256(source.read_bytes()).hexdigest()==report['input']['sha256'];assert report['original_unchanged']
 report['status']='complete';(OUT/'completed.json').write_text(json.dumps(report,indent=2))
except Exception:
 report.update(status='failed',error=traceback.format_exc());(OUT/'error.txt').write_text(report['error'])
finally:(OUT/'garden-review.json').write_text(json.dumps(report,indent=2))
