"""Build a Max 2027 MZP from the qualified surface-brush pair and indexed library."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'));import build_max
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--native',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
native=a.native.resolve();out=a.output.resolve();assert out.is_relative_to(ROOT/'build/surface-brush-0866-20261019') and not out.exists()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();receipt=json.loads((native/'receipt.json').read_text())
assert receipt['max_year']==2027 and all(x['exit_code']==0 for x in receipt['stages'])
assert not receipt.get('placement_qualification') and not receipt.get('preview_fault_lab')
for name,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/name)==digest,name
assert build_max.scatter_version()=='0.86.6';library=ROOT/'AminScatter/library';inventory=json.loads((library/'inventory.json').read_text())
assert inventory['qualification_status'].startswith('passed:') and inventory['version']=='0.86.6'
out.mkdir(parents=True);stage=out/'staging/AminScatter';stage.mkdir(parents=True)
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
for name in names+['CyrusGallery.dll']:shutil.copy2(native/name,stage/name)
core=stage/'CyrusInstaller.dll';subprocess.run([sys.executable,str(ROOT/'AminScatter/tools/build_installer.py'),'--output',str(core)],check=True)
args=SimpleNamespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=out,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',library_dir=library)
build_max.package('AminScatter','Cyrus Scatter','0.86.6',names,'AminScatterObject.ms',args,stage.parent)
package=out/'CyrusScatter-0.86.6-Max2027.mzp'
with zipfile.ZipFile(package) as z:
 assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'))
 assert manifest['version']=='0.86.6' and manifest['max_year']==2027 and manifest['licensing']['mode']=='offline-team'
 assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
 for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
 for name in names+['CyrusGallery.dll']:assert manifest['files'][name]==sha(native/name),name
 assert manifest['files']['CyrusScatter.ms']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
 assert '29000' in z.read('install.ms').decode('utf-8')
 assert '0.86.6' in z.read('InstallInventory.txt').decode('utf-8').splitlines()[0]
 for row in json.loads((ROOT/'AminScatter/patterns/index.json').read_text())['entries']:assert hashlib.sha256(z.read('Patterns/'+row['file'])).hexdigest()==row['sha256']
 for name in z.namelist():assert not Path(name).is_absolute() and '..' not in Path(name).parts
 z.extractall(out/'payload')
(out/'package-receipt.json').write_text(json.dumps({'status':'passed','version':'0.86.6','max_year':2027,'mzp':str(package),'mzp_sha256':sha(package),'native_receipt_sha256':sha(native/'receipt.json'),'manifest':manifest,'artist_installation':False},indent=2)+'\n')
print(package)
