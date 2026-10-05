"""Freeze/build the ordinary candidate; test only disposable Max profiles.

No MZP, normal-profile install, commit or external publication is performed.
"""
from pathlib import Path
import argparse,json,re,sys,time,shutil
import psutil
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/licensing_lab'))
from run import snapshot,run_command,write_json,digest,compiler_environment
from run_installation import launch_private
from runtime_driver import run_script
from build_max import reject_development_binary

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--run',required=True)
    parser.add_argument('--reuse-build',type=Path,help='Reuse verified identical compiled sources after a fixture-only correction')
    args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+',args.run):raise SystemExit('Invalid run name')
    out=ROOT/'build/qualification-07-20261005'/args.run;out.mkdir(parents=True,exist_ok=False)
    env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    run_command([sys.executable,ROOT/'tools/procedural_lab/check_generated.py'],out/'generated',env)
    source=snapshot(out);builds={}
    if args.reuse_build:
        origin=args.reuse_build.resolve()
        if not origin.is_relative_to(ROOT/'build/qualification-07-20261005'):raise ValueError('Private build required')
        for entry in json.loads((origin/'source.json').read_text())['files']:
            if entry['path'].startswith(('AminScatter/','cmake/','CyrusLicensing/')) and digest(ROOT/entry['path'])!=entry['sha256']:
                raise RuntimeError('Compiled source changed: '+entry['path'])
        for year in [2026,2027]:
            if json.loads((origin/f'tests-{year}.json').read_text())['exit_code']!=0:raise RuntimeError('Prior tests failed')
            target=out/f'max{year}';target.mkdir()
            for p in (origin/f'max{year}').glob('*.dl?'):shutil.copy2(p,target/p.name)
            shutil.copy2(origin/f'tests-{year}.log',out/f'tests-{year}.log')
        write_json(out/'reused-build.json',{'origin':str(origin),'compiled_sources_match':True,'reason':'Private UI fixture requires procedural07-ui profile prefix'})
    for year in [2026,2027]:
        target=out/f'max{year}';sdk=ROOT/f'build/tooling/max{year}-sdk/Program Files/Autodesk/3ds Max {year} SDK/maxsdk'
        if not args.reuse_build:
            run_command(['cmake','-S',source/'AminScatter','-B',target,'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',
                '-DCYRUS_NATIVE_LICENSE_EXPERIMENT=OFF','-DCYRUS_LICENSE_INSTALLATION_CONTEXT=OFF',
                f'-DCYRUS_MAX_YEAR={year}',f'-DMAXSDK_ROOT={sdk}'],out/f'configure-{year}',env)
            run_command(['cmake','--build',target],out/f'build-{year}',env,timeout=600)
            run_command(['ctest','--test-dir',target,'--output-on-failure','-V'],out/f'tests-{year}',env)
        builds[str(year)]={p.name:digest(p) for p in target.glob('*.dl?')}
        for p in target.glob('*.dl?'):reject_development_binary(p.name,p.read_bytes())
    run_command([ROOT/'build/mcp-venv/Scripts/python.exe','-m','pytest',ROOT/'CyrusMCP/tests','-q'],out/'mcp-tests',env)
    startup='fileIn @"'+(source/'AminScatter/scripts/AminScatterObject.ms').as_posix()+'"\nglobal CyrusPerfHeadless=true\n'
    startup+='fileIn @"'+(source/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\n'
    startup+='fileIn @"'+(source/'tools/procedural_lab/Max_Procedural_07_Acceptance.ms').as_posix()+'"\n'
    process,folder=launch_private(source,out,out/'max2027','ordinary',startup_source=startup,profile_prefix='procedural07-ui')
    results=[]
    def execute(label,script):
        result=run_script(folder,script,timeout=600);print(label+': '+result.strip(),flush=True)
        results.append({'stage':label,'result':result.strip()})
        write_json(out/'max-stages.json',results)
        if not result.startswith('SUCCESS '):raise RuntimeError(result)
    try:
        execute('loaded identities','if cyrusOwnedLabStatus!=undefined or cyrusOwnedLabBrushEnd!=undefined do throw "Development authority leaked"\n'+
            'local p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),f=createFile (MCPFixtureDir+"loaded.tsv")\n'+
            'for i=0 to p.Modules.Count-1 do (local m=p.Modules.Item[i];format "%\\t%\\n" m.ModuleName m.FileName to:f)\nclose f')
        loaded={}
        for line in (folder/'loaded.tsv').read_text(encoding='utf-8-sig').splitlines():
            name,path=line.split('\t',1)
            if name in builds['2027']:
                if Path(path).resolve()!=(folder/'bin'/name).resolve() or digest(Path(path))!=builds['2027'][name]:raise RuntimeError('Mixed native module: '+name)
                loaded[name]=digest(Path(path))
        if loaded!=builds['2027']:raise RuntimeError('Missing native module')
        execute('core','P07Acceptance()')
        for name in ['Max_Procedural_07_Bindings.ms','Max_Procedural_07_UI_Acceptance.ms','Max_Procedural_07_Regression.ms',
                     'Max_Source_Containers_Acceptance.ms','Max_Source_Containers_EdgeCases.ms','Max_Source_Containers_Output.ms']:
            execute(name,(source/'tools/procedural_lab'/name).read_text())
        execute('Live event setup',(source/'tools/procedural_lab/Max_Source_Containers_Events.ms').read_text()+'\nSCEventSetup()')
        for stage in ['SCEventPark','SCEventReturn','SCEventEnroll','SCEventFinish','SCEventGroupFinish','SCEventContainerReturn','SCEventGeometry','SCEventGeometryFinish']:
            time.sleep(1);execute(stage,stage+'()')
        execute('retained 100k navigation',(source/'tools/procedural_lab/Max_Procedural_07_Navigation.ms').read_text()+
            '\nP07Navigation "final-container-100k" 100000 procedural:true frames:30 modes:#(0,1,3,4) containers:true')
        # Freeze verifies hard-coded historical fixture paths did not diverge.
        for entry in json.loads((out/'source.json').read_text())['files']:
            if digest(ROOT/entry['path'])!=entry['sha256']:raise RuntimeError('Source changed during qualification: '+entry['path'])
        write_json(out/'result.json',{'status':'PASS','product':'0.7.0','serialization':53,
            'script_sha256':digest(source/'AminScatter/scripts/AminScatterObject.ms'),'native':builds,'loaded':loaded,
            'max_runtime':2027,'Max2026_runtime_qualified':False,'private_profile':str(folder),
            'licensing_enforcement':False,'stages':results,'package_created':False})
    finally:
        if process.poll() is None:
            if str(folder/'max.ini') not in psutil.Process(process.pid).cmdline():raise RuntimeError('Unrelated Max process')
            process.terminate();process.wait(timeout=30)
    print('PASS ordinary candidate '+str(out),flush=True)

if __name__=='__main__':main()
