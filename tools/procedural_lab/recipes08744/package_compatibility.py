"""Build the requested three-host EXE from distinct frozen SDK producers."""
from argparse import ArgumentParser,Namespace
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[3];sys.path[:0]=[str(ROOT/'tools'),str(ROOT/'AminScatter/tools')]
import build_max,build_installer
VERSION='0.87.4.4';NAMES=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
p=ArgumentParser();p.add_argument('--run',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args();run=a.run.resolve();out=a.output.resolve()
assert run.is_relative_to(ROOT/'build') and out.is_relative_to(ROOT/'dist') and build_max.scatter_version()==VERSION
core=run/'stage-06/AminScatter/CyrusInstaller.dll';build_installer.verify_core(core)
packages=[];builds={}
for year in [2024,2026,2027]:
 native=run/('native-06' if year==2027 else f'max{year}-native-06');receipt_path=native/'receipt.json'
 receipt=build_max.verify_native_receipt(receipt_path,'AminScatter',year,{n:native/n for n in NAMES})
 assert bool(receipt['tests_run'])==(year==2027)
 if year!=2027:
  assert receipt['source_selection']['build_testing'] is False
  stage=run/f'compatibility-stage-{year}'/'AminScatter';stage.mkdir(parents=True,exist_ok=False)
  for name in NAMES+['CyrusGallery.dll','CyrusGallery.build.json']:shutil.copy2(native/name,stage/name)
  for name in ['CyrusInstaller.dll','CyrusInstaller.build.json']:shutil.copy2(core.parent/name,stage/name)
  settings=Namespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=out,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',content_dir=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content',native_receipts={'AminScatter':receipt_path})
  build_max.package('AminScatter','Cyrus Scatter',VERSION,NAMES,'AminScatterObject.ms',settings,stage.parent)
 package=out/f'CyrusScatter-{VERSION}-Max{year}.mzp'
 with zipfile.ZipFile(package) as z:
  assert z.testzip() is None
  manifest=json.loads(z.read('manifest.json'));assert manifest['max_year']==year and manifest['version']==VERSION
  assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
  for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
  script=z.read('CyrusScatter.ms');guard=z.read('install.ms');assert str((year-1998)*1000).encode() in guard and b'__MAX_' not in guard
  assert b'0.87.4.4' in script and b'fn CyrusRecipeCaptureAuthored' in script
 packages.append(package);builds[str(year)]={'receipt':str(receipt_path),'receipt_sha256':sha(receipt_path),'tests_run':bool(receipt['tests_run']),'runtime_tested':year==2027,'native':{n:sha(native/n) for n in NAMES}}
exe=out/f'CyrusScatter-{VERSION}-Setup.exe';build_installer.build_exe(exe,packages,core)
# Inspect actual embedded resources without launching the installer or Max.
source=run/'ExeResources.cs';probe=run/'ExeResources.exe'
source.write_text('using System;using System.IO;using System.Reflection;using System.Security.Cryptography;class Probe {static int Main(string[] a){var assembly=Assembly.LoadFile(Path.GetFullPath(a[0]));foreach(var name in assembly.GetManifestResourceNames()){using(var stream=assembly.GetManifestResourceStream(name)){Console.WriteLine(name+"\\t"+BitConverter.ToString(SHA256.Create().ComputeHash(stream)).Replace("-","").ToLowerInvariant());}}return 0;}}',encoding='utf-8')
csc=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
subprocess.run([str(csc),'/nologo','/target:exe','/platform:x64','/out:'+str(probe),str(source)],check=True,capture_output=True)
result=subprocess.check_output([str(probe),str(exe)],text=True);resources=dict(line.split('\t') for line in result.splitlines());assert len(resources)==3
for year,package in zip([2024,2026,2027],packages):assert resources[f'Cyrus.Payload.{year}.mzp']==sha(package)
receipt={'status':'passed','version':VERSION,'exe':str(exe),'exe_sha256':sha(exe),'packages':{p.name:sha(p) for p in packages},'embedded_resources':resources,'builds':builds,'scope':'Distinct SDK/native/managed pairs. Runtime checks only in Max 2027. Max 2024/2026 compile and package checks only; no launches or runtime qualification. Installer resources inspected without launching the EXE.','analyzer':'Independent installation retained; not rebuilt or bundled.','content':'Existing independently versioned shared content reused.'}
(out/'DELIVERY_RECEIPT.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
(out/'SHA256SUMS.txt').write_text(''.join(sha(p)+'  '+p.name+'\n' for p in [exe,*packages]),encoding='utf-8')
(out/'READ_ME.txt').write_text('CyrusScatter 0.87.4.4 for Max 2024, 2026 and 2027.\n\nClose the Max versions you want to update. Run CyrusScatter-0.87.4.4-Setup.exe, select the installed versions, and choose Install / Update. Restart Max.\n\nAlternative: Scripting > Run Script > matching Max-year MZP, then restart.\n\nThis release fixes Library recipe transport for Cyrus Edit overrides and prepared interactions. Max 2027 was runtime tested. Max 2024/2026 were compiled and package checked without being launched. Existing static-asset restrictions apply. Independent Analyzer installation and shared content are retained.\n',encoding='utf-8')
print(json.dumps({'exe':str(exe),'sha256':sha(exe),'embedded_max_years':[2024,2026,2027]},indent=2))
