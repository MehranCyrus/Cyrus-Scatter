"""Exercise each older host's exact gallery assembly on its target CLR."""
from pathlib import Path
import argparse, hashlib, json, shutil, subprocess
ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser(); p.add_argument('--year', type=int, choices=(2024,2026), required=True); a = p.parse_args()
out = ROOT/f'build/compatibility-0862-20261019/managed{a.year}'; out.mkdir(parents=True, exist_ok=False)
gallery = Path(f'D:/CyrusScatterBuilds/compatibility-0862-20261019/native{a.year}/CyrusGallery.dll')
receipt = json.loads(gallery.with_suffix('.build.json').read_text())
assert receipt['max_year'] == a.year and hashlib.sha256(gallery.read_bytes()).hexdigest() == receipt['artifact_sha256']
shutil.copy2(gallery, out/gallery.name)
source = (ROOT/'tools/library_0861/ManagedGalleryChecks.cs').read_text()
source = source.replace('new[]{0.0,1.0,1.5}', 'new[]{0.0,1.0,1.5,2.0}')
source = source.replace('Console.WriteLine("PASSED', '''using(var patterns=new DensityPatternPanel()) {
            patterns.LoadPatterns(args[4]);Check(patterns.Gallery.ItemCount==3,"All three product patterns appear on the target CLR");
            patterns.Gallery.SelectedIndex=0;Check(File.Exists(patterns.SelectedPath)&&patterns.SelectedHash.Length==64,"Selected pattern retains absolute path and content hash");
            string empty=Path.Combine(args[3],"empty-patterns");Directory.CreateDirectory(empty);File.WriteAllText(Path.Combine(empty,"catalog.tsv"),"");
            patterns.LoadPatterns(empty);Check(patterns.Gallery.ItemCount==0,"Empty catalog safely clears the pattern view");
        }
        Console.WriteLine("PASSED''')
refs = list(receipt['references'])+[str(gallery)]
if a.year == 2026:
    source = source.replace('net48', 'net8').replace('.NET Framework 4.8', '.NET 8')
    core = Path('C:/Program Files/dotnet/shared/Microsoft.NETCore.App/8.0.16')
    refs += [str(core/(n+'.dll')) for n in ('System.Console','System.Diagnostics.TraceSource','System.Diagnostics.Process','System.Runtime.Extensions')]
src = out/'ManagedChecks.cs'; src.write_text(source, encoding='utf-8')
exe = out/('ManagedChecks.exe' if a.year == 2024 else 'ManagedChecks.dll')
cmd = [receipt['compiler'], '/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+', '/target:exe','/platform:x64','/out:'+str(exe),
       *('/reference:'+name for name in dict.fromkeys(refs)), str(src)]
r = subprocess.run(cmd, capture_output=True, text=True); (out/'compile.log').write_text(r.stdout+r.stderr); assert r.returncode==0, r.stdout+r.stderr
command = [str(exe)]
if a.year == 2026:
    exe.with_suffix('.runtimeconfig.json').write_text(json.dumps({'runtimeOptions':{'tfm':'net8.0','framework':{'name':'Microsoft.WindowsDesktop.App','version':'8.0.16'}}}))
    command = ['C:/Program Files/dotnet/dotnet.exe', str(exe)]
inv = json.loads((ROOT/'AminScatter/library/inventory.json').read_text()); thumbnail = ROOT/'AminScatter/library'/inv['entries'][0]['thumbnail']
r = subprocess.run(command+[str(thumbnail),hashlib.sha256(thumbnail.read_bytes()).hexdigest(),str(thumbnail.stat().st_size),str(out),str(ROOT/'AminScatter/patterns')],capture_output=True,text=True)
(out/'result.txt').write_text(r.stdout+r.stderr); print(r.stdout+r.stderr); assert r.returncode==0
