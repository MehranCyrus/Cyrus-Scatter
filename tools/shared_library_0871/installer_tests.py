"""Qualify the exact EXE's embedded installer in explicitly owned profiles."""
from pathlib import Path
import argparse,json,hashlib,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2]
def main():
    p=argparse.ArgumentParser();p.add_argument('--exe',type=Path,required=True);p.add_argument('--core',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--data',type=Path,required=True);a=p.parse_args()
    out=a.output.resolve();data=a.data.resolve();assert out.is_relative_to(ROOT/'build') and data.is_relative_to(ROOT/'build')
    out.mkdir(parents=True,exist_ok=False);assert not data.exists();core=out/'CyrusInstaller.dll';shutil.copy2(a.core,core);shutil.copy2(a.exe,out/a.exe.name)
    csc=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe');framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
    command=[str(csc),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/platform:x64','/out:'+str(out/'InstallerChecks.exe'),'/reference:'+str(a.exe.resolve()),*('/reference:'+str(framework/(x+'.dll')) for x in ('mscorlib','System','System.Core','System.IO.Compression')),str(Path(__file__).with_name('InstallerChecks.cs'))]
    compile_result=subprocess.run(command,text=True,capture_output=True);(out/'compile.log').write_text(compile_result.stdout+compile_result.stderr);assert compile_result.returncode==0,compile_result.stdout+compile_result.stderr
    result=subprocess.run([str(out/'InstallerChecks.exe'),str(a.exe.resolve()),str(data),str(ROOT/'build')],text=True,capture_output=True);(out/'tests.log').write_text(result.stdout+result.stderr)
    installed={}
    for line in result.stdout.splitlines():
        if line.startswith('INSTALLED\t'):
            _,year,release,startup,macros,profile=line.split('\t');installed[year]=dict(release=release,startup=startup,macros=macros,profile=profile)
    (out/'installed.json').write_text(json.dumps(installed,indent=2));(out/'receipt.json').write_text(json.dumps(dict(status='pass' if not result.returncode else 'failed',exe=str(a.exe.resolve()),exe_sha256=hashlib.sha256(a.exe.read_bytes()).hexdigest(),core_sha256=hashlib.sha256(core.read_bytes()).hexdigest(),installed=installed),indent=2))
    print(result.stdout[-2000:]+result.stderr);raise SystemExit(result.returncode)
if __name__=='__main__':main()
