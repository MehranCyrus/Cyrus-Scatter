"""Build the current exact-pair candidate; delivery remains a separate gate."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'))
import build_max
p=argparse.ArgumentParser();p.add_argument('--native',required=True,type=Path);p.add_argument('--output',required=True,type=Path);p.add_argument('--core',required=True,type=Path);a=p.parse_args()
native=a.native.resolve();out=a.output.resolve();core=a.core.resolve();assert not out.exists() and out.is_relative_to(ROOT/'build')
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
receipt=json.loads((native/'receipt.json').read_text());assert receipt['max_year']==2027 and all(x['exit_code']==0 for x in receipt['stages'])
for name,digest in receipt['sources'].items():assert sha(ROOT/name)==digest,name
for name,digest in receipt['binaries'].items():assert sha(ROOT/name)==digest,name
stage=out/'staging/AminScatter';stage.mkdir(parents=True)
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
for name in names+['CyrusGallery.dll']:shutil.copy2(native/name,stage/name)
shutil.copy2(core,stage/core.name);shutil.copy2(core.with_suffix('.build.json'),stage/core.with_suffix('.build.json').name)
args=SimpleNamespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=out,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',library_dir=ROOT/'AminScatter/library')
version=build_max.scatter_version();assert version=='0.85.2'
build_max.package('AminScatter','Cyrus Scatter',version,names,'AminScatterObject.ms',args,out/'staging')
mzp=out/f'CyrusScatter-{version}-Max2027.mzp'
with zipfile.ZipFile(mzp) as archive:
 assert archive.testzip() is None
 manifest=json.loads(archive.read('manifest.json'));assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
 for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
 assert b'29000' in archive.read('install.ms') and b'0.85.2' in archive.read('install.ms')
 archive.extractall(out/'payload')
exe=out/f'CyrusScatter-{version}-Max2027-Setup.exe'
subprocess.run([sys.executable,str(ROOT/'AminScatter/tools/build_installer.py'),'--output',str(exe),'--package',str(mzp),'--core',str(core)],check=True)
(out/'candidate.json').write_text(json.dumps({'status':'candidate; host acceptance required','mzp_sha256':sha(mzp),'exe_sha256':sha(exe),'script_sha256':sha(ROOT/'AminScatter/scripts/AminScatterObject.ms'),'native_receipt_sha256':sha(native/'receipt.json'),'manifest':manifest},indent=2))
print('Verified candidate:',out)
