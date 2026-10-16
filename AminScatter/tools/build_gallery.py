"""Compile the bounded Max 2027 gallery against its installed .NET 10 runtime."""
from pathlib import Path
import argparse, hashlib, json, subprocess

ROOT = Path(__file__).resolve().parents[2]

def build(output: Path):
    compiler = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
    core = Path('C:/Program Files/dotnet/shared/Microsoft.NETCore.App/10.0.0')
    desktop = Path('C:/Program Files/dotnet/shared/Microsoft.WindowsDesktop.App/10.0.0')
    names = ['System.Private.CoreLib', 'System.Runtime', 'System.Collections', 'System.Threading',
             'System.Threading.Tasks', 'System.Security.Cryptography', 'System.Memory', 'System.Drawing.Primitives',
             'System.ComponentModel.Primitives', 'System.ComponentModel', 'System.Runtime.InteropServices']
    references = [core / (name + '.dll') for name in names]
    references += [desktop / (name + '.dll') for name in ['System.Windows.Forms', 'System.Windows.Forms.Primitives', 'System.Drawing.Common',
                                                        'System.Private.Windows.Core', 'System.Private.Windows.GdiPlus']]
    source = ROOT / 'AminScatter/ui/LibraryGallery.cs'
    for path in [compiler, source, *references]:
        if not path.is_file(): raise FileNotFoundError(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    args = [str(compiler), '/nologo', '/noconfig', '/nostdlib+', '/langversion:latest', '/nullable:enable',
            '/warnaserror+', '/target:library', '/optimize+', '/deterministic+', '/platform:x64', '/out:' + str(output),
            *('/reference:' + str(p) for p in references), str(source)]
    result = subprocess.run(args, text=True, capture_output=True)
    output.with_suffix('.build.log').write_text(result.stdout + result.stderr, encoding='utf-8')
    if result.returncode: raise RuntimeError(result.stdout + result.stderr)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    output.with_suffix('.build.json').write_text(json.dumps({'compiler': str(compiler), 'compiler_sha256': sha(compiler),
        'source_sha256': sha(source), 'artifact_sha256': sha(output), 'framework': 'net10.0-windows',
        'references': {str(p): sha(p) for p in references}}, indent=2) + '\n', encoding='utf-8')
    print('Built', output)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    build(parser.parse_args().output.resolve())
