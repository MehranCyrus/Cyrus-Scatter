"""Build only the 0.87.2 Max 2027 Scatter MZP from the sealed producer."""
from pathlib import Path
from argparse import Namespace,ArgumentParser
import hashlib,importlib.util,json,sys,zipfile
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools'))
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
p=ArgumentParser();p.add_argument('--producer',type=Path,default=ROOT/'build/interactions0872-release-20261026-03');p.add_argument('--output',type=Path,default=ROOT/'dist/CyrusScatter-0.87.2-20261026-r2');p.add_argument('--payload',type=Path,default=ROOT/'build/interactions0872-final-payload-20261026-02');a=p.parse_args()
base=a.producer.resolve()
receipt=json.loads((base/'AminScatter/receipt.json').read_text())
assert receipt['status']=='complete' and receipt['tests_run'] and not receipt['preview_fault_lab']
installer=module('installer087',ROOT/'AminScatter/tools/build_installer.py')
installer.build(base/'AminScatter/CyrusInstaller.dll')
builder=module('package087',ROOT/'tools/build_max.py')
output=a.output.resolve()
args=Namespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=output,
    team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',content_dir=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content')
builder.package('AminScatter','Cyrus Scatter','0.87.2',
    ['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'],'AminScatterObject.ms',args,base)
archive=output/'CyrusScatter-0.87.2-Max2027.mzp'
payload=a.payload.resolve()
payload.mkdir(exist_ok=False)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    manifest=json.loads(z.read('manifest.json'))
    assert manifest['version']=='0.87.2' and manifest['max_year']==2027
    for name,expected in manifest['files'].items():
        assert hashlib.sha256(z.read(name)).hexdigest()==expected,name
    for name in ['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatter.ms','CyrusGallery.dll','CyrusInstaller.dll']:
        (payload/name).write_bytes(z.read(name))
    assert b'29000' in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
    (payload/'package-identity.json').write_text(json.dumps({'archive':str(archive),'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'files':{n:manifest['files'][n] for n in [p.name for p in payload.iterdir()]}},indent=2))
print('Final payload',payload)
