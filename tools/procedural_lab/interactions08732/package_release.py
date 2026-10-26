"""Package the explicitly user-selected 0.87.3.2 revision without replacing prior receipts."""
from pathlib import Path
from argparse import Namespace,ArgumentParser
import hashlib,importlib.util,json,sys,zipfile,shutil
ROOT=Path(__file__).resolve().parents[3];sys.path.insert(0,str(ROOT/'tools'))
def module(name,path):
    s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
p=ArgumentParser();p.add_argument('--producer',required=True,type=Path);p.add_argument('--stage',required=True,type=Path);p.add_argument('--output',required=True,type=Path);p.add_argument('--payload',required=True,type=Path);p.add_argument('--allow-untested',action='store_true',help='Only for an explicit user-authorized build-only delivery; record tests_run=false');a=p.parse_args()
producer=a.producer.resolve();stage=a.stage.resolve();folder=stage/'AminScatter'
receipt=json.loads((producer/'receipt.json').read_text());assert receipt['status']=='complete' and (receipt['tests_run'] or a.allow_untested) and receipt['max_year']==2027
folder.mkdir(parents=True,exist_ok=False)
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
for name in names+['CyrusGallery.dll','CyrusGallery.build.json']:shutil.copy2(producer/name,folder/name)
installer=module('installer0873e',ROOT/'AminScatter/tools/build_installer.py');installer.build(folder/'CyrusInstaller.dll')
builder=module('package0873e',ROOT/'tools/build_max.py')
args=Namespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=a.output.resolve(),team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',content_dir=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content',native_receipts={'AminScatter':producer/'receipt.json'})
builder.package('AminScatter','Cyrus Scatter','0.87.3.2',names,'AminScatterObject.ms',args,stage)
archive=args.output/'CyrusScatter-0.87.3.2-Max2027.mzp';payload=a.payload.resolve();payload.mkdir(parents=True,exist_ok=False)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'));assert manifest['version']=='0.87.3.2' and manifest['max_year']==2027
    for name,expected in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==expected,name
    for name in names+['CyrusScatter.ms','CyrusGallery.dll','CyrusInstaller.dll']:(payload/name).write_bytes(z.read(name))
    assert b'29000' in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
    identity={'archive':str(archive),'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'producer':str(producer/'receipt.json'),'tests_run':bool(receipt['tests_run']),'qualification':receipt['qualification'],'files':{p.name:manifest['files'][p.name] for p in payload.iterdir()}}
    (payload/'package-identity.json').write_text(json.dumps(identity,indent=2))
print(json.dumps(identity,indent=2))
