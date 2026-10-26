"""Compile and run file-transaction tests; never launches Max or changes profiles."""
from pathlib import Path
import argparse, json, subprocess, hashlib
ROOT=Path(__file__).resolve().parents[2]
def main():
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();out=a.output.resolve()
    if not out.is_relative_to(ROOT/'build'):raise ValueError('Owned build directory required')
    out.mkdir(parents=True,exist_ok=False)
    csc=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
    framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
    sources=sorted((ROOT/'AminScatter/shared').glob('*.cs'))+[Path(__file__).with_name('StoreTests.cs')]
    refs=[framework/(x+'.dll') for x in ('mscorlib','System','System.Core','System.IO.Compression')]
    exe=out/'StoreTests.exe';cmd=[str(csc),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(exe),*('/reference:'+str(x) for x in refs),*map(str,sources)]
    result=subprocess.run(cmd,text=True,capture_output=True);(out/'compile.log').write_text(result.stdout+result.stderr)
    if result.returncode:raise RuntimeError(result.stdout+result.stderr)
    data=ROOT/'build'/('sl871-tests-'+out.name.rsplit('-',1)[-1])
    run=subprocess.run([str(exe),str(data)],text=True,capture_output=True);(out/'test.log').write_text(run.stdout+run.stderr)
    receipt={'status':'pass' if not run.returncode else 'failed','command':cmd,'source_hashes':{str(x.relative_to(ROOT)):hashlib.sha256(x.read_bytes()).hexdigest() for x in sources},'stdout':run.stdout,'stderr':run.stderr}
    (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(run.stdout+run.stderr,flush=True)
    if run.returncode:raise SystemExit(run.returncode)
if __name__=='__main__':main()
