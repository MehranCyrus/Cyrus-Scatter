"""Isolated legacy CLR checks, including upgrade from the actual previous MZPs."""
from pathlib import Path
import argparse,json,subprocess,uuid,zipfile
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/installer-0862-20261019-01'
p=argparse.ArgumentParser();p.add_argument('--package',type=Path,default=BASE/'package03');a=p.parse_args()
package=a.package.resolve();out=BASE/('recipient-'+uuid.uuid4().hex[:8]);out.mkdir()
owned=Path('D:/CyrusScatterBuilds/if0862')/uuid.uuid4().hex[:6];owned.mkdir(parents=True)
for year in (2024,2026,2027):
 with zipfile.ZipFile(ROOT/f'dist/CyrusScatter-0.86.2-20261019-multihost01/CyrusScatter-0.86.2-Max{year}.mzp') as z:z.extractall(owned/f'old{year}')
exe=package/'CyrusScatter-0.86.2-Setup.exe';compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe');framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
harness=package/'RecipientChecks.exe'
cmd=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(harness),'/reference:'+str(exe),*('/reference:'+str(framework/(n+'.dll')) for n in ('mscorlib','System','System.Core')),str(ROOT/'tools/installer_0862/RecipientChecks.cs')]
r=subprocess.run(cmd,capture_output=True,text=True);(out/'compile.txt').write_text(r.stdout+r.stderr);assert r.returncode==0,r.stdout+r.stderr
harness.with_suffix('.exe.config').write_text('<configuration><startup><supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.0"/></startup><runtime><AppContextSwitchOverrides value="Switch.System.IO.UseLegacyPathHandling=true;Switch.System.IO.BlockLongPaths=true"/></runtime></configuration>')
r=subprocess.run([str(harness),str(exe),str(owned)],capture_output=True,text=True);(out/'result.txt').write_text(r.stdout+r.stderr);print(r.stdout+r.stderr)
(out/'run.json').write_text(json.dumps({'owned_root':str(owned),'exit_code':r.returncode,'package':str(package)},indent=2)+'\n')
assert r.returncode==0
(BASE/'recipient-latest.txt').write_text(str(out))
