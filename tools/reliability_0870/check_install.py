"""Exercise the exact packaged managed installer in disposable directories."""
from pathlib import Path
import argparse,json,subprocess,shutil,hashlib
ROOT=Path(__file__).resolve().parents[2];p=argparse.ArgumentParser();p.add_argument('package_dir',type=Path);p.add_argument('--root',type=Path,required=True);a=p.parse_args()
out=a.package_dir.resolve();assert out.is_relative_to(ROOT/'build/reliability-0870-20261019')
core=out/'payload/CyrusInstaller.dll';exe=out/'InstallChecks.exe';shutil.copy2(core,out/core.name)
framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319');compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
cmd=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(exe),'/reference:'+str(core),*('/reference:'+str(framework/(n+'.dll')) for n in ('mscorlib','System','System.Core','System.Windows.Forms','System.Drawing')),str(ROOT/'tools/reliability_0870/InstallChecks.cs')]
r=subprocess.run(cmd,capture_output=True,text=True);(out/'install-compile.log').write_text(r.stdout+r.stderr);assert r.returncode==0,r.stdout+r.stderr
r=subprocess.run([str(exe),str(out/'payload'),str(a.root.resolve())],capture_output=True,text=True);(out/'install-tests.log').write_text(r.stdout+r.stderr);print(r.stdout+r.stderr);assert r.returncode==0
(out/'install-receipt.json').write_text(json.dumps({'status':'passed','artist_installation':False,'root':str(a.root.resolve()),'assembly_sha256':hashlib.sha256(core.read_bytes()).hexdigest(),'test_sha256':hashlib.sha256((ROOT/'tools/reliability_0870/InstallChecks.cs').read_bytes()).hexdigest(),'log_sha256':hashlib.sha256((out/'install-tests.log').read_bytes()).hexdigest()},indent=2)+'\n')
