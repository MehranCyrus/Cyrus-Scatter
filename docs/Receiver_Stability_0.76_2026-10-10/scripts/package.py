from pathlib import Path
from types import SimpleNamespace
import sys,json,hashlib,shutil,zipfile
R=Path.cwd();W=R/'build/receiver076';H=R/'build/mcp-qualification/receiver076-release'
sys.path.insert(0,str(R/'tools'));from build_max import package,scatter_version
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
campaign=json.loads((W/'campaign.json').read_text())
assert all(row['passed'] for row in campaign)
assert any(row['name']=='corona-production' for row in campaign)
assert 'SUCCESS 942 assertions' in (H/'result.txt').read_text()
base=W/'package-input';base.mkdir(exist_ok=True)
for folder,project in [('release-max2027','AminScatter'),('../courtyard-fixes075/analyzer2027-release','CyrusSurfaceAnalyzer')]:
 receipt=json.loads((W/folder/'receipt.json').read_text())
 assert all(s['exit_code']==0 for s in receipt['stages'])
 for p,h in {**receipt['sources'],**receipt['binaries']}.items():assert sha(R/p)==h,p
 dest=base/project;dest.mkdir(exist_ok=True)
 for p in receipt['binaries']:shutil.copy2(R/p,dest/Path(p).name)
out=R/'dist/Receiver_Stability_0.76_2026-10-10/Max2027'
args=SimpleNamespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=out)
package('AminScatter','Cyrus Scatter',scatter_version(),['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'],'AminScatterObject.ms',args,base)
package('CyrusSurfaceAnalyzer','Cyrus Surface Analyzer','0.14',['CyrusSurfaceAnalyzer.dlx'],'CyrusSurfaceAnalyzer.ms',args,base)
loaded=json.loads((H/'launch.json').read_text());files=[]
for p in sorted(out.glob('*.mzp')):
 with zipfile.ZipFile(p) as z:
  manifest=json.loads(z.read('manifest.json'))
  for n,digest in manifest['files'].items():assert hashlib.sha256(z.read(n)).hexdigest()==digest
  for n,digest in loaded['binaries'].items():
   if n in z.namelist():assert manifest['files'][n]==digest,n
  if 'CyrusScatter.ms' in z.namelist():assert manifest['files']['CyrusScatter.ms']==loaded['script_sha256']
  if 'CyrusSurfaceAnalyzer.ms' in z.namelist():assert manifest['files']['CyrusSurfaceAnalyzer.ms']==sha(R/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms')
 files.append({'path':p.relative_to(R).as_posix(),'sha256':sha(p),'manifest':manifest})
doc=R/'docs/Receiver_Stability_0.76_2026-10-10';doc.mkdir(exist_ok=True)
(doc/'PACKAGE.json').write_text(json.dumps({'packages':files,'installed':False,'installer_execution_qualified':False,'host':str(H.relative_to(R)),'scope':'Max 2027 development candidate; raw runtime-tested payload hashes verified in both archives'},indent=2))
