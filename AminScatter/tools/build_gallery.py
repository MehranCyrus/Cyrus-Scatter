"""Compile the bounded gallery against the selected Max host's managed runtime."""
from pathlib import Path
import argparse, hashlib, json, re, subprocess, sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from build_inputs import frozen, managed_pending, managed_complete, tool_versions

def release_version():
    versions = re.findall(r'project\(CyrusScatter VERSION ([0-9.]+) LANGUAGES CXX\)',
                          (ROOT/'AminScatter/CMakeLists.txt').read_text(encoding='utf-8'))
    if len(versions) != 1:
        raise ValueError('One Scatter release version is required for the gallery assembly.')
    return '.'.join(versions[0].split('.') + ['0'] * (4-len(versions[0].split('.'))))

def build(output: Path, year: int = 2027):
    compiler = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
    if year not in (2024,2026,2027): raise ValueError('Unsupported Max year')
    runtime = '10.0.0' if year == 2027 else '8.0.16'
    core = Path('C:/Program Files/dotnet/shared/Microsoft.NETCore.App') / runtime
    desktop = Path('C:/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App') / runtime
    names = ['System.Private.CoreLib', 'System.Runtime', 'System.Collections', 'System.Threading',
             'System.Threading.Tasks', 'System.Security.Cryptography', 'System.Memory', 'System.Drawing.Primitives',
             'System.ComponentModel.Primitives', 'System.ComponentModel', 'System.Runtime.InteropServices',
             'System.Text.Json', 'System.Text.Encodings.Web','System.Text.RegularExpressions','System.IO.Compression','System.Linq','System.IO.FileSystem.DriveInfo','System.Diagnostics.Process']
    references = [core / (name + '.dll') for name in names]
    references += [desktop / (name + '.dll') for name in ['System.Windows.Forms', 'System.Windows.Forms.Primitives', 'System.Drawing.Common']]
    if year == 2027: references += [desktop / (name + '.dll') for name in ['System.Private.Windows.Core','System.Private.Windows.GdiPlus']]
    if year == 2024:
        framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
        references=[framework/(name+'.dll') for name in ['mscorlib','System','System.Core','System.Drawing','System.Windows.Forms','System.IO.Compression']]
    source = ROOT / 'AminScatter/ui/LibraryGallery.cs'
    shared = sorted((ROOT/'AminScatter/shared').glob('*.cs'))
    for path in [compiler, source, *references]:
        if not path.is_file(): raise FileNotFoundError(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    version = release_version()
    identity = output.with_suffix('.identity.cs')
    identity.write_text('[assembly:System.Reflection.AssemblyVersion("'+version+'")]\n'+
                        '[assembly:System.Reflection.AssemblyFileVersion("'+version+'")]\n', encoding='utf-8')
    args = [str(compiler), '/nologo', '/noconfig', '/nostdlib+', '/langversion:latest', '/nullable:enable',
            '/warnaserror+', '/target:library', '/optimize+', '/deterministic+', '/platform:x64', '/out:' + str(output),
            *('/reference:' + str(p) for p in references), str(source), *(str(p) for p in shared), str(identity)]
    inputs = frozen([compiler, source, *shared, identity,
                     ROOT/'AminScatter/CMakeLists.txt', Path(__file__), ROOT/'tools/build_inputs.py',
                     Path(sys.executable), *references],
                    {'producer':'gallery', 'command':args, 'max_year':year, 'assembly_version':version,
                     'tool_versions':tool_versions([compiler])}, ROOT)
    managed_pending(output, 'gallery')
    result = subprocess.run(args, text=True, capture_output=True)
    output.with_suffix('.build.log').write_text(result.stdout + result.stderr, encoding='utf-8')
    if result.returncode: raise RuntimeError(result.stdout + result.stderr)
    assembly_path = str(output).replace("'", "''")
    actual = subprocess.check_output(['powershell.exe','-NoProfile','-NonInteractive','-Command',
        "[Reflection.AssemblyName]::GetAssemblyName('"+assembly_path+"').Version.ToString()"], text=True).strip()
    if actual != version:
        raise RuntimeError('Compiled gallery assembly version differs from the Scatter release: '+actual)
    if release_version()!=version:
        raise RuntimeError('Scatter release identity changed while compiling the gallery.')
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    managed_complete(output, 'gallery', inputs, ROOT, {'compiler': str(compiler), 'compiler_sha256': sha(compiler),
        'source_sha256': sha(source), 'shared_source_sha256':sha(ROOT/'AminScatter/shared/LibraryLocation.cs'), 'artifact_sha256': sha(output), 'assembly_version':actual, 'identity_sha256':sha(identity), 'max_year':year,'framework': 'net48' if year==2024 else 'net'+runtime+'-windows',
        'references': {str(p): sha(p) for p in references}})
    print('Built', output)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--year',type=int,choices=(2024,2026,2027),default=2027)
    args=parser.parse_args();build(args.output.resolve(),args.year)
