"""Package exact source/SDK pairs for three hosts and embed their MZPs in one EXE."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'));import build_max
p=argparse.ArgumentParser();p.add_argument('--build',required=True,type=Path);p.add_argument('--libraries',required=True,type=Path);p.add_argument('--core',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args()
base=a.build.resolve();out=a.output.resolve();core=a.core.resolve();assert out.is_relative_to(ROOT/'build') and not out.exists()
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
version=build_max.scatter_version();assert version=='0.86.1';out.mkdir(parents=True)
packages=[];receipts={}
for year in (2024,2026,2027):
 native=base/f'native{year}';receipt=json.loads((native/'receipt.json').read_text())
 assert receipt['max_year']==year and not receipt.get('placement_qualification') and not receipt.get('preview_fault_lab') and all(stage['exit_code']==0 for stage in receipt['stages'])
 for name,digest in receipt['sources'].items():assert sha(ROOT/name)==digest,name
 for name,digest in receipt['binaries'].items():assert sha(ROOT/name)==digest,name
 stage=out/f'staging{year}/AminScatter';stage.mkdir(parents=True)
 names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
 for name in names+['CyrusGallery.dll']:shutil.copy2(native/name,stage/name)
 shutil.copy2(core,stage/core.name);shutil.copy2(core.with_suffix('.build.json'),stage/core.with_suffix('.build.json').name)
 args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=out,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',library_dir=a.libraries.resolve()/f'library{year}')
 build_max.package('AminScatter','Cyrus Scatter',version,names,'AminScatterObject.ms',args,stage.parent)
 package=out/f'CyrusScatter-{version}-Max{year}.mzp'
 with zipfile.ZipFile(package) as archive:
  assert archive.testzip() is None;manifest=json.loads(archive.read('manifest.json'))
  assert manifest['max_year']==year and manifest['version']==version
  assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
  for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
  assert str((year-1998)*1000).encode() in archive.read('install.ms')
  archive.extractall(out/f'payload{year}')
 packages.append(package);receipts[str(year)]={'native_receipt_sha256':sha(native/'receipt.json'),'mzp_sha256':sha(package),'manifest':manifest}
exe=out/f'CyrusScatter-{version}-Setup.exe'
command=[sys.executable,str(ROOT/'AminScatter/tools/build_installer.py'),'--output',str(exe),'--core',str(core)]
for package in packages:command+=['--package',str(package)]
subprocess.run(command,check=True)
(out/'candidate.json').write_text(json.dumps({'version':version,'status':'Candidate; runtime and distribution qualification are separate','exe_sha256':sha(exe),'packages':receipts},indent=2)+'\n')
print('Verified candidate:',out)
