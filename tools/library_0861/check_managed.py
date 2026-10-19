"""Compile and execute the gallery regression harness on the actual net48 CLR."""
from pathlib import Path
import argparse,hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--gallery',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args();out=a.output.resolve();assert out.is_relative_to(ROOT/'build');out.mkdir(parents=True,exist_ok=True)
gallery=a.gallery.resolve();shutil.copy2(gallery,out/gallery.name)
compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe');framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319');source=ROOT/'tools/library_0861/ManagedGalleryChecks.cs';exe=out/'ManagedGalleryChecks.exe'
command=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(exe),'/reference:'+str(out/gallery.name),*('/reference:'+str(framework/(name+'.dll')) for name in ['mscorlib','System','System.Core','System.Drawing','System.Windows.Forms']),str(source)]
result=subprocess.run(command,capture_output=True,text=True);(out/'compile.log').write_text(result.stdout+result.stderr);assert result.returncode==0,result.stdout+result.stderr
inventory=json.loads((ROOT/'AminScatter/library/inventory.json').read_text());thumbnail=ROOT/'AminScatter/library'/inventory['entries'][0]['thumbnail'];data=thumbnail.read_bytes()
result=subprocess.run([str(exe),str(thumbnail),hashlib.sha256(data).hexdigest(),str(len(data)),str(out)],capture_output=True,text=True)
(out/'result.txt').write_text(result.stdout+result.stderr);print(result.stdout+result.stderr);assert result.returncode==0
