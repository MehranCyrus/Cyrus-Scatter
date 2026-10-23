from pathlib import Path
import argparse,hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/combined-installer-08685-20261022'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--run',required=True);a=p.parse_args()
    if not a.candidate.isalnum() or not a.run.isalnum():raise ValueError('Fresh alphanumeric names required')
    out=WORK/a.run;out.mkdir(exist_ok=False);recipient=out/'only-exe';recipient.mkdir()
    source=WORK/a.candidate/'CyrusScatter-0.86.8.5-Setup.exe';exe=recipient/source.name;shutil.copy2(source,exe);assert sha(exe)==sha(source)
    csc=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
    framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319');helper=recipient/'CombinedInstallerChecks.exe'
    fixture=Path(__file__).with_name('CombinedInstallerChecks.cs')
    command=[str(csc),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(helper),'/reference:'+str(exe),
        *('/reference:'+str(framework/n) for n in ['mscorlib.dll','System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll']),str(fixture)]
    subprocess.run(command,check=True)
    with (out/'checks.log').open('w',encoding='utf-8') as f:
        result=subprocess.run([str(helper),str(exe),str(out/'results'),str(WORK/'legacy-analyzer-startup.ms')],stdout=f,stderr=subprocess.STDOUT,timeout=600)
    data={'exe':str(exe),'exe_sha256':sha(exe),'fixture_sha256':sha(fixture),'exit_code':result.returncode,'output':str(out),'checks':None}
    if result.returncode==0:data['checks']=int((out/'results/passed.txt').read_text(encoding='utf-8'))
    (out/'receipt.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8');print(json.dumps(data),flush=True)
    if result.returncode:print((out/'checks.log').read_text(encoding='utf-8')[-5000:]);raise SystemExit(result.returncode)
if __name__=='__main__':main()
