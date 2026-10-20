from pathlib import Path
import argparse,subprocess,uuid
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/installer-0862-20261019-01'
p=argparse.ArgumentParser();p.add_argument('--name',default='package03');a=p.parse_args();package=BASE/a.name
out=BASE/('ui-'+uuid.uuid4().hex[:8]);out.mkdir();owned=Path('D:/CyrusScatterBuilds/if0862')/uuid.uuid4().hex[:6]
exe=package/'CyrusScatter-0.86.2-Setup.exe';harness=package/'UiChecks.exe';framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319');compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
cmd=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(harness),'/reference:'+str(exe),*('/reference:'+str(framework/(n+'.dll')) for n in ('mscorlib','System','System.Core','System.Drawing','System.Windows.Forms')),str(ROOT/'tools/installer_0862/UiChecks.cs')]
r=subprocess.run(cmd,capture_output=True,text=True);(out/'compile.txt').write_text(r.stdout+r.stderr);assert r.returncode==0,r.stdout+r.stderr
r=subprocess.run([str(harness),str(exe),str(owned),str(out)],capture_output=True,text=True);(out/'result.txt').write_text(r.stdout+r.stderr);print(r.stdout+r.stderr);assert r.returncode==0
(BASE/'ui-latest.txt').write_text(str(out))
