"""Package exact per-host producers; never installs or starts an artist host."""
from argparse import ArgumentParser,Namespace
from pathlib import Path
import sys,json,shutil,hashlib,zipfile
ROOT=Path(__file__).resolve().parents[3]
sys.path[:0]=[str(ROOT/'tools'),str(ROOT/'AminScatter/tools')]
import build_max,build_installer
p=ArgumentParser();p.add_argument('--run',type=Path,required=True);p.add_argument('--year',type=int,choices=(2024,2026,2027));p.add_argument('--exe',action='store_true');a=p.parse_args()
run=a.run.resolve();assert run.is_relative_to(ROOT/'build')
version=build_max.scatter_version();assert version=='0.87.6.1'
packages=run/'packages';packages.mkdir(exist_ok=True)
core=run/'installer/CyrusInstaller.dll'
if not core.exists():core.parent.mkdir(exist_ok=True);build_installer.build(core)
build_installer.verify_core(core)
if a.year:
    native=run/f'native-{a.year}';names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
    receipt=build_max.verify_native_receipt(native/'receipt.json','AminScatter',a.year,{n:native/n for n in names})
    stage=run/f'package-{a.year}';folder=stage/'AminScatter';folder.mkdir(parents=True,exist_ok=False)
    for n in names+['CyrusGallery.dll','CyrusGallery.build.json']:shutil.copy2(native/n,folder/n)
    for n in ['CyrusInstaller.dll','CyrusInstaller.build.json']:shutil.copy2(core.parent/n,folder/n)
    settings=Namespace(max_year=a.year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=packages,
        team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',content_dir=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content',native_receipts={'AminScatter':native/'receipt.json'})
    build_max.package('AminScatter','Cyrus Scatter',version,names,'AminScatterObject.ms',settings,stage)
    archive=packages/f'CyrusScatter-{version}-Max{a.year}.mzp';payload=run/f'payload-{a.year}';payload.mkdir(exist_ok=False)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        manifest=json.loads(z.read('manifest.json'));assert manifest['version']==version and manifest['max_year']==a.year
        assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
        for n,h in manifest['files'].items():assert hashlib.sha256(z.read(n)).hexdigest()==h,n
        assert str((a.year-1998)*1000).encode() in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
        for n in names+['CyrusScatter.ms','CyrusGallery.dll','CyrusInstaller.dll']:(payload/n).write_bytes(z.read(n))
    (payload/'package-identity.json').write_text(json.dumps(dict(archive=str(archive),sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),host=a.year),indent=2))
    print(archive)
if a.exe:
    mzps=[packages/f'CyrusScatter-{version}-Max{year}.mzp' for year in (2024,2026,2027)]
    assert all(x.is_file() for x in mzps)
    exe=packages/f'CyrusScatter-{version}-Setup.exe';build_installer.build_exe(exe,mzps,core);print(exe)
