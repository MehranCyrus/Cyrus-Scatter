"""Reproduce the preceding core's archive-path failure in an isolated legacy CLR."""
from pathlib import Path
import json,subprocess,uuid,zipfile
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/installer-0862-20261019-01'
out=BASE/('old-probe-'+uuid.uuid4().hex[:8]);out.mkdir();owned=Path('D:/CyrusScatterBuilds/if0862')/uuid.uuid4().hex[:6];owned.mkdir(parents=True)
package=ROOT/'dist/CyrusScatter-0.86.2-20261019-multihost01/CyrusScatter-0.86.2-Max2024.mzp'
deep=owned/('old-extraction-'+('x'*105));deep.mkdir()
with zipfile.ZipFile(package) as z:
 for name in ('CyrusInstaller.dll','InstallInventory.txt'):(owned/name).write_bytes(z.read(name))
(deep/'InstallInventory.txt').write_bytes((owned/'InstallInventory.txt').read_bytes())
source=out/'OldProbe.cs';source.write_text('''using System;using System.IO;using System.Reflection;using System.Security.Cryptography;
[assembly:System.Runtime.Versioning.TargetFramework(".NETFramework,Version=v4.0")]
static class OldProbe { static int Main(string[] args){
 AppContext.SetSwitch("Switch.System.IO.UseLegacyPathHandling",true);AppContext.SetSwitch("Switch.System.IO.BlockLongPaths",true);
 var a=Assembly.LoadFrom(args[0]);string hash;using(var sha=SHA256.Create())hash=BitConverter.ToString(sha.ComputeHash(File.ReadAllBytes(Path.Combine(args[1],"InstallInventory.txt")))).Replace("-","").ToLowerInvariant();
 try{Activator.CreateInstance(a.GetType("Cyrus.Setup.InstallEngine"),new object[]{args[1],hash});Console.WriteLine("FAIL: preceding core admitted the deep source");return 1;}
 catch(TargetInvocationException e){Console.WriteLine(e.InnerException);if(!(e.InnerException is PathTooLongException))return 1;Console.WriteLine("PASS: actual preceding core reproduces PathTooLongException with legacy handling; Windows/Max settings unchanged");return 0;}
} }''')
framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319');compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe');exe=out/'OldProbe.exe'
cmd=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(exe),*('/reference:'+str(framework/(n+'.dll')) for n in ('mscorlib','System','System.Core')),str(source)]
r=subprocess.run(cmd,capture_output=True,text=True);(out/'compile.txt').write_text(r.stdout+r.stderr);assert r.returncode==0,r.stdout+r.stderr
exe.with_suffix('.exe.config').write_text('<configuration><startup><supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.0"/></startup><runtime><AppContextSwitchOverrides value="Switch.System.IO.UseLegacyPathHandling=true;Switch.System.IO.BlockLongPaths=true"/></runtime></configuration>')
r=subprocess.run([str(exe),str(owned/'CyrusInstaller.dll'),str(deep)],capture_output=True,text=True);(out/'result.txt').write_text(r.stdout+r.stderr);print(r.stdout+r.stderr)
(out/'run.json').write_text(json.dumps({'owned_root':str(owned),'preceding_package':str(package),'exit_code':r.returncode,'max_default_reproduction':False},indent=2)+'\n');assert r.returncode==0
(BASE/'old-probe-latest.txt').write_text(str(out))
