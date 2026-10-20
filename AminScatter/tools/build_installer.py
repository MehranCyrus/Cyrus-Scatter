"""Build the small installer core without installing it or changing a profile."""
from pathlib import Path
import argparse, hashlib, json, subprocess, zipfile

ROOT = Path(__file__).resolve().parents[2]


def build(output: Path):
    compiler = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
    framework = Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
    source = ROOT / 'AminScatter/setup/InstallEngine.cs'
    references = [framework / name for name in ('mscorlib.dll', 'System.dll', 'System.Core.dll')]
    for path in [compiler, source, *references]:
        if not path.is_file(): raise FileNotFoundError(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    command = [str(compiler), '/nologo', '/noconfig', '/nostdlib+', '/langversion:latest', '/warnaserror+',
               '/target:library', '/optimize+', '/deterministic+', '/platform:x64', '/out:' + str(output),
               *('/reference:' + str(path) for path in references), str(source)]
    result = subprocess.run(command, text=True, capture_output=True)
    output.with_suffix('.build.log').write_text(result.stdout + result.stderr, encoding='utf-8')
    if result.returncode: raise RuntimeError(result.stdout + result.stderr)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    output.with_suffix('.build.json').write_text(json.dumps({'compiler': str(compiler), 'compiler_sha256': sha(compiler),
        'source_sha256': sha(source), 'artifact_sha256': sha(output), 'framework': 'net48; Max 2027 loading requires host qualification',
        'references': {str(path): sha(path) for path in references}}, indent=2) + '\n', encoding='utf-8')
    print('Built', output)


def build_exe(output: Path, package: Path | list[Path], core: Path):
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    receipt=json.loads(core.with_suffix('.build.json').read_text(encoding='utf-8'))
    assert receipt['artifact_sha256']==sha(core)
    assert receipt['source_sha256']==sha(ROOT/'AminScatter/setup/InstallEngine.cs')
    packages=[package] if isinstance(package,Path) else package
    descriptors=[]
    for item in packages:
        with zipfile.ZipFile(item) as archive:
            assert archive.testzip() is None
            manifest=json.loads(archive.read('manifest.json'))
            assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
            for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
            assert manifest['files']['CyrusInstaller.dll']==sha(core)
            inventory=archive.read('InstallInventory.txt')
            marker,version,year,content_id=inventory.decode('utf-8').splitlines()[0].split('\t')
            assert marker in ('CyrusScatterInstall1','CyrusScatterInstall2') and year in ('2024','2026','2027')
            assert manifest['max_year']==int(year)
            descriptors.append({'year':year,'version':version,'path':str(item),'package_sha256':sha(item),
                'inventory_sha256':hashlib.sha256(inventory).hexdigest(),'resource':'Cyrus.Payload.'+year+'.mzp'})
    descriptors.sort(key=lambda item:item['year'])
    assert len({d['year'] for d in descriptors})==len(descriptors) and len({d['version'] for d in descriptors})==1
    version=descriptors[0]['version']
    output.parent.mkdir(parents=True,exist_ok=True)
    identity=output.with_suffix('.identity.cs')
    assembly_version='.'.join(version.split('.')+['0']*(4-len(version.split('.'))))
    identity.write_text('[assembly:System.Reflection.AssemblyTitle("Cyrus Scatter Installer")]\n'+
        '[assembly:System.Reflection.AssemblyProduct("Cyrus Scatter")]\n'+
        '[assembly:System.Reflection.AssemblyVersion("'+assembly_version+'")]\n'+
        '[assembly:System.Reflection.AssemblyFileVersion("'+assembly_version+'")]\n'+
        '[assembly:System.Reflection.AssemblyInformationalVersion("'+version+'")]\n'+
        'namespace Cyrus.Setup { internal static class BuildIdentity { public const string Version="'+version+'"; '+
        ''.join('public static readonly string[] '+name+'=new string[]{'+','.join(json.dumps(d[key]) for d in descriptors)+'};'
            for name,key in [('Years','year'),('PackageHashes','package_sha256'),('InventoryHashes','inventory_sha256'),('Resources','resource')])+' } }\n',encoding='utf-8')
    compiler=Path(receipt['compiler'])
    framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
    references=[framework/name for name in ('mscorlib.dll','System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll','System.IO.Compression.dll')]
    sources=[ROOT/'AminScatter/setup'/name for name in ('InstallEngine.cs','Distribution.cs','Program.cs')]
    manifest_path=ROOT/'AminScatter/setup/app.manifest'
    command=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+',
             '/target:winexe','/optimize+','/deterministic+','/platform:x64','/out:'+str(output),
             '/win32manifest:'+str(manifest_path),*('/resource:'+d['path']+','+d['resource'] for d in descriptors),
             *('/reference:'+str(path) for path in references),*(str(path) for path in sources),str(identity)]
    result=subprocess.run(command,text=True,capture_output=True)
    output.with_suffix('.build.log').write_text(result.stdout+result.stderr,encoding='utf-8')
    if result.returncode:raise RuntimeError(result.stdout+result.stderr)
    output.with_suffix('.build.json').write_text(json.dumps({'artifact_sha256':sha(output),'packages':descriptors,
        'core_sha256':sha(core),'version':version,'max_years':[int(d['year']) for d in descriptors],
        'signed':False,'runtime':'.NET Framework 4.8 (Windows)','compiler':str(compiler),'compiler_sha256':sha(compiler),
        'sources':{str(path.relative_to(ROOT)):sha(path) for path in [*sources,manifest_path]},
        'references':{str(path):sha(path) for path in references}},indent=2)+'\n',encoding='utf-8')
    print('Built unsigned EXE',output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--package', type=Path,action='append')
    parser.add_argument('--core', type=Path)
    args=parser.parse_args()
    if args.package:
        if not args.core:parser.error('--package requires --core')
        build_exe(args.output.resolve(),[p.resolve() for p in args.package],args.core.resolve())
    else:
        build(args.output.resolve())
