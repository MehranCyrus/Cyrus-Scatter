from pathlib import Path
from argparse import Namespace
import sys,shutil,json,hashlib,zipfile
root=Path.cwd();run=root/'build/edit-size-review-20261029-01';frozen=run/'frozen-08767'
sys.path[:0]=[str(frozen/'tools'),str(frozen/'AminScatter/tools')]
import build_max,build_installer
version=build_max.scatter_version();assert version=='0.87.6.7'
packages=run/'compat-packages';packages.mkdir(exist_ok=True)
core=run/'final-08767-installer/CyrusInstaller.dll';build_installer.verify_core(core)
for year in (2024,2026):
 native=run/f'compat-08767-max{year}';stage=run/f'compat-stage-{year}';folder=stage/'AminScatter';folder.mkdir(parents=True,exist_ok=False)
 names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
 for n in names+['CyrusGallery.dll','CyrusGallery.build.json']:shutil.copy2(native/n,folder/n)
 for n in ['CyrusInstaller.dll','CyrusInstaller.build.json']:shutil.copy2(core.parent/n,folder/n)
 a=Namespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=packages,team_trust_header=frozen/'CyrusLicensing/team/team_public_key.h',content_dir=root/'dist/CyrusScatter-0.86.7-20261020/Content',native_receipts={'AminScatter':native/'receipt.json'})
 build_max.package('AminScatter','Cyrus Scatter',version,names,'AminScatterObject.ms',a,stage)
for source in (run/'packages-08767').glob('CyrusScatter-0.87.6.7-Max2027.*'):shutil.copy2(source,packages/source.name)
mzps=[packages/f'CyrusScatter-{version}-Max{year}.mzp' for year in (2024,2026,2027)]
build_installer.build_exe(packages/f'CyrusScatter-{version}-Setup.exe',mzps,core)
print('Complete',packages)
