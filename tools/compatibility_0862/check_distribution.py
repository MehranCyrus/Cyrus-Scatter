"""Exact three-host EXE: install, repair, upgrade and recovery in owned paths."""
from pathlib import Path
import hashlib, json, subprocess, zipfile
ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'build/compatibility-0862-20261019'; out = BASE/'distribution01'; out.mkdir(exist_ok=False)
exe = BASE/'package01/CyrusScatter-0.86.2-Setup.exe'
for year in (2024,2026,2027):
    package = ROOT/f'dist/CyrusScatter-0.86.1-20261018/CyrusScatter-0.86.1-Max{year}.mzp'
    with zipfile.ZipFile(package) as archive:
        assert archive.testzip() is None; manifest = json.loads(archive.read('manifest.json'))
        assert manifest['version']=='0.86.1' and manifest['max_year']==year
        for name,digest in manifest['files'].items(): assert hashlib.sha256(archive.read(name)).hexdigest()==digest
        for name in archive.namelist(): assert not Path(name).is_absolute() and '..' not in Path(name).parts
        old = out/f'old-{year}'; archive.extractall(old)
    (out/f'old-{year}.sha256').write_text(hashlib.sha256((old/'InstallInventory.txt').read_bytes()).hexdigest())
source = (ROOT/'tools/library_0861/DistributionChecks.cs').read_text()
source = source.replace('CyrusScatter\\build\\library-surface-0861-', 'CyrusScatter\\build\\compatibility-0862-20261019\\distribution01')
source = source.replace('Library-0.86.1','Library-0.86.2')
source = source.replace('string before=File.ReadAllText(settings);', '''
   Check(File.Exists(Path.Combine(release,"Patterns","catalog.tsv"))&&Directory.GetFiles(Path.Combine(release,"Patterns"),"*.png").Length==3,"Three starter masks are staged for "+year);
   string ini=Path.Combine(target,"Recipient Windows user باغ","3dsMax.ini");Directory.CreateDirectory(Path.GetDirectoryName(ini));
   File.WriteAllText(ini,"[Directories]\\r\\nAdditional Scripts="+paths.Scripts+"\\r\\nAdditional Startup Scripts="+paths.Startup+"\\r\\nAdditional Macros="+paths.Macros+"\\r\\n",System.Text.Encoding.Unicode);
   var routed=Distribution.FromProfile(ini,year);Check(routed.Scripts==paths.Scripts&&routed.Startup==paths.Startup&&routed.Macros==paths.Macros,"Recipient profile paths are read from that user's INI "+year);
   var upgrade=new InstallPaths(Path.Combine(target,"upgrade/scripts"),Path.Combine(target,"upgrade/startup"),Path.Combine(target,"upgrade/macros"),Path.Combine(target,"upgrade/profile"));
   var previous=new InstallEngine(Path.Combine(root,"old-"+year),File.ReadAllText(Path.Combine(root,"old-"+year+".sha256")));
   string previousRelease=previous.Install(upgrade),previousSettings=File.ReadAllText(Path.Combine(upgrade.Profile,"Plugin.UserSettings.ini"));
   bool upgradeRejected=false;try{engine.Install(upgrade,value=>{if(value=="publishing:2")throw new OperationCanceledException("Owned interrupted upgrade");});}catch(OperationCanceledException){upgradeRejected=true;}
   Check(upgradeRejected&&File.ReadAllText(Path.Combine(upgrade.Profile,"Plugin.UserSettings.ini"))==previousSettings,"Interrupted upgrade retains preceding registration "+year);
   string currentRelease=engine.Install(upgrade);Check(currentRelease!=previousRelease&&Directory.Exists(previousRelease)&&File.Exists(Path.Combine(currentRelease,"Patterns","catalog.tsv")),"0.86.1 upgrade retains recovery content and publishes 0.86.2 "+year);
   InstallEngine.RemoveRegistration(upgrade,year);
   string before=File.ReadAllText(settings);''')
src = out/'DistributionChecks.cs'; src.write_text(source,encoding='utf-8')
compiler = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe'); framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
harness=exe.parent/'DistributionChecks0862.exe'
cmd=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/win32manifest:'+str(ROOT/'AminScatter/setup/app.manifest'),'/out:'+str(harness),'/reference:'+str(exe),*('/reference:'+str(framework/(n+'.dll')) for n in ('mscorlib','System','System.Core','System.Drawing','System.Windows.Forms')),str(src)]
r=subprocess.run(cmd,capture_output=True,text=True);(out/'compile.log').write_text(r.stdout+r.stderr);assert r.returncode==0,r.stdout+r.stderr
r=subprocess.run([str(harness),str(exe),str(out)],capture_output=True,text=True);(out/'result.txt').write_text(r.stdout+r.stderr);print(r.stdout+r.stderr);assert r.returncode==0
