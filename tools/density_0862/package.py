"""Package only the exact qualified 0.86.2 Max 2027 source/native pair."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'));import build_max
p=argparse.ArgumentParser();p.add_argument('--native',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args()
native=a.native.resolve();out=a.output.resolve();assert out.is_relative_to(ROOT/'build') and not out.exists()
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
receipt=json.loads((native/'receipt.json').read_text(encoding='utf-8'))
assert receipt['max_year']==2027 and all(stage['exit_code']==0 for stage in receipt['stages'])
assert not receipt.get('placement_qualification') and not receipt.get('preview_fault_lab')
for name,digest in receipt['sources'].items():assert sha(ROOT/name)==digest,name
for name,digest in receipt['binaries'].items():assert sha(ROOT/name)==digest,name
assert build_max.scatter_version()=='0.86.2';out.mkdir(parents=True)
library=out/'library';shutil.copytree(ROOT/'AminScatter/library',library)
inventory=json.loads((library/'inventory.json').read_text(encoding='utf-8'))
inventory['version']='0.86.2';inventory['delivery_note']='Existing authored example bytes retained. Eight Add/Undo/Redo witnesses on their compatible terrains passed with the 0.86.2 Max 2027 pair; channel/Paint requirements are derived in the library.'
(library/'inventory.json').write_text(json.dumps(inventory,indent=2)+'\n',encoding='utf-8')
stage=out/'staging/AminScatter';stage.mkdir(parents=True)
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
for name in names+['CyrusGallery.dll']:shutil.copy2(native/name,stage/name)
core=stage/'CyrusInstaller.dll'
subprocess.run([sys.executable,str(ROOT/'AminScatter/tools/build_installer.py'),'--output',str(core)],check=True)
args=SimpleNamespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=out,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',library_dir=library)
build_max.package('AminScatter','Cyrus Scatter','0.86.2',names,'AminScatterObject.ms',args,stage.parent)
package=out/'CyrusScatter-0.86.2-Max2027.mzp'
with zipfile.ZipFile(package) as archive:
 assert archive.testzip() is None;manifest=json.loads(archive.read('manifest.json'))
 assert manifest['version']=='0.86.2' and manifest['max_year']==2027
 assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
 for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
 assert '29000' in archive.read('install.ms').decode('utf-8')
 patterns=json.loads((ROOT/'AminScatter/patterns/index.json').read_text(encoding='utf-8'))['entries']
 assert {name for name in archive.namelist() if name.startswith('Patterns/') and name.endswith('.png')}=={'Patterns/'+row['file'] for row in patterns}
 for row in patterns:assert hashlib.sha256(archive.read('Patterns/'+row['file'])).hexdigest()==row['sha256']
 assert manifest['licensing']['mode']=='offline-team'
 archive.extractall(out/'payload')
exe=out/'CyrusScatter-0.86.2-Setup.exe'
subprocess.run([sys.executable,str(ROOT/'AminScatter/tools/build_installer.py'),'--output',str(exe),'--core',str(core),'--package',str(package)],check=True)
(out/'candidate.json').write_text(json.dumps({'version':'0.86.2','status':'Package candidate; distribution tests separate','native_receipt_sha256':sha(native/'receipt.json'),'exe_sha256':sha(exe),'mzp_sha256':sha(package),'manifest':manifest},indent=2)+'\n',encoding='utf-8')
print('Exact pair package candidate:',out)
