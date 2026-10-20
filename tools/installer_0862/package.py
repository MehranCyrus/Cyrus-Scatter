"""Package the path/UI correction without changing the qualified Scatter pair."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools'));import build_max
BASE=ROOT/'build/installer-0862-20261019-01'
p=argparse.ArgumentParser();p.add_argument('--name',default='package03');p.add_argument('--core',default='core02');a=p.parse_args();assert a.name.startswith('package') and a.name.isalnum();assert a.core.startswith('core') and a.core.isalnum();OUT=BASE/a.name
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert not OUT.exists();OUT.mkdir(parents=True)
core=BASE/a.core/'CyrusInstaller.dll';packages=[];records={}
for year in (2024,2026,2027):
 native=Path(f'D:/CyrusScatterBuilds/compatibility-0862-20261019/native{year}') if year!=2027 else Path('D:/CyrusScatterBuilds/ui-polish-0862-20261019/pair03')
 receipt=json.loads((native/'receipt.json').read_text());assert receipt['max_year']==year
 for key in ('sources','binaries'):
  for name,digest in receipt[key].items():assert sha(ROOT/name)==digest,name
 stage=OUT/f'stage{year}/AminScatter';stage.mkdir(parents=True)
 names=['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm']
 for name in names+['CyrusGallery.dll']:shutil.copy2(native/name,stage/name)
 for p in (core,core.with_suffix('.build.json')):shutil.copy2(p,stage/p.name)
 library=(ROOT/f'build/compatibility-0862-20261019/libraries/library{year}') if year!=2027 else ROOT/'build/compatibility-0862-20261019/package01/payload2027/Library'
 args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=OUT,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',library_dir=library)
 build_max.package('AminScatter','Cyrus Scatter','0.86.2',names,'AminScatterObject.ms',args,stage.parent)
 package=OUT/f'CyrusScatter-0.86.2-Max{year}.mzp'
 with zipfile.ZipFile(package) as z:
  assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'))
  for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
  inventory=z.read('InstallInventory.txt').decode().splitlines();assert inventory[0].startswith('CyrusScatterInstall2\t')
  logical={}
  for line in inventory[1:]:
   name,digest,size,source=line.split('\t');data=z.read(source)
   assert hashlib.sha256(data).hexdigest()==digest and len(data)==int(size)
   assert len(source)<64;logical[name]={'source':source,'sha256':digest,'bytes':int(size)}
  assert not any(n.startswith('Library/') for n in z.namelist())
  assert {n for n in logical if n.startswith('Library/')}=={'Library/'+n for n in json.loads((library/'inventory.json').read_text())['files']}|{'Library/inventory.json'}
  assert manifest['licensing']['mode']=='offline-team'
  for name in names+['CyrusGallery.dll']:assert manifest['files'][name]==sha(native/name)
  assert manifest['files']['CyrusScatter.ms']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
  z.extractall(OUT/f'payload{year}')
 records[str(year)]={'native_receipt':str(native/'receipt.json'),'native_receipt_sha256':sha(native/'receipt.json'),'mzp_sha256':sha(package),'manifest':manifest,'logical_inventory':logical}
 packages.append(package)
exe=OUT/'CyrusScatter-0.86.2-Setup.exe'
cmd=[sys.executable,str(ROOT/'AminScatter/tools/build_installer.py'),'--output',str(exe),'--core',str(core)]
for p in packages:cmd+=['--package',str(p)]
subprocess.run(cmd,check=True)
(OUT/'candidate.json').write_text(json.dumps({'version':'0.86.2','status':'Candidate; runtime/recipient qualification separate','exe_sha256':sha(exe),'packages':records},indent=2)+'\n')
print('Verified all three compact package inventories and unchanged native/script/gallery identities')
