"""Package the qualified host pairs; reference the existing shared content."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,sys,zipfile
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('--work',type=Path,default=ROOT/'build/final-08672-20261020')
parser.add_argument('--output',type=Path,default=ROOT/'dist/CyrusScatter-0.86.7.2-20261020')
parser.add_argument('--compiled',type=Path,default=ROOT/'build/final-08672-20261020')
options=parser.parse_args()
WORK=options.work.resolve();OUT=options.output.resolve();COMPILED=options.compiled.resolve()
WORK.mkdir(parents=True,exist_ok=True)
CONTENT=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content'
sys.path.insert(0,str(ROOT/'tools'));import build_max
sys.path.insert(0,str(ROOT/'AminScatter/tools'));import build_installer
sha=lambda p:hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
packages=[]
for year in (2024,2026,2027):
    base=WORK/f'package{year}';runtime=base/'AminScatter';runtime.mkdir(parents=True,exist_ok=True)
    for name in names+['CyrusGallery.dll']:
        shutil.copy2(COMPILED/f'max{year}'/name,runtime/name)
    for name in ['CyrusInstaller.dll','CyrusInstaller.build.json']:
        shutil.copy2(COMPILED/name,runtime/name)
    args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',
        output=OUT,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',content_dir=CONTENT)
    build_max.package('AminScatter','Cyrus Scatter','0.86.7.2',names,'AminScatterObject.ms',args,base)
    mzp=OUT/f'CyrusScatter-0.86.7.2-Max{year}.mzp'
    with zipfile.ZipFile(mzp) as archive:
        assert archive.testzip() is None
        manifest=json.loads(archive.read('manifest.json'))
        assert manifest['max_year']==year and manifest['version']=='0.86.7.2'
        for name,digest in manifest['files'].items():
            assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
        for name in names+['CyrusGallery.dll']:
            assert manifest['files'][name]==sha(COMPILED/f'max{year}'/name)
        assert manifest['files']['CyrusScatter.ms']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
        assert str((year-1998)*1000).encode() in archive.read('install.ms')
        payload=WORK/f'payload-final{year}';payload.mkdir(exist_ok=True)
        for name in archive.namelist():
            assert not Path(name).is_absolute() and '..' not in Path(name).parts
        archive.extractall(payload)
    packages.append(mzp)
exe=OUT/'CyrusScatter-0.86.7.2-Setup.exe'
build_installer.build_exe(exe,packages,COMPILED/'CyrusInstaller.dll')
(OUT/'SHA256SUMS.txt').write_text('\n'.join(sha(p)+'  '+p.name for p in [exe,*packages,CONTENT/'content-manifest.json'])+'\n')
(WORK/'package-checks.json').write_text(json.dumps({'status':'passed','hosts':[2024,2026,2027],
    'checks':['archive CRC','every member SHA256','exact compiled payloads','generated script identity','host/version guards'],
    'packages':{p.name:sha(p) for p in [exe,*packages]},'content_copied':False},indent=2)+'\n')
print(OUT)
