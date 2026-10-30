"""Read packaged bytes and embedded EXE resources without running the installer."""
from pathlib import Path
import hashlib,json,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[3]
RUN=ROOT/'build/terraces0877-20261029-01';OUT=RUN/'packages'
sys.path[:0]=[str(ROOT/'tools'),str(ROOT/'AminScatter/tools')]
import build_max
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
version='0.87.6.1';builds={};archives={}
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
for year in (2024,2026,2027):
    native=RUN/f'native-{year}'
    receipt=build_max.verify_native_receipt(native/'receipt.json','AminScatter',year,{n:native/n for n in names})
    package=OUT/f'CyrusScatter-{version}-Max{year}.mzp'
    with zipfile.ZipFile(package) as z:
        assert z.testzip() is None
        manifest=json.loads(z.read('manifest.json'))
        assert manifest['version']==version and manifest['max_year']==year
        for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
        assert hashlib.sha256(z.read('CyrusScatter.ms')).hexdigest()==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
        for name in names:assert hashlib.sha256(z.read(name)).hexdigest()==sha(native/name)
    archives[package.name]=sha(package)
    builds[str(year)]=dict(receipt_sha256=sha(native/'receipt.json'),native={n:sha(native/n) for n in names},host_tested=year==2027)
source=RUN/'ExeResources.cs';probe=RUN/'ExeResources.exe'
source.write_text('using System;using System.IO;using System.Reflection;using System.Security.Cryptography;class Probe {static void Main(string[] a){var assembly=Assembly.LoadFile(Path.GetFullPath(a[0]));foreach(var name in assembly.GetManifestResourceNames()){using(var stream=assembly.GetManifestResourceStream(name)){Console.WriteLine(name+"\\t"+BitConverter.ToString(SHA256.Create().ComputeHash(stream)).Replace("-","").ToLowerInvariant());}}}}',encoding='utf-8')
compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
subprocess.run([str(compiler),'/nologo','/target:exe','/platform:x64','/out:'+str(probe),str(source)],check=True,capture_output=True)
exe=OUT/f'CyrusScatter-{version}-Setup.exe'
resources=dict(line.split('\t') for line in subprocess.check_output([str(probe),str(exe)],text=True).splitlines())
assert len(resources)==3
for year in (2024,2026,2027):assert resources[f'Cyrus.Payload.{year}.mzp']==archives[f'CyrusScatter-{version}-Max{year}.mzp']
data=dict(status='passed',version=version,exe_sha256=sha(exe),exe_bytes=exe.stat().st_size,packages=archives,embedded_resources=resources,builds=builds,
          scope='Exact-source native SDK builds and ZIP/EXE payload integrity. Max 2027 native and owned-host evidence is separate. Max 2024/2026 were not launched. Installer was not executed in artist profiles.',
          content='Existing shared library and independently installed Surface Analyzer are retained; optional content ZIP is not embedded.')
(OUT/'PACKAGE_VERIFICATION.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
(OUT/'SHA256SUMS.txt').write_text(''.join(sha(p)+'  '+p.name+'\n' for p in [exe,*[OUT/n for n in archives]]),encoding='utf-8')
print(json.dumps(dict(status=data['status'],version=version,exe_bytes=data['exe_bytes'],embedded_years=[2024,2026,2027]),indent=2))
