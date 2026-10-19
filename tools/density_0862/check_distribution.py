"""Execute this exact single-host EXE against disposable paths, never artist profiles."""
from pathlib import Path
import argparse,hashlib,json,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--exe',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--previous-package',type=Path);a=p.parse_args()
out=a.output.resolve();exe=a.exe.resolve();assert any(out.is_relative_to(ROOT/'build'/folder) for folder in ('density-recipes-0862-20261018-01','ui-polish-0862-20261019'));out.mkdir(parents=True,exist_ok=True)
source=(ROOT/'tools/library_0861/DistributionChecks.cs').read_text(encoding='utf-8')
source=source.replace('CyrusScatter\\build\\library-surface-0861-',str(out.relative_to(ROOT.parent)))
source=source.replace('"2024,2026,2027"','"2027"').replace('One EXE has three distinct host descriptors','EXE advertises only its qualified Max 2027 payload')
source=source.replace('host.Items.Count==3&&host.Items[0].ToString().Contains("preview")','host.Items.Count==1&&host.Items[0].ToString()=="3ds Max 2027"')
source=source.replace('Installer exposes three hosts and labels unqualified 2024 preview','Installer lists its one matching host')
source=source.replace('Library-0.86.1','Library-0.86.2')
old_package=(a.previous_package or ROOT/'dist/CyrusScatter-0.86.1-20261018/CyrusScatter-0.86.1-Max2027.mzp').resolve()
old=out/'old-payload'
with zipfile.ZipFile(old_package) as archive:
    assert archive.testzip() is None;manifest=json.loads(archive.read('manifest.json'))
    assert manifest['version'] in ('0.86.1','0.86.2') and manifest['max_year']==2027
    for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest
    for name in archive.namelist():assert not Path(name).is_absolute() and '..' not in Path(name).parts
    archive.extractall(old)
old_hash=hashlib.sha256((old/'InstallInventory.txt').read_bytes()).hexdigest()
source=source.replace('string before=File.ReadAllText(settings);', '''
   var upgrade=new InstallPaths(Path.Combine(target,"upgrade/scripts"),Path.Combine(target,"upgrade/startup"),Path.Combine(target,"upgrade/macros"),Path.Combine(target,"upgrade/profile"));
   var previous=new InstallEngine(args[2],args[3]);string previousRelease=previous.Install(upgrade),previousSettings=File.ReadAllText(Path.Combine(upgrade.Profile,"Plugin.UserSettings.ini"));
   bool upgradeRejected=false;try{engine.Install(upgrade,value=>{if(value=="publishing:2")throw new OperationCanceledException("Owned interrupted upgrade");});}catch(OperationCanceledException){upgradeRejected=true;}
   Check(upgradeRejected&&File.ReadAllText(Path.Combine(upgrade.Profile,"Plugin.UserSettings.ini"))==previousSettings,"Interrupted upgrade retains the old registration");
   string currentRelease=engine.Install(upgrade);Check(currentRelease!=previousRelease&&Directory.Exists(previousRelease)&&File.Exists(Path.Combine(currentRelease,"Patterns","catalog.tsv")),"0.86.1 to 0.86.2 upgrade retains recovery files and stages new content");
   InstallEngine.RemoveRegistration(upgrade,year);
   string before=File.ReadAllText(settings);''')
source=source.replace('Check(File.Exists(Path.Combine(release,"Library-0.86.2","inventory.json")),"Bundled presets stage for "+year);','''Check(File.Exists(Path.Combine(release,"Library-0.86.2","inventory.json")),"Bundled presets stage for "+year);
   Check(File.Exists(Path.Combine(release,"Patterns","catalog.tsv"))&&Directory.GetFiles(Path.Combine(release,"Patterns"),"*.png").Length==3,"Three product starter masks are installed with their catalog");''')
source=source.replace('0.86.1 to 0.86.2 upgrade',manifest['version']+' to corrected 0.86.2 upgrade')
path=out/'DistributionChecks.cs';path.write_text(source,encoding='utf-8');harness=exe.parent/'DistributionChecks0862.exe'
compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe');framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
command=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/win32manifest:'+str(ROOT/'AminScatter/setup/app.manifest'),'/out:'+str(harness),'/reference:'+str(exe),*('/reference:'+str(framework/(name+'.dll')) for name in ['mscorlib','System','System.Core','System.Drawing','System.Windows.Forms']),str(path)]
r=subprocess.run(command,capture_output=True,text=True);(out/'compile.log').write_text(r.stdout+r.stderr,encoding='utf-8');assert r.returncode==0,r.stdout+r.stderr
r=subprocess.run([str(harness),str(exe),str(out),str(old),old_hash],capture_output=True,text=True);(out/'result.txt').write_text(r.stdout+r.stderr,encoding='utf-8');print(r.stdout+r.stderr);assert r.returncode==0
