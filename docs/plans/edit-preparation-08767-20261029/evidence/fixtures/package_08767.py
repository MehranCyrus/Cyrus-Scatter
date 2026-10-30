from pathlib import Path
from argparse import Namespace
import sys,shutil,json,hashlib,zipfile
root=Path.cwd();run=root/'build/edit-size-review-20261029-01';frozen=run/'frozen-08767'
sys.path[:0]=[str(frozen/'tools'),str(frozen/'AminScatter/tools')]
import build_max,build_installer
version=build_max.scatter_version();assert version=='0.87.6.7'
core=run/'final-08767-installer/CyrusInstaller.dll';build_installer.build(core)
native=run/'final-08767-native';stage=run/'final-08767-package-stage';folder=stage/'AminScatter';folder.mkdir(parents=True,exist_ok=True)
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
for n in names+['CyrusGallery.dll','CyrusGallery.build.json']:shutil.copy2(native/n,folder/n)
for n in ['CyrusInstaller.dll','CyrusInstaller.build.json']:shutil.copy2(core.parent/n,folder/n)
output=run/'packages-08767';output.mkdir(exist_ok=True)
a=Namespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=output,team_trust_header=frozen/'CyrusLicensing/team/team_public_key.h',content_dir=root/'dist/CyrusScatter-0.86.7-20261020/Content',native_receipts={'AminScatter':native/'receipt.json'})
build_max.package('AminScatter','Cyrus Scatter',version,names,'AminScatterObject.ms',a,stage)
archive=output/f'CyrusScatter-{version}-Max2027.mzp'
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'))
 assert manifest['version']==version and manifest['max_year']==2027
 assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
 for n,h in manifest['files'].items():assert hashlib.sha256(z.read(n)).hexdigest()==h,n
 assert b'29000' in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
 for n in names+['CyrusGallery.dll','CyrusScatter.ms']:assert z.read(n)==(run/'final-08767-payload'/n).read_bytes(),n
receipt=dict(path=str(archive),sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),bytes=archive.stat().st_size,version=version,max_year=2027,archive_crc=True,manifest_hashes=True,host_guard=True,matches_runtime_payload=True)
(run/'package-08767-integrity.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(receipt))
