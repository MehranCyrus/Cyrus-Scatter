"""Exercise the exact Max 2027 managed assembly in a .NET 10 Windows process."""
from pathlib import Path
import argparse,hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--gallery',required=True,type=Path);p.add_argument('--output',required=True,type=Path);a=p.parse_args()
out=a.output.resolve();assert out.is_relative_to(ROOT/'build');out.mkdir(parents=True,exist_ok=True)
gallery=a.gallery.resolve();receipt=json.loads(gallery.with_suffix('.build.json').read_text(encoding='utf-8'));assert receipt['max_year']==2027
assert hashlib.sha256(gallery.read_bytes()).hexdigest()==receipt['artifact_sha256'];shutil.copy2(gallery,out/gallery.name)
source=(ROOT/'tools/library_0861/ManagedGalleryChecks.cs').read_text(encoding='utf-8')
source=source.replace('new[]{0.0,1.0,1.5}','new[]{0.0,1.0,1.5,2.0}').replace('net48','net10').replace('.NET Framework 4.8','.NET 10')
source=source.replace('Console.WriteLine("PASSED', '''using(var patterns=new DensityPatternPanel()) {
            patterns.LoadPatterns(args[4]);Check(patterns.Gallery.ItemCount==3,"Three original generated reference patterns are present");
            patterns.Gallery.SelectedIndex=0;Check(File.Exists(patterns.SelectedPath)&&patterns.SelectedHash.Length==64,"Pattern selection retains content identity and an absolute path");
            patterns.LoadPatterns(args[5]);Check(patterns.Gallery.ItemCount==3,"Product catalog presents all three installed starter patterns");
            string empty=Path.Combine(args[3],"empty-patterns");Directory.CreateDirectory(empty);File.WriteAllText(Path.Combine(empty,"catalog.tsv"),"");patterns.LoadPatterns(empty);Check(patterns.Gallery.ItemCount==0,"An empty catalog clears the browser safely");
        }
        Console.WriteLine("PASSED''')
path=out/'ManagedChecks.cs';path.write_text(source,encoding='utf-8')
core=Path('C:/Program Files/dotnet/shared/Microsoft.NETCore.App/10.0.0')
refs=list(receipt['references'])+[str(gallery)]+[str(core/(name+'.dll')) for name in ('System.Console','System.Diagnostics.TraceSource','System.Diagnostics.Process','System.Runtime.Extensions')]
exe=out/'ManagedChecks.dll'
command=[receipt['compiler'],'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(exe),*('/reference:'+name for name in dict.fromkeys(refs)),str(path)]
r=subprocess.run(command,capture_output=True,text=True);(out/'compile.log').write_text(r.stdout+r.stderr,encoding='utf-8');assert r.returncode==0,r.stdout+r.stderr
exe.with_suffix('.runtimeconfig.json').write_text(json.dumps({'runtimeOptions':{'tfm':'net10.0','framework':{'name':'Microsoft.WindowsDesktop.App','version':'10.0.0'}}}))
inventory=json.loads((ROOT/'AminScatter/library/inventory.json').read_text());thumbnail=ROOT/'AminScatter/library'/inventory['entries'][0]['thumbnail'];data=thumbnail.read_bytes()
r=subprocess.run(['C:/Program Files/dotnet/dotnet.exe',str(exe),str(thumbnail),hashlib.sha256(data).hexdigest(),str(len(data)),str(out),str(ROOT/'tools/density_0862/patterns'),str(ROOT/'AminScatter/patterns')],capture_output=True,text=True)
(out/'result.txt').write_text(r.stdout+r.stderr,encoding='utf-8');print(r.stdout+r.stderr);assert r.returncode==0
