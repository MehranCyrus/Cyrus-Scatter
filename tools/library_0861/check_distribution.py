"""Execute the exact universal EXE's extraction/transaction API against owned paths."""
from pathlib import Path
import argparse,subprocess
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--exe',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args();out=a.output.resolve();exe=a.exe.resolve();assert out.is_relative_to(ROOT/'build');out.mkdir(parents=True,exist_ok=True)
compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe');framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319');harness=exe.parent/'DistributionChecks.exe'
command=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/win32manifest:'+str(ROOT/'AminScatter/setup/app.manifest'),'/out:'+str(harness),'/reference:'+str(exe),*('/reference:'+str(framework/(name+'.dll')) for name in ['mscorlib','System','System.Core','System.Drawing','System.Windows.Forms']),str(ROOT/'tools/library_0861/DistributionChecks.cs')]
result=subprocess.run(command,capture_output=True,text=True);(out/'compile.log').write_text(result.stdout+result.stderr);assert result.returncode==0,result.stdout+result.stderr
result=subprocess.run([str(harness),str(exe),str(out)],capture_output=True,text=True);(out/'result.txt').write_text(result.stdout+result.stderr);print(result.stdout+result.stderr);assert result.returncode==0
