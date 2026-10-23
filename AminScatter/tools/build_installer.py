"""Build the small installer core without installing it or changing a profile."""
from pathlib import Path
import argparse, hashlib, json, re, subprocess, sys, zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from build_inputs import (CORE_SOURCES, frozen, managed_pending, managed_complete,
                          verify_managed, producer_link, tool_versions, verify_package_receipt)


def verify_core(path):
    return verify_managed(path, 'installer-core', ROOT,
        (*CORE_SOURCES, 'AminScatter/tools/build_installer.py', 'tools/build_inputs.py'))


def build(output: Path):
    compiler = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
    framework = Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
    source = ROOT / 'AminScatter/setup/InstallEngine.cs'
    analyzer_source = ROOT / 'AminScatter/setup/AnalyzerInstallEngine.cs'
    references = [framework / name for name in ('mscorlib.dll', 'System.dll', 'System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll','System.IO.Compression.dll')]
    sources = [ROOT/name for name in CORE_SOURCES]
    for path in [compiler, *sources, *references]:
        if not path.is_file(): raise FileNotFoundError(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    command = [str(compiler), '/nologo', '/noconfig', '/nostdlib+', '/langversion:latest', '/warnaserror+',
               '/target:library', '/optimize+', '/deterministic+', '/platform:x64', '/out:' + str(output),
               *('/reference:' + str(path) for path in references), *(str(path) for path in sources)]
    inputs = frozen([compiler, *sources, *references, Path(__file__), ROOT/'tools/build_inputs.py', Path(sys.executable)],
                    {'producer':'installer-core', 'command':command, 'framework':'net48',
                     'tool_versions':tool_versions([compiler])}, ROOT)
    managed_pending(output, 'installer-core')
    result = subprocess.run(command, text=True, capture_output=True)
    output.with_suffix('.build.log').write_text(result.stdout + result.stderr, encoding='utf-8')
    if result.returncode: raise RuntimeError(result.stdout + result.stderr)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    assembly_path=str(output).replace("'", "''")
    mvid=subprocess.check_output(['powershell.exe','-NoProfile','-NonInteractive','-Command',
        "([Reflection.Assembly]::ReflectionOnlyLoadFrom('"+assembly_path+"')).ManifestModule.ModuleVersionId.ToString()"],text=True).strip().lower()
    if not re.fullmatch('[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}',mvid):
        raise ValueError('The compiled installer module identity is unavailable.')
    managed_complete(output, 'installer-core', inputs, ROOT, {'compiler': str(compiler), 'compiler_sha256': sha(compiler),
        'source_sha256': sha(source), 'analyzer_source_sha256':sha(analyzer_source), 'options_source_sha256':sha(ROOT/'AminScatter/setup/LibraryOptions.cs'), 'shared_source_sha256':sha(ROOT/'AminScatter/shared/LibraryLocation.cs'), 'artifact_sha256': sha(output), 'framework': 'net48; Max host loading requires qualification',
        'module_version_id':mvid, 'backup_source_sha256':sha(ROOT/'AminScatter/setup/VerifiedBackup.cs'),
        'references': {str(path): sha(path) for path in references}})
    print('Built', output)


def build_exe(output: Path, package: Path | list[Path], core: Path, analyzer_packages: list[Path] | None = None):
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    receipt=verify_core(core)
    assert receipt['artifact_sha256']==sha(core)
    assert receipt['source_sha256']==sha(ROOT/'AminScatter/setup/InstallEngine.cs')
    assert receipt['analyzer_source_sha256']==sha(ROOT/'AminScatter/setup/AnalyzerInstallEngine.cs')
    assert receipt['shared_source_sha256']==sha(ROOT/'AminScatter/shared/LibraryLocation.cs')
    assert receipt['options_source_sha256']==sha(ROOT/'AminScatter/setup/LibraryOptions.cs')
    packages=[package] if isinstance(package,Path) else package
    descriptors=[]
    for item in packages:
        package_receipt=verify_package_receipt(item,ROOT)
        with zipfile.ZipFile(item) as archive:
            assert archive.testzip() is None
            manifest=json.loads(archive.read('manifest.json'))
            if (manifest.get('build_evidence_schema')!='cyrus.package-inputs/2'
                    or manifest.get('producer_receipts')!=package_receipt.get('producer_receipts')
                    or manifest['producer_receipts'].get('installer')!=producer_link(core,receipt)):
                raise ValueError('Scatter package does not bind the current complete installer producer.')
            assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
            for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
            assert manifest['files']['CyrusInstaller.dll']==sha(core)
            inventory=archive.read('InstallInventory.txt')
            marker,version,year,content_id=inventory.decode('utf-8').splitlines()[0].split('\t')
            assert marker in ('CyrusScatterInstall1','CyrusScatterInstall2') and year in ('2024','2026','2027')
            assert manifest['max_year']==int(year)
            external=json.loads(archive.read('ExternalContent.json')) if 'ExternalContent.json' in archive.namelist() else None
            descriptors.append({'year':year,'version':version,'path':str(item),'package_sha256':sha(item),
                'inventory_sha256':hashlib.sha256(inventory).hexdigest(),'resource':'Cyrus.Payload.'+year+'.mzp',
                'external_content':external})
    descriptors.sort(key=lambda item:item['year'])
    assert len({d['year'] for d in descriptors})==len(descriptors) and len({d['version'] for d in descriptors})==1
    analyzers=[]
    for item in analyzer_packages or []:
        package_receipt=verify_package_receipt(item,ROOT)
        with zipfile.ZipFile(item) as archive:
            assert archive.testzip() is None
            manifest=json.loads(archive.read('manifest.json'))
            if (manifest.get('build_evidence_schema')!='cyrus.package-inputs/2'
                    or manifest.get('producer_receipts')!=package_receipt.get('producer_receipts')
                    or manifest['producer_receipts'].get('installer')!=producer_link(core,receipt)):
                raise ValueError('Analyzer package does not bind the current complete installer producer.')
            assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
            for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
            year=str(manifest['max_year'])
            assert year in ('2024','2026','2027')
            native=archive.read('CyrusSurfaceAnalyzer.dlx');script=archive.read('CyrusSurfaceAnalyzer.ms')
            startup=archive.read('CyrusSurfaceAnalyzerStartup.ms');installer=archive.read('install.ms')
            runtime_id=hashlib.sha256(native+script).hexdigest()[:16]
            descriptor=archive.read('AnalyzerPackage.txt')
            expected=('CyrusAnalyzerPackage1\n'+year+'\n'+manifest['version']+'\n'+runtime_id+'\n'+
                hashlib.sha256(native).hexdigest()+'\n'+hashlib.sha256(script).hexdigest()+'\n'+hashlib.sha256(startup).hexdigest()+'\n').encode()
            if descriptor!=expected or archive.read('CyrusInstaller.dll')!=core.read_bytes():
                raise ValueError('Analyzer descriptor/helper differs from the shared installer core.')
            if (hashlib.sha256(descriptor).hexdigest().encode() not in installer
                    or receipt['module_version_id'].encode() not in installer
                    or str((int(year)-1998)*1000).encode() not in installer or b'__' in installer):
                raise ValueError('Analyzer host adapter does not bind the exact descriptor/helper/host.')
            analyzers.append({'year':year,'version':manifest['version'],'path':str(item),'package_sha256':sha(item),
                'resource':'Cyrus.Analyzer.'+year+'.mzp','runtime_id':runtime_id,
                'native_sha256':hashlib.sha256(native).hexdigest(),'script_sha256':hashlib.sha256(script).hexdigest(),
                'startup_sha256':hashlib.sha256(startup).hexdigest()})
    analyzers.sort(key=lambda d:d['year'])
    if analyzers:
        assert [d['year'] for d in analyzers]==[d['year'] for d in descriptors]
        assert len({d['version'] for d in analyzers})==1
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
            for name,key in [('Years','year'),('PackageHashes','package_sha256'),('InventoryHashes','inventory_sha256'),('Resources','resource')])+
        ''.join('public static readonly string[] '+name+'=new string[]{'+','.join(json.dumps(d[key]) for d in analyzers)+'};'
            for name,key in [('AnalyzerPackageHashes','package_sha256'),('AnalyzerResources','resource')])+
        'public static readonly AnalyzerPackage[] AnalyzerPackages=new AnalyzerPackage[]{'+
        ','.join('new AnalyzerPackage('+','.join(json.dumps(d[k]) for k in ('year','version','runtime_id','native_sha256','script_sha256','startup_sha256'))+')' for d in analyzers)+'}; } }\n',encoding='utf-8')
    compiler=Path(receipt['compiler'])
    framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
    references=[framework/name for name in ('mscorlib.dll','System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll','System.IO.Compression.dll')]
    sources=[ROOT/name for name in CORE_SOURCES]+[ROOT/'AminScatter/setup/Distribution.cs', ROOT/'AminScatter/setup/Program.cs']
    manifest_path=ROOT/'AminScatter/setup/app.manifest'
    command=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+',
             '/target:winexe','/optimize+','/deterministic+','/platform:x64','/out:'+str(output),
             '/win32manifest:'+str(manifest_path),*('/resource:'+d['path']+','+d['resource'] for d in descriptors+analyzers),
             *('/reference:'+str(path) for path in references),*(str(path) for path in sources),str(identity)]
    for descriptor in descriptors+analyzers:
        if sha(Path(descriptor['path']))!=descriptor['package_sha256']:
            raise ValueError('An embedded package changed while preparing the EXE identity.')
    inputs=frozen([compiler,*sources,*references,manifest_path,identity,core,core.with_suffix('.build.json'),
                   *packages,*(analyzer_packages or []),*(p.with_suffix('.build.json') for p in packages+(analyzer_packages or [])),
                   Path(__file__),ROOT/'tools/build_inputs.py',Path(sys.executable)],
                  {'producer':'installer-exe','command':command,'version':version,
                   'core_producer':producer_link(core,receipt),'tool_versions':tool_versions([compiler])},ROOT)
    managed_pending(output,'installer-exe')
    result=subprocess.run(command,text=True,capture_output=True)
    output.with_suffix('.build.log').write_text(result.stdout+result.stderr,encoding='utf-8')
    if result.returncode:raise RuntimeError(result.stdout+result.stderr)
    verify_core(core)
    managed_complete(output,'installer-exe',inputs,ROOT,{'artifact_sha256':sha(output),'packages':descriptors,'analyzer_packages':analyzers,
        'core_sha256':sha(core),'version':version,'max_years':[int(d['year']) for d in descriptors],
        'signed':False,'runtime':'.NET Framework 4.8 (Windows)','compiler':str(compiler),'compiler_sha256':sha(compiler),
        'sources':{str(path.relative_to(ROOT)):sha(path) for path in [*sources,manifest_path]},
        'references':{str(path):sha(path) for path in references},'core_producer':producer_link(core,receipt)})
    print('Built unsigned EXE',output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--package', type=Path,action='append')
    parser.add_argument('--core', type=Path)
    parser.add_argument('--analyzer-package', type=Path,action='append')
    args=parser.parse_args()
    if args.package:
        if not args.core:parser.error('--package requires --core')
        build_exe(args.output.resolve(),[p.resolve() for p in args.package],args.core.resolve(),[p.resolve() for p in args.analyzer_package or []])
    else:
        build(args.output.resolve())
