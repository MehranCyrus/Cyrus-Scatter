"""Run the matched MZP's installer engine into a disposable local profile."""
from argparse import ArgumentParser
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[3]
parser = ArgumentParser()
parser.add_argument('--archive', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
archive, output = args.archive.resolve(), args.output.resolve()
if not output.is_relative_to(ROOT / 'build') or output.exists():
    raise ValueError('A fresh owned build directory is required')
output.mkdir(parents=True)
package, scripts, startup, macros, profile, runtime = [output / x for x in ('package', 'scripts', 'startup', 'macros', 'profile', 'runtime')]
for folder in (package, scripts, startup, macros, profile, runtime):
    folder.mkdir()
with zipfile.ZipFile(archive) as z:
    if z.testzip() is not None:
        raise ValueError('MZP integrity failed')
    for item in z.infolist():
        destination = (package / item.filename).resolve()
        if not destination.is_relative_to(package):
            raise ValueError('MZP member escaped the owned extraction folder')
    z.extractall(package)
    manifest = json.loads(z.read('manifest.json'))
    if manifest['version'] != '0.87.4.4' or manifest['max_year'] != 2027:
        raise ValueError('MZP identity differs from the intended Max 2027 package')
    for name, expected in manifest['files'].items():
        if hashlib.sha256(z.read(name)).hexdigest() != expected:
            raise ValueError('MZP payload hash differs: ' + name)
    install = z.read('install.ms').decode('utf-8-sig')
match = re.search(r'dotNetObject\s+"Cyrus\.Setup\.InstallEngine"\s+packageDir\s+"([0-9a-f]{64})"', install)
if not match:
    raise ValueError('MZP install manifest hash was not found')
source = r'''using System;
using System.IO;
using Cyrus.Setup;
class Program {
  static int Main(string[] a) {
    try {
      var paths=new InstallPaths(a[1],a[2],a[3],a[4],a[5]);
      var engine=new InstallEngine(a[0],a[6]);
      if(engine.Year!="2027" || engine.Version!="0.87.4.4") throw new Exception("Installer identity differs");
      var release=engine.Install(paths);
      Console.WriteLine("RELEASE\t"+release);
      return 0;
    } catch(Exception e) { Console.Error.WriteLine(e); return 1; }
  }
}'''
(output / 'InstallerProbe.cs').write_text(source, encoding='utf-8')
shutil.copy2(package / 'CyrusInstaller.dll', output / 'CyrusInstaller.dll')
csc = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
framework = Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
command = [str(csc), '/nologo', '/noconfig', '/nostdlib+', '/langversion:latest', '/platform:x64',
           '/out:'+str(output / 'InstallerProbe.exe'), '/reference:'+str(output / 'CyrusInstaller.dll'),
           *('/reference:'+str(framework/(name+'.dll')) for name in ('mscorlib', 'System', 'System.Core')),
           str(output / 'InstallerProbe.cs')]
built = subprocess.run(command, text=True, capture_output=True)
(output / 'compile.log').write_text(built.stdout+built.stderr, encoding='utf-8')
if built.returncode:
    raise RuntimeError('Installer probe did not compile; inspect the owned compile log')
result = subprocess.run([str(output / 'InstallerProbe.exe'), str(package), str(scripts), str(startup), str(macros),
                         str(profile), str(runtime), match.group(1)], text=True, capture_output=True)
(output / 'install.log').write_text(result.stdout+result.stderr, encoding='utf-8')
release_line = next((line for line in result.stdout.splitlines() if line.startswith('RELEASE\t')), None)
if result.returncode or release_line is None:
    raise RuntimeError('MZP installer engine failed; inspect the owned install log')
release = Path(release_line.split('\t', 1)[1]).resolve()
if not release.is_relative_to(output):
    raise ValueError('Installer release escaped its owned profile')
installed = {'2027': {'release': str(release), 'startup': str(startup), 'macros': str(macros), 'profile': str(profile)}}
(output / 'installed.json').write_text(json.dumps(installed, indent=2), encoding='utf-8')
receipt = {'status': 'pass', 'scope': 'Exact MZP installer engine in a disposable profile; Max UI and installed startup are separate checks',
           'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'release': str(release),
           'script_sha256': hashlib.sha256((release / 'CyrusScatter.ms').read_bytes()).hexdigest(),
           'native_sha256': hashlib.sha256((release / 'bin/AminScatter.dlx').read_bytes()).hexdigest()}
(output / 'receipt.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
print(json.dumps(receipt, indent=2))
